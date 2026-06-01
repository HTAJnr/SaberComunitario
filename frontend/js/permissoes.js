// ════════════════════════════════════════════════
// TELA 10 — PERMISSÕES (só Administrador)
// ════════════════════════════════════════════════

let _permRows  = [];
let _cargosRows = [];
let _permTab    = 'cargos';
let _matrizCargoId = null;
let _matrizActual  = {}; // { 'modulo:accao': 0|1 }

const MODULOS_ACCOES = {
  leitores:       ['ver','criar','editar','eliminar','alterar_status'],
  emprestimos:    ['ver','criar','devolver','eliminar'],
  materiais:      ['ver','criar','editar','eliminar'],
  transferencias: ['ver','solicitar','aprovar'],
  eventos:        ['ver','criar','editar','cancelar','gerir_participantes'],
  doacoes:        ['ver','registar','emitir_certificado'],
  programas:      ['ver','criar','editar','gerir_participantes'],
  funcionarios:   ['ver','criar','editar','eliminar'],
  permissoes:     ['ver','gerir'],
  bibliotecas:    ['ver','editar','alterar_estado'],
  auditoria:      ['ver'],
};

const _NIVEIS_CARGO = ['Administrador','Coordenador','Bibliotecario','Assistente'];

// ── Entry point ──
async function carregarPermissoes() {
  if (utilizadorActual?.NIVEL_ACESSO !== 'Administrador') {
    toast('Acesso não autorizado.', 'erro');
    navegarPara('dashboard');
    return;
  }
  // mostra os botões Admin (btn-novo-cargo removido — NOME_FUNCAO é constrained na BD)
  document.getElementById('btn-guardar-matriz')?.classList.remove('hidden');

  switchTabPermissoes(_permTab);
}

function switchTabPermissoes(tab) {
  _permTab = tab;
  ['cargos','matriz','funcs'].forEach(t => {
    const sub = document.getElementById(`sub-perm-${t}`);
    const btn = document.getElementById(`tab-perm-${t}-btn`);
    if (sub) sub.style.display = t === tab ? '' : 'none';
    if (btn) btn.classList.toggle('tab-active', t === tab);
  });
  if (tab === 'cargos')      carregarCargos();
  else if (tab === 'matriz') carregarSelectCargos();
  else if (tab === 'funcs')  carregarFuncionariosPerm();
}

// ── Tab 1 — CARGOS ──
async function carregarCargos() {
  try {
    _cargosRows = await get('/api/permissoes/cargos');
    _renderizarCargoCards();
  } catch (err) {
    toast('Erro a carregar cargos: ' + err.message, 'erro');
  }
}

const _CARGO_ESTILOS = {
  'Administrador': { bg: 'rgba(192,132,252,.08)', border: 'rgba(192,132,252,.2)', icon: '#c084fc', iconBg: 'rgba(192,132,252,.12)', fa: 'fa-crown' },
  'Coordenador':   { bg: 'rgba(96,165,250,.08)',  border: 'rgba(96,165,250,.2)',  icon: '#60a5fa', iconBg: 'rgba(96,165,250,.12)',  fa: 'fa-compass' },
  'Bibliotecario': { bg: 'rgba(63,178,122,.08)',  border: 'rgba(63,178,122,.2)',  icon: '#3fb27a', iconBg: 'rgba(63,178,122,.12)',  fa: 'fa-book-open' },
  'Assistente':    { bg: 'rgba(210,153,34,.08)',   border: 'rgba(210,153,34,.2)',   icon: '#d29922', iconBg: 'rgba(210,153,34,.12)',  fa: 'fa-user-check' },
};

