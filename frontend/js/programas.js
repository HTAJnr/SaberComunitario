// ════════════════════════════════════════════════
// PROGRAMAS DE ALFABETIZAÇÃO (TELA 08)
// ════════════════════════════════════════════════

let _progRows      = [];
let _progDetalhe   = null;
let _progDrawerCod = null;
let _progDrawerTab = 'info';
let _editProgCod   = null;
let _progNiveisWiz = [];
let _progMatWiz    = [];
let _progFuncWiz   = [];
let _inscrCod      = null;
let _partCod       = null;
let _partCartao    = null;
let _progMatLista  = []; // [{COD_MATERIAL, TITULO}]
let _progFuncLista = []; // [{COD_FUNCIONARIO, NOME_FUNCIONARIO}]
let _progTabActual = 'lista';

// ── Helpers de apresentação ────────────────────

const _pcampo = campoDetalhe;
const _psecao = secaoDetalhe;

function _badgeEstadoProg(estado) {
  const m = {
    'Activo':    'bdg-activo-emp',
    'Concluido': 'bdg-devolvido',
    'Suspenso':  'bdg-suspenso'
  };
  const label = estado === 'Concluido' ? 'Concluído' : (estado || '—');
  return estado
    ? `<span class="bdg ${m[estado] || ''}">${label}</span>`
    : '—';
}

function _badgePublico(publico) {
  if (!publico) return '—';
  return `<span class="bdg" style="background:#1a1035;color:#a78bfa;font-size:10px">${publico}</span>`;
}

function _badgeEstadoPart(estado) {
  const m = {
    'Activo':    'bdg-activo-emp',
    'Concluido': 'bdg-devolvido',
    'Desistiu':  'bdg-suspenso'
  };
  const label = estado === 'Concluido' ? 'Concluído' : (estado || '—');
  return estado
    ? `<span class="bdg ${m[estado] || ''}">${label}</span>`
    : '—';
}

// ── 08-A Lista ─────────────────────────────────

function _switchTabProg(tab) {
  _progTabActual = tab;
  ['lista', 'relatorio'].forEach(t => {
    document.getElementById(`tab-prog-${t}`)?.classList.toggle('tab-active', t === tab);
  });
  document.getElementById('prog-painel-lista').style.display     = tab === 'lista'     ? '' : 'none';
  document.getElementById('prog-painel-relatorio').style.display = tab === 'relatorio' ? '' : 'none';
  document.getElementById('btn-novo-prog-wrap').style.display    = tab === 'lista'     ? '' : 'none';
  if (tab === 'relatorio') _carregarRelatorioNacional();
}

async function _carregarRelatorioNacional() {
  const conteudo = document.getElementById('prog-relatorio-conteudo');
  conteudo.innerHTML = '<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:24px">A carregar…</p>';
  try {
    const rows = await get('/api/programas/relatorio-nacional');
    if (!Array.isArray(rows) || !rows.length) {
      conteudo.innerHTML = emptyState('fa-chart-bar', 'Nenhum dado disponível', 'Esta vista requer ligação ao NacionalDB');
      return;
    }
    conteudo.innerHTML = `
      <table class="tbl">
        <thead>
          <tr>
            <th>Biblioteca</th>
            <th>Programa</th>
            <th>Público-alvo</th>
            <th style="text-align:center">Dur.</th>
            <th>Estado</th>
            <th style="text-align:center">Total</th>
            <th style="text-align:center">Activos</th>
            <th style="text-align:center">Concluídos</th>
            <th style="text-align:center">Desistiram</th>
          </tr>
        </thead>
        <tbody>
          ${rows.map(r => `<tr>
            <td style="font-size:11px;font-family:monospace;color:var(--text-muted)">${r.COD_BIBLIOTECA || '—'}</td>
            <td style="font-weight:500">${r.NOME_PROGRAMA || '—'}</td>
            <td>${_badgePublico(r.PUBLICO_ALVO)}</td>
            <td style="text-align:center;color:var(--text-muted)">${r.DURACAO_SEMANAS ? r.DURACAO_SEMANAS + ' sem.' : '—'}</td>
            <td>${_badgeEstadoProg(r.ESTADO_PROGRAMA)}</td>
            <td style="text-align:center">${r.TOTAL_PARTICIPANTES ?? 0}</td>
            <td style="text-align:center">${r.PARTICIPANTES_ACTIVOS ?? 0}</td>
            <td style="text-align:center">${r.PARTICIPANTES_CONCLUIDOS ?? 0}</td>
            <td style="text-align:center">${r.PARTICIPANTES_DESISTIRAM ?? 0}</td>
          </tr>`).join('')}
        </tbody>
      </table>
    `;
  } catch (err) {
    conteudo.innerHTML = `<p style="text-align:center;color:#f85149;font-size:12px;padding:24px">Erro: ${err.message}</p>`;
  }
}

