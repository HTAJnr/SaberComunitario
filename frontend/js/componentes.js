// ════════════════════════════════════════════════
//  Componentes reutilizáveis — usar sempre estes.
//  Nunca recriar inline o que já existe aqui.
// ════════════════════════════════════════════════

function emptyState(icone, msg, sub) {
  return `<div class="empty-state">
    <div class="empty-state-icon">${icone}</div>
    <div class="empty-state-text">${msg}</div>
    ${sub ? `<div class="empty-state-sub">${sub}</div>` : ''}
  </div>`;
}

// ── Regiões / Províncias ──────────────────────────
const PROVINCIAS_SUL    = ['Maputo Cidade','Maputo Provincia','Gaza','Inhambane'];
const PROVINCIAS_CENTRO = ['Sofala','Manica','Tete','Zambezia'];

function regiaoDeProvinccia(provincia) {
  if (PROVINCIAS_SUL.includes(provincia))    return 'Sul';
  if (PROVINCIAS_CENTRO.includes(provincia)) return 'Centro';
  return 'Norte';
}

// ── Drawer campo/secção ───────────────────────────
function campoDetalhe(label, valor, estilo) {
  return `<div style="display:flex;justify-content:space-between;align-items:baseline;
                      padding:5px 0;border-bottom:0.5px solid #f0f0f0;font-size:12px">
    <span style="color:var(--text-muted);flex-shrink:0;margin-right:8px">${label}</span>
    <span style="text-align:right;${estilo || ''}">${valor ?? '—'}</span>
  </div>`;
}

function secaoDetalhe(titulo) {
  return `<div style="font-size:10px;font-weight:500;color:var(--text-muted);text-transform:uppercase;
                      letter-spacing:.06em;margin:14px 0 6px">${titulo}</div>`;
}

// ── Avatar circular ───────────────────────────────
function avatarCirculo(nome, tamanho) {
  const t   = tamanho || 32;
  const ini = (nome || '?').trim().split(/\s+/).filter(Boolean);
  const txt = ini.length === 1
    ? ini[0].slice(0, 2).toUpperCase()
    : (ini[0][0] + ini[ini.length - 1][0]).toUpperCase();
  return `<div style="width:${t}px;height:${t}px;border-radius:50%;background:var(--theme-accent);
    color:#fff;display:flex;align-items:center;justify-content:center;
    font-size:${Math.round(t * 0.38)}px;font-weight:700;flex-shrink:0">${txt}</div>`;
}