function _renderizarCargoCards() {
  const grid = document.getElementById('cargo-cards-grid');
  if (!grid) return;
  if (!_cargosRows.length) {
    grid.innerHTML = `<p style="color:var(--text-muted);font-size:12px;padding:16px 0">Sem cargos registados.</p>`;
    return;
  }
  grid.innerHTML = _cargosRows.map(c => {
    const e = _CARGO_ESTILOS[c.NIVEL_ACESSO] || { bg: 'rgba(139,148,158,.08)', border: 'rgba(139,148,158,.2)', icon: '#8b949e', iconBg: 'rgba(139,148,158,.12)', fa: 'fa-user' };
    return `
    <div class="cargo-card" style="border-color:${e.border}">
      <div class="cargo-card-header" style="background:${e.bg}">
        <div class="cargo-card-icon" style="background:${e.iconBg};color:${e.icon}">
          <i class="fa-solid ${e.fa}"></i>
        </div>
        <div class="cargo-card-actions">
          <button class="btn-ghost btn-sm" title="Editar" onclick="abrirModalCargo(${c.ID_FUNCAO})">
            <i class="fa-solid fa-pen" style="font-size:10px"></i>
          </button>
          <button class="btn-ghost btn-sm" title="Eliminar" onclick="eliminarCargo(${c.ID_FUNCAO})" style="color:#f85149">
            <i class="fa-solid fa-trash" style="font-size:10px"></i>
          </button>
        </div>
      </div>
      <div class="cargo-card-body">
        <div class="cargo-card-nome">${c.NOME_FUNCAO || '—'}</div>
        <div style="margin-bottom:8px">${_badgeNivelCargo(c.NIVEL_ACESSO)}</div>
        <div class="cargo-card-desc">${c.DESCRICAO || '<span style="color:var(--text-muted);font-style:italic">Sem descrição</span>'}</div>
        <div class="cargo-card-meta">
          <i class="fa-solid fa-users" style="font-size:9px"></i>
          ${c.NUM_FUNCIONARIOS ?? 0} funcionário${(c.NUM_FUNCIONARIOS ?? 0) !== 1 ? 's' : ''}
        </div>
      </div>
    </div>`;
  }).join('');
}

function _badgeNivelCargo(nivel) {
  if (!nivel) return '—';
  const cores = {
    'Administrador':  'background:#3d1f4a;color:#c084fc',
    'Coordenador':    'background:#1f3a5a;color:#60a5fa',
    'Bibliotecario':  'background:#1f4a3a;color:#3fb27a',
    'Assistente':     'background:#3a3a1f;color:#d29922',
  };
  return `<span class="bdg" style="font-size:10px;${cores[nivel] || ''}">${nivel}</span>`;
}