async function carregarProgramas() {
  const nivel = utilizadorActual?.NIVEL_ACESSO || '';
  const podeGerir = ['Administrador', 'Coordenador'].includes(nivel);
  const tabRelatorio = document.getElementById('tab-prog-relatorio');
  if (tabRelatorio) tabRelatorio.style.display = nivel === 'Administrador' ? '' : 'none';

  try {
    const rows = await get('/api/programas');
    _progRows = Array.isArray(rows) ? rows : [];
    _renderizarTabelaProgramas();
  } catch (err) {
    toast('Erro a carregar programas: ' + err.message, 'erro');
  }

  const wrap = document.getElementById('btn-novo-prog-wrap');
  if (wrap) wrap.style.display = podeGerir ? '' : 'none';
}

function _renderizarTabelaProgramas() {
  const q = (document.getElementById('filtro-prog-q')?.value || '').toLowerCase();
  let rows = _progRows;
  if (q) rows = rows.filter(r => (r.NOME_PROGRAMA || '').toLowerCase().includes(q));

  const tbody = document.getElementById('tabela-programas');
  if (!tbody) return;
  tbody.innerHTML = rows.length ? rows.map(_linhaProg).join('') : linhaVazia(7);
}

function _linhaProg(r) {
  const dur = r.DURACAO_SEMANAS ? `${r.DURACAO_SEMANAS} sem.` : '—';
  return `<tr>
    <td style="font-size:11px;color:var(--text-muted);font-family:monospace">${r.COD_PROGRAMA}</td>
    <td style="font-weight:500">${r.NOME_PROGRAMA || '—'}</td>
    <td>${_badgePublico(r.PUBLICO_ALVO)}</td>
    <td style="text-align:center;color:var(--text-muted)">${dur}</td>
    <td style="text-align:center;color:var(--text-muted)">${r.TOTAL_PARTICIPANTES_ACTIVOS ?? 0}</td>
    <td>${_badgeEstadoProg(r.ESTADO_PROGRAMA)}</td>
    <td style="text-align:right">
      <button class="btn-ghost btn-sm" onclick="abrirCtxMenuProg(event,'${r.COD_PROGRAMA}')">···</button>
    </td>
  </tr>`;
}

// ── Context menu ───────────────────────────────

function abrirCtxMenuProg(evt, cod) {
  evt.stopPropagation();
  const nivel = utilizadorActual?.NIVEL_ACESSO || '';
  const podeGerir = ['Administrador', 'Coordenador'].includes(nivel);

  const prog = _progRows.find(r => r.COD_PROGRAMA === cod);
  const estadoActual = prog?.ESTADO_PROGRAMA || '';

  let accoesGestao = '';
  if (podeGerir) {
    accoesGestao += `
      <div class="ctx-menu-item" onclick="fecharCtxMenuProg();abrirModalProg('${cod}')">
        <i class="fa-solid fa-pen" style="width:14px"></i> Editar
      </div>`;
    if (estadoActual !== 'Suspenso') {
      accoesGestao += `
      <div class="ctx-menu-item" onclick="fecharCtxMenuProg();_mudarEstadoProg('${cod}','Suspenso')">
        <i class="fa-solid fa-pause" style="width:14px"></i> Suspender
      </div>`;
    }
    if (estadoActual !== 'Concluido') {
      accoesGestao += `
      <div class="ctx-menu-item" onclick="fecharCtxMenuProg();_mudarEstadoProg('${cod}','Concluido')">
        <i class="fa-solid fa-flag-checkered" style="width:14px"></i> Encerrar
      </div>`;
    }
    if (estadoActual !== 'Activo') {
      accoesGestao += `
      <div class="ctx-menu-item" onclick="fecharCtxMenuProg();_mudarEstadoProg('${cod}','Activo')">
        <i class="fa-solid fa-play" style="width:14px"></i> Reactivar
      </div>`;
    }
  }

  const menu = document.getElementById('ctx-menu-prog');
  menu.innerHTML = `
    <div class="ctx-menu-item" onclick="fecharCtxMenuProg();abrirDrawerProg('${cod}')">
      <i class="fa-solid fa-eye" style="width:14px"></i> Ver detalhe
    </div>
    ${accoesGestao}
  `;

  const btn  = evt.currentTarget;
  const rect = btn.getBoundingClientRect();
  menu.style.display  = 'block';
  menu.style.position = 'fixed';
  menu.style.top      = (rect.bottom + 4) + 'px';
  menu.style.left     = Math.max(4, rect.right - 210) + 'px';

  setTimeout(() => document.addEventListener('click', fecharCtxMenuProg, { once: true }), 0);
}

