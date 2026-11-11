// Sube todos los workflows de n8n/workflows al n8n local y los publica.
// Uso: node n8n/deploy.mjs        (requiere N8N_API_KEY en infra/.env.local)
import fs from 'node:fs';
import { execFileSync } from 'node:child_process';

const env = Object.fromEntries(
  fs.readFileSync(new URL('../infra/.env.local', import.meta.url), 'utf8')
    .split(/\r?\n/).filter(l => l.includes('='))
    .map(l => [l.slice(0, l.indexOf('=')).trim(), l.slice(l.indexOf('=') + 1).trim()]));
const api = (method, ruta, body) => fetch('http://localhost:5678/api/v1' + ruta, {
  method, headers: { 'X-N8N-API-KEY': env.N8N_API_KEY, 'content-type': 'application/json' }, body: body && JSON.stringify(body) });

const dir = new URL('./workflows/', import.meta.url);
for (const f of fs.readdirSync(dir).filter(f => f.endsWith('.json')).sort()) {
  const w = JSON.parse(fs.readFileSync(new URL(f, dir), 'utf8'));
  let r = await api('PUT', '/workflows/' + w.id, { name: w.name, nodes: w.nodes, connections: w.connections, settings: w.settings });
  let paso = 'actualizado';
  if (r.status === 404) {
    // La API no deja elegir el id al crear; el import por CLI si lo respeta.
    execFileSync('docker', ['exec', 'fico-local-n8n-1', 'n8n', 'import:workflow', '--input=/workflows/' + f], { stdio: 'ignore' });
    r = { ok: true }; paso = 'importado';
  }
  if (!r.ok) { console.log(f, 'ERROR', r.status, (await r.text()).slice(0, 300)); process.exitCode = 1; continue; }
  const a = await api('POST', `/workflows/${w.id}/activate`);
  console.log(f, paso, a.ok ? 'publicado' : 'NO publicado: ' + (await a.text()).slice(0, 200));
  if (!a.ok) process.exitCode = 1;
}
