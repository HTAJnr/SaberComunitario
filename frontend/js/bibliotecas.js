// ════════════════════════════════════════════════
// TELA 11 — Biblioteca (Admin: rede | Coord: própria)
// ════════════════════════════════════════════════

let _bibRows      = [];
let _bibDetalhe   = null;
let _bibDrawerCod = null;
let _bibDrawerTab = 'info';
let _bibEditCod   = null;
let _wizBibStep   = 1;
let _wizBibDados  = {};

// ── Helpers de render ────────────────────────────

const _PROVINCIAS = [
  'Maputo Cidade','Maputo Provincia','Gaza','Inhambane',
  'Sofala','Manica','Tete','Zambezia',
  'Nampula','Niassa','Cabo Delgado',
];

function _badgeRegiao(provincia) {
  const r = regiaoDeProvinccia(provincia);
  const cls = { Sul: 'bdg-activo', Centro: 'bdg-adulto', Norte: '' };
  return `<span class="bdg ${cls[r] || ''}">${r}</span>`;
}

function _bsecao(titulo) {
  return `<div style="font-size:10px;font-weight:600;color:var(--text-muted);text-transform:uppercase;
    letter-spacing:.06em;padding:10px 0 4px;border-top:1px solid var(--border-soft);margin-top:8px">${titulo}</div>`;
}

function _bcampo(label, valor) {
  return `<div style="display:flex;justify-content:space-between;padding:5px 0;border-bottom:1px solid #f8f8f8">
    <span style="color:var(--text-muted);font-size:12px">${label}</span>
    <span style="font-size:12px;text-align:right;max-width:55%">${valor ?? '—'}</span>
  </div>`;
}

function _mostrarErroBib(msg) {
  const div  = document.getElementById('modal-bib-erro');
  const span = document.getElementById('modal-bib-erro-msg');
  if (div)  div.classList.remove('hidden');
  if (span) span.textContent = msg;
}

// ════════════════════════════════════════════════
// ENTRADA — detecta role e divide vistas
// ════════════════════════════════════════════════

async function carregarBibliotecas() {
  const isAdmin = utilizadorActual?.NIVEL_ACESSO === 'Administrador';
  const pAdmin  = document.getElementById('bib-painel-admin');
  const pCoord  = document.getElementById('bib-painel-coord');

  if (pAdmin) pAdmin.style.display = isAdmin ? '' : 'none';
  if (pCoord) pCoord.style.display = isAdmin ? 'none' : '';

  if (isAdmin) {
    try {
      _bibRows = await get('/api/bibliotecas');
      _renderizarTabelaBibliotecas();
    } catch (err) {
      toast('Erro a carregar bibliotecas: ' + err.message, 'erro');
    }
  } else {
    const cod = utilizadorActual?.COD_BIBLIOTECA;
    if (!cod) {
      const card = document.getElementById('bib-card-conteudo');
      if (card) card.innerHTML = emptyState('🏛️', 'Sem biblioteca associada', 'A sua conta não está ligada a nenhuma biblioteca.');
      return;
    }
    try {
      const d = await get(`/api/bibliotecas/${cod}`);
      _renderizarCardBiblioteca(d);
    } catch (err) {
      toast('Erro a carregar dados da biblioteca: ' + err.message, 'erro');
    }
  }
}

// alias para o router (rota /biblioteca)
async function carregarBiblioteca() {
  await carregarBibliotecas();
}

// ════════════════════════════════════════════════
// 11-A VISTA ADMIN — Tabela
// ════════════════════════════════════════════════

function _renderizarTabelaBibliotecas() {
  const tbody = document.getElementById('tabela-bibliotecas');
  if (!tbody) return;
  const q = (document.getElementById('filtro-bib-q')?.value || '').toLowerCase();
  const rows = _bibRows.filter(r =>
    !q || (r.NOME_BIBLIOTECA || '').toLowerCase().includes(q)
       || (r.COD_BIBLIOTECA  || '').toLowerCase().includes(q)
       || (r.PROVINCIA       || '').toLowerCase().includes(q)
  );

  if (!rows.length) {
    tbody.innerHTML = linhaVazia(8, q ? 'Sem resultados para a pesquisa.' : 'Sem bibliotecas registadas.');
    return;
  }
  tbody.innerHTML = rows.map(_linhaBib).join('');
}