function fecharCtxMenuProg() {
  const m = document.getElementById('ctx-menu-prog');
  if (m) m.style.display = 'none';
}

async function _mudarEstadoProg(cod, estado) {
  try {
    await patch(`/api/programas/${cod}`, { estado_programa: estado });
    toast('Estado actualizado.', 'sucesso');
    carregarProgramas();
  } catch (err) {
    toast('Erro: ' + err.message, 'erro');
  }
}

// ── Drawer 08-B ────────────────────────────────

async function abrirDrawerProg(cod) {
  _progDrawerCod = cod;
  _progDrawerTab = 'info';
  _progDetalhe   = null;

  document.getElementById('drawer-prog-overlay').style.display = 'block';
  document.getElementById('drawer-prog').classList.add('open');

  ['info','niveis','participantes','materiais','funcionarios'].forEach(t =>
    document.getElementById(`dtab-prog-${t}`)?.classList.toggle('tab-active', t === 'info')
  );

  const conteudo = document.getElementById('drawer-prog-conteudo');
  conteudo.innerHTML = '<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:24px">A carregar…</p>';

  try {
    _progDetalhe = await get(`/api/programas/${cod}`);
    document.getElementById('drawer-prog-titulo').textContent = _progDetalhe.programa?.NOME_PROGRAMA || 'Programa';
    _renderizarInfoProg(_progDetalhe);
  } catch (err) {
    conteudo.innerHTML = `<p style="text-align:center;color:#f85149;font-size:12px;padding:24px">Erro: ${err.message}</p>`;
  }
}

function fecharDrawerProg() {
  document.getElementById('drawer-prog-overlay').style.display = 'none';
  document.getElementById('drawer-prog').classList.remove('open');
  _progDrawerCod = null;
  _progDetalhe   = null;
}

function mudarTabDrawerProg(tab) {
  _progDrawerTab = tab;
  ['info','niveis','participantes','materiais','funcionarios'].forEach(t =>
    document.getElementById(`dtab-prog-${t}`)?.classList.toggle('tab-active', t === tab)
  );

  if (!_progDetalhe && tab !== 'participantes') return;

  if (tab === 'info')            _renderizarInfoProg(_progDetalhe);
  else if (tab === 'niveis')     _renderizarNiveisProg(_progDetalhe);
  else if (tab === 'participantes') _renderizarParticipantesProg();
  else if (tab === 'materiais')  _renderizarMateriaisProg(_progDetalhe);
  else if (tab === 'funcionarios') _renderizarFuncionariosProg(_progDetalhe);
}

function _renderizarInfoProg(d) {
  const p = d.programa || {};
  document.getElementById('drawer-prog-conteudo').innerHTML = `
    ${_psecao('Programa')}
    ${_pcampo('Código', `<span style="font-family:monospace">${p.COD_PROGRAMA || '—'}</span>`)}
    ${_pcampo('Nome', p.NOME_PROGRAMA || '—')}
    ${_pcampo('Estado', _badgeEstadoProg(p.ESTADO_PROGRAMA))}
    ${_pcampo('Público-alvo', _badgePublico(p.PUBLICO_ALVO))}
    ${_pcampo('Duração', p.DURACAO_SEMANAS ? `${p.DURACAO_SEMANAS} semanas` : '—')}
    ${p.DESCRICAO ? `${_psecao('Descrição')}<div style="font-size:12px;color:var(--text-secondary);line-height:1.5">${p.DESCRICAO}</div>` : ''}
    ${_psecao('Biblioteca')}
    ${_pcampo('Biblioteca', p.NOME_BIBLIOTECA || p.COD_BIBLIOTECA || '—')}
    ${p.METODOLOGIA ? `${_psecao('Metodologia')}<div style="font-size:12px;color:var(--text-secondary);line-height:1.5">${p.METODOLOGIA}</div>` : ''}
    ${p.RESULTADOS_ESPERADOS ? `${_psecao('Resultados Esperados')}<div style="font-size:12px;color:var(--text-secondary);line-height:1.5">${p.RESULTADOS_ESPERADOS}</div>` : ''}
  `;
}

