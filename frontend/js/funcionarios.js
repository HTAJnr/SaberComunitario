// ════════════════════════════════════════════════
// TELA 09 — FUNCIONÁRIOS
// ════════════════════════════════════════════════

// ── Estado local ─────────────────────────────────
let _funcRows      = [];
let _funcDetalhe   = null;
let _funcDrawerCod = null;
let _editFuncCod   = null;
let _permFuncCod   = null;
let _permFuncoes   = [];
let _funcHabilWiz  = [];
let _funcHorWiz    = [];
let _funcHabilEdit = [];
let _funcHorEdit   = [];
let _wizFuncStep   = 1;
let _wizFuncDados  = {};

// ── Helpers de apresentação ───────────────────────
function _fcampo(label, valor) {
  return `<div style="margin-bottom:10px">
    <div style="font-size:10px;color:var(--text-muted);font-weight:500;margin-bottom:2px">${label}</div>
    <div style="font-size:13px;color:var(--text-primary)">${valor || '—'}</div>
  </div>`;
}

function _fsecao(titulo) {
  return `<div style="font-size:11px;font-weight:600;color:var(--text-secondary);text-transform:uppercase;
    letter-spacing:.5px;margin:16px 0 8px;border-bottom:1px solid var(--border);padding-bottom:4px">
    ${titulo}
  </div>`;
}

function _badgeNivel(nivel) {
  const mapa = {
    'Administrador': 'bdg-adulto',
    'Coordenador':   'bdg-suspenso',
    'Bibliotecario': 'bdg-activo',
    'Assistente':    '',
  };
  if (!nivel) return '—';
  return `<span class="bdg ${mapa[nivel] || ''}">${nivel}</span>`;
}

// ── Matriz de permissões (hardcoded de SCREENS.md) ──
const _MATRIZ_PERM = [
  { modulo: 'Dashboard (rede)',                  admin: true,  coord: false, biblio: false, assist: false },
  { modulo: 'Dashboard (biblioteca)',             admin: true,  coord: true,  biblio: true,  assist: true  },
  { modulo: 'Leitores — ver lista',               admin: true,  coord: true,  biblio: true,  assist: true  },
  { modulo: 'Leitores — cadastrar',               admin: true,  coord: true,  biblio: true,  assist: true  },
  { modulo: 'Leitores — editar',                  admin: true,  coord: true,  biblio: true,  assist: false },
  { modulo: 'Leitores — eliminar',                admin: true,  coord: false, biblio: false, assist: false },
  { modulo: 'Leitores — alterar status',          admin: true,  coord: true,  biblio: false, assist: false },
  { modulo: 'Empréstimos — ver',                  admin: true,  coord: true,  biblio: true,  assist: true  },
  { modulo: 'Empréstimos — criar',                admin: true,  coord: true,  biblio: true,  assist: true  },
  { modulo: 'Empréstimos — devolver',             admin: true,  coord: true,  biblio: true,  assist: true  },
  { modulo: 'Empréstimos — eliminar',             admin: true,  coord: false, biblio: false, assist: false },
  { modulo: 'Multas — marcar paga',               admin: true,  coord: true,  biblio: true,  assist: false },
  { modulo: 'Materiais — ver',                    admin: true,  coord: true,  biblio: true,  assist: true  },
  { modulo: 'Materiais — adicionar',              admin: true,  coord: true,  biblio: true,  assist: false },
  { modulo: 'Materiais — editar',                 admin: true,  coord: true,  biblio: true,  assist: false },
  { modulo: 'Materiais — eliminar',               admin: true,  coord: true,  biblio: false, assist: false },
  { modulo: 'Transferências — ver',               admin: true,  coord: true,  biblio: false, assist: false },
  { modulo: 'Transferências — solicitar',         admin: true,  coord: true,  biblio: false, assist: false },
  { modulo: 'Transferências — aprovar/rejeitar',  admin: true,  coord: true,  biblio: false, assist: false },
  { modulo: 'Eventos — ver',                      admin: true,  coord: true,  biblio: true,  assist: true  },
  { modulo: 'Eventos — criar/editar',             admin: true,  coord: true,  biblio: true,  assist: false },
  { modulo: 'Eventos — cancelar',                 admin: true,  coord: true,  biblio: false, assist: false },
  { modulo: 'Eventos — gerir participantes',      admin: true,  coord: true,  biblio: true,  assist: true  },
  { modulo: 'Doações — ver',                      admin: true,  coord: true,  biblio: true,  assist: false },
  { modulo: 'Doações — registar',                 admin: true,  coord: true,  biblio: false, assist: false },
  { modulo: 'Certificados — emitir',              admin: true,  coord: true,  biblio: false, assist: false },
  { modulo: 'Programas — ver',                    admin: true,  coord: true,  biblio: true,  assist: true  },
  { modulo: 'Programas — criar/editar',           admin: true,  coord: true,  biblio: false, assist: false },
  { modulo: 'Programas — gerir participantes',    admin: true,  coord: true,  biblio: true,  assist: false },
  { modulo: 'Funcionários — ver',                 admin: true,  coord: true,  biblio: false, assist: false },
  { modulo: 'Funcionários — cadastrar/editar',    admin: true,  coord: true,  biblio: false, assist: false },
  { modulo: 'Funcionários — eliminar',            admin: true,  coord: false, biblio: false, assist: false },
  { modulo: 'Permissões — ver/gerir',             admin: true,  coord: false, biblio: false, assist: false },
  { modulo: 'Bibliotecas (rede)',                 admin: true,  coord: false, biblio: false, assist: false },
  { modulo: 'Biblioteca (própria)',               admin: true,  coord: true,  biblio: false, assist: false },
  { modulo: 'Suspensões — reduzir',               admin: true,  coord: true,  biblio: false, assist: false },
];

// ════════════════════════════════════════════════
// 09-A — LISTA
// ════════════════════════════════════════════════