// ── Matriz estática de referência ──
const _MATRIZ_REF = [
  { grupo: 'Dashboard', fa: 'fa-chart-bar', itens: [
    { label: 'Dashboard — rede',             A:1, C:0, B:0, As:0 },
    { label: 'Dashboard — biblioteca',       A:1, C:1, B:1, As:1 },
  ]},
  { grupo: 'Leitores', fa: 'fa-users', itens: [
    { label: 'Ver lista',                    A:1, C:1, B:1, As:1 },
    { label: 'Cadastrar',                    A:1, C:1, B:1, As:1 },
    { label: 'Editar',                       A:1, C:1, B:1, As:0 },
    { label: 'Eliminar',                     A:1, C:0, B:0, As:0 },
    { label: 'Alterar status',               A:1, C:1, B:0, As:0 },
  ]},
  { grupo: 'Empréstimos', fa: 'fa-arrow-right-arrow-left', itens: [
    { label: 'Ver',                          A:1, C:1, B:1, As:1 },
    { label: 'Criar',                        A:1, C:1, B:1, As:1 },
    { label: 'Devolver',                     A:1, C:1, B:1, As:1 },
    { label: 'Eliminar',                     A:1, C:0, B:0, As:0 },
    { label: 'Multas — marcar paga',         A:1, C:1, B:1, As:0 },
  ]},
  { grupo: 'Materiais', fa: 'fa-book', itens: [
    { label: 'Ver',                          A:1, C:1, B:1, As:1 },
    { label: 'Adicionar',                    A:1, C:1, B:1, As:0 },
    { label: 'Editar',                       A:1, C:1, B:1, As:0 },
    { label: 'Eliminar',                     A:1, C:1, B:0, As:0 },
  ]},
  { grupo: 'Transferências', fa: 'fa-truck', itens: [
    { label: 'Ver',                          A:1, C:1, B:0, As:0 },
    { label: 'Solicitar',                    A:1, C:1, B:0, As:0 },
    { label: 'Aprovar / Rejeitar',           A:1, C:1, B:0, As:0 },
  ]},
  { grupo: 'Eventos', fa: 'fa-calendar-days', itens: [
    { label: 'Ver',                          A:1, C:1, B:1, As:1 },
    { label: 'Criar / Editar',               A:1, C:1, B:1, As:0 },
    { label: 'Cancelar',                     A:1, C:1, B:0, As:0 },
    { label: 'Gerir participantes',          A:1, C:1, B:1, As:1 },
  ]},
  { grupo: 'Doações', fa: 'fa-hand-holding-heart', itens: [
    { label: 'Ver',                          A:1, C:1, B:1, As:0 },
    { label: 'Registar',                     A:1, C:1, B:0, As:0 },
    { label: 'Certificados — emitir',        A:1, C:1, B:0, As:0 },
  ]},
  { grupo: 'Programas', fa: 'fa-graduation-cap', itens: [
    { label: 'Ver',                          A:1, C:1, B:1, As:1 },
    { label: 'Criar / Editar',               A:1, C:1, B:0, As:0 },
    { label: 'Gerir participantes',          A:1, C:1, B:1, As:0 },
  ]},
  { grupo: 'Funcionários', fa: 'fa-user-tie', itens: [
    { label: 'Ver',                          A:1, C:1, B:0, As:0 },
    { label: 'Cadastrar / Editar',           A:1, C:1, B:0, As:0 },
    { label: 'Eliminar',                     A:1, C:0, B:0, As:0 },
  ]},
  { grupo: 'Sistema', fa: 'fa-gear', itens: [
    { label: 'Permissões — ver / gerir',     A:1, C:0, B:0, As:0 },
    { label: 'Bibliotecas (rede)',           A:1, C:0, B:0, As:0 },
    { label: 'Biblioteca (própria)',         A:1, C:1, B:0, As:0 },
    { label: 'Suspensões — reduzir',         A:1, C:1, B:0, As:0 },
  ]},
];

function _celula(val) {
  return val
    ? `<span class="matriz-check sim"><i class="fa-solid fa-check"></i></span>`
    : `<span class="matriz-check nao">—</span>`;
}

function _renderizarMatrizRef() {
  const container = document.getElementById('matriz-ref-container');
  if (!container) return;

  const linhas = _MATRIZ_REF.map(grupo => {
    const headerRow = `
      <tr class="grupo-header">
        <td colspan="5">
          <i class="fa-solid ${grupo.fa}" style="margin-right:6px;font-size:10px"></i>${grupo.grupo}
        </td>
      </tr>`;
    const itemRows = grupo.itens.map(item => `
      <tr>
        <td style="padding-left:20px;color:var(--text-secondary)">${item.label}</td>
        <td>${_celula(item.A)}</td>
        <td>${_celula(item.C)}</td>
        <td>${_celula(item.B)}</td>
        <td>${_celula(item.As)}</td>
      </tr>`).join('');
    return headerRow + itemRows;
  }).join('');

  container.innerHTML = `
    <table>
      <thead>
        <tr>
          <th>Operação</th>
          <th style="color:#c084fc">Admin</th>
          <th style="color:#60a5fa">Coord.</th>
          <th style="color:#3fb27a">Biblio.</th>
          <th style="color:#d29922">Assist.</th>
        </tr>
      </thead>
      <tbody>${linhas}</tbody>
    </table>`;
}