function _renderizarNiveisProg(d) {
  const niveis = d.niveis || [];
  const conteudo = document.getElementById('drawer-prog-conteudo');
  if (!niveis.length) {
    conteudo.innerHTML = emptyState('fa-layer-group', 'Sem níveis de progressão', 'Adicione níveis ao criar ou editar o programa.');
    return;
  }
  conteudo.innerHTML = niveis.map((n, i) => `
    <div style="padding:10px 0;border-bottom:0.5px solid var(--border-soft)">
      <div style="display:flex;align-items:center;gap:8px;margin-bottom:4px">
        <span style="width:22px;height:22px;border-radius:50%;background:#6366f1;color:#fff;
                     display:inline-flex;align-items:center;justify-content:center;font-size:11px;font-weight:600;flex-shrink:0">${n.ORDEM ?? i + 1}</span>
        <span style="font-size:13px;font-weight:500">${n.NOME_NIVEL || '—'}</span>
      </div>
      ${n.DESCRICAO ? `<p style="font-size:11px;color:var(--text-muted);margin:0 0 0 30px;line-height:1.4">${n.DESCRICAO}</p>` : ''}
    </div>
  `).join('');
}

async function _renderizarParticipantesProg() {
  const conteudo = document.getElementById('drawer-prog-conteudo');
  const cod = _progDrawerCod;
  if (!cod) return;

  const nivel = utilizadorActual?.NIVEL_ACESSO || '';
  const podeGerir = ['Administrador', 'Coordenador'].includes(nivel);
  const podeInscrever = ['Administrador', 'Coordenador', 'Bibliotecario'].includes(nivel);

  conteudo.innerHTML = '<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:24px">A carregar…</p>';

  try {
    const parts = await get(`/api/programas/${cod}/participantes`);

    const niveis = _progDetalhe?.niveis || [];
    const btnInscrever = podeInscrever
      ? `<button onclick="abrirModalInscrever('${cod}')" class="btn-ghost" style="font-size:11px;margin-bottom:10px">
           <i class="fa-solid fa-user-plus" style="margin-right:4px"></i>Inscrever Leitor
         </button>`
      : '';

    if (!parts.length) {
      conteudo.innerHTML = btnInscrever + emptyState('fa-users', 'Sem participantes', 'Inscreva o primeiro leitor neste programa.');
      return;
    }

    const rows = parts.map(p => {
      const accoesGestao = podeGerir
        ? `<button onclick="abrirModalActualizarPart('${cod}','${p.NUM_CARTAO}')" class="btn-ghost btn-sm" title="Actualizar">
             <i class="fa-solid fa-pen"></i>
           </button>`
        : '';
      return `<tr>
        <td style="font-size:11px;font-family:monospace;color:var(--text-muted)">${p.NUM_CARTAO}</td>
        <td style="font-weight:500">${p.NOME_COMPLETO || '—'}</td>
        <td style="font-size:11px;color:var(--text-muted)">${p.NOME_NIVEL || '—'}</td>
        <td>${_badgeEstadoPart(p.ESTADO_PARTICIPACAO)}</td>
        <td style="color:var(--text-muted);font-size:11px">${fmtData(p.DATA_INSCRICAO)}</td>
        <td style="text-align:right">${accoesGestao}</td>
      </tr>`;
    }).join('');

    conteudo.innerHTML = `
      ${btnInscrever}
      <table class="tbl">
        <thead>
          <tr>
            <th>Cartão</th>
            <th>Nome</th>
            <th>Nível</th>
            <th>Estado</th>
            <th>Inscrição</th>
            <th></th>
          </tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    `;
  } catch (err) {
    conteudo.innerHTML = `<p style="text-align:center;color:#f85149;font-size:12px;padding:24px">Erro: ${err.message}</p>`;
  }
}

function _renderizarMateriaisProg(d) {
  const mats = d.materiais || [];
  const conteudo = document.getElementById('drawer-prog-conteudo');
  if (!mats.length) {
    conteudo.innerHTML = emptyState('fa-book', 'Sem materiais associados', 'Adicione materiais ao criar ou editar o programa.');
    return;
  }
  conteudo.innerHTML = `
    <table class="tbl">
      <thead><tr><th>Código</th><th>Título</th><th>Autor</th><th>Observações</th></tr></thead>
      <tbody>
        ${mats.map(m => `<tr>
          <td style="font-size:11px;font-family:monospace;color:var(--text-muted)">${m.COD_MATERIAL}</td>
          <td style="font-weight:500">${m.TITULO || '—'}</td>
          <td style="color:var(--text-muted)">${m.AUTOR || '—'}</td>
          <td style="color:var(--text-muted);font-size:11px">${m.OBSERVACOES || '—'}</td>
        </tr>`).join('')}
      </tbody>
    </table>
  `;
}