async function carregarFuncionarios() {
  try {
    _funcRows = await get('/api/funcionarios');
    _renderizarTabelaFuncionarios();
  } catch (err) {
    toast('Erro a carregar funcionários: ' + err.message, 'erro');
  }
}

function _renderizarTabelaFuncionarios() {
  const tbody = document.getElementById('tabela-funcionarios');
  if (!tbody) return;

  const q = (document.getElementById('filtro-func-q')?.value || '').toLowerCase();
  const rows = _funcRows.filter(r =>
    !q ||
    (r.NOME || '').toLowerCase().includes(q) ||
    (r.FUNCAO || '').toLowerCase().includes(q) ||
    (r.NOME_BIBLIOTECA || '').toLowerCase().includes(q)
  );

  if (!rows.length) {
    tbody.innerHTML = linhaVazia(8, q ? 'Sem resultados para "' + q + '"' : 'Sem funcionários');
    return;
  }

  tbody.innerHTML = rows.map(r => _linhaFunc(r)).join('');
}

function _linhaFunc(r) {
  const av = `<div style="width:32px;height:32px;border-radius:50%;background:var(--theme-accent);
    color:#fff;display:flex;align-items:center;justify-content:center;
    font-size:11px;font-weight:700;flex-shrink:0">${iniciais(r.NOME)}</div>`;

  return `<tr>
    <td style="padding:6px 10px">${av}</td>
    <td style="font-family:monospace;font-size:11px;color:var(--text-secondary)">${r.COD_FUNCIONARIO || '—'}</td>
    <td style="font-weight:500">${r.NOME || '—'}</td>
    <td style="color:var(--text-secondary)">${r.FUNCAO || '—'}</td>
    <td>${_badgeNivel(r.NIVEL_ACESSO)}</td>
    <td style="color:var(--text-muted)">${r.NOME_BIBLIOTECA || '—'}</td>
    <td><span class="bdg bdg-activo">Activo</span></td>
    <td style="text-align:right;padding-right:10px">
      <button class="btn-ghost btn-sm" onclick="abrirCtxMenuFunc(event,'${r.COD_FUNCIONARIO}')">···</button>
    </td>
  </tr>`;
}

// ── Context menu ──────────────────────────────────
function abrirCtxMenuFunc(evt, cod) {
  evt.stopPropagation();
  fecharCtxMenuFunc();

  const isAdmin = utilizadorActual?.NIVEL_ACESSO === 'Administrador';
  const itens = [
    `<div class="ctx-menu-item" onclick="fecharCtxMenuFunc();abrirDrawerFunc('${cod}')">
       <i class="fa-solid fa-eye fa-fw"></i> Ver perfil
     </div>`,
    `<div class="ctx-menu-item" onclick="fecharCtxMenuFunc();abrirModalEditarFunc('${cod}')">
       <i class="fa-solid fa-pen fa-fw"></i> Editar
     </div>`,
  ];
  if (isAdmin) {
    itens.push(`<div class="ctx-menu-item" onclick="fecharCtxMenuFunc();abrirModalPermissoes('${cod}')">
       <i class="fa-solid fa-shield-halved fa-fw"></i> Gerir permissões
     </div>`);
    itens.push(`<div class="ctx-menu-item ctx-menu-danger" onclick="fecharCtxMenuFunc();_desactivarFunc('${cod}')">
       <i class="fa-solid fa-user-slash fa-fw"></i> Desactivar
     </div>`);
  }

  const menu = document.getElementById('ctx-menu-func');
  menu.innerHTML = itens.join('');
  menu.style.display = 'block';

  const rect = evt.currentTarget.getBoundingClientRect();
  let top = rect.bottom + 4;
  let left = rect.right - 160;
  if (top + 160 > window.innerHeight) top = rect.top - 160;
  if (left < 8) left = 8;
  menu.style.top  = top + 'px';
  menu.style.left = left + 'px';

  setTimeout(() => document.addEventListener('click', fecharCtxMenuFunc, { once: true }), 0);
}

function fecharCtxMenuFunc() {
  const m = document.getElementById('ctx-menu-func');
  if (m) m.style.display = 'none';
}

async function _desactivarFunc(cod) {
  confirmar('Desactivar este funcionário? Esta acção não pode ser revertida.', async () => {
    try {
      await del(`/api/funcionarios/${cod}`);
      toast('Funcionário desactivado.');
      carregarFuncionarios();
    } catch (err) {
      toast(err.message, 'erro');
    }
  });
}

// ════════════════════════════════════════════════
// 09-B — DRAWER PERFIL
// ════════════════════════════════════════════════

async function abrirDrawerFunc(cod) {
  _funcDrawerCod = cod;
  _funcDetalhe   = null;

  const overlay = document.getElementById('drawer-func-overlay');
  const drawer  = document.getElementById('drawer-func');
  const conteudo = document.getElementById('drawer-func-conteudo');

  conteudo.innerHTML = `<div style="text-align:center;padding:30px;color:var(--text-muted)">
    <i class="fa-solid fa-spinner fa-spin"></i> A carregar…
  </div>`;
  overlay.style.display = 'block';
  drawer.classList.add('open');

  try {
    _funcDetalhe = await get(`/api/funcionarios/${cod}`);
    conteudo.innerHTML = _renderizarPerfilFunc(_funcDetalhe);
  } catch (err) {
    conteudo.innerHTML = `<div style="color:#f85149;padding:20px">${err.message}</div>`;
  }
}

function fecharDrawerFunc() {
  document.getElementById('drawer-func-overlay').style.display = 'none';
  document.getElementById('drawer-func').classList.remove('open');
  _funcDrawerCod = null;
  _funcDetalhe   = null;
}