// Modal de cargo (criar ou editar)
function abrirModalCargo(idCargo) {
  const isEdit = !!idCargo;
  const existente = isEdit ? _cargosRows.find(c => c.ID_FUNCAO === idCargo) : null;

  document.getElementById('modal-titulo').textContent = isEdit ? 'Editar Cargo' : 'Novo Cargo';
  document.getElementById('modal-erro').classList.add('hidden');
  document.getElementById('modal-conteudo').innerHTML = `
    <div class="space-y-3">
      <div>
        <label class="form-label">Nome do Cargo *</label>
        <select id="cargo-nome" class="input-field" ${isEdit ? 'disabled' : ''}>
          ${_NIVEIS_CARGO.map(n =>
            `<option value="${n}"${existente?.NOME_FUNCAO === n ? ' selected' : ''}>${n}</option>`
          ).join('')}
        </select>
        ${isEdit ? `<input type="hidden" id="cargo-nome-hidden" value="${existente?.NOME_FUNCAO || ''}"/>
        <p style="font-size:10px;color:var(--text-muted);margin-top:3px">O nome do cargo não pode ser alterado.</p>` : ''}
      </div>
      <div>
        <label class="form-label">Nível de Acesso *</label>
        <select id="cargo-nivel" class="input-field">
          ${_NIVEIS_CARGO.map(n =>
            `<option value="${n}"${existente?.NIVEL_ACESSO === n ? ' selected' : ''}>${n}</option>`
          ).join('')}
        </select>
      </div>
      <div>
        <label class="form-label">Descrição</label>
        <textarea id="cargo-desc" class="input-field" rows="3" style="resize:vertical">${existente?.DESCRICAO || ''}</textarea>
      </div>
    </div>
  `;
  modalSalvarFn = async () => {
    const nome = isEdit
      ? (document.getElementById('cargo-nome-hidden')?.value || existente?.NOME_FUNCAO || '')
      : document.getElementById('cargo-nome').value;
    const nivel = document.getElementById('cargo-nivel').value;
    const desc = (document.getElementById('cargo-desc').value || '').trim() || null;
    try {
      if (isEdit) {
        await patch(`/api/permissoes/cargos/${idCargo}`, {
          nome_funcao: nome, nivel_acesso: nivel, descricao: desc
        });
        toast('Cargo actualizado.', 'sucesso');
      } else {
        await post('/api/permissoes/cargos', {
          nome_funcao: nome, nivel_acesso: nivel, descricao: desc
        });
        toast('Cargo criado.', 'sucesso');
      }
      fecharModal();
      carregarCargos();
    } catch (err) {
      mostrarErroModal(err.message);
    }
  };
  abrirModal();
}

function eliminarCargo(idCargo) {
  const c = _cargosRows.find(r => r.ID_FUNCAO === idCargo);
  if (!c) return;
  if ((c.NUM_FUNCIONARIOS ?? 0) > 0) {
    toast(`"${c.NOME_FUNCAO}" tem ${c.NUM_FUNCIONARIOS} funcionário(s) — reassigna-os antes de eliminar.`, 'erro');
    return;
  }
  confirmar(`Eliminar o cargo "${c.NOME_FUNCAO}"? Esta acção não pode ser revertida.`, async () => {
    try {
      await del(`/api/permissoes/cargos/${idCargo}`);
      toast('Cargo eliminado.', 'sucesso');
      carregarCargos();
    } catch (err) {
      toast(err.message, 'erro');
    }
  }, { labelOk: 'Eliminar', danger: true });
}

