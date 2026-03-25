#!/usr/bin/env node
/**
 * OpenClaw Subagents TUI Dashboard - FIXED VERSION
 * Reads session transcripts directly from .jsonl files for complete data
 */

import blessed from 'blessed';
import { exec } from 'child_process';
import { promisify } from 'util';
import { readFile, readdir } from 'fs/promises';
import { join } from 'path';
import { homedir } from 'os';

const execAsync = promisify(exec);

// ============================================================================
// Data Layer
// ============================================================================

async function getSessionMetadata(sessionId) {
  try {
    const sessionPath = join(homedir(), '.openclaw/agents/main/sessions', `${sessionId}.jsonl`);
    const content = await readFile(sessionPath, 'utf-8');
    const lines = content.trim().split('\n');
    
    let startTime = null;
    let lastActivity = null;
    let taskText = null;
    let inputTokens = 0;
    let outputTokens = 0;
    
    // Parse all entries
    for (const line of lines) {
      try {
        const entry = JSON.parse(line);
        
        // Get session start timestamp
        if (!startTime && entry.type === 'session' && entry.timestamp) {
          startTime = new Date(entry.timestamp).getTime();
        }
        
        // Track last activity
        if (entry.timestamp) {
          const ts = new Date(entry.timestamp).getTime();
          if (!lastActivity || ts > lastActivity) {
            lastActivity = ts;
          }
        }
        
        // Get token usage from assistant messages
        if (entry.type === 'message' && entry.message && entry.message.usage) {
          const u = entry.message.usage;
          // Accumulate input/output from each turn
          if (u.input) inputTokens += u.input;
          if (u.output) outputTokens += u.output;
        }
        
        // Get task text (only first user message)
        if (!taskText && entry.type === 'message' && entry.message && entry.message.role === 'user') {
          const textParts = entry.message.content
            .filter(c => c.type === 'text')
            .map(c => c.text);
          
          if (textParts.length === 0) continue;
          
          const fullText = textParts.join('\n');
          
          // Look for [Subagent Task]: marker
          const taskMatch = fullText.match(/\[Subagent Task\]:\s*(.+?)(?:\n\n|$)/s);
          if (taskMatch) {
            taskText = taskMatch[1].trim();
            continue; // Keep parsing for tokens
          }
          
          // Fallback: skip [Subagent Context] header
          const textLines = fullText.split('\n');
          let foundContext = false;
          let taskLines = [];
          
          for (const l of textLines) {
            if (l.includes('[Subagent Context]')) {
              foundContext = true;
              continue;
            }
            if (foundContext && l.trim()) {
              taskLines.push(l);
            }
          }
          
          if (taskLines.length > 0) {
            taskText = taskLines.join('\n').trim();
          }
        }
      } catch (parseError) {
        continue;
      }
    }
    
    // Calculate real status
    const now = Date.now();
    const ageMs = lastActivity ? now - lastActivity : 0;
    const isRunning = ageMs < 120000; // < 2 minutes = still running
    
    // Check if session ended cleanly (last entry is "custom" = completion message)
    // vs was interrupted (last entry is mid-execution, e.g. toolResult)
    let endedCleanly = false;
    try {
      const lastLine = lines[lines.length - 1];
      const lastEntry = JSON.parse(lastLine);
      endedCleanly = lastEntry.type === 'custom';
    } catch (e) { /* ignore */ }
    
    return {
      taskText,
      startTime,
      lastActivity,
      inputTokens,
      outputTokens,
      totalTokens: inputTokens + outputTokens,
      isRunning,
      endedCleanly,
      ageMs
    };
  } catch (e) {
    return {
      taskText: null,
      startTime: null,
      lastActivity: null,
      inputTokens: 0,
      outputTokens: 0,
      totalTokens: 0,
      isRunning: false,
      endedCleanly: false,
      ageMs: 0
    };
  }
}

async function getSessionTask(sessionId) {
  const { taskText } = await getSessionMetadata(sessionId);
  return taskText;
}