function _renderizarPerfilFunc(d) {
  const habilidades = (d.HABILIDADES || []);
  const horario     = (d.HORARIO || []);

  const avatarHtml = `
    <div style="display:flex;align-items:center;gap:14px;margin-bottom:18px;
      padding:14px;background:var(--surface-raised);border-radius:10px">
      <div style="width:52px;height:52px;border-radius:50%;background:var(--theme-accent);
        color:#fff;display:flex;align-items:center;justify-content:center;
        font-size:18px;font-weight:700;flex-shrink:0">${iniciais(d.NOME_FUNCIONARIO)}</div>
      <div>
        <div style="font-size:10px;font-family:monospace;color:var(--text-muted);margin-bottom:2px">${d.COD_FUNCIONARIO}</div>
        <div style="font-size:15px;font-weight:600;color:var(--text-primary)">${d.NOME_FUNCIONARIO || '—'}</div>
        <div style="display:flex;align-items:center;gap:6px;margin-top:4px">
          <span style="font-size:12px;color:var(--text-secondary)">${d.FUNCAO || '—'}</span>
          ${_badgeNivel(d.NIVEL_ACESSO)}
        </div>
      </div>
    </div>`;

  const dadosPessoais = _fsecao('Dados Pessoais') +
    `<div style="display:grid;grid-template-columns:1fr 1fr;gap:0 16px">` +
    _fcampo('Género', d.GENERO) +
    _fcampo('Data de Nascimento', fmtData(d.DATA_NASC)) +
    `</div>` +
    _fcampo('Contacto', d.CONTACTO) +
    _fcampo('Endereço', d.ENDERECO);

  const dadosProfissionais = _fsecao('Dados Profissionais') +
    _fcampo('Formação', d.FORMACAO) +
    _fcampo('Experiência', d.EXPERIENCIA) +
    `<div style="display:grid;grid-template-columns:1fr 1fr;gap:0 16px">` +
    _fcampo('Data de Contratação', fmtData(d.DATA_CONTRATACAO)) +
    _fcampo('Biblioteca', d.NOME_BIBLIOTECA) +
    `</div>`;

  let habilHtml = _fsecao('Habilidades');
  if (habilidades.length) {
    habilHtml += `<div class="chips-wrap">` +
      habilidades.map(h => `<span class="chip">${h}</span>`).join('') +
      `</div>`;
  } else {
    habilHtml += `<span style="font-size:12px;color:var(--text-muted)">Sem habilidades registadas</span>`;
  }

  let horarioHtml = _fsecao('Horário');
  if (horario.length) {
    horarioHtml += `<table style="width:100%;font-size:12px;border-collapse:collapse">
      <thead><tr style="border-bottom:1px solid var(--border)">
        <th style="text-align:left;padding:4px 8px;color:var(--text-muted);font-weight:500">Dia</th>
        <th style="text-align:left;padding:4px 8px;color:var(--text-muted);font-weight:500">Entrada</th>
        <th style="text-align:left;padding:4px 8px;color:var(--text-muted);font-weight:500">Saída</th>
      </tr></thead>
      <tbody>` +
      horario.map(h => `<tr style="border-bottom:1px solid var(--border-soft)">
        <td style="padding:5px 8px">${h.DIA_SEMANA}</td>
        <td style="padding:5px 8px;font-family:monospace">${h.HORA_ENTRADA || '—'}</td>
        <td style="padding:5px 8px;font-family:monospace">${h.HORA_SAIDA || '—'}</td>
      </tr>`).join('') +
      `</tbody></table>`;
  } else {
    horarioHtml += `<span style="font-size:12px;color:var(--text-muted)">Sem horário definido</span>`;
  }

  return avatarHtml + dadosPessoais + dadosProfissionais + habilHtml + horarioHtml;
}

// ════════════════════════════════════════════════
// 09-C — MODAL EDITAR FUNCIONÁRIO
// ════════════════════════════════════════════════