function _linhaBib(r) {
  const cod  = r.COD_BIBLIOTECA || '';
  const resp = r.RESPONSAVEL_ACTUAL || '—';
  return `<tr>
    <td><span style="font-family:monospace;font-size:11px">${cod}</span></td>
    <td style="font-weight:500">${r.NOME_BIBLIOTECA || '—'}</td>
    <td>${r.PROVINCIA || '—'}</td>
    <td>${_badgeRegiao(r.PROVINCIA)}</td>
    <td style="text-align:center">${r.CAPACIDADE ?? '—'}</td>
    <td>${resp}</td>
    <td><span class="bdg bdg-activo" style="font-size:10px">● Online</span></td>
    <td style="text-align:right">
      <button class="btn-ghost btn-sm"
              onclick="abrirCtxMenuBib(event,'${cod}')">···</button>
    </td>
  </tr>`;
}

// ════════════════════════════════════════════════
// 11-B VISTA COORD — Card da própria biblioteca
// ════════════════════════════════════════════════

function _renderizarCardBiblioteca(d) {
  const card = document.getElementById('bib-card-conteudo');
  if (!card) return;

  const horarios = (d.HORARIOS || []).map(h =>
    `<tr>
      <td style="padding:4px 8px;font-size:12px">${h.DIA_SEMANA}</td>
      <td style="padding:4px 8px;font-size:12px">${h.HORA_ABERTURA || '—'}</td>
      <td style="padding:4px 8px;font-size:12px">${h.HORA_FECHO || '—'}</td>
    </tr>`
  ).join('');

  const responsaveis = (d.RESPONSAVEIS || []).map(r =>
    `<div style="display:flex;align-items:center;gap:10px;padding:8px 0;border-bottom:1px solid var(--border-soft)">
      <div style="width:34px;height:34px;border-radius:50%;background:var(--theme-accent);
        color:#fff;display:flex;align-items:center;justify-content:center;
        font-size:12px;font-weight:700;flex-shrink:0">${iniciais(r.NOME_FUNCIONARIO)}</div>
      <div style="flex:1">
        <div style="font-size:13px;font-weight:600">${r.NOME_FUNCIONARIO || '—'}</div>
        <div style="font-size:11px;color:var(--text-muted)">${r.PAPEL || '—'} · ${r.DATA_FIM ? 'até ' + fmtData(r.DATA_FIM) : 'actual'}</div>
      </div>
    </div>`
  ).join('');

  card.innerHTML = `
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px">
      <div>
        <div style="font-size:18px;font-weight:700;color:var(--text-primary)">${d.NOME_BIBLIOTECA || '—'}</div>
        <div style="font-size:12px;font-family:monospace;color:var(--text-muted);margin-top:2px">${d.COD_BIBLIOTECA || ''}</div>
      </div>
      <button class="btn-ghost" onclick="abrirModalEditarBib('${d.COD_BIBLIOTECA}')">
        <i class="fa-solid fa-pen" style="margin-right:5px"></i>Editar
      </button>
    </div>

    <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px">

      <!-- Informação Geral -->
      <div class="panel">
        <div style="font-size:11px;font-weight:600;color:var(--text-secondary);text-transform:uppercase;
          letter-spacing:.06em;margin-bottom:10px">Informação Geral</div>
        ${_bcampo('Província', d.PROVINCIA)}
        ${_bcampo('Endereço', d.ENDERECO)}
        ${_bcampo('Contacto', d.CONTACTO_BIBLIOTECA)}
        ${_bcampo('Inauguração', fmtData(d.DATA_INAUGURACAO))}
        ${_bcampo('Capacidade', d.CAPACIDADE ? d.CAPACIDADE + ' pessoas' : '—')}
      </div>

      <!-- Estatísticas -->
      <div class="panel">
        <div style="font-size:11px;font-weight:600;color:var(--text-secondary);text-transform:uppercase;
          letter-spacing:.06em;margin-bottom:10px">Estatísticas</div>
        ${_bcampo('Total de Materiais', d.STATS?.TOTAL_MATERIAIS ?? d.TOTAL_MATERIAIS ?? '—')}
        ${_bcampo('Total de Leitores', d.STATS?.TOTAL_LEITORES ?? d.TOTAL_LEITORES ?? '—')}
        ${_bcampo('Empréstimos Activos', d.STATS?.EMPRESTIMOS_ACTIVOS ?? '—')}
        ${_bcampo('Região', _badgeRegiao(d.PROVINCIA))}
      </div>

      <!-- Infraestrutura & Serviços -->
      <div class="panel">
        <div style="font-size:11px;font-weight:600;color:var(--text-secondary);text-transform:uppercase;
          letter-spacing:.06em;margin-bottom:10px">Infraestrutura & Serviços</div>
        <div style="font-size:12px;color:var(--text-secondary);margin-bottom:8px">
          <span style="font-weight:600;color:var(--text-muted);display:block;margin-bottom:3px">Infraestrutura</span>
          ${d.INFRAESTRUTURA || '<em style="color:var(--text-muted)">Não especificada</em>'}
        </div>
        <div style="font-size:12px;color:var(--text-secondary)">
          <span style="font-weight:600;color:var(--text-muted);display:block;margin-bottom:3px">Serviços</span>
          ${d.SERVICOS || '<em style="color:var(--text-muted)">Não especificados</em>'}
        </div>
      </div>

      <!-- Responsáveis -->
      <div class="panel">
        <div style="font-size:11px;font-weight:600;color:var(--text-secondary);text-transform:uppercase;
          letter-spacing:.06em;margin-bottom:10px">Responsáveis</div>
        ${responsaveis || `<div style="font-size:12px;color:var(--text-muted)">Sem responsáveis registados.</div>`}
      </div>

    </div>

    ${horarios ? `
    <div class="panel" style="margin-top:16px">
      <div style="font-size:11px;font-weight:600;color:var(--text-secondary);text-transform:uppercase;
        letter-spacing:.06em;margin-bottom:10px">Horários de Funcionamento</div>
      <table style="width:100%;border-collapse:collapse">
        <thead>
          <tr style="border-bottom:1px solid var(--border)">
            <th style="text-align:left;padding:4px 8px;font-size:11px;color:var(--text-muted)">Dia</th>
            <th style="text-align:left;padding:4px 8px;font-size:11px;color:var(--text-muted)">Abertura</th>
            <th style="text-align:left;padding:4px 8px;font-size:11px;color:var(--text-muted)">Fecho</th>
          </tr>
        </thead>
        <tbody>${horarios}</tbody>
      </table>
    </div>` : ''}
  `;
}