// ── Estrutura de grupos para a matriz editável ──
const _GRUPOS_MATRIZ = [
  { grupo: 'Leitores', fa: 'fa-users', itens: [
    { label: 'Ver lista',          modulo: 'leitores',       accao: 'ver' },
    { label: 'Cadastrar',          modulo: 'leitores',       accao: 'criar' },
    { label: 'Editar',             modulo: 'leitores',       accao: 'editar' },
    { label: 'Eliminar',           modulo: 'leitores',       accao: 'eliminar' },
    { label: 'Alterar status',     modulo: 'leitores',       accao: 'alterar_status' },
  ]},
  { grupo: 'Empréstimos', fa: 'fa-arrow-right-arrow-left', itens: [
    { label: 'Ver',                modulo: 'emprestimos',    accao: 'ver' },
    { label: 'Criar',              modulo: 'emprestimos',    accao: 'criar' },
    { label: 'Devolver',           modulo: 'emprestimos',    accao: 'devolver' },
    { label: 'Eliminar',           modulo: 'emprestimos',    accao: 'eliminar' },
  ]},
  { grupo: 'Materiais', fa: 'fa-book', itens: [
    { label: 'Ver',                modulo: 'materiais',      accao: 'ver' },
    { label: 'Adicionar',          modulo: 'materiais',      accao: 'criar' },
    { label: 'Editar',             modulo: 'materiais',      accao: 'editar' },
    { label: 'Eliminar',           modulo: 'materiais',      accao: 'eliminar' },
  ]},
  { grupo: 'Transferências', fa: 'fa-truck', itens: [
    { label: 'Ver',                modulo: 'transferencias', accao: 'ver' },
    { label: 'Solicitar',          modulo: 'transferencias', accao: 'solicitar' },
    { label: 'Aprovar / Rejeitar', modulo: 'transferencias', accao: 'aprovar' },
  ]},
  { grupo: 'Eventos', fa: 'fa-calendar-days', itens: [
    { label: 'Ver',                modulo: 'eventos',        accao: 'ver' },
    { label: 'Criar',              modulo: 'eventos',        accao: 'criar' },
    { label: 'Editar',             modulo: 'eventos',        accao: 'editar' },
    { label: 'Cancelar',           modulo: 'eventos',        accao: 'cancelar' },
    { label: 'Gerir participantes',modulo: 'eventos',        accao: 'gerir_participantes' },
  ]},
  { grupo: 'Doações', fa: 'fa-hand-holding-heart', itens: [
    { label: 'Ver',                modulo: 'doacoes',        accao: 'ver' },
    { label: 'Registar',           modulo: 'doacoes',        accao: 'registar' },
    { label: 'Emitir certificado', modulo: 'doacoes',        accao: 'emitir_certificado' },
  ]},
  { grupo: 'Programas', fa: 'fa-graduation-cap', itens: [
    { label: 'Ver',                modulo: 'programas',      accao: 'ver' },
    { label: 'Criar',              modulo: 'programas',      accao: 'criar' },
    { label: 'Editar',             modulo: 'programas',      accao: 'editar' },
    { label: 'Gerir participantes',modulo: 'programas',      accao: 'gerir_participantes' },
  ]},
  { grupo: 'Funcionários', fa: 'fa-user-tie', itens: [
    { label: 'Ver',                modulo: 'funcionarios',   accao: 'ver' },
    { label: 'Cadastrar',          modulo: 'funcionarios',   accao: 'criar' },
    { label: 'Editar',             modulo: 'funcionarios',   accao: 'editar' },
    { label: 'Eliminar',           modulo: 'funcionarios',   accao: 'eliminar' },
  ]},
  { grupo: 'Sistema', fa: 'fa-gear', itens: [
    { label: 'Ver permissões',     modulo: 'permissoes',     accao: 'ver' },
    { label: 'Gerir permissões',   modulo: 'permissoes',     accao: 'gerir' },
    { label: 'Ver bibliotecas',    modulo: 'bibliotecas',    accao: 'ver' },
    { label: 'Editar biblioteca',  modulo: 'bibliotecas',    accao: 'editar' },
    { label: 'Alterar estado',     modulo: 'bibliotecas',    accao: 'alterar_estado' },
    { label: 'Ver auditoria',      modulo: 'auditoria',      accao: 'ver' },
  ]},
];

