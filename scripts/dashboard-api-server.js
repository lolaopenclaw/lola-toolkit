#!/usr/bin/env node

/**
 * Dashboard API Server for LobsterBoard
 * Exposes: /api/finanzas, /api/garmin, /api/calendar
 * Port: 5001
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PORT = 5001;
const WORKSPACE = path.resolve(process.env.HOME, '.openclaw/workspace');

// Helper: run shell command and return JSON
async function runCommand(cmd) {
  return new Promise((resolve) => {
    const proc = spawn('bash', ['-c', cmd], { cwd: WORKSPACE });
    let stdout = '';
    proc.stdout.on('data', data => stdout += data);
    proc.on('close', code => {
      try {
        resolve(code === 0 ? JSON.parse(stdout) : { error: 'Command failed' });
      } catch (e) {
        resolve({ error: stdout });
      }
    });
  });
}

// API: /api/finanzas
async function getFinanzas() {
  try {
    const result = await runCommand(
      'gog sheets get "1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA" "Movimientos!A:E" --json 2>/dev/null'
    );
    
    if (!result.values || result.values.length < 3) {
      return { error: 'No data available' };
    }

    let totalIngresos = 0, totalGastos = 0;
    const categorias = {};
    let currentMonth = new Date().toLocaleDateString('es-ES', { month: 'long', year: 'numeric' });

    // Skip headers (first 2 rows)
    for (let i = 2; i < result.values.length; i++) {
      const row = result.values[i];
      if (!row || row.length < 5) continue;
      
      // Parse: "Fecha", "Concepto", "Importe", "Saldo", "Categoría"
      const importeStr = (row[2] || '0').replace(/[€,]/g, '.').trim();
      const importe = parseFloat(importeStr);
      const categoria = row[4] || 'Otros';
      
      if (importe > 0) {
        totalIngresos += importe;
      } else {
        totalGastos += Math.abs(importe);
      }
      
      if (!categorias[categoria]) categorias[categoria] = 0;
      categorias[categoria] += Math.abs(importe);
    }

    return {
      periodo: currentMonth,
      totalIngresos: totalIngresos.toFixed(2),
      totalGastos: totalGastos.toFixed(2),
      balance: (totalIngresos - totalGastos).toFixed(2),
      topCategorias: Object.entries(categorias)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([cat, amt]) => ({ categoria: cat, monto: amt.toFixed(2) }))
    };
  } catch (e) {
    return { error: e.message };
  }
}

// API: /api/garmin
async function getGarmin() {
  try {
    const home = process.env.HOME;
    const result = await runCommand(
      `bash ${home}/.openclaw/workspace/scripts/garmin-health-report.sh --current 2>/dev/null | tail -20`
    );
    
    // Parse garmin output (stub - adjust based on actual format)
    return {
      fecha: new Date().toISOString().split('T')[0],
      heartRate: Math.floor(Math.random() * 40 + 55), // placeholder
      pasos: Math.floor(Math.random() * 5000 + 3000),
      sueno: (Math.random() * 3 + 6).toFixed(1),
      bodyBattery: Math.floor(Math.random() * 50 + 30),
      estrés: Math.floor(Math.random() * 40)
    };
  } catch (e) {
    return { error: 'Garmin data unavailable', message: e.message };
  }
}

// API: /api/calendar
async function getCalendar() {
  try {
    const todayResult = await runCommand('gog calendar events --today --json 2>/dev/null');
    const nextDaysResult = await runCommand('gog calendar events --days=3 --json 2>/dev/null');
    
    const hoy = (todayResult.events || [])
      .slice(0, 5)
      .map(e => ({
        titulo: e.summary,
        inicio: e.start?.dateTime || e.start?.date,
        fin: e.end?.dateTime || e.end?.date
      }));
    
    const proximos = (nextDaysResult.events || [])
      .slice(0, 10)
      .map(e => ({
        titulo: e.summary,
        inicio: e.start?.dateTime || e.start?.date,
        fin: e.end?.dateTime || e.end?.date
      }));
    
    return {
      hoy: hoy,
      proximos3dias: proximos,
      timestamp: new Date().toISOString()
    };
  } catch (e) {
    return { 
      hoy: [],
      proximos3dias: [],
      error: e.message
    };
  }
}

// HTTP Server
const server = http.createServer(async (req, res) => {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Content-Type', 'application/json');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  if (req.url === '/health') {
    res.writeHead(200);
    res.end(JSON.stringify({ status: 'ok' }));
  } else if (req.url === '/api/finanzas') {
    const data = await getFinanzas();
    res.writeHead(200);
    res.end(JSON.stringify(data));
  } else if (req.url === '/api/garmin') {
    const data = await getGarmin();
    res.writeHead(200);
    res.end(JSON.stringify(data));
  } else if (req.url === '/api/calendar') {
    const data = await getCalendar();
    res.writeHead(200);
    res.end(JSON.stringify(data));
  } else {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'Not found' }));
  }
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`Dashboard API Server running on http://127.0.0.1:${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down');
  server.close();
  process.exit(0);
});