function _renderizarFuncionariosProg(d) {
  const funcs = d.funcionarios || [];
  const conteudo = document.getElementById('drawer-prog-conteudo');
  if (!funcs.length) {
    conteudo.innerHTML = emptyState('fa-user-tie', 'Sem funcionários associados', 'Adicione funcionários ao criar ou editar o programa.');
    return;
  }
  conteudo.innerHTML = `
    <table class="tbl">
      <thead><tr><th>Código</th><th>Nome</th><th>Papel</th></tr></thead>
      <tbody>
        ${funcs.map(f => `<tr>
          <td style="font-size:11px;font-family:monospace;color:var(--text-muted)">${f.COD_FUNCIONARIO}</td>
          <td style="font-weight:500">${f.NOME_COMPLETO || '—'}</td>
          <td>${_badgePapel(f.PAPEL)}</td>
        </tr>`).join('')}
      </tbody>
    </table>
  `;
}

function _badgePapel(papel) {
  const m = {
    'Responsavel': 'bdg-activo-emp',
    'Instrutor':   'bdg-devolvido',
    'Auxiliar':    'bdg'
  };
  const label = papel === 'Responsavel' ? 'Responsável' : (papel || '—');
  return papel
    ? `<span class="bdg ${m[papel] || ''}" style="font-size:10px">${label}</span>`
    : '—';
}

// ── Modal 08-C — Criar / Editar ────────────────

async function abrirModalProg(cod) {
  _editProgCod   = cod || null;
  _progNiveisWiz = [];
  _progMatWiz    = [];
  _progFuncWiz   = [];

  document.getElementById('modal-prog-titulo').textContent = cod ? 'Editar Programa' : 'Novo Programa';
  document.getElementById('modal-prog-erro').classList.add('hidden');
  document.getElementById('modal-prog-overlay').classList.remove('hidden');

  // Carregar listas para comboboxes de materiais e funcionários
  try { const r = await get('/api/materiais?limit=300'); _progMatLista = r.materiais || r || []; } catch { _progMatLista = []; }
  try { const r = await get('/api/funcionarios?limit=300'); _progFuncLista = r.funcionarios || r || []; } catch { _progFuncLista = []; }

  let dados = null;
  if (cod) {
    try {
      const d = await get(`/api/programas/${cod}`);
      dados = d.programa || {};
      _progNiveisWiz = (d.niveis || []).map(n => ({
        nome_nivel: n.NOME_NIVEL || '',
        descricao:  n.DESCRICAO  || '',
        ordem:      n.ORDEM      ?? ''
      }));
      _progMatWiz = (d.materiais || []).map(m => ({
        cod_material: m.COD_MATERIAL || '',
        observacoes:  m.OBSERVACOES  || ''
      }));
      _progFuncWiz = (d.funcionarios || []).map(f => ({
        cod_funcionario: f.COD_FUNCIONARIO || '',
        papel:           f.PAPEL           || 'Instrutor'
      }));
    } catch (err) {
      toast('Erro ao carregar dados: ' + err.message, 'erro');
    }
  }

  _renderizarModalProgConteudo(dados);
}

function fecharModalProg(evt) {
  if (evt && evt.target !== document.getElementById('modal-prog-overlay')) return;
  document.getElementById('modal-prog-overlay').classList.add('hidden');
}

