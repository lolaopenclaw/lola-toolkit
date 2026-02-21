#!/usr/bin/env node
/**
 * Semantic Memory Search - OpenClaw Workspace
 * Uses LanceDB + Ollama (nomic-embed-text) for vector search over memory files.
 * 
 * Usage:
 *   node scripts/semantic-search.js index          # Index all memory files
 *   node scripts/semantic-search.js search "query"  # Search by meaning
 *   node scripts/semantic-search.js search "query" --top 10  # More results
 *   node scripts/semantic-search.js status          # Show index stats
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const WORKSPACE = path.resolve(__dirname, '..');
const MEMORY_DIR = path.join(WORKSPACE, 'memory');
const DB_PATH = path.join(WORKSPACE, '.vectordb');
const TABLE_NAME = 'memory_chunks';
const OLLAMA_MODEL = 'nomic-embed-text';
const CHUNK_SIZE = 800;  // chars per chunk (~200 tokens)
const CHUNK_OVERLAP = 100;
const TOP_K = 5;

// --- Embedding via Ollama ---
async function getEmbedding(text) {
  const resp = await fetch('http://localhost:11434/api/embed', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: OLLAMA_MODEL, input: text })
  });
  if (!resp.ok) throw new Error(`Ollama error: ${resp.status} ${await resp.text()}`);
  const data = await resp.json();
  return data.embeddings[0];
}

async function getEmbeddingsBatch(texts) {
  const resp = await fetch('http://localhost:11434/api/embed', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: OLLAMA_MODEL, input: texts })
  });
  if (!resp.ok) throw new Error(`Ollama error: ${resp.status}`);
  const data = await resp.json();
  return data.embeddings;
}

// --- Chunking ---
function chunkText(text, filePath) {
  const chunks = [];
  // Split by sections (## headers) first
  const sections = text.split(/(?=^##\s)/m);
  
  for (const section of sections) {
    if (section.trim().length < 20) continue;
    
    if (section.length <= CHUNK_SIZE) {
      chunks.push(section.trim());
    } else {
      // Sub-chunk large sections
      let start = 0;
      while (start < section.length) {
        const end = Math.min(start + CHUNK_SIZE, section.length);
        const chunk = section.slice(start, end).trim();
        if (chunk.length > 20) chunks.push(chunk);
        start += CHUNK_SIZE - CHUNK_OVERLAP;
      }
    }
  }
  
  // If no sections found, chunk the whole text
  if (chunks.length === 0 && text.trim().length > 20) {
    let start = 0;
    while (start < text.length) {
      const end = Math.min(start + CHUNK_SIZE, text.length);
      const chunk = text.slice(start, end).trim();
      if (chunk.length > 20) chunks.push(chunk);
      start += CHUNK_SIZE - CHUNK_OVERLAP;
    }
  }
  
  return chunks;
}

// --- Find all memory .md files ---
function findMemoryFiles() {
  const files = [];
  function walk(dir) {
    if (!fs.existsSync(dir)) return;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        if (entry.name === '.vectordb' || entry.name === 'node_modules' || entry.name === 'COLD') continue;
        walk(full);
      } else if (entry.name.endsWith('.md')) {
        files.push(full);
      }
    }
  }
  walk(MEMORY_DIR);
  // Also index top-level workspace .md files
  for (const f of ['MEMORY.md', 'AGENTS.md', 'TOOLS.md']) {
    const full = path.join(WORKSPACE, f);
    if (fs.existsSync(full)) files.push(full);
  }
  return files;
}

// --- Index ---
async function indexMemory() {
  const lancedb = require('@lancedb/lancedb');
  
  console.log('🔍 Finding memory files...');
  const files = findMemoryFiles();
  console.log(`📄 Found ${files.length} files`);
  
  // Build chunks
  const allChunks = [];
  for (const filePath of files) {
    const text = fs.readFileSync(filePath, 'utf-8');
    const relPath = path.relative(WORKSPACE, filePath);
    const mtime = fs.statSync(filePath).mtimeMs;
    const chunks = chunkText(text, filePath);
    
    for (let i = 0; i < chunks.length; i++) {
      allChunks.push({
        text: chunks[i],
        file: relPath,
        chunk_index: i,
        mtime: mtime,
      });
    }
  }
  
  console.log(`📦 ${allChunks.length} chunks to embed`);
  
  // Batch embed (groups of 32)
  const BATCH = 32;
  const vectors = [];
  for (let i = 0; i < allChunks.length; i += BATCH) {
    const batch = allChunks.slice(i, i + BATCH).map(c => c.text);
    process.stdout.write(`\r  Embedding ${i + batch.length}/${allChunks.length}...`);
    const embs = await getEmbeddingsBatch(batch);
    vectors.push(...embs);
  }
  console.log('\n✅ Embeddings complete');
  
  // Build records with vector field
  const records = allChunks.map((c, i) => ({
    vector: Array.from(vectors[i]),
    text: c.text,
    file: c.file,
    chunk_index: c.chunk_index,
    mtime: c.mtime,
  }));
  
  // Write to LanceDB
  const db = await lancedb.connect(DB_PATH);
  
  // Drop existing table if exists
  try { await db.dropTable(TABLE_NAME); } catch {}
  
  await db.createTable(TABLE_NAME, records);
  
  // Save metadata
  fs.writeFileSync(path.join(DB_PATH, 'index-meta.json'), JSON.stringify({
    indexed_at: new Date().toISOString(),
    files: files.length,
    chunks: allChunks.length,
    model: OLLAMA_MODEL,
    dim: vectors[0].length,
  }, null, 2));
  
  console.log(`🗃️  Indexed ${allChunks.length} chunks from ${files.length} files → ${DB_PATH}`);
}

// --- Search ---
async function search(query, topK) {
  const lancedb = require('@lancedb/lancedb');
  
  const db = await lancedb.connect(DB_PATH);
  const table = await db.openTable(TABLE_NAME);
  
  const queryVec = await getEmbedding(query);
  
  const results = await table.search(Array.from(queryVec)).limit(topK).toArray();
  
  // Deduplicate by file, keeping best score per file
  const seen = new Map();
  for (const r of results) {
    const key = `${r.file}#${r.chunk_index}`;
    if (!seen.has(key)) {
      seen.set(key, r);
    }
  }
  
  return [...seen.values()];
}

// --- Status ---
async function status() {
  const metaFile = path.join(DB_PATH, 'index-meta.json');
  if (!fs.existsSync(metaFile)) {
    console.log('❌ No index found. Run: node scripts/semantic-search.js index');
    return;
  }
  const meta = JSON.parse(fs.readFileSync(metaFile, 'utf-8'));
  console.log('📊 Semantic Search Index Status');
  console.log(`  Indexed: ${meta.indexed_at}`);
  console.log(`  Files: ${meta.files}`);
  console.log(`  Chunks: ${meta.chunks}`);
  console.log(`  Model: ${meta.model} (${meta.dim} dims)`);
  
  const dbSize = execSync(`du -sh ${DB_PATH} 2>/dev/null`).toString().split('\t')[0];
  console.log(`  DB Size: ${dbSize}`);
}

// --- Main ---
async function main() {
  const [,, cmd, ...args] = process.argv;
  
  switch (cmd) {
    case 'index':
      await indexMemory();
      break;
    case 'search': {
      const query = args.filter(a => !a.startsWith('--')).join(' ');
      const topIdx = args.indexOf('--top');
      const topK = topIdx >= 0 ? parseInt(args[topIdx + 1]) : TOP_K;
      const jsonMode = args.includes('--json');
      
      if (!query) { console.error('Usage: semantic-search.js search "query"'); process.exit(1); }
      
      const results = await search(query, topK);
      
      if (jsonMode) {
        console.log(JSON.stringify(results.map(r => ({
          file: r.file,
          score: r._distance,
          text: r.text.slice(0, 200),
        }))));
      } else {
        console.log(`\n🔎 Results for: "${query}"\n`);
        for (const r of results) {
          const score = (1 - r._distance).toFixed(3);
          console.log(`📄 ${r.file} (relevance: ${score})`);
          console.log(`   ${r.text.slice(0, 150).replace(/\n/g, ' ')}...`);
          console.log();
        }
      }
      break;
    }
    case 'status':
      await status();
      break;
    default:
      console.log('Usage: semantic-search.js <index|search|status>');
      console.log('  index              Index all memory files');
      console.log('  search "query"     Search by meaning');
      console.log('  search "q" --top N Return N results (default 5)');
      console.log('  search "q" --json  JSON output');
      console.log('  status             Show index info');
  }
}

main().catch(e => { console.error(e.message); process.exit(1); });