// ════════════════════════════════════════════════
// CONTEXT MENU
// ════════════════════════════════════════════════

function abrirCtxMenuBib(evt, cod) {
  evt.stopPropagation();
  const menu = document.getElementById('ctx-menu-bib');
  menu.innerHTML = `
    <div class="ctx-menu-item" onclick="fecharCtxMenuBib();abrirDrawerBiblioteca('${cod}')">
      <i class="fa-solid fa-eye" style="width:14px"></i> Ver detalhe
    </div>
    <div class="ctx-menu-item" onclick="fecharCtxMenuBib();abrirModalEditarBib('${cod}')">
      <i class="fa-solid fa-pen" style="width:14px"></i> Editar
    </div>
    <div class="ctx-menu-item ctx-menu-danger" onclick="fecharCtxMenuBib();_confirmarDesactivarBib('${cod}')">
      <i class="fa-solid fa-ban" style="width:14px"></i> Desactivar
    </div>`;

  const btn  = evt.currentTarget;
  const rect = btn.getBoundingClientRect();
  menu.style.display = 'block';
  menu.style.position = 'fixed';
  menu.style.top  = (rect.bottom + 4) + 'px';
  menu.style.left = Math.max(4, rect.right - 170) + 'px';

  setTimeout(() => document.addEventListener('click', fecharCtxMenuBib, { once: true }), 0);
}

function fecharCtxMenuBib() {
  const m = document.getElementById('ctx-menu-bib');
  if (m) m.style.display = 'none';
}

function _confirmarDesactivarBib(cod) {
  confirmar(
    'Desactivar esta biblioteca? Esta acção só é possível se não houver materiais nem empréstimos activos.',
    async () => {
      try {
        await patch(`/api/bibliotecas/${cod}/desactivar`, {});
        toast('Biblioteca desactivada.');
        carregarBibliotecas();
      } catch (err) {
        toast('Erro: ' + err.message, 'erro');
      }
    }
  );
}

// ════════════════════════════════════════════════
// DRAWER — Detalhe da Biblioteca
// ════════════════════════════════════════════════