function _renderizarModalProgConteudo(dados) {
  const d = dados || {};
  document.getElementById('modal-prog-conteudo').innerHTML = `
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:12px">
      <div style="grid-column:1/-1">
        <label class="form-label">Nome do Programa *</label>
        <input id="prog-nome" type="text" class="input-field" value="${d.NOME_PROGRAMA || ''}" placeholder="Ex: Alfabetização Básica 2026"/>
      </div>
      <div>
        <label class="form-label">Público-alvo *</label>
        <select id="prog-publico" class="input-field">
          ${['Iniciantes','Intermedios','Avancados','Todos'].map(v =>
            `<option value="${v}" ${d.PUBLICO_ALVO === v ? 'selected' : ''}>${v}</option>`
          ).join('')}
        </select>
      </div>
      <div>
        <label class="form-label">Duração (semanas)</label>
        <input id="prog-duracao" type="number" min="1" class="input-field" value="${d.DURACAO_SEMANAS || ''}"/>
      </div>
      <div style="grid-column:1/-1">
        <label class="form-label">Descrição</label>
        <textarea id="prog-descricao" class="input-field" rows="2" style="resize:vertical">${d.DESCRICAO || ''}</textarea>
      </div>
      <div style="grid-column:1/-1">
        <label class="form-label">Metodologia</label>
        <textarea id="prog-metodologia" class="input-field" rows="2" style="resize:vertical">${d.METODOLOGIA || ''}</textarea>
      </div>
      <div style="grid-column:1/-1">
        <label class="form-label">Resultados Esperados</label>
        <textarea id="prog-resultados" class="input-field" rows="2" style="resize:vertical">${d.RESULTADOS_ESPERADOS || ''}</textarea>
      </div>
    </div>

    <!-- Níveis dinâmicos -->
    <div style="margin-bottom:12px">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
        <span style="font-size:11px;font-weight:600;color:var(--text-secondary);text-transform:uppercase;letter-spacing:.05em">Níveis de Progressão</span>
        <button type="button" onclick="_adicionarNivelWiz()" class="btn-ghost" style="font-size:11px">
          <i class="fa-solid fa-plus" style="margin-right:4px"></i>Adicionar Nível
        </button>
      </div>
      <div id="prog-niveis-lista"></div>
    </div>

    <!-- Materiais dinâmicos -->
    <div style="margin-bottom:12px">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
        <span style="font-size:11px;font-weight:600;color:var(--text-secondary);text-transform:uppercase;letter-spacing:.05em">Materiais</span>
        <button type="button" onclick="_adicionarMatWiz()" class="btn-ghost" style="font-size:11px">
          <i class="fa-solid fa-plus" style="margin-right:4px"></i>Adicionar Material
        </button>
      </div>
      <div id="prog-mat-lista"></div>
    </div>

    <!-- Funcionários dinâmicos -->
    <div>
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
        <span style="font-size:11px;font-weight:600;color:var(--text-secondary);text-transform:uppercase;letter-spacing:.05em">Funcionários</span>
        <button type="button" onclick="_adicionarFuncWiz()" class="btn-ghost" style="font-size:11px">
          <i class="fa-solid fa-plus" style="margin-right:4px"></i>Adicionar Funcionário
        </button>
      </div>
      <div id="prog-func-lista"></div>
    </div>
  `;

  _renderizarNiveisWiz();
  _renderizarMatWiz();
  _renderizarFuncWiz();
}

// ── Gestão dinâmica de níveis ──────────────────

function _adicionarNivelWiz() {
  _progNiveisWiz.push({ nome_nivel: '', descricao: '', ordem: _progNiveisWiz.length + 1 });
  _renderizarNiveisWiz();
}

function _removerNivelWiz(i) {
  _progNiveisWiz.splice(i, 1);
  _progNiveisWiz.forEach((n, idx) => { if (!n.ordem) n.ordem = idx + 1; });
  _renderizarNiveisWiz();
}

function _renderizarNiveisWiz() {
  const lista = document.getElementById('prog-niveis-lista');
  if (!lista) return;
  if (!_progNiveisWiz.length) {
    lista.innerHTML = '<p style="font-size:11px;color:var(--text-muted);font-style:italic">Sem níveis adicionados.</p>';
    return;
  }
  lista.innerHTML = _progNiveisWiz.map((n, i) => `
    <div style="border:1px solid var(--border);border-radius:6px;padding:10px;margin-bottom:8px">
      <div style="display:flex;gap:8px;align-items:flex-start">
        <div style="flex:1">
          <input type="text" class="input-field" placeholder="Nome do nível *"
                 value="${n.nome_nivel}" oninput="_progNiveisWiz[${i}].nome_nivel=this.value"
                 style="margin-bottom:6px"/>
          <input type="text" class="input-field" placeholder="Descrição"
                 value="${n.descricao}" oninput="_progNiveisWiz[${i}].descricao=this.value"
                 style="margin-bottom:6px"/>
          <input type="number" class="input-field" placeholder="Ordem" min="1"
                 value="${n.ordem}" oninput="_progNiveisWiz[${i}].ordem=parseInt(this.value)||${i+1}"
                 style="width:80px"/>
        </div>
        <button type="button" onclick="_removerNivelWiz(${i})"
                style="background:none;border:none;color:#f85149;cursor:pointer;font-size:14px;padding:2px">
          <i class="fa-solid fa-xmark"></i>
        </button>
      </div>
    </div>
  `).join('');
}

// ── Gestão dinâmica de materiais ───────────────

