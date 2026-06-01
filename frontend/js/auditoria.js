// ════════════════════════════════════════════════
// TELA 12 — AUDITORIA
// Lê de VW_AUDITORIA — view padronizada criada por cada nó no seu schema.
// O backend não sabe em que nó está; o Oracle resolve a view automaticamente.
// ════════════════════════════════════════════════

let _audPage     = 1;
let _audTotal    = 0;
let _audRegistos = [];
let _audFiltros  = { operacao: '', resultado: '', data_inicio: '', data_fim: '' };
let _audDrawerIdx = null;

const _AUD_LIMIT = 20;

// ── Entrada da secção ─────────────────────────

async function carregarAuditoria() {
  _audPage = 1;
  _audActualizarPill();

  // Carrega opções de filtro e primeira página em paralelo
  try {
    const opcoes = await get('/api/auditoria/opcoes');
    const sel = document.getElementById('aud-filtro-op');
    if (sel) {
      const valorActual = _audFiltros.operacao;
      sel.innerHTML = '<option value="">Todas as operações</option>' +
        (opcoes.operacoes || []).map(op =>
          `<option value="${op}"${op === valorActual ? ' selected' : ''}>${op}</option>`
        ).join('');
    }
  } catch { /* sem opções — dropdown fica só com "Todas" */ }

  await _audCarregarPagina(1);
}

function _audActualizarPill() {
  const pill = document.getElementById('aud-no-pill');
  if (!pill) return;
  const nome   = noActual?.no_nome || '…';
  const dbUser = noActual?.db_user;
  pill.textContent = `Nó: ${nome}`;
  pill.title = dbUser ? `Utilizador Oracle: ${dbUser}` : '';
}

// ── Carregar página ───────────────────────────

async function _audCarregarPagina(page) {
  _audPage = page;
  const qs = new URLSearchParams({ page });
  if (_audFiltros.operacao)    qs.set('operacao',    _audFiltros.operacao);
  if (_audFiltros.resultado)   qs.set('resultado',   _audFiltros.resultado);
  if (_audFiltros.data_inicio) qs.set('data_inicio', _audFiltros.data_inicio);
  if (_audFiltros.data_fim)    qs.set('data_fim',    _audFiltros.data_fim);

  const tbody = document.getElementById('tabela-auditoria');
  if (tbody) tbody.innerHTML = `<tr><td colspan="7" style="padding:20px;text-align:center;color:var(--text-muted);font-size:12px">
    <i class="fa-solid fa-spinner fa-spin" style="margin-right:6px"></i>A carregar…</td></tr>`;

  try {
    const data = await get(`/api/auditoria?${qs}`);
    _audRegistos = data.registos || [];
    _audTotal    = data.total    || 0;
    _audRenderTabela();
    _audRenderPaginacao();
  } catch (err) {
    if (tbody) tbody.innerHTML = `<tr><td colspan="7" style="padding:20px;text-align:center;color:#f85149;font-size:12px">
      <i class="fa-solid fa-circle-exclamation" style="margin-right:6px"></i>${err.message}</td></tr>`;
  }
}

// ── Render tabela ─────────────────────────────

function _audRenderTabela() {
  const tbody = document.getElementById('tabela-auditoria');
  if (!tbody) return;

  if (!_audRegistos.length) {
    tbody.innerHTML = `<tr><td colspan="7" style="padding:24px;text-align:center;color:var(--text-muted);font-size:12px">
      Sem registos para os filtros seleccionados.</td></tr>`;
    return;
  }

  tbody.innerHTML = _audRegistos.map((r, i) => _audLinha(r, i)).join('');
}

function _audLinha(r, idx) {
  const resBadge = r.RESULTADO === 'SUCESSO'
    ? `<span class="badge badge-green">SUCESSO</span>`
    : r.RESULTADO === 'FALHA'
      ? `<span class="badge badge-red">FALHA</span>`
      : `<span class="badge badge-gray">${r.RESULTADO || '—'}</span>`;

  const noOrigemPill = r.NO_ORIGEM
    ? `<span style="font-size:10px;padding:2px 7px;border-radius:10px;
         background:var(--surface-raised);border:0.5px solid var(--border);
         color:var(--text-secondary)">${r.NO_ORIGEM}</span>`
    : '—';

  const dataFmt = r.DATA_OPERACAO ? fmtData(r.DATA_OPERACAO) : '—';
  const motivo  = r.MOTIVO_FALHA
    ? `<span style="color:#f85149;font-size:11px" title="${r.MOTIVO_FALHA}">
         ${r.MOTIVO_FALHA.length > 40 ? r.MOTIVO_FALHA.slice(0, 40) + '…' : r.MOTIVO_FALHA}
       </span>`
    : '—';

  const nosAfetados = r.NOS_AFETADOS
    ? r.NOS_AFETADOS.split(', ').map(n =>
        `<span style="display:inline-block;font-size:10px;background:var(--border);color:var(--text-secondary);border-radius:4px;padding:1px 5px;margin-right:3px;white-space:nowrap">${n.trim()}</span>`
      ).join('')
    : '—';

  return `<tr>
    <td style="white-space:nowrap;font-size:12px">${dataFmt}</td>
    <td style="font-weight:500;font-size:12px">${r.OPERACAO || '—'}</td>
    <td>${resBadge}</td>
    <td>${noOrigemPill}</td>
    <td style="max-width:200px">${nosAfetados}</td>
    <td style="max-width:200px">${motivo}</td>
    <td style="text-align:right">
      <button class="btn-ghost btn-sm" onclick="abrirCtxMenuAud(event,${idx})">···</button>
    </td>
  </tr>`;
}