async function abrirDrawerBiblioteca(cod) {
  _bibDrawerCod = cod;
  _bibDrawerTab = 'info';
  _bibDetalhe   = null;

  const overlay  = document.getElementById('drawer-bib-overlay');
  const drawer   = document.getElementById('drawer-bib');
  const conteudo = document.getElementById('drawer-bib-conteudo');

  conteudo.innerHTML = `<div style="text-align:center;padding:30px;color:var(--text-muted)">
    <i class="fa-solid fa-spinner fa-spin"></i> A carregar…
  </div>`;
  overlay.style.display = 'block';
  drawer.classList.add('open');

  ['info','horarios','responsaveis'].forEach(t =>
    document.getElementById(`dtab-bib-${t}`)?.classList.toggle('tab-active', t === 'info')
  );

  try {
    _bibDetalhe = await get(`/api/bibliotecas/${cod}`);
    _renderizarDrawerBib();
  } catch (err) {
    conteudo.innerHTML = `<div style="color:#f85149;padding:20px">${err.message}</div>`;
  }
}

function fecharDrawerBiblioteca() {
  document.getElementById('drawer-bib-overlay').style.display = 'none';
  document.getElementById('drawer-bib').classList.remove('open');
  _bibDrawerCod = null;
  _bibDetalhe   = null;
}

function mudarTabDrawerBib(tab) {
  _bibDrawerTab = tab;
  ['info','horarios','responsaveis'].forEach(t =>
    document.getElementById(`dtab-bib-${t}`)?.classList.toggle('tab-active', t === tab)
  );
  _renderizarDrawerBib();
}

function _renderizarDrawerBib() {
  if (!_bibDetalhe) return;
  if (_bibDrawerTab === 'info')         _renderizarDrawerInfoBib(_bibDetalhe);
  else if (_bibDrawerTab === 'horarios')     _renderizarDrawerHorariosBib(_bibDetalhe);
  else if (_bibDrawerTab === 'responsaveis') _renderizarDrawerResponsaveisBib(_bibDetalhe);
}

function _renderizarDrawerInfoBib(d) {
  const conteudo = document.getElementById('drawer-bib-conteudo');
  conteudo.innerHTML = `
    <div style="display:flex;align-items:center;gap:12px;padding:12px;background:var(--surface-raised);border-radius:10px;margin-bottom:14px">
      <div style="width:44px;height:44px;border-radius:10px;background:var(--theme-accent);
        color:#fff;display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0">
        <i class="fa-solid fa-building-columns"></i>
      </div>
      <div>
        <div style="font-size:15px;font-weight:700">${d.NOME_BIBLIOTECA || '—'}</div>
        <div style="font-size:10px;font-family:monospace;color:var(--text-muted)">${d.COD_BIBLIOTECA || ''}</div>
      </div>
    </div>

    ${_bsecao('Localização')}
    ${_bcampo('Província', d.PROVINCIA)}
    ${_bcampo('Região', _badgeRegiao(d.PROVINCIA))}
    ${_bcampo('Endereço', d.ENDERECO)}
    ${d.LATITUDE ? _bcampo('Coordenadas', `${d.LATITUDE}, ${d.LONGITUDE}`) : ''}

    ${_bsecao('Contacto & Capacidade')}
    ${_bcampo('Contacto', d.CONTACTO_BIBLIOTECA)}
    ${_bcampo('Capacidade', d.CAPACIDADE ? d.CAPACIDADE + ' pessoas' : '—')}
    ${_bcampo('Inauguração', fmtData(d.DATA_INAUGURACAO))}

    ${_bsecao('Estatísticas')}
    ${_bcampo('Materiais', d.STATS?.TOTAL_MATERIAIS ?? d.TOTAL_MATERIAIS ?? '—')}
    ${_bcampo('Leitores', d.STATS?.TOTAL_LEITORES ?? d.TOTAL_LEITORES ?? '—')}
    ${_bcampo('Empréstimos Activos', d.STATS?.EMPRESTIMOS_ACTIVOS ?? '—')}

    ${_bsecao('Infraestrutura & Serviços')}
    <div style="font-size:12px;color:var(--text-secondary);margin:6px 0 10px">
      <div style="font-weight:600;color:var(--text-muted);margin-bottom:3px">Infraestrutura</div>
      <div>${d.INFRAESTRUTURA || '<em style="color:var(--text-muted)">Não especificada</em>'}</div>
    </div>
    <div style="font-size:12px;color:var(--text-secondary)">
      <div style="font-weight:600;color:var(--text-muted);margin-bottom:3px">Serviços</div>
      <div>${d.SERVICOS || '<em style="color:var(--text-muted)">Não especificados</em>'}</div>
    </div>

    ${utilizadorActual?.NIVEL_ACESSO === 'Administrador' ? `
    <div style="margin-top:18px;padding-top:14px;border-top:1px solid var(--border)">
      <button onclick="_desativarBiblioteca('${d.COD_BIBLIOTECA}')"
              style="width:100%;padding:9px;border:1px solid #ef4444;color:#ef4444;background:transparent;border-radius:7px;cursor:not-allowed;font-size:12px;font-weight:500;opacity:.6"
              disabled title="Funcionalidade ainda não disponível no backend">
        <i class="fa-solid fa-power-off" style="margin-right:6px"></i>Desativar Biblioteca
      </button>
      <div style="font-size:10px;color:var(--text-muted);text-align:center;margin-top:5px">Disponível em breve</div>
    </div>` : ''}
  `;
}