async function abrirModalEditarFunc(cod) {
  _editFuncCod   = cod;
  _funcHabilEdit = [];
  _funcHorEdit   = [];

  document.getElementById('modal-func-overlay').classList.remove('hidden');
  document.getElementById('modal-func-erro').classList.add('hidden');

  let funcoes = [], bibliotecas = [];
  try { funcoes     = await get('/api/funcionarios/funcoes'); } catch {}
  try { bibliotecas = await get('/api/funcionarios/bibliotecas'); } catch {}

  let dados = null;
  try { dados = await get(`/api/funcionarios/${cod}`); } catch {}

  if (dados) {
    _funcHabilEdit = [...(dados.HABILIDADES || [])];
    _funcHorEdit   = (dados.HORARIO || []).map(h => ({
      dia_semana:   h.DIA_SEMANA,
      hora_entrada: h.HORA_ENTRADA,
      hora_saida:   h.HORA_SAIDA,
    }));
  }

  const isAdmin = utilizadorActual?.NIVEL_ACESSO === 'Administrador';

  document.getElementById('modal-func-conteudo').innerHTML = `
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:0 16px">
      <div class="form-group" style="grid-column:1/-1">
        <label class="form-label">Nome *</label>
        <input id="ef-nome" class="input-field" value="${dados?.NOME_FUNCIONARIO || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Email (não editável)</label>
        <input class="input-field" value="${dados?.EMAIL || ''}" readonly
               style="background:var(--surface-raised);color:var(--text-muted);cursor:not-allowed"/>
      </div>
      <div class="form-group">
        <label class="form-label">Contacto</label>
        <input id="ef-contacto" class="input-field" value="${dados?.CONTACTO || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Género</label>
        <select id="ef-genero" class="input-field">
          <option value="">— Seleccionar —</option>
          ${['Masculino','Feminino','Outro'].map(g =>
            `<option value="${g}" ${dados?.GENERO === g ? 'selected' : ''}>${g}</option>`).join('')}
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Data de Nascimento</label>
        <input id="ef-data-nasc" type="date" class="input-field"
               value="${dados?.DATA_NASC ? dados.DATA_NASC.toString().slice(0,10) : ''}"/>
      </div>
      <div class="form-group" style="grid-column:1/-1">
        <label class="form-label">Endereço</label>
        <input id="ef-endereco" class="input-field" value="${dados?.ENDERECO || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Formação</label>
        <input id="ef-formacao" class="input-field" value="${dados?.FORMACAO || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Experiência</label>
        <input id="ef-experiencia" class="input-field" value="${dados?.EXPERIENCIA || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Função</label>
        <select id="ef-funcao" class="input-field">
          <option value="">— Seleccionar —</option>
          ${funcoes.map(f =>
            `<option value="${f.ID_FUNCAO}" ${dados?.ID_FUNCAO == f.ID_FUNCAO ? 'selected' : ''}>${f.DESCRICAO}</option>`
          ).join('')}
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Biblioteca${isAdmin ? '' : ' (da sua biblioteca)'}</label>
        <select id="ef-biblioteca" class="input-field" ${!isAdmin ? 'disabled' : ''}>
          <option value="">— Seleccionar —</option>
          ${bibliotecas.map(b =>
            `<option value="${b.COD_BIBLIOTECA}" ${dados?.COD_BIBLIOTECA === b.COD_BIBLIOTECA ? 'selected' : ''}>${b.NOME}</option>`
          ).join('')}
        </select>
      </div>
    </div>

    <div style="margin-top:4px">
      <div style="font-size:11px;font-weight:600;color:var(--text-secondary);margin-bottom:8px">Habilidades</div>
      <div id="ef-habils-wrap" class="chips-wrap" style="margin-bottom:8px"></div>
      <div style="display:flex;gap:6px">
        <input id="ef-habil-input" class="input-field" style="flex:1" placeholder="Nova habilidade…"
               onkeydown="if(event.key==='Enter'){event.preventDefault();_adicionarHabilEdit();}"/>
        <button class="btn-ghost" onclick="_adicionarHabilEdit()">+ Adicionar</button>
      </div>
    </div>

    <div style="margin-top:18px">
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px">
        <span style="font-size:11px;font-weight:600;color:var(--text-secondary)">Horário Semanal</span>
        <button class="btn-ghost" style="font-size:11px;padding:3px 10px" onclick="_adicionarHorEdit()">
          + Dia
        </button>
      </div>
      <div id="ef-hor-wrap"></div>
    </div>`;

  _renderizarHabilEdit();
  _renderizarHorEdit();
}

function fecharModalFunc(evt) {
  if (evt && evt.target !== document.getElementById('modal-func-overlay')) return;
  document.getElementById('modal-func-overlay').classList.add('hidden');
  _editFuncCod = null;
}

// Habilidades (modal editar)
function _renderizarHabilEdit() {
  const wrap = document.getElementById('ef-habils-wrap');
  if (!wrap) return;
  wrap.innerHTML = _funcHabilEdit.length
    ? _funcHabilEdit.map((h, i) =>
        `<span class="chip">${h}<span class="chip-x" onclick="_removerHabilEdit(${i})"> ×</span></span>`
      ).join('')
    : `<span style="font-size:11px;color:var(--text-muted)">Sem habilidades</span>`;
}

function _adicionarHabilEdit() {
  const inp = document.getElementById('ef-habil-input');
  const v = inp.value.trim();
  if (!v) return;
  _funcHabilEdit.push(v);
  inp.value = '';
  _renderizarHabilEdit();
}

function _removerHabilEdit(i) {
  _funcHabilEdit.splice(i, 1);
  _renderizarHabilEdit();
}

// Horário (modal editar)
const _DIAS = ['Segunda','Terça','Quarta','Quinta','Sexta','Sábado','Domingo'];

function _renderizarHorEdit() {
  const wrap = document.getElementById('ef-hor-wrap');
  if (!wrap) return;
  if (!_funcHorEdit.length) {
    wrap.innerHTML = `<div style="font-size:12px;color:var(--text-muted)">Sem horário definido. Clique em "+ Dia" para adicionar.</div>`;
    return;
  }
  wrap.innerHTML = _funcHorEdit.map((h, i) => `
    <div style="display:grid;grid-template-columns:1fr 1fr 1fr auto;gap:6px;margin-bottom:6px;align-items:center">
      <select class="input-field" style="font-size:12px"
              onchange="_funcHorEdit[${i}].dia_semana=this.value">
        ${_DIAS.map(d => `<option value="${d}" ${h.dia_semana === d ? 'selected' : ''}>${d}</option>`).join('')}
      </select>
      <input type="time" class="input-field" style="font-size:12px"
             value="${h.hora_entrada || ''}"
             oninput="_funcHorEdit[${i}].hora_entrada=this.value"/>
      <input type="time" class="input-field" style="font-size:12px"
             value="${h.hora_saida || ''}"
             oninput="_funcHorEdit[${i}].hora_saida=this.value"/>
      <button style="background:none;border:none;color:#f85149;cursor:pointer;font-size:14px;padding:0 4px"
              onclick="_removerHorEdit(${i})">×</button>
    </div>`).join('');
}

function _adicionarHorEdit() {
  _funcHorEdit.push({ dia_semana: 'Segunda', hora_entrada: '', hora_saida: '' });
  _renderizarHorEdit();
}

function _removerHorEdit(i) {
  _funcHorEdit.splice(i, 1);
  _renderizarHorEdit();
}