// Defaults por nível — usados quando PERMISSAO_CARGO está vazia para um cargo
const _DEFAULTS_POR_NIVEL = {
  'Administrador': {
    'leitores:ver':1,'leitores:criar':1,'leitores:editar':1,'leitores:eliminar':1,'leitores:alterar_status':1,
    'emprestimos:ver':1,'emprestimos:criar':1,'emprestimos:devolver':1,'emprestimos:eliminar':1,
    'materiais:ver':1,'materiais:criar':1,'materiais:editar':1,'materiais:eliminar':1,
    'transferencias:ver':1,'transferencias:solicitar':1,'transferencias:aprovar':1,
    'eventos:ver':1,'eventos:criar':1,'eventos:editar':1,'eventos:cancelar':1,'eventos:gerir_participantes':1,
    'doacoes:ver':1,'doacoes:registar':1,'doacoes:emitir_certificado':1,
    'programas:ver':1,'programas:criar':1,'programas:editar':1,'programas:gerir_participantes':1,
    'funcionarios:ver':1,'funcionarios:criar':1,'funcionarios:editar':1,'funcionarios:eliminar':1,
    'permissoes:ver':1,'permissoes:gerir':1,
    'bibliotecas:ver':1,'bibliotecas:editar':1,'bibliotecas:alterar_estado':1,'auditoria:ver':1,
  },
  'Coordenador': {
    'leitores:ver':1,'leitores:criar':1,'leitores:editar':1,'leitores:eliminar':0,'leitores:alterar_status':1,
    'emprestimos:ver':1,'emprestimos:criar':1,'emprestimos:devolver':1,'emprestimos:eliminar':0,
    'materiais:ver':1,'materiais:criar':1,'materiais:editar':1,'materiais:eliminar':1,
    'transferencias:ver':1,'transferencias:solicitar':1,'transferencias:aprovar':1,
    'eventos:ver':1,'eventos:criar':1,'eventos:editar':1,'eventos:cancelar':1,'eventos:gerir_participantes':1,
    'doacoes:ver':1,'doacoes:registar':1,'doacoes:emitir_certificado':1,
    'programas:ver':1,'programas:criar':1,'programas:editar':1,'programas:gerir_participantes':1,
    'funcionarios:ver':1,'funcionarios:criar':1,'funcionarios:editar':1,'funcionarios:eliminar':0,
    'permissoes:ver':0,'permissoes:gerir':0,
    'bibliotecas:ver':0,'bibliotecas:editar':1,'bibliotecas:alterar_estado':0,'auditoria:ver':0,
  },
  'Bibliotecario': {
    'leitores:ver':1,'leitores:criar':1,'leitores:editar':1,'leitores:eliminar':0,'leitores:alterar_status':0,
    'emprestimos:ver':1,'emprestimos:criar':1,'emprestimos:devolver':1,'emprestimos:eliminar':0,
    'materiais:ver':1,'materiais:criar':1,'materiais:editar':1,'materiais:eliminar':0,
    'transferencias:ver':0,'transferencias:solicitar':0,'transferencias:aprovar':0,
    'eventos:ver':1,'eventos:criar':1,'eventos:editar':1,'eventos:cancelar':0,'eventos:gerir_participantes':1,
    'doacoes:ver':1,'doacoes:registar':0,'doacoes:emitir_certificado':0,
    'programas:ver':1,'programas:criar':0,'programas:editar':0,'programas:gerir_participantes':1,
    'funcionarios:ver':0,'funcionarios:criar':0,'funcionarios:editar':0,'funcionarios:eliminar':0,
    'permissoes:ver':0,'permissoes:gerir':0,
    'bibliotecas:ver':0,'bibliotecas:editar':0,'bibliotecas:alterar_estado':0,'auditoria:ver':0,
  },
  'Assistente': {
    'leitores:ver':1,'leitores:criar':1,'leitores:editar':0,'leitores:eliminar':0,'leitores:alterar_status':0,
    'emprestimos:ver':1,'emprestimos:criar':1,'emprestimos:devolver':1,'emprestimos:eliminar':0,
    'materiais:ver':1,'materiais:criar':0,'materiais:editar':0,'materiais:eliminar':0,
    'transferencias:ver':0,'transferencias:solicitar':0,'transferencias:aprovar':0,
    'eventos:ver':1,'eventos:criar':0,'eventos:editar':0,'eventos:cancelar':0,'eventos:gerir_participantes':1,
    'doacoes:ver':0,'doacoes:registar':0,'doacoes:emitir_certificado':0,
    'programas:ver':1,'programas:criar':0,'programas:editar':0,'programas:gerir_participantes':0,
    'funcionarios:ver':0,'funcionarios:criar':0,'funcionarios:editar':0,'funcionarios:eliminar':0,
    'permissoes:ver':0,'permissoes:gerir':0,
    'bibliotecas:ver':0,'bibliotecas:editar':0,'bibliotecas:alterar_estado':0,'auditoria:ver':0,
  },
};