function _desativarBiblioteca(cod) {
  toast('Funcionalidade de desativação ainda não disponível.', 'erro');
}

function _renderizarDrawerHorariosBib(d) {
  const conteudo = document.getElementById('drawer-bib-conteudo');
  const horarios = d.HORARIOS || [];
  if (!horarios.length) {
    conteudo.innerHTML = emptyState('🕐', 'Sem horários definidos', 'Esta biblioteca não tem horários registados.');
    return;
  }
  const linhas = horarios.map(h => `
    <tr style="border-bottom:1px solid var(--border-soft)">
      <td style="padding:8px;font-size:13px;font-weight:500">${h.DIA_SEMANA}</td>
      <td style="padding:8px;font-size:13px">${h.HORA_ABERTURA || '—'}</td>
      <td style="padding:8px;font-size:13px">${h.HORA_FECHO || '—'}</td>
    </tr>`).join('');
  conteudo.innerHTML = `
    <table style="width:100%;border-collapse:collapse">
      <thead>
        <tr style="border-bottom:2px solid var(--border)">
          <th style="text-align:left;padding:8px;font-size:11px;color:var(--text-muted)">Dia</th>
          <th style="text-align:left;padding:8px;font-size:11px;color:var(--text-muted)">Abertura</th>
          <th style="text-align:left;padding:8px;font-size:11px;color:var(--text-muted)">Fecho</th>
        </tr>
      </thead>
      <tbody>${linhas}</tbody>
    </table>`;
}

function _renderizarDrawerResponsaveisBib(d) {
  const conteudo = document.getElementById('drawer-bib-conteudo');
  const resps = d.RESPONSAVEIS || [];
  if (!resps.length) {
    conteudo.innerHTML = emptyState('👤', 'Sem responsáveis', 'Esta biblioteca não tem responsáveis registados.');
    return;
  }
  conteudo.innerHTML = resps.map(r => `
    <div style="display:flex;align-items:center;gap:12px;padding:10px 0;border-bottom:1px solid var(--border-soft)">
      <div style="width:38px;height:38px;border-radius:50%;background:var(--theme-accent);
        color:#fff;display:flex;align-items:center;justify-content:center;
        font-size:13px;font-weight:700;flex-shrink:0">${iniciais(r.NOME_FUNCIONARIO)}</div>
      <div style="flex:1">
        <div style="font-size:13px;font-weight:600">${r.NOME_FUNCIONARIO || '—'}</div>
        <div style="font-size:11px;color:var(--text-muted)">
          ${r.PAPEL || '—'} ·
          desde ${fmtData(r.DATA_INICIO)}
          ${r.DATA_FIM ? ' até ' + fmtData(r.DATA_FIM) : ' <span style="color:var(--theme-accent-text);font-weight:500">(actual)</span>'}
        </div>
      </div>
    </div>`).join('');
}

// ════════════════════════════════════════════════
// MODAL EDITAR — 11-C
// ════════════════════════════════════════════════