async function _submeterModalFunc() {
  const nome = document.getElementById('ef-nome')?.value?.trim();
  if (!nome) {
    _mostrarErroFunc('modal-func-erro', 'modal-func-erro-msg', 'Nome é obrigatório.');
    return;
  }

  const isAdmin = utilizadorActual?.NIVEL_ACESSO === 'Administrador';

  const body = {
    nome_funcionario: nome,
    contacto:         document.getElementById('ef-contacto')?.value || undefined,
    genero:           document.getElementById('ef-genero')?.value || undefined,
    data_nasc:        document.getElementById('ef-data-nasc')?.value || undefined,
    endereco:         document.getElementById('ef-endereco')?.value || undefined,
    formacao:         document.getElementById('ef-formacao')?.value || undefined,
    experiencia:      document.getElementById('ef-experiencia')?.value || undefined,
    id_funcao:        document.getElementById('ef-funcao')?.value || undefined,
    cod_biblioteca:   isAdmin ? (document.getElementById('ef-biblioteca')?.value || undefined) : undefined,
    habilidades:      _funcHabilEdit,
    horarios:         _funcHorEdit,
  };

  try {
    await patch(`/api/funcionarios/${_editFuncCod}`, body);
    fecharModalFunc();
    toast('Funcionário actualizado com sucesso.');
    carregarFuncionarios();
    if (_funcDrawerCod === _editFuncCod) abrirDrawerFunc(_editFuncCod);
  } catch (err) {
    _mostrarErroFunc('modal-func-erro', 'modal-func-erro-msg', err.message);
  }
}

function _mostrarErroFunc(idDiv, idMsg, msg) {
  const div = document.getElementById(idDiv);
  const span = document.getElementById(idMsg);
  if (div)  div.classList.remove('hidden');
  if (span) span.textContent = msg;
}

// ════════════════════════════════════════════════
// 09-D — MODAL GERIR PERMISSÕES
// ════════════════════════════════════════════════

async function abrirModalPermissoes(cod) {
  _permFuncCod = cod;
  document.getElementById('modal-perm-overlay').classList.remove('hidden');
  document.getElementById('modal-perm-erro').classList.add('hidden');

  let funcoes = [], dados = null;
  try { funcoes = await get('/api/funcionarios/funcoes'); } catch {}
  try { dados   = await get(`/api/funcionarios/${cod}`); } catch {}

  _permFuncoes = funcoes;
  const idFuncaoActual = dados?.ID_FUNCAO || '';

  document.getElementById('modal-perm-conteudo').innerHTML = `
    <div style="display:flex;align-items:center;gap:12px;padding:12px;background:var(--surface-raised);
      border-radius:10px;margin-bottom:16px">
      <div style="width:40px;height:40px;border-radius:50%;background:var(--theme-accent);
        color:#fff;display:flex;align-items:center;justify-content:center;
        font-size:14px;font-weight:700;flex-shrink:0">${iniciais(dados?.NOME_FUNCIONARIO || '')}</div>
      <div>
        <div style="font-size:14px;font-weight:600">${dados?.NOME_FUNCIONARIO || '—'}</div>
        <div style="font-size:12px;color:var(--text-secondary)">${dados?.FUNCAO || '—'} · ${_badgeNivel(dados?.NIVEL_ACESSO)}</div>
      </div>
    </div>

    <div class="form-group">
      <label class="form-label">Nova Função / Nível de Acesso</label>
      <select id="perm-funcao-sel" class="input-field" onchange="_actualizarPreviewPerm()">
        <option value="">— Seleccionar —</option>
        ${funcoes.map(f =>
          `<option value="${f.ID_FUNCAO}" data-nivel="${f.NIVEL_ACESSO}"
            ${f.ID_FUNCAO == idFuncaoActual ? 'selected' : ''}>${f.DESCRICAO} (${f.NIVEL_ACESSO})</option>`
        ).join('')}
      </select>
    </div>

    <div style="font-size:11px;font-weight:600;color:var(--text-secondary);margin-bottom:8px">
      Preview — Permissões deste nível
    </div>
    <div id="perm-preview" style="overflow-x:auto"></div>`;

  _actualizarPreviewPerm();
}

function _actualizarPreviewPerm() {
  const sel    = document.getElementById('perm-funcao-sel');
  const preview = document.getElementById('perm-preview');
  if (!sel || !preview) return;

  const opt    = sel.options[sel.selectedIndex];
  const nivel  = opt?.dataset?.nivel || '';

  const colKey = { 'Administrador': 'admin', 'Coordenador': 'coord', 'Bibliotecario': 'biblio', 'Assistente': 'assist' };
  const key    = colKey[nivel];

  const check = (val) => val
    ? `<span style="color:var(--theme-accent-text);font-weight:600">✓</span>`
    : `<span style="color:var(--text-muted)">—</span>`;

  const linhas = _MATRIZ_PERM.map(m => {
    const hl = key && m[key] ? 'background:var(--surface-raised)' : '';
    return `<tr style="${hl};border-bottom:1px solid var(--border-soft)">
      <td style="padding:4px 8px;font-size:12px">${m.modulo}</td>
      <td style="text-align:center;padding:4px 8px">${check(m.admin)}</td>
      <td style="text-align:center;padding:4px 8px">${check(m.coord)}</td>
      <td style="text-align:center;padding:4px 8px">${check(m.biblio)}</td>
      <td style="text-align:center;padding:4px 8px">${check(m.assist)}</td>
    </tr>`;
  }).join('');

  preview.innerHTML = `
    <table style="width:100%;border-collapse:collapse;font-size:12px">
      <thead><tr style="border-bottom:2px solid var(--border)">
        <th style="text-align:left;padding:5px 8px;color:var(--text-secondary)">Módulo / Acção</th>
        <th style="text-align:center;padding:5px 8px;color:#58a6ff">Admin</th>
        <th style="text-align:center;padding:5px 8px;color:#d29922">Coord</th>
        <th style="text-align:center;padding:5px 8px;color:var(--theme-accent-text)">Biblio</th>
        <th style="text-align:center;padding:5px 8px;color:var(--text-muted)">Assist</th>
      </tr></thead>
      <tbody>${linhas}</tbody>
    </table>`;
}

function fecharModalPerm(evt) {
  if (evt && evt.target !== document.getElementById('modal-perm-overlay')) return;
  document.getElementById('modal-perm-overlay').classList.add('hidden');
  _permFuncCod = null;
}