function _adicionarMatWiz() {
  _progMatWiz.push({ cod_material: '', observacoes: '' });
  _renderizarMatWiz();
}

function _removerMatWiz(i) {
  _progMatWiz.splice(i, 1);
  _renderizarMatWiz();
}

function _renderizarMatWiz() {
  const lista = document.getElementById('prog-mat-lista');
  if (!lista) return;
  if (!_progMatWiz.length) {
    lista.innerHTML = '<p style="font-size:11px;color:var(--text-muted);font-style:italic">Sem materiais adicionados.</p>';
    return;
  }
  const matOpts = _progMatLista.map(m =>
    `<option value="${m.COD_MATERIAL}">${m.TITULO || m.COD_MATERIAL} (${m.COD_MATERIAL})</option>`
  ).join('');
  lista.innerHTML = _progMatWiz.map((m, i) => `
    <div style="display:flex;gap:8px;align-items:center;margin-bottom:6px">
      <select class="input-field" style="flex:2"
              onchange="_progMatWiz[${i}].cod_material=this.value">
        <option value="">— Seleccionar material —</option>
        ${matOpts.replace(`value="${m.cod_material}"`, `value="${m.cod_material}" selected`)}
      </select>
      <input type="text" class="input-field" placeholder="Observações"
             value="${m.observacoes}" oninput="_progMatWiz[${i}].observacoes=this.value"
             style="flex:1"/>
      <button type="button" onclick="_removerMatWiz(${i})"
              style="background:none;border:none;color:#f85149;cursor:pointer;font-size:14px;padding:2px">
        <i class="fa-solid fa-xmark"></i>
      </button>
    </div>
  `).join('');
}

// ── Gestão dinâmica de funcionários ───────────

function _adicionarFuncWiz() {
  _progFuncWiz.push({ cod_funcionario: '', papel: 'Instrutor' });
  _renderizarFuncWiz();
}

function _removerFuncWiz(i) {
  _progFuncWiz.splice(i, 1);
  _renderizarFuncWiz();
}

function _renderizarFuncWiz() {
  const lista = document.getElementById('prog-func-lista');
  if (!lista) return;
  if (!_progFuncWiz.length) {
    lista.innerHTML = '<p style="font-size:11px;color:var(--text-muted);font-style:italic">Sem funcionários adicionados.</p>';
    return;
  }
  const funcOpts = _progFuncLista.map(f =>
    `<option value="${f.COD_FUNCIONARIO}">${f.NOME || f.NOME_FUNCIONARIO || f.COD_FUNCIONARIO} (${f.COD_FUNCIONARIO})</option>`
  ).join('');
  lista.innerHTML = _progFuncWiz.map((f, i) => `
    <div style="display:flex;gap:8px;align-items:center;margin-bottom:6px">
      <select class="input-field" style="flex:2"
              onchange="_progFuncWiz[${i}].cod_funcionario=this.value">
        <option value="">— Seleccionar funcionário —</option>
        ${funcOpts.replace(`value="${f.cod_funcionario}"`, `value="${f.cod_funcionario}" selected`)}
      </select>
      <select class="input-field" style="flex:1"
              onchange="_progFuncWiz[${i}].papel=this.value">
        ${['Responsavel','Instrutor','Auxiliar'].map(p =>
          `<option value="${p}" ${f.papel === p ? 'selected' : ''}>${p === 'Responsavel' ? 'Responsável' : p}</option>`
        ).join('')}
      </select>
      <button type="button" onclick="_removerFuncWiz(${i})"
              style="background:none;border:none;color:#f85149;cursor:pointer;font-size:14px;padding:2px">
        <i class="fa-solid fa-xmark"></i>
      </button>
    </div>
  `).join('');
}

// ── Submeter modal criar/editar ────────────────

