// ════════════════════════════════════════════════
//  Componentes reutilizáveis — usar sempre estes.
//  Nunca recriar inline o que já existe aqui.
// ════════════════════════════════════════════════

function emptyState(icone, msg, sub) {
  const iconHtml = icone && icone.startsWith('fa-')
    ? `<i class="fa-solid ${icone}" style="font-size:28px"></i>`
    : icone;
  return `<div class="empty-state">
    <div class="empty-state-icon">${iconHtml}</div>
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
                      padding:5px 0;border-bottom:0.5px solid var(--border-soft);font-size:12px">
    <span style="color:var(--text-muted);flex-shrink:0;margin-right:8px">${label}</span>
    <span style="text-align:right;${estilo || ''}">${valor ?? '—'}</span>
  </div>`;
}

function secaoDetalhe(titulo) {
  return `<div style="font-size:10px;font-weight:500;color:var(--text-muted);text-transform:uppercase;
                      letter-spacing:.06em;margin:14px 0 6px">${titulo}</div>`;
}

// ── Wizard indicador de passos ────────────────────
function wizardIndicador(stepActual, total, labels) {
  const hasLabels = labels && labels.length > 0;
  const circles = Array.from({ length: total }, (_, i) => {
    const n = i + 1;
    const activo   = n === stepActual;
    const concluido = n < stepActual;
    const bg      = (activo || concluido) ? 'var(--theme-accent)' : 'var(--border)';
    const txtCor  = (activo || concluido) ? '#fff' : 'var(--text-muted)';
    const labelCor = activo ? 'var(--text-primary)' : 'var(--text-muted)';
    const fw = activo ? '600' : '400';
    return { n, activo, concluido, bg, txtCor, labelCor, fw };
  });

  const parts = [];
  circles.forEach((c, i) => {
    parts.push(`<div style="display:flex;flex-direction:column;align-items:center;gap:4px">
      <div style="width:26px;height:26px;border-radius:50%;background:${c.bg};color:${c.txtCor};
                  display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;flex-shrink:0">
        ${c.concluido ? '<i class="fa-solid fa-check" style="font-size:10px"></i>' : c.n}
      </div>
      ${hasLabels && labels[i] ? `<span style="font-size:10px;color:${c.labelCor};font-weight:${c.fw};white-space:nowrap;text-align:center">${labels[i]}</span>` : ''}
    </div>`);
    if (i < total - 1) {
      parts.push(`<div style="flex:1;height:1px;background:var(--border);align-self:flex-start;margin-top:13px${hasLabels ? '' : ''}"></div>`);
    }
  });

  return `<div style="display:flex;align-items:flex-start;gap:4px;padding:12px 16px 8px;justify-content:center">
    ${parts.join('')}
  </div>`;
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