async function _submeterModalPerm() {
  const sel = document.getElementById('perm-funcao-sel');
  const id_funcao = sel?.value;
  if (!id_funcao) {
    _mostrarErroFunc('modal-perm-erro', 'modal-perm-erro-msg', 'Seleccione uma função.');
    return;
  }
  try {
    await patch(`/api/funcionarios/${_permFuncCod}/acesso`, { id_funcao });
    fecharModalPerm();
    toast('Permissão actualizada com sucesso.');
    carregarFuncionarios();
  } catch (err) {
    _mostrarErroFunc('modal-perm-erro', 'modal-perm-erro-msg', err.message);
  }
}

// ════════════════════════════════════════════════
// 09-E — WIZARD CADASTRAR FUNCIONÁRIO
// ════════════════════════════════════════════════

async function abrirWizardFunc() {
  _wizFuncStep   = 1;
  _wizFuncDados  = {};
  _funcHabilWiz  = [];
  _funcHorWiz    = [];

  document.getElementById('modal-wiz-func-overlay').classList.remove('hidden');
  document.getElementById('modal-wiz-func-erro').classList.add('hidden');

  // Pré-carrega listas
  try { _wizFuncDados._funcoes     = await get('/api/funcionarios/funcoes'); } catch { _wizFuncDados._funcoes = []; }
  try { _wizFuncDados._bibliotecas = await get('/api/funcionarios/bibliotecas'); } catch { _wizFuncDados._bibliotecas = []; }

  _renderizarWizFunc();
}

function fecharWizardFunc(evt) {
  if (evt && evt.target !== document.getElementById('modal-wiz-func-overlay')) return;
  document.getElementById('modal-wiz-func-overlay').classList.add('hidden');
}

function _renderizarWizFunc() {
  // Indicador
  const titulos = ['Dados Pessoais', 'Dados Profissionais', 'Confirmação'];
  const total = 3;
  const dots = [1, 2, 3].map(i => {
    const cls = i < _wizFuncStep ? 'done' : i === _wizFuncStep ? 'active' : 'pending';
    return `<div class="step-dot ${cls}"></div>${i < 3 ? '<div class="step-line"></div>' : ''}`;
  }).join('');
  document.getElementById('wiz-func-indicador').innerHTML =
    `<div style="display:flex;flex-direction:column;align-items:center;gap:6px;width:100%">
      <div class="wizard-steps">${dots}</div>
      <div style="font-size:11px;color:var(--text-muted)">Passo ${_wizFuncStep} de 3 — ${titulos[_wizFuncStep - 1]}</div>
    </div>`;

  // Botões
  const btnRecuar  = document.getElementById('wiz-func-btn-recuar');
  const btnAvancar = document.getElementById('wiz-func-btn-avancar');
  if (btnRecuar)  btnRecuar.style.display  = _wizFuncStep > 1 ? 'inline-flex' : 'none';
  if (btnAvancar) {
    if (_wizFuncStep < total) {
      btnAvancar.innerHTML = `Próximo <i class="fa-solid fa-arrow-right" style="margin-left:5px"></i>`;
      btnAvancar.onclick   = _wizFuncAvancar;
    } else {
      btnAvancar.innerHTML = `<i class="fa-solid fa-check" style="margin-right:5px"></i>Confirmar e Criar`;
      btnAvancar.onclick   = _wizFuncConfirmar;
    }
  }

  // Conteúdo
  const conteudo = document.getElementById('wiz-func-conteudo');
  if (_wizFuncStep === 1) conteudo.innerHTML = _wizFuncStep1Html();
  if (_wizFuncStep === 2) conteudo.innerHTML = _wizFuncStep2Html();
  if (_wizFuncStep === 3) conteudo.innerHTML = _wizFuncStep3Html();

  if (_wizFuncStep === 2) {
    _renderizarHabilWiz();
    _renderizarHorWiz();
  }
}

function _wizFuncStep1Html() {
  const d = _wizFuncDados;
  return `
    <div style="margin-bottom:10px;padding:8px 12px;background:var(--theme-accent-light);border-radius:6px;font-size:11px;color:#58a6ff">
      <i class="fa-solid fa-circle-info" style="margin-right:5px"></i>
      O email de acesso será gerado automaticamente a partir do nome (ex: <em>ana.machava@sabercomunitario.mz</em>).
    </div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:0 16px">
      <div class="form-group" style="grid-column:1/-1">
        <label class="form-label">Nome completo *</label>
        <input id="wf1-nome" class="input-field" placeholder="Ex: Ana Beatriz Machava"
               value="${d.nome_funcionario || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Género</label>
        <select id="wf1-genero" class="input-field">
          <option value="">— Seleccionar —</option>
          ${['Masculino','Feminino','Outro'].map(g =>
            `<option value="${g}" ${d.genero === g ? 'selected' : ''}>${g}</option>`).join('')}
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Data de Nascimento</label>
        <input id="wf1-data-nasc" type="date" class="input-field" value="${d.data_nasc || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Contacto *</label>
        <input id="wf1-contacto" class="input-field" placeholder="Ex: +258 84 000 0000"
               value="${d.contacto || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Senha *</label>
        <input id="wf1-senha" type="password" class="input-field" placeholder="Mínimo 6 caracteres"
               value="${d.senha || ''}"/>
      </div>
      <div class="form-group" style="grid-column:1/-1">
        <label class="form-label">Endereço</label>
        <input id="wf1-endereco" class="input-field" placeholder="Ex: Av. Eduardo Mondlane, Maputo"
               value="${d.endereco || ''}"/>
      </div>
    </div>`;
}