// ── Tab 2 — MATRIZ DE PERMISSÕES POR CARGO ──
async function carregarSelectCargos() {
  try {
    if (!_cargosRows.length) _cargosRows = await get('/api/permissoes/cargos');
  } catch (err) {
    toast('Erro a carregar cargos: ' + err.message, 'erro');
    return;
  }
  const sel = document.getElementById('sel-cargo-matriz');
  if (!sel) return;
  sel.innerHTML = `<option value="">— Seleccionar cargo —</option>` +
    _cargosRows.map(c =>
      `<option value="${c.ID_FUNCAO}">${c.NOME_FUNCAO} (${c.NIVEL_ACESSO})</option>`
    ).join('');

  const conteudo = document.getElementById('matriz-cargo-conteudo');
  if (conteudo) {
    conteudo.innerHTML = `<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:30px">
      Selecciona um cargo para ver e editar a sua matriz de permissões.
    </p>`;
  }
}

async function carregarMatrizCargo(idCargo) {
  if (!idCargo) {
    _matrizCargoId = null;
    _matrizActual = {};
    document.getElementById('matriz-cargo-conteudo').innerHTML =
      `<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:30px">
        Selecciona um cargo para ver e editar a sua matriz de permissões.
      </p>`;
    return;
  }
  _matrizCargoId = parseInt(idCargo);
  try {
    const rows = await get(`/api/permissoes/cargos/${idCargo}/matriz`);
    _matrizActual = {};
    rows.forEach(r => { _matrizActual[`${r.MODULO}:${r.ACCAO}`] = r.PERMITIDO; });

    // Se vazio, pré-preenche com defaults do nível (primeiro uso)
    if (rows.length === 0) {
      const cargo = _cargosRows.find(c => c.ID_FUNCAO === _matrizCargoId);
      const defaults = _DEFAULTS_POR_NIVEL[cargo?.NIVEL_ACESSO];
      if (defaults) _matrizActual = { ...defaults };
    }

    _renderizarMatrizEditavel();
  } catch (err) {
    toast('Erro a carregar matriz: ' + err.message, 'erro');
  }
}

function _renderizarMatrizEditavel() {
  const conteudo = document.getElementById('matriz-cargo-conteudo');
  if (!conteudo) return;

  const linhas = _GRUPOS_MATRIZ.map(grupo => {
    const headerRow = `
      <tr class="grupo-header">
        <td colspan="2">
          <i class="fa-solid ${grupo.fa}" style="margin-right:6px;font-size:10px"></i>${grupo.grupo}
        </td>
      </tr>`;
    const itemRows = grupo.itens.map(item => {
      const key = `${item.modulo}:${item.accao}`;
      const val = _matrizActual[key] === 1;
      return `
        <tr>
          <td style="padding-left:20px;color:var(--text-secondary);font-size:12px">${item.label}</td>
          <td style="text-align:center;width:72px">
            <button class="matriz-toggle ${val ? 'sim' : 'nao'}"
                    onclick="_togglePermissaoVisual('${item.modulo}','${item.accao}',this)"
                    title="${val ? 'Clique para revogar' : 'Clique para permitir'}">
              <i class="fa-solid ${val ? 'fa-check' : 'fa-xmark'}"></i>
            </button>
          </td>
        </tr>`;
    }).join('');
    return headerRow + itemRows;
  }).join('');

  conteudo.innerHTML = `
    <div class="matriz-ref">
      <table>
        <thead>
          <tr>
            <th>Operação</th>
            <th style="width:72px;text-align:center">Permitido</th>
          </tr>
        </thead>
        <tbody>${linhas}</tbody>
      </table>
    </div>
    <p style="font-size:11px;color:var(--text-muted);margin-top:10px">
      <i class="fa-solid fa-circle-info" style="margin-right:4px"></i>
      Clica nos botões para alternar e depois em "Guardar Matriz" para aplicar.
    </p>`;
}