async function abrirModalEditarBib(cod) {
  _bibEditCod = cod;
  document.getElementById('modal-bib-overlay').classList.remove('hidden');
  document.getElementById('modal-bib-erro').classList.add('hidden');

  const isAdmin  = utilizadorActual?.NIVEL_ACESSO === 'Administrador';
  const conteudo = document.getElementById('modal-bib-conteudo');
  const titulo   = document.getElementById('modal-bib-titulo');

  conteudo.innerHTML = `<div style="text-align:center;padding:20px;color:var(--text-muted)">
    <i class="fa-solid fa-spinner fa-spin"></i>
  </div>`;

  let d = null;
  try { d = await get(`/api/bibliotecas/${cod}`); } catch (err) {
    conteudo.innerHTML = `<div style="color:#f85149;padding:10px">${err.message}</div>`;
    return;
  }

  if (titulo) titulo.textContent = isAdmin ? 'Editar Biblioteca' : 'Editar A Minha Biblioteca';

  if (isAdmin) {
    conteudo.innerHTML = `
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:0 16px">
        <div class="form-group" style="grid-column:1/-1">
          <label class="form-label">Nome da Biblioteca *</label>
          <input id="eb-nome" class="input-field" value="${d.NOME_BIBLIOTECA || ''}"/>
        </div>
        <div class="form-group">
          <label class="form-label">Província</label>
          <select id="eb-provincia" class="input-field">
            ${_PROVINCIAS.map(p =>
              `<option value="${p}" ${d.PROVINCIA === p ? 'selected' : ''}>${p}</option>`
            ).join('')}
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Capacidade</label>
          <input id="eb-capacidade" type="number" min="1" class="input-field" value="${d.CAPACIDADE || ''}"/>
        </div>
        <div class="form-group" style="grid-column:1/-1">
          <label class="form-label">Endereço</label>
          <input id="eb-endereco" class="input-field" value="${d.ENDERECO || ''}"/>
        </div>
        <div class="form-group">
          <label class="form-label">Contacto</label>
          <input id="eb-contacto" class="input-field" value="${d.CONTACTO_BIBLIOTECA || ''}"/>
        </div>
        <div class="form-group">
          <label class="form-label">Data de Inauguração</label>
          <input id="eb-inauguracao" type="date" class="input-field"
                 value="${d.DATA_INAUGURACAO ? d.DATA_INAUGURACAO.substring(0,10) : ''}"/>
        </div>
        <div class="form-group" style="grid-column:1/-1">
          <label class="form-label">Infraestrutura</label>
          <textarea id="eb-infraestrutura" class="input-field" rows="2"
                    style="resize:vertical">${d.INFRAESTRUTURA || ''}</textarea>
        </div>
        <div class="form-group" style="grid-column:1/-1">
          <label class="form-label">Serviços</label>
          <textarea id="eb-servicos" class="input-field" rows="2"
                    style="resize:vertical">${d.SERVICOS || ''}</textarea>
        </div>
      </div>`;
  } else {
    conteudo.innerHTML = `
      <div style="margin-bottom:12px;padding:8px 12px;background:var(--theme-accent-light);border-radius:6px;font-size:11px;color:#58a6ff">
        <i class="fa-solid fa-circle-info" style="margin-right:5px"></i>
        Pode editar infraestrutura e serviços. Nome, província, contacto e código só o Administrador pode alterar.
      </div>
      <div class="form-group">
        <label class="form-label">Infraestrutura</label>
        <textarea id="eb-infraestrutura" class="input-field" rows="4"
                  style="resize:vertical">${d.INFRAESTRUTURA || ''}</textarea>
      </div>
      <div class="form-group">
        <label class="form-label">Serviços</label>
        <textarea id="eb-servicos" class="input-field" rows="4"
                  style="resize:vertical">${d.SERVICOS || ''}</textarea>
      </div>`;
  }
}

function fecharModalBib(evt) {
  if (evt && evt.target !== document.getElementById('modal-bib-overlay')) return;
  document.getElementById('modal-bib-overlay').classList.add('hidden');
  _bibEditCod = null;
}

async function _submeterModalBib() {
  const isAdmin = utilizadorActual?.NIVEL_ACESSO === 'Administrador';
  const body    = {};

  const get_val = (id) => document.getElementById(id)?.value?.trim() || undefined;

  if (isAdmin) {
    const nome = get_val('eb-nome');
    if (!nome) { _mostrarErroBib('O nome da biblioteca é obrigatório.'); return; }
    body.nome_biblioteca      = nome;
    body.provincia             = get_val('eb-provincia');
    body.endereco              = get_val('eb-endereco');
    body.contacto_biblioteca   = get_val('eb-contacto');
    body.capacidade            = parseInt(document.getElementById('eb-capacidade')?.value) || undefined;
    body.data_inauguracao      = get_val('eb-inauguracao') || undefined;
    body.infraestrutura        = get_val('eb-infraestrutura');
    body.servicos              = get_val('eb-servicos');
  } else {
    body.infraestrutura = get_val('eb-infraestrutura');
    body.servicos       = get_val('eb-servicos');
  }

  try {
    await patch(`/api/bibliotecas/${_bibEditCod}`, body);
    fecharModalBib();
    toast('Biblioteca actualizada com sucesso.');
    carregarBibliotecas();
    if (_bibDrawerCod === _bibEditCod) abrirDrawerBiblioteca(_bibEditCod);
  } catch (err) {
    _mostrarErroBib(err.message);
  }
}