function _wizFuncStep2Html() {
  const d   = _wizFuncDados;
  const fns = d._funcoes || [];
  const bib = d._bibliotecas || [];
  const isAdmin = utilizadorActual?.NIVEL_ACESSO === 'Administrador';

  return `
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:0 16px">
      <div class="form-group">
        <label class="form-label">Formação</label>
        <input id="wf2-formacao" class="input-field" placeholder="Ex: Licenciatura em…"
               value="${d.formacao || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Experiência</label>
        <input id="wf2-experiencia" class="input-field" placeholder="Ex: 3 anos em bibliotecas"
               value="${d.experiencia || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Data de Contratação *</label>
        <input id="wf2-data-cont" type="date" class="input-field"
               value="${d.data_contratacao || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Função</label>
        <select id="wf2-funcao" class="input-field">
          <option value="">— Seleccionar —</option>
          ${fns.map(f =>
            `<option value="${f.ID_FUNCAO}" ${d.id_funcao == f.ID_FUNCAO ? 'selected' : ''}>${f.DESCRICAO}</option>`
          ).join('')}
        </select>
      </div>
      <div class="form-group" style="grid-column:1/-1">
        <label class="form-label">Biblioteca${isAdmin ? '' : ' (atribuída automaticamente)'}</label>
        <select id="wf2-biblioteca" class="input-field" ${!isAdmin ? 'disabled' : ''}>
          <option value="">— Seleccionar —</option>
          ${bib.map(b =>
            `<option value="${b.COD_BIBLIOTECA}" ${d.cod_biblioteca === b.COD_BIBLIOTECA ? 'selected' : ''}>${b.NOME}</option>`
          ).join('')}
        </select>
      </div>
    </div>

    <div style="margin-top:4px">
      <div style="font-size:11px;font-weight:600;color:var(--text-secondary);margin-bottom:8px">Habilidades</div>
      <div id="wf2-habils-wrap" class="chips-wrap" style="margin-bottom:8px"></div>
      <div style="display:flex;gap:6px">
        <input id="wf2-habil-input" class="input-field" style="flex:1" placeholder="Nova habilidade…"
               onkeydown="if(event.key==='Enter'){event.preventDefault();_adicionarHabilWiz();}"/>
        <button class="btn-ghost" onclick="_adicionarHabilWiz()">+ Adicionar</button>
      </div>
    </div>

    <div style="margin-top:18px">
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px">
        <span style="font-size:11px;font-weight:600;color:var(--text-secondary)">Horário Semanal</span>
        <button class="btn-ghost" style="font-size:11px;padding:3px 10px" onclick="_adicionarHorWiz()">
          + Dia
        </button>
      </div>
      <div id="wf2-hor-wrap"></div>
    </div>`;
}

function _wizFuncStep3Html() {
  const d = _wizFuncDados;
  const fns = (d._funcoes || []).find(f => f.ID_FUNCAO == d.id_funcao);
  const bib = (d._bibliotecas || []).find(b => b.COD_BIBLIOTECA === d.cod_biblioteca);

  const linha = (label, val) => val
    ? `<tr><td style="padding:4px 8px;color:var(--text-muted);font-size:12px;width:45%">${label}</td>
           <td style="padding:4px 8px;font-size:12px">${val}</td></tr>`
    : '';

  const habilHtml = _funcHabilWiz.length
    ? `<div class="chips-wrap">${_funcHabilWiz.map(h => `<span class="chip">${h}</span>`).join('')}</div>`
    : '—';

  const horHtml = _funcHorWiz.length
    ? _funcHorWiz.map(h => `${h.dia_semana} ${h.hora_entrada}–${h.hora_saida}`).join(', ')
    : '—';

  return `
    <div style="padding:14px;background:var(--surface-raised);border-radius:10px">
      <div style="font-size:13px;font-weight:600;color:var(--text-primary);margin-bottom:12px">
        <i class="fa-solid fa-user-check" style="color:var(--theme-accent);margin-right:6px"></i>
        Confirmar dados do novo funcionário
      </div>
      <table style="width:100%;border-collapse:collapse">
        <tbody>
          ${linha('Nome', d.nome_funcionario)}
          ${linha('Género', d.genero)}
          ${linha('Data de Nascimento', d.data_nasc ? fmtData(d.data_nasc) : null)}
          ${linha('Contacto', d.contacto)}
          ${linha('Endereço', d.endereco)}
          ${linha('Formação', d.formacao)}
          ${linha('Experiência', d.experiencia)}
          ${linha('Data de Contratação', d.data_contratacao ? fmtData(d.data_contratacao) : null)}
          ${linha('Função', fns?.DESCRICAO)}
          ${linha('Biblioteca', bib?.NOME)}
        </tbody>
      </table>
      <div style="margin-top:12px">
        <div style="font-size:11px;color:var(--text-muted);margin-bottom:4px">Habilidades</div>
        ${habilHtml}
      </div>
      <div style="margin-top:10px">
        <div style="font-size:11px;color:var(--text-muted);margin-bottom:4px">Horário</div>
        <div style="font-size:12px">${horHtml}</div>
      </div>
      <div style="margin-top:12px;padding:8px;background:var(--theme-accent-light);border-radius:6px;font-size:11px;color:#58a6ff">
        <i class="fa-solid fa-circle-info" style="margin-right:4px"></i>
        O código de funcionário e o email serão gerados automaticamente pelo sistema.
      </div>
    </div>`;
}

// Chips (wizard)
function _renderizarHabilWiz() {
  const wrap = document.getElementById('wf2-habils-wrap');
  if (!wrap) return;
  wrap.innerHTML = _funcHabilWiz.length
    ? _funcHabilWiz.map((h, i) =>
        `<span class="chip">${h}<span class="chip-x" onclick="_removerHabilWiz(${i})"> ×</span></span>`
      ).join('')
    : `<span style="font-size:11px;color:var(--text-muted)">Sem habilidades</span>`;
}

function _adicionarHabilWiz() {
  const inp = document.getElementById('wf2-habil-input');
  const v = inp.value.trim();
  if (!v) return;
  _funcHabilWiz.push(v);
  inp.value = '';
  _renderizarHabilWiz();
}

function _removerHabilWiz(i) {
  _funcHabilWiz.splice(i, 1);
  _renderizarHabilWiz();
}