// ── Paginação ─────────────────────────────────

function _audRenderPaginacao() {
  const el = document.getElementById('aud-paginacao');
  if (!el) return;

  const totalPags = Math.ceil(_audTotal / _AUD_LIMIT) || 1;

  if (totalPags <= 1 && _audTotal === 0) {
    el.innerHTML = '';
    return;
  }

  const btnAnt = `<button class="btn-ghost btn-sm" ${_audPage <= 1 ? 'disabled' : ''}
    onclick="_audCarregarPagina(${_audPage - 1})">
    <i class="fa-solid fa-chevron-left"></i>
  </button>`;
  const btnSeg = `<button class="btn-ghost btn-sm" ${_audPage >= totalPags ? 'disabled' : ''}
    onclick="_audCarregarPagina(${_audPage + 1})">
    <i class="fa-solid fa-chevron-right"></i>
  </button>`;

  el.innerHTML = `${btnAnt}
    <span>Página ${_audPage} de ${totalPags} · ${_audTotal} registo${_audTotal !== 1 ? 's' : ''}</span>
    ${btnSeg}`;
}

// ── Context menu ──────────────────────────────

function abrirCtxMenuAud(evt, idx) {
  evt.stopPropagation();
  const menu = document.getElementById('ctx-menu-aud');
  if (!menu) return;

  menu.innerHTML = `
    <div class="ctx-menu-item" onclick="fecharCtxMenuAud();abrirDrawerAud(${idx})">
      <i class="fa-solid fa-eye" style="width:14px"></i> Ver detalhe
    </div>`;

  const btn  = evt.currentTarget;
  const rect = btn.getBoundingClientRect();
  menu.style.display  = 'block';
  menu.style.position = 'fixed';
  menu.style.top      = `${rect.bottom + 4}px`;
  menu.style.right    = `${window.innerWidth - rect.right}px`;
  menu.style.left     = 'auto';
  menu.style.zIndex   = '200';

  setTimeout(() => document.addEventListener('click', fecharCtxMenuAud, { once: true }), 0);
}

function fecharCtxMenuAud() {
  const menu = document.getElementById('ctx-menu-aud');
  if (menu) menu.style.display = 'none';
}

// ── Drawer ────────────────────────────────────

function abrirDrawerAud(idx) {
  _audDrawerIdx = idx;
  const r = _audRegistos[idx];
  if (!r) return;

  const overlay = document.getElementById('drawer-aud-overlay');
  const drawer  = document.getElementById('drawer-aud');
  if (overlay) overlay.style.display = 'block';
  if (drawer)  drawer.classList.add('open');

  const resBadge = r.RESULTADO === 'SUCESSO'
    ? `<span class="badge badge-green">SUCESSO</span>`
    : `<span class="badge badge-red">${r.RESULTADO || '—'}</span>`;

  document.getElementById('drawer-aud-conteudo').innerHTML = `
    ${secaoDetalhe('Identificação')}
    ${campoDetalhe('ID Auditoria', r.ID_AUDITORIA)}
    ${campoDetalhe('Data / Hora', r.DATA_OPERACAO ? new Date(r.DATA_OPERACAO).toLocaleString('pt-PT') : '—')}
    ${campoDetalhe('Nó Origem', r.NO_ORIGEM || '—')}
    ${secaoDetalhe('Operação')}
    ${campoDetalhe('Operação', `<strong>${r.OPERACAO || '—'}</strong>`)}
    ${campoDetalhe('Resultado', resBadge)}
    ${secaoDetalhe('Contexto')}
    ${campoDetalhe('Nós Afetados', r.NOS_AFETADOS
      ? r.NOS_AFETADOS.split(', ').map(n =>
          `<span style="display:inline-block;font-size:10px;background:var(--border);color:var(--text-secondary);border-radius:4px;padding:1px 5px;margin-right:3px">${n.trim()}</span>`
        ).join('')
      : '—')}
    ${campoDetalhe('Observações', r.OBSERVACOES || '—')}
    ${r.RESULTADO === 'FALHA' ? `
    ${secaoDetalhe('Falha')}
    <div style="background:rgba(248,81,73,.08);border:0.5px solid rgba(248,81,73,.3);
         border-radius:6px;padding:10px 12px;font-size:12px;color:#f85149;line-height:1.6;margin-top:4px">
      ${r.MOTIVO_FALHA || 'Sem detalhe de falha.'}
    </div>` : ''}
  `;
}

function fecharDrawerAud() {
  const overlay = document.getElementById('drawer-aud-overlay');
  const drawer  = document.getElementById('drawer-aud');
  if (overlay) overlay.style.display = 'none';
  if (drawer)  drawer.classList.remove('open');
  _audDrawerIdx = null;
}

// ── Filtros ───────────────────────────────────

function _audAplicarFiltros() {
  _audFiltros.operacao    = document.getElementById('aud-filtro-op')?.value     || '';
  _audFiltros.resultado   = document.getElementById('aud-filtro-res')?.value    || '';
  _audFiltros.data_inicio = document.getElementById('aud-filtro-inicio')?.value || '';
  _audFiltros.data_fim    = document.getElementById('aud-filtro-fim')?.value    || '';
  _audCarregarPagina(1);
}

function _audLimparFiltros() {
  _audFiltros = { operacao: '', resultado: '', data_inicio: '', data_fim: '' };
  const ids = ['aud-filtro-op','aud-filtro-res','aud-filtro-inicio','aud-filtro-fim'];
  ids.forEach(id => { const el = document.getElementById(id); if (el) el.value = ''; });
  _audCarregarPagina(1);
}