// ════════════════════════════════════════════════
// WIZARD ADICIONAR — 11-D (Admin)
// ════════════════════════════════════════════════

function abrirWizardBib() {
  _wizBibStep  = 1;
  _wizBibDados = {};
  document.getElementById('wiz-bib-overlay').classList.remove('hidden');
  document.getElementById('wiz-bib-erro').classList.add('hidden');
  _renderizarWizBib();
}

function fecharWizardBib(evt) {
  if (evt && evt.target !== document.getElementById('wiz-bib-overlay')) return;
  document.getElementById('wiz-bib-overlay').classList.add('hidden');
}

function _renderizarWizBib() {
  const total = 2;
  document.getElementById('wiz-bib-indicador').innerHTML =
    wizardIndicador(_wizBibStep, total, ['Dados da Biblioteca', 'Confirmação']);

  const btnRecuar  = document.getElementById('wiz-bib-btn-recuar');
  const btnAvancar = document.getElementById('wiz-bib-btn-avancar');

  if (btnRecuar)  btnRecuar.style.display = _wizBibStep > 1 ? 'inline-flex' : 'none';
  if (btnAvancar) {
    if (_wizBibStep < total) {
      btnAvancar.innerHTML = `Próximo <i class="fa-solid fa-arrow-right" style="margin-left:5px"></i>`;
      btnAvancar.onclick   = _avancarWizBib;
    } else {
      btnAvancar.innerHTML = `<i class="fa-solid fa-check" style="margin-right:5px"></i>Confirmar e Adicionar`;
      btnAvancar.onclick   = _submeterWizBib;
    }
  }

  const conteudo = document.getElementById('wiz-bib-conteudo');
  if (_wizBibStep === 1) conteudo.innerHTML = _wizBibStep1Html();
  if (_wizBibStep === 2) conteudo.innerHTML = _wizBibStep2Html();
}

function _wizBibStep1Html() {
  const d = _wizBibDados;
  return `
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:0 16px">
      <div class="form-group" style="grid-column:1/-1">
        <label class="form-label">Nome da Biblioteca *</label>
        <input id="wb1-nome" class="input-field" placeholder="Ex: Biblioteca Esperança de Maputo"
               value="${d.nome_biblioteca || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Província *</label>
        <select id="wb1-provincia" class="input-field">
          <option value="">— Seleccionar —</option>
          ${_PROVINCIAS.map(p =>
            `<option value="${p}" ${d.provincia === p ? 'selected' : ''}>${p}</option>`
          ).join('')}
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Capacidade</label>
        <input id="wb1-capacidade" type="number" min="1" class="input-field"
               placeholder="Ex: 150" value="${d.capacidade || ''}"/>
      </div>
      <div class="form-group" style="grid-column:1/-1">
        <label class="form-label">Endereço *</label>
        <input id="wb1-endereco" class="input-field" placeholder="Ex: Av. Karl Marx, nº 23"
               value="${d.endereco || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Contacto *</label>
        <input id="wb1-contacto" class="input-field" placeholder="Ex: +258 21 000 000"
               value="${d.contacto_biblioteca || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Data de Inauguração</label>
        <input id="wb1-inauguracao" type="date" class="input-field"
               value="${d.data_inauguracao || ''}"/>
      </div>
      <div class="form-group" style="grid-column:1/-1">
        <label class="form-label">Infraestrutura</label>
        <textarea id="wb1-infraestrutura" class="input-field" rows="2"
                  placeholder="Ex: Sala de leitura, sala infantil, computadores"
                  style="resize:vertical">${d.infraestrutura || ''}</textarea>
      </div>
      <div class="form-group" style="grid-column:1/-1">
        <label class="form-label">Serviços</label>
        <textarea id="wb1-servicos" class="input-field" rows="2"
                  placeholder="Ex: Empréstimos, referência, internet"
                  style="resize:vertical">${d.servicos || ''}</textarea>
      </div>
    </div>`;
}