async function getSessionLabel(sessionId) {
  try {
    const fullTask = await getSessionTask(sessionId);
    if (!fullTask) return null;
    
    // Extract a meaningful summary from the full task
    const lines = fullTask.split('\n').filter(l => l.trim());
    
    // Prefer markdown headers (## or **bold**)
    for (const line of lines) {
      if (line.match(/^#+\s+/) || line.match(/^\*\*.*\*\*$/)) {
        const cleaned = line.replace(/^#+\s+/, '').replace(/^\*\*/, '').replace(/\*\*$/, '').trim();
        if (cleaned.length > 10) {
          return cleaned.slice(0, 200);
        }
      }
    }
    
    // Otherwise take first substantial line
    for (const line of lines) {
      if (line.length > 20) {
        return line.slice(0, 200);
      }
    }
    
    // Fallback: first 200 chars
    return fullTask.slice(0, 200);
  } catch (e) {
    return null;
  }
}

async function fetchSubagents() {
  try {
    // Read runs.json directly - the source of truth for subagent status
    const runsPath = join(homedir(), '.openclaw/subagents/runs.json');
    const runsContent = await readFile(runsPath, 'utf-8');
    const runsData = JSON.parse(runsContent);
    
    // Build map: childSessionKey → run data
    // runs.json has runs as an object keyed by runId
    const runsMap = new Map();
    const runsObj = runsData.runs || {};
    for (const runId of Object.keys(runsObj)) {
      const run = runsObj[runId];
      if (run && run.childSessionKey) {
        runsMap.set(run.childSessionKey, run);
      }
    }
    
    // Get session list from OpenClaw
    const { stdout: sessionsOut } = await execAsync('openclaw sessions --json --active 180');
    const sessionsData = JSON.parse(sessionsOut);
    
    // Filter subagent sessions (key contains ':subagent:')
    const subagentSessions = sessionsData.sessions
      .filter(s => s.key && s.key.includes(':subagent:'))
      .map(s => {
        const keyParts = s.key.split(':');
        const subagentUuid = keyParts[keyParts.length - 1];
        
        // Get run data from runs.json
        const run = runsMap.get(s.key);
        const isRunning = run && !run.endedAt;
        
        // Extract first line of task as label
        let taskLabel = null;
        let fullTask = null;
        if (run && run.task) {
          fullTask = run.task;
          const firstLine = run.task.split('\n')[0];
          taskLabel = firstLine.replace(/^\*\*/, '').replace(/\*\*$/, '').trim();
        }
        
        return {
          key: s.key,
          uuid: subagentUuid,
          sessionId: s.sessionId,
          agentId: s.agentId || 'unknown',
          model: run?.model || s.model || 'unknown',
          modelProvider: s.modelProvider || inferProvider(run?.model || s.model) || 'unknown',
          contextTokens: s.contextTokens || 200000,
          updatedAt: s.updatedAt,
          abortedLastRun: s.abortedLastRun || false,
          label: taskLabel,
          fullTask: fullTask,
          startTime: run?.startedAt || null,
          lastActivity: null,
          inputTokens: null,
          outputTokens: null,
          totalTokens: null,
          status: isRunning ? 'running' : 'pending_check', // will be refined with transcript data
          isRunning: isRunning,
          ageMs: 0,
        };
      });
    
    // Enrich with transcript data (tokens, timing)
    await Promise.all(
      subagentSessions.map(async (session) => {
        const metadata = await getSessionMetadata(session.sessionId);
        
        // Use transcript label if runs.json didn't have one
        if (!session.label) {
          session.label = await getSessionLabel(session.sessionId);
        }
        if (!session.fullTask) {
          session.fullTask = metadata.taskText;
        }
        
        // Always use transcript for timing and tokens
        if (!session.startTime) session.startTime = metadata.startTime;
        session.lastActivity = metadata.lastActivity;
        session.inputTokens = metadata.inputTokens;
        session.outputTokens = metadata.outputTokens;
        session.totalTokens = metadata.totalTokens;
        session.ageMs = metadata.ageMs;
        
        // Refine status for non-running sessions using transcript analysis
        if (session.status === 'pending_check') {
          if (metadata.endedCleanly) {
            session.status = 'completed';
          } else {
            session.status = 'stopped';
          }
        }
      })
    );
    
    // Debug: log count
    const { writeFile: dbgWrite } = await import('fs/promises');
    await dbgWrite('/tmp/tui-debug.log', `${new Date().toISOString()} fetchSubagents OK: ${subagentSessions.length} sessions, runsMap: ${runsMap.size}\n`, { flag: 'a' }).catch(() => {});
    
    return subagentSessions;
  } catch (error) {
    // Log error to file for debugging
    const { writeFile } = await import('fs/promises');
    await writeFile('/tmp/tui-debug.log', `${new Date().toISOString()} fetchSubagents error: ${error.message}\n${error.stack}\n`, { flag: 'a' }).catch(() => {});
    return [];
  }
}

function calculateStats(subagents) {
  return {
    total: subagents.length,
    active: subagents.filter(s => s.status === 'running').length,
    running: subagents.filter(s => s.status === 'running').length,
    totalTokens: subagents.reduce((sum, s) => sum + (s.totalTokens || 0), 0),
    avgTokens: subagents.length > 0
      ? Math.round(subagents.reduce((sum, s) => sum + (s.totalTokens || 0), 0) / subagents.length)
      : 0,
  };
}

function inferProvider(model) {
  if (!model) return null;
  if (model.includes('claude') || model.includes('sonnet') || model.includes('haiku') || model.includes('opus')) return 'anthropic';
  if (model.includes('gemini') || model.includes('google')) return 'google';
  if (model.includes('gpt') || model.includes('openai')) return 'openai';
  return null;
}

function getShortUuid(uuid) {
  return uuid.slice(0, 8);
}

function formatAge(ageMs) {
  const seconds = Math.floor(ageMs / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  
  if (hours > 0) return `${hours}h ${minutes % 60}m`;
  if (minutes > 0) return `${minutes}m ${seconds % 60}s`;
  return `${seconds}s`;
}

function formatTimestamp(timestampMs) {
  const date = new Date(timestampMs);
  return date.toLocaleString('es-ES', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
}

function truncateLabel(label, maxLength) {
  if (!label) return 'Unknown task';
  if (label.length <= maxLength) return label;
  return label.slice(0, maxLength - 3) + '...';
}

// ============================================================================
// UI Setup
// ============================================================================

const screen = blessed.screen({
  smartCSR: true,
  title: 'OpenClaw Subagents Dashboard',
  fullUnicode: true,
});

// Dashboard box (top)
const dashboardBox = blessed.box({
  top: 0,
  left: 0,
  width: '100%',
  height: 5,
  border: {
    type: 'line',
  },
  style: {
    border: {
      fg: 'cyan',
    },
  },
  tags: true,
});

// List box (left panel)
const listBox = blessed.list({
  top: 5,
  left: 0,
  width: '50%',
  height: '100%-8',
  keys: true,
  vi: true,
  mouse: true,
  border: {
    type: 'line',
  },
  style: {
    selected: {
      bg: 'blue',
      bold: true,
    },
    border: {
      fg: 'white',
    },
  },
  scrollbar: {
    ch: '█',
    style: {
      fg: 'cyan',
    },
  },
  tags: true,
  label: ' 📋 Subagents ',
});

// Detail box (right panel)
const detailBox = blessed.box({
  top: 5,
  left: '50%',
  width: '50%',
  height: '100%-8',
  border: {
    type: 'line',
  },
  style: {
    border: {
      fg: 'white',
    },
  },
  tags: true,
  label: ' 🔍 Details ',
  scrollable: true,
  alwaysScroll: true,
  scrollbar: {
    ch: '█',
    style: {
      fg: 'cyan',
    },
  },
});

// Status box (bottom)
const statusBox = blessed.box({
  bottom: 0,
  left: 0,
  width: '100%',
  height: 4,
  border: {
    type: 'line',
  },
  style: {
    border: {
      fg: 'white',
    },
  },
  tags: true,
});

screen.append(dashboardBox);
screen.append(listBox);
screen.append(detailBox);
screen.append(statusBox);

// ============================================================================
// State Management
// ============================================================================

let subagents = [];
let selectedIndex = 0;
let loading = false;

async function loadSessions() {
  loading = true;
  updateStatusBar();
  
  subagents = await fetchSubagents();
  
  // Sort: running first, then by start time (newest first)
  subagents.sort((a, b) => {
    if (a.status === 'running' && b.status !== 'running') return -1;
    if (a.status !== 'running' && b.status === 'running') return 1;
    return (b.startTime || 0) - (a.startTime || 0);
  });
  
  loading = false;
  updateDashboard();
  updateList();
  updateDetails();
  updateStatusBar();
  screen.render();
}

function updateDashboard() {
  const stats = calculateStats(subagents);
  
  const content = `{bold}{cyan-fg}📊 OpenClaw Subagents Dashboard{/cyan-fg}{/bold}

  {white-fg}Total:{/white-fg} {green-fg}{bold}${stats.total}{/bold}{/green-fg}    {white-fg}Active (<2 min):{/white-fg} {yellow-fg}{bold}${stats.active}{/bold}{/yellow-fg}    {white-fg}Total Tokens:{/white-fg} {cyan-fg}{bold}${stats.totalTokens.toLocaleString()}{/bold}{/cyan-fg}    {white-fg}Avg Tokens:{/white-fg} {magenta-fg}{bold}${stats.avgTokens.toLocaleString()}{/bold}{/magenta-fg}`;
  
  dashboardBox.setContent(content);
}

function updateList() {
  if (subagents.length === 0) {
    listBox.setItems(['{white-fg}No subagents found (last 3 hours){/white-fg}']);
    listBox.select(0);
    return;
  }
  
  const items = subagents.map((sub, index) => {
    // Status indicator
    let indicator;
    if (sub.status === 'running') {
      indicator = '{green-fg}●{/green-fg}';
    } else if (sub.status === 'completed') {
      indicator = '{cyan-fg}✓{/cyan-fg}';
    } else if (sub.status === 'stopped') {
      indicator = '{yellow-fg}⏹{/yellow-fg}';
    } else if (sub.status === 'aborted' || sub.status === 'failed') {
      indicator = '{red-fg}✗{/red-fg}';
    } else {
      indicator = '{yellow-fg}○{/yellow-fg}';
    }
    
    const shortId = getShortUuid(sub.uuid);
    const label = truncateLabel(sub.label, 28);
    const age = formatAge(sub.ageMs);
    
    return `${indicator} ${shortId} {white-fg}${label}{/white-fg} {cyan-fg}${age}{/cyan-fg}`;
  });
  
  listBox.setItems(items);
  listBox.select(selectedIndex);
}

function updateDetails() {
  if (subagents.length === 0) {
    detailBox.setContent('{white-fg}No subagent selected{/white-fg}');
    return;
  }
  
  const sub = subagents[selectedIndex];
  if (!sub) {
    detailBox.setContent('{white-fg}Select a subagent to view details{/white-fg}');
    return;
  }
  
  const tokenUsage = sub.contextTokens > 0 && sub.totalTokens > 0
    ? ((sub.totalTokens / sub.contextTokens) * 100).toFixed(1)
    : '0';
  const usageColor = parseFloat(tokenUsage) > 80 ? 'red' : 'green';
  
  // Status color
  let statusColor;
  if (sub.status === 'running') statusColor = 'green';
  else if (sub.status === 'completed') statusColor = 'blue';
  else if (sub.status === 'stopped') statusColor = 'yellow';
  else if (sub.status === 'aborted' || sub.status === 'failed') statusColor = 'red';
  else statusColor = 'white';
  
  // Prepare task description (use fullTask if available, fallback to label)
  let taskDisplay = sub.fullTask || sub.label || 'Unknown task';
  
  // Truncate to first 500 chars if too long
  if (taskDisplay.length > 500) {
    taskDisplay = taskDisplay.slice(0, 497) + '...';
  }
  
  // Word-wrap at 55 chars per line for readability
  const taskLines = [];
  const words = taskDisplay.split(/\s+/);
  let currentLine = '';
  
  for (const word of words) {
    if ((currentLine + ' ' + word).length > 55) {
      if (currentLine) taskLines.push(currentLine);
      currentLine = word;
    } else {
      currentLine = currentLine ? currentLine + ' ' + word : word;
    }
  }
  if (currentLine) taskLines.push(currentLine);
  
  const taskWrapped = taskLines.join('\n  ');
  
  // Calculate timing info
  const now = Date.now();
  
  let startedAgo = 'Unknown';
  let duration = 'Unknown';
  let lastSeenAgo = 'Unknown';
  
  if (sub.startTime) {
    startedAgo = formatAge(now - sub.startTime);
    
    if (sub.lastActivity) {
      lastSeenAgo = formatAge(now - sub.lastActivity);
      
      // Duration = from start to last activity
      duration = formatAge(sub.lastActivity - sub.startTime);
    }
  }
  
  // Handle token display
  let tokensSection;
  const hasTokens = sub.totalTokens != null && sub.totalTokens > 0;
  
  if (!hasTokens) {
    tokensSection = `{bold}{yellow-fg}Tokens:{/yellow-fg}{/bold}
  {yellow-fg}(no usage data yet){/yellow-fg}`;
  } else {
    const inputDisplay = (sub.inputTokens || 0).toLocaleString();
    const outputDisplay = (sub.outputTokens || 0).toLocaleString();
    const totalDisplay = sub.totalTokens.toLocaleString();
    const limitDisplay = (sub.contextTokens || 200000).toLocaleString();
    
    const usagePercent = sub.contextTokens > 0
      ? ((sub.totalTokens / sub.contextTokens) * 100).toFixed(1)
      : '0';
    const usageColor = parseFloat(usagePercent) > 80 ? 'red' : 'green';
    
    tokensSection = `{bold}{yellow-fg}Tokens:{/yellow-fg}{/bold}
  In:    {green-fg}${inputDisplay}{/green-fg} (prompt)
  Out:   {cyan-fg}${outputDisplay}{/cyan-fg} (reply)
  Total: {magenta-fg}{bold}${totalDisplay}{/bold}{/magenta-fg}
  Limit: ${limitDisplay} ({${usageColor}-fg}${usagePercent}%{/${usageColor}-fg})`;
  }
  
  const content = `
{bold}Task:{/bold}
  ${taskWrapped}

{bold}Status:{/bold}
  {${statusColor}-fg}${sub.status}{/${statusColor}-fg}

{bold}{yellow-fg}Timing:{/yellow-fg}{/bold}
  Started:   ${startedAgo} ago
  ${sub.status === 'running' ? 'Running:  ' : 'Ran for:  '} ${duration}
  Last seen: ${lastSeenAgo} ago

{bold}Model:{/bold}
  {cyan-fg}${sub.model}{/cyan-fg} (${sub.modelProvider})

${tokensSection}

{bold}Session:{/bold}
  Key: ${sub.key}
  ID:  ${sub.sessionId}
`;
  
  detailBox.setContent(content);
}

function updateStatusBar() {
  const timestamp = new Date().toLocaleTimeString();
  const status = loading
    ? '{yellow-fg}⟳ Refreshing...{/yellow-fg}'
    : `{cyan-fg}${timestamp}{/cyan-fg}  {bold}↑↓{/bold} Navigate  {bold}R{/bold} Refresh  {bold}Q{/bold} Quit\n  {green-fg}●{/green-fg} running  {cyan-fg}✓{/cyan-fg} done  {yellow-fg}⏹{/yellow-fg} stopped  {red-fg}✗{/red-fg} failed`;
  
  statusBox.setContent(`  ${status}`);
}

// ============================================================================
// Event Handlers
// ============================================================================

// Navigation
listBox.on('select', (item, index) => {
  selectedIndex = index;
  updateDetails();
  screen.render();
});

// Keyboard shortcuts
screen.key(['r'], async () => {
  await loadSessions();
});

screen.key(['q', 'C-c'], () => {
  process.exit(0);
});

// Auto-refresh every 5 seconds
setInterval(async () => {
  if (!loading) {
    await loadSessions();
  }
}, 5000);

// ============================================================================
// Initialize
// ============================================================================

async function init() {
  await loadSessions();
  listBox.focus();
}

init();
