// ════════════════════════════════════════════════
// TELA 10 — PERMISSÕES (só Administrador)
// ════════════════════════════════════════════════

let _permRows = [];

async function carregarPermissoes() {
  if (utilizadorActual?.NIVEL_ACESSO !== 'Administrador') {
    toast('Acesso não autorizado.', 'erro');
    navegarPara('dashboard');
    return;
  }
  try {
    _permRows = await get('/api/funcionarios');
    _renderizarTabelaPermissoes();
  } catch (err) {
    toast('Erro a carregar permissões: ' + err.message, 'erro');
  }
  _renderizarMatrizPerm();
}

function _renderizarTabelaPermissoes() {
  const tbody = document.getElementById('tabela-permissoes');
  if (!tbody) return;
  if (!_permRows.length) {
    tbody.innerHTML = linhaVazia(6, 'Sem funcionários registados.');
    return;
  }
  tbody.innerHTML = _permRows.map(r => _linhaPermissao(r)).join('');
}

function _linhaPermissao(r) {
  const av = `<div style="width:32px;height:32px;border-radius:50%;background:var(--theme-accent);
    color:#fff;display:flex;align-items:center;justify-content:center;
    font-size:11px;font-weight:700;flex-shrink:0">${iniciais(r.NOME)}</div>`;

  return `<tr>
    <td style="padding:6px 10px">${av}</td>
    <td style="font-family:monospace;font-size:11px;color:#666">${r.COD_FUNCIONARIO || '—'}</td>
    <td style="font-weight:500">${r.NOME || '—'}</td>
    <td style="color:#555">${r.FUNCAO || '—'}</td>
    <td>${_badgeNivel(r.NIVEL_ACESSO)}</td>
    <td style="color:#777">${r.NOME_BIBLIOTECA || '—'}</td>
    <td style="text-align:right;padding-right:10px">
      <button class="btn-secondary btn-sm"
              onclick="abrirModalPermissoes('${r.COD_FUNCIONARIO}');_permRefreshOnClose()">
        <i class="fa-solid fa-shield-halved" style="margin-right:4px"></i>Gerir
      </button>
    </td>
  </tr>`;
}

// Garante que a tabela recarrega após fechar o modal (se estiver na secção permissoes)
function _permRefreshOnClose() {
  const orig = window._permOrigFechar;
  if (orig) return; // já registado
  window._permOrigFechar = fecharModalPerm;
  window.fecharModalPerm = function(e) {
    window._permOrigFechar(e);
    window.fecharModalPerm = window._permOrigFechar;
    window._permOrigFechar = null;
    const sec = document.getElementById('section-permissoes');
    if (sec && !sec.classList.contains('hidden')) {
      carregarPermissoes();
    }
  };
}

function _renderizarMatrizPerm() {
  const el = document.getElementById('matriz-permissoes');
  if (!el) return;

  const tick = v => v
    ? `<span style="color:#16a34a;font-size:14px;font-weight:700">✓</span>`
    : `<span style="color:#ccc;font-size:12px">—</span>`;

  el.innerHTML = `<table class="tbl">
    <thead>
      <tr>
        <th style="text-align:left;min-width:220px">Módulo</th>
        <th style="text-align:center;width:80px">Admin</th>
        <th style="text-align:center;width:80px">Coord</th>
        <th style="text-align:center;width:80px">Biblio</th>
        <th style="text-align:center;width:80px">Assist</th>
      </tr>
    </thead>
    <tbody>
      ${_MATRIZ_PERM.map(m => `<tr>
        <td style="font-size:12px;color:#444">${m.modulo}</td>
        <td style="text-align:center">${tick(m.admin)}</td>
        <td style="text-align:center">${tick(m.coord)}</td>
        <td style="text-align:center">${tick(m.biblio)}</td>
        <td style="text-align:center">${tick(m.assist)}</td>
      </tr>`).join('')}
    </tbody>
  </table>`;
}