function _togglePermissaoVisual(modulo, accao, btn) {
  const key = `${modulo}:${accao}`;
  const novo = _matrizActual[key] === 1 ? 0 : 1;
  _matrizActual[key] = novo;
  btn.className = `matriz-toggle ${novo ? 'sim' : 'nao'}`;
  btn.innerHTML = `<i class="fa-solid ${novo ? 'fa-check' : 'fa-xmark'}"></i>`;
  btn.title = novo ? 'Clique para revogar' : 'Clique para permitir';
}

function _togglePermissao(modulo, accao, permitido) {
  _matrizActual[`${modulo}:${accao}`] = permitido ? 1 : 0;
}

async function guardarMatrizCargo() {
  if (!_matrizCargoId) {
    toast('Selecciona um cargo primeiro.', 'erro');
    return;
  }
  // construir array completo (incluindo as não-marcadas como permitido=0)
  const permissoes = [];
  for (const [modulo, accoes] of Object.entries(MODULOS_ACCOES)) {
    for (const accao of accoes) {
      const key = `${modulo}:${accao}`;
      permissoes.push({ modulo, accao, permitido: _matrizActual[key] === 1 ? 1 : 0 });
    }
  }
  try {
    await put(`/api/permissoes/cargos/${_matrizCargoId}/matriz`, { permissoes });
    toast('Matriz guardada com sucesso.', 'sucesso');
  } catch (err) {
    toast('Erro ao guardar: ' + err.message, 'erro');
  }
}

// ── Tab 3 — FUNCIONÁRIOS (vista original mantida) ──
async function carregarFuncionariosPerm() {
  try {
    _permRows = await get('/api/funcionarios');
    _renderizarTabelaPermissoes();
  } catch (err) {
    toast('Erro a carregar funcionários: ' + err.message, 'erro');
  }
}

function _renderizarTabelaPermissoes() {
  const tbody = document.getElementById('tabela-permissoes');
  if (!tbody) return;
  if (!_permRows.length) {
    tbody.innerHTML = linhaVazia(7, 'Sem funcionários registados.');
    return;
  }
  tbody.innerHTML = _permRows.map(r => _linhaPermissao(r)).join('');
}

function _linhaPermissao(r) {
  const av = avatarCirculo(r.NOME, 32);
  return `<tr>
    <td style="padding:6px 10px">${av}</td>
    <td style="font-family:monospace;font-size:11px;color:var(--text-secondary)">${r.COD_FUNCIONARIO || '—'}</td>
    <td style="font-weight:500">${r.NOME || '—'}</td>
    <td style="color:var(--text-secondary)">${r.FUNCAO || '—'}</td>
    <td>${_badgeNivelCargo(r.NIVEL_ACESSO)}</td>
    <td style="color:var(--text-muted)">${r.NOME_BIBLIOTECA || '—'}</td>
    <td style="text-align:right;padding-right:10px">
      ${String(r.COD_FUNCIONARIO) === String(utilizadorActual?.COD_FUNCIONARIO)
        ? `<span style="font-size:11px;color:var(--text-muted)">—</span>`
        : (typeof abrirModalPermissoes === 'function'
            ? `<button class="btn-ghost btn-sm"
                       onclick="abrirModalPermissoes('${r.COD_FUNCIONARIO}')">
                 <i class="fa-solid fa-shield-halved" style="margin-right:4px"></i>Gerir
               </button>`
            : '')}
    </td>
  </tr>`;
}