// Horário (wizard)
function _renderizarHorWiz() {
  const wrap = document.getElementById('wf2-hor-wrap');
  if (!wrap) return;
  if (!_funcHorWiz.length) {
    wrap.innerHTML = `<div style="font-size:12px;color:var(--text-muted)">Clique em "+ Dia" para definir horário.</div>`;
    return;
  }
  wrap.innerHTML = _funcHorWiz.map((h, i) => `
    <div style="display:grid;grid-template-columns:1fr 1fr 1fr auto;gap:6px;margin-bottom:6px;align-items:center">
      <select class="input-field" style="font-size:12px"
              onchange="_funcHorWiz[${i}].dia_semana=this.value">
        ${_DIAS.map(d => `<option value="${d}" ${h.dia_semana === d ? 'selected' : ''}>${d}</option>`).join('')}
      </select>
      <input type="time" class="input-field" style="font-size:12px"
             value="${h.hora_entrada || ''}"
             oninput="_funcHorWiz[${i}].hora_entrada=this.value"/>
      <input type="time" class="input-field" style="font-size:12px"
             value="${h.hora_saida || ''}"
             oninput="_funcHorWiz[${i}].hora_saida=this.value"/>
      <button style="background:none;border:none;color:#f85149;cursor:pointer;font-size:14px;padding:0 4px"
              onclick="_removerHorWiz(${i})">×</button>
    </div>`).join('');
}

function _adicionarHorWiz() {
  _funcHorWiz.push({ dia_semana: 'Segunda', hora_entrada: '', hora_saida: '' });
  _renderizarHorWiz();
}

function _removerHorWiz(i) {
  _funcHorWiz.splice(i, 1);
  _renderizarHorWiz();
}

// Navegação wizard
function _wizFuncAvancar() {
  document.getElementById('modal-wiz-func-erro').classList.add('hidden');

  if (_wizFuncStep === 1) {
    const nome     = document.getElementById('wf1-nome')?.value?.trim();
    const contacto = document.getElementById('wf1-contacto')?.value?.trim();
    const senha    = document.getElementById('wf1-senha')?.value;
    if (!nome)     { _mostrarErroFunc('modal-wiz-func-erro', 'modal-wiz-func-erro-msg', 'Nome é obrigatório.'); return; }
    if (!contacto) { _mostrarErroFunc('modal-wiz-func-erro', 'modal-wiz-func-erro-msg', 'Contacto é obrigatório.'); return; }
    if (!senha)    { _mostrarErroFunc('modal-wiz-func-erro', 'modal-wiz-func-erro-msg', 'Senha é obrigatória.'); return; }

    _wizFuncDados.nome_funcionario = nome;
    _wizFuncDados.genero           = document.getElementById('wf1-genero')?.value || undefined;
    _wizFuncDados.data_nasc        = document.getElementById('wf1-data-nasc')?.value || undefined;
    _wizFuncDados.contacto         = contacto;
    _wizFuncDados.senha            = senha;
    _wizFuncDados.endereco         = document.getElementById('wf1-endereco')?.value || undefined;
  }

  if (_wizFuncStep === 2) {
    const dataCont = document.getElementById('wf2-data-cont')?.value;
    if (!dataCont) { _mostrarErroFunc('modal-wiz-func-erro', 'modal-wiz-func-erro-msg', 'Data de contratação é obrigatória.'); return; }

    _wizFuncDados.formacao          = document.getElementById('wf2-formacao')?.value || undefined;
    _wizFuncDados.experiencia       = document.getElementById('wf2-experiencia')?.value || undefined;
    _wizFuncDados.data_contratacao  = dataCont;
    _wizFuncDados.id_funcao         = document.getElementById('wf2-funcao')?.value || undefined;
    _wizFuncDados.cod_biblioteca    = document.getElementById('wf2-biblioteca')?.value || undefined;
  }

  _wizFuncStep++;
  _renderizarWizFunc();
}

function _wizFuncRecuar() {
  document.getElementById('modal-wiz-func-erro').classList.add('hidden');
  _wizFuncStep--;
  _renderizarWizFunc();
}

async function _wizFuncConfirmar() {
  document.getElementById('modal-wiz-func-erro').classList.add('hidden');

  const body = {
    nome_funcionario: _wizFuncDados.nome_funcionario,
    senha:            _wizFuncDados.senha,
    contacto:         _wizFuncDados.contacto,
    genero:           _wizFuncDados.genero,
    data_nasc:        _wizFuncDados.data_nasc,
    endereco:         _wizFuncDados.endereco,
    formacao:         _wizFuncDados.formacao,
    experiencia:      _wizFuncDados.experiencia,
    data_contratacao: _wizFuncDados.data_contratacao,
    id_funcao:        _wizFuncDados.id_funcao,
    cod_biblioteca:   _wizFuncDados.cod_biblioteca,
    habilidades:      _funcHabilWiz,
    horarios:         _funcHorWiz,
  };

  // Limpar undefined
  Object.keys(body).forEach(k => body[k] === undefined && delete body[k]);

  try {
    const btnAvancar = document.getElementById('wiz-func-btn-avancar');
    if (btnAvancar) { btnAvancar.disabled = true; btnAvancar.textContent = 'A criar…'; }

    const resp = await post('/api/funcionarios', body);

    document.getElementById('modal-wiz-func-overlay').classList.add('hidden');
    toast(`Funcionário criado! Código: ${resp.cod_funcionario} · Email: ${resp.email}`);
    carregarFuncionarios();
  } catch (err) {
    _mostrarErroFunc('modal-wiz-func-erro', 'modal-wiz-func-erro-msg', err.message);
    const btnAvancar = document.getElementById('wiz-func-btn-avancar');
    if (btnAvancar) {
      btnAvancar.disabled = false;
      btnAvancar.innerHTML = `<i class="fa-solid fa-check" style="margin-right:5px"></i>Confirmar e Criar`;
    }
  }
}