async function _submeterModalProg() {
  const erroEl  = document.getElementById('modal-prog-erro');
  const erroMsg = document.getElementById('modal-prog-erro-msg');
  erroEl.classList.add('hidden');

  const nome     = document.getElementById('prog-nome')?.value.trim();
  const publico  = document.getElementById('prog-publico')?.value;
  const duracao  = parseInt(document.getElementById('prog-duracao')?.value) || null;
  const descricao     = document.getElementById('prog-descricao')?.value.trim() || null;
  const metodologia   = document.getElementById('prog-metodologia')?.value.trim() || null;
  const resultados    = document.getElementById('prog-resultados')?.value.trim() || null;

  if (!nome) {
    erroMsg.textContent = 'O nome do programa é obrigatório.';
    erroEl.classList.remove('hidden');
    return;
  }

  const body = {
    nome_programa:       nome,
    publico_alvo:        publico,
    duracao_semanas:     duracao,
    descricao,
    metodologia,
    resultados_esperados: resultados,
    niveis:       _progNiveisWiz.filter(n => n.nome_nivel),
    materiais:    _progMatWiz.filter(m => m.cod_material),
    funcionarios: _progFuncWiz.filter(f => f.cod_funcionario)
  };

  try {
    if (_editProgCod) {
      await patch(`/api/programas/${_editProgCod}`, body);
      toast('Programa actualizado.', 'sucesso');
    } else {
      await post('/api/programas', body);
      toast('Programa criado.', 'sucesso');
    }
    document.getElementById('modal-prog-overlay').classList.add('hidden');
    carregarProgramas();
  } catch (err) {
    erroMsg.textContent = err.message;
    erroEl.classList.remove('hidden');
  }
}

// ── Modal Inscrever Leitor ─────────────────────

function abrirModalInscrever(cod) {
  _inscrCod = cod;
  document.getElementById('modal-inscr-erro').classList.add('hidden');
  document.getElementById('inscr-num-cartao').value = '';

  const niveis = _progDetalhe?.niveis || [];
  const sel = document.getElementById('inscr-nivel');
  sel.innerHTML = '<option value="">— Sem nível —</option>' +
    niveis.map(n => `<option value="${n.ID_NIVEL}">${n.ORDEM}. ${n.NOME_NIVEL}</option>`).join('');

  document.getElementById('modal-inscr-overlay').classList.remove('hidden');
}

function fecharModalInscrever(evt) {
  if (evt && evt.target !== document.getElementById('modal-inscr-overlay')) return;
  document.getElementById('modal-inscr-overlay').classList.add('hidden');
}

async function _submeterInscricao() {
  const erroEl  = document.getElementById('modal-inscr-erro');
  const erroMsg = document.getElementById('modal-inscr-erro-msg');
  erroEl.classList.add('hidden');

  const num_cartao       = document.getElementById('inscr-num-cartao')?.value.trim();
  const id_nivel_inicial = document.getElementById('inscr-nivel')?.value || null;

  if (!num_cartao) {
    erroMsg.textContent = 'O número de cartão é obrigatório.';
    erroEl.classList.remove('hidden');
    return;
  }

  try {
    await post(`/api/programas/${_inscrCod}/participantes`, { num_cartao, id_nivel_inicial: id_nivel_inicial || null });
    toast('Leitor inscrito com sucesso.', 'sucesso');
    document.getElementById('modal-inscr-overlay').classList.add('hidden');
    _renderizarParticipantesProg();
  } catch (err) {
    erroMsg.textContent = err.message;
    erroEl.classList.remove('hidden');
  }
}

// ── Modal Actualizar Participante ──────────────

function abrirModalActualizarPart(cod, num_cartao) {
  _partCod    = cod;
  _partCartao = num_cartao;

  document.getElementById('modal-part-erro').classList.add('hidden');

  const niveis = _progDetalhe?.niveis || [];
  const selNivel = document.getElementById('part-nivel');
  selNivel.innerHTML = '<option value="">— Sem nível —</option>' +
    niveis.map(n => `<option value="${n.ID_NIVEL}">${n.ORDEM}. ${n.NOME_NIVEL}</option>`).join('');

  document.getElementById('part-estado').value = 'Activo';
  document.getElementById('modal-part-overlay').classList.remove('hidden');
}

function fecharModalPart(evt) {
  if (evt && evt.target !== document.getElementById('modal-part-overlay')) return;
  document.getElementById('modal-part-overlay').classList.add('hidden');
}

async function _submeterActualizacaoPart() {
  const erroEl  = document.getElementById('modal-part-erro');
  const erroMsg = document.getElementById('modal-part-erro-msg');
  erroEl.classList.add('hidden');

  const id_nivel_atual      = document.getElementById('part-nivel')?.value || null;
  const estado_participacao = document.getElementById('part-estado')?.value;

  try {
    await patch(`/api/programas/${_partCod}/participantes/${_partCartao}`, {
      id_nivel_atual:      id_nivel_atual || null,
      estado_participacao
    });
    toast('Participação actualizada.', 'sucesso');
    document.getElementById('modal-part-overlay').classList.add('hidden');
    _renderizarParticipantesProg();
  } catch (err) {
    erroMsg.textContent = err.message;
    erroEl.classList.remove('hidden');
  }
}