function _wizBibStep2Html() {
  const d = _wizBibDados;
  return `
    <div style="background:var(--surface-raised);border:0.5px solid var(--border);border-radius:10px;padding:16px;margin-bottom:4px">
      <div style="font-size:12px;font-weight:600;color:var(--text-primary);margin-bottom:12px">Confirme os dados antes de adicionar:</div>
      ${_bcampo('Nome', d.nome_biblioteca)}
      ${_bcampo('Província', d.provincia)}
      ${_bcampo('Região', _badgeRegiao(d.provincia))}
      ${_bcampo('Endereço', d.endereco || '—')}
      ${_bcampo('Contacto', d.contacto_biblioteca || '—')}
      ${_bcampo('Capacidade', d.capacidade ? d.capacidade + ' pessoas' : '—')}
      ${_bcampo('Inauguração', d.data_inauguracao ? fmtData(d.data_inauguracao) : '—')}
      ${d.infraestrutura ? _bcampo('Infraestrutura', d.infraestrutura) : ''}
      ${d.servicos       ? _bcampo('Serviços', d.servicos) : ''}
    </div>
    <div style="font-size:11px;color:var(--text-muted);margin-top:10px;padding:8px;background:var(--surface-raised);border-radius:6px">
      <i class="fa-solid fa-circle-info" style="margin-right:5px;color:#d29922"></i>
      O código da biblioteca será gerado automaticamente pelo sistema.
    </div>`;
}

function _avancarWizBib() {
  const erro = document.getElementById('wiz-bib-erro');
  if (erro) erro.classList.add('hidden');

  if (_wizBibStep === 1) {
    const nome      = document.getElementById('wb1-nome')?.value?.trim();
    const provincia = document.getElementById('wb1-provincia')?.value;
    const endereco  = document.getElementById('wb1-endereco')?.value?.trim();
    const contacto  = document.getElementById('wb1-contacto')?.value?.trim();
    if (!nome)      { _mostrarErroWizBib('O nome da biblioteca é obrigatório.'); return; }
    if (!provincia) { _mostrarErroWizBib('Seleccione a província.'); return; }
    if (!endereco)  { _mostrarErroWizBib('O endereço é obrigatório.'); return; }
    if (!contacto)  { _mostrarErroWizBib('O contacto é obrigatório.'); return; }

    _wizBibDados.nome_biblioteca    = nome;
    _wizBibDados.provincia           = provincia;
    _wizBibDados.endereco            = endereco;
    _wizBibDados.contacto_biblioteca = contacto;
    _wizBibDados.capacidade          = parseInt(document.getElementById('wb1-capacidade')?.value) || undefined;
    _wizBibDados.data_inauguracao    = document.getElementById('wb1-inauguracao')?.value || undefined;
    _wizBibDados.infraestrutura      = document.getElementById('wb1-infraestrutura')?.value?.trim() || undefined;
    _wizBibDados.servicos            = document.getElementById('wb1-servicos')?.value?.trim() || undefined;
  }

  _wizBibStep++;
  _renderizarWizBib();
}

function _recuarWizBib() {
  if (_wizBibStep > 1) { _wizBibStep--; _renderizarWizBib(); }
}

function _mostrarErroWizBib(msg) {
  const div  = document.getElementById('wiz-bib-erro');
  const span = document.getElementById('wiz-bib-erro-msg');
  if (div)  div.classList.remove('hidden');
  if (span) span.textContent = msg;
}

async function _submeterWizBib() {
  const btn = document.getElementById('wiz-bib-btn-avancar');
  if (btn) { btn.disabled = true; btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>'; }

  try {
    await post('/api/bibliotecas', _wizBibDados);
    document.getElementById('wiz-bib-overlay').classList.add('hidden');
    toast('Biblioteca adicionada à rede com sucesso.');
    carregarBibliotecas();
  } catch (err) {
    _mostrarErroWizBib(err.message);
  } finally {
    if (btn) {
      btn.disabled = false;
      btn.innerHTML = '<i class="fa-solid fa-check" style="margin-right:5px"></i>Confirmar e Adicionar';
      btn.onclick   = _submeterWizBib;
    }
  }
}
