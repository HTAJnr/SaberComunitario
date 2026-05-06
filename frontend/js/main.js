/* ════════════════════════════════════════════════
   Saber Comunitário — main.js
   Estado global, helpers, auth, router, modais genéricos.
   Lógica de cada secção → js/<secção>.js
   Componentes reutilizáveis → js/componentes.js
═══════════════════════════════════════════════ */

// ── Estado global ─────────────────────────────
let utilizadorActual = null;
let modalSalvarFn = null;

// ── Helpers HTTP ──────────────────────────────
async function api(path, opts = {}) {
  const res = await fetch(path, {
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    ...opts,
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.erro || `Erro ${res.status}`);
  return data;
}
const get  = (p)    => api(p);
const post = (p, b) => api(p, { method: 'POST', body: b });
const put   = (p, b) => api(p, { method: 'PUT',   body: b });
const patch = (p, b) => api(p, { method: 'PATCH', body: b });
const del   = (p)    => api(p, { method: 'DELETE' });

// ── Toast ─────────────────────────────────────
function toast(msg, tipo = 'ok') {
  const t = document.getElementById('toast');
  const icon = tipo === 'ok' ? 'fa-circle-check' : 'fa-circle-xmark';
  t.className = tipo === 'ok' ? 'toast-ok' : 'toast-erro';
  t.innerHTML = `<i class="fa-solid ${icon}"></i><span>${msg}</span>`;
  t.classList.remove('hidden');
  setTimeout(() => t.classList.add('hidden'), 3500);
}

// ── Modal de confirmação ──────────────────────
function confirmar(mensagem, callback, { labelOk = 'Confirmar', danger = true } = {}) {
  document.getElementById('modal-confirm-msg').textContent = mensagem;
  const btn = document.getElementById('modal-confirm-ok');
  btn.textContent = labelOk;
  btn.className = danger ? 'btn-danger' : 'btn-primary';
  document.getElementById('modal-confirm').classList.remove('hidden');
  const close = () => document.getElementById('modal-confirm').classList.add('hidden');
  btn.onclick = () => { close(); callback(); };
  document.getElementById('modal-confirm-cancelar').onclick = close;
}

// ── Formatação ────────────────────────────────
function fmtData(d) {
  if (!d) return '—';
  const dt = new Date(d);
  if (isNaN(dt)) return d;
  return dt.toLocaleDateString('pt-PT');
}
function fmtMoeda(v) {
  if (v === null || v === undefined) return '—';
  return `${parseFloat(v).toFixed(2)} MT`;
}
function badge(texto, cor) {
  const cores = { verde: 'badge-green', vermelho: 'badge-red', amarelo: 'badge-yellow', azul: 'badge-blue', cinza: 'badge-gray' };
  return `<span class="badge ${cores[cor] || 'badge-gray'}">${texto}</span>`;
}
function badgeEstado(estado) {
  const m = {
    ATIVO: 'verde', ACTIVO: 'verde', DISPONIVEL: 'verde', Activo: 'verde',
    Bom: 'verde',
    SUSPENSO: 'amarelo', EMPRESTADO: 'amarelo', Suspenso: 'amarelo',
    Degradado: 'amarelo',
    DEVOLVIDO: 'azul',
    INATIVO: 'cinza',
    INDISPONIVEL: 'vermelho', Indisponivel: 'vermelho', PERDIDO: 'vermelho', Bloqueado: 'vermelho',
  };
  return badge(estado || '—', m[estado] || 'cinza');
}
function badgeTipo(tipo) {
  const m = { ADULTO: 'azul', CRIANCA: 'verde', PROFESSOR: 'amarelo',
    LIVRO_FISICO: 'azul', EBOOK: 'verde', PERIODICO: 'amarelo',
    Livro: 'azul', Ebook: 'verde', Periodico: 'amarelo',
    INDIVIDUAL: 'azul', INSTITUCIONAL: 'verde' };
  const labels = { LIVRO_FISICO: 'Livro Físico', EBOOK: 'Ebook', PERIODICO: 'Periódico',
    Livro: 'Livro Físico', Ebook: 'Ebook', Periodico: 'Periódico',
    INDIVIDUAL: 'Individual', INSTITUCIONAL: 'Institucional' };
  return badge(labels[tipo] || tipo || '—', m[tipo] || 'cinza');
}
function linhaVazia(colunas, msg = 'Sem registos.') {
  return `<tr><td colspan="${colunas}" style="padding:24px;text-align:center;color:var(--text-muted);font-size:12px">${msg}</td></tr>`;
}

function iniciais(nome) {
  if (!nome) return '?';
  const parts = nome.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

function calcularRegiao(provincia) {
  return regiaoDeProvinccia(provincia);
}

function setTopbar(titulo, sub) {
  const t = document.getElementById('topbar-title');
  const s = document.getElementById('topbar-sub');
  if (t) t.textContent = titulo || '';
  if (s) s.textContent = sub || '';
}

function bdgEstado(estado) {
  const m = {
    'Activo': 'bdg-activo', 'Suspenso': 'bdg-suspenso', 'Bloqueado': 'bdg-bloqueado',
    'Pendente': 'bdg-pendente', 'Aprovada': 'bdg-aprovada',
    'Concluida': 'bdg-concluida', 'Concluída': 'bdg-concluida',
    'Rejeitada': 'bdg-rejeitada',
    'Activo (emp)': 'bdg-activo-emp', 'Vencido': 'bdg-vencido', 'Devolvido': 'bdg-devolvido',
  };
  return `<span class="bdg ${m[estado] || ''}">${estado || '—'}</span>`;
}

function bdgTipo(tipo) {
  const m = {
    'Adulto': 'bdg-adulto', 'Professor': 'bdg-professor',
    'Crianca': 'bdg-crianca', 'Criança': 'bdg-crianca',
  };
  const labels = { 'Crianca': 'Criança' };
  return `<span class="bdg ${m[tipo] || ''}">${labels[tipo] || tipo || '—'}</span>`;
}

// ════════════════════════════════════════════════
// AUTH
// ════════════════════════════════════════════════
function calcularTema(provincia) {
  return 'theme-' + regiaoDeProvinccia(provincia).toLowerCase();
}

async function init() {
  try {
    utilizadorActual = await get('/api/auth/me');
    const tema = calcularTema(utilizadorActual.PROVINCIA || 'Maputo Cidade');
    document.documentElement.className = tema;
    mostrarApp();
  } catch {
    mostrarLogin();
  }
}

function mostrarLogin() {
  document.documentElement.className = 'theme-sul';
  document.getElementById('login-screen').classList.remove('hidden');
  document.getElementById('app').classList.add('hidden');
}

function mostrarApp() {
  document.getElementById('login-screen').classList.add('hidden');
  document.getElementById('app').classList.remove('hidden');

  const nome = utilizadorActual.NOME_FUNCIONARIO || utilizadorActual.EMAIL || 'Funcionário';
  const prov = utilizadorActual.PROVINCIA || 'Maputo Cidade';
  const regiao = calcularRegiao(prov);

  document.getElementById('sidebar-user-name').textContent = nome;
  document.getElementById('sidebar-user-role').textContent =
    utilizadorActual.NIVEL_ACESSO || utilizadorActual.FUNCAO || '';
  document.getElementById('sidebar-avatar').textContent = iniciais(nome);
  document.getElementById('sidebar-library-name').textContent =
    utilizadorActual.NOME_BIBLIOTECA || '';
  document.getElementById('sidebar-region-label').textContent = `Região · ${regiao}`;
  document.getElementById('topbar-region-pill').textContent = regiao;

  configurarNavPorRole();
  configurarNavegacao();
  navegarPara(location.hash.slice(1) || 'dashboard');
}

function bindEventos() {
  document.getElementById('login-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const erroEl = document.getElementById('login-erro');
    erroEl.classList.add('hidden');
    const btn = document.getElementById('login-btn');
    const email = document.getElementById('login-email').value;
    const senha = document.getElementById('login-senha').value;
    btn.disabled = true;
    btn.textContent = 'A entrar…';
    try {
      const data = await post('/api/auth/login', { email, senha });
      utilizadorActual = data.funcionario;
      const tema = calcularTema(utilizadorActual.PROVINCIA || 'Maputo Cidade');
      document.documentElement.className = tema;
      mostrarApp();
    } catch (err) {
      document.getElementById('login-erro-msg').textContent = err.message;
      erroEl.classList.remove('hidden');
      btn.disabled = false;
      btn.textContent = 'Entrar';
    }
  });

  document.getElementById('btn-logout').addEventListener('click', async () => {
    await post('/api/auth/logout', {}).catch(() => {});
    utilizadorActual = null;
    mostrarLogin();
  });
}

// ════════════════════════════════════════════════
// ROUTER
// ════════════════════════════════════════════════
const sectionLoaders = {
  dashboard:       carregarDashboard,
  leitores:        carregarLeitores,
  materiais:       carregarMateriais,
  emprestimos:     () => carregarEmprestimos('ACTIVO'),
  funcionarios:    carregarFuncionarios,
  eventos:         carregarEventos,
  doacoes:         carregarDoacoes,
  transferencias:  () => carregarTransferencias('todas'),
  programas:       carregarProgramas,
  permissoes:      carregarPermissoes,
  biblioteca:      carregarBibliotecas,
};

const SECTION_TOPBAR = {
  dashboard:      { titulo: 'Dashboard' },
  leitores:       { titulo: 'Leitores' },
  materiais:      { titulo: 'Materiais' },
  emprestimos:    { titulo: 'Empréstimos' },
  funcionarios:   { titulo: 'Funcionários' },
  eventos:        { titulo: 'Eventos' },
  doacoes:        { titulo: 'Doações' },
  transferencias: { titulo: 'Transferências' },
  programas:      { titulo: 'Programas' },
  permissoes:     { titulo: 'Permissões' },
  biblioteca:     { titulo: 'Biblioteca' },
};

function configurarNavPorRole() {
  const nivel = utilizadorActual?.NIVEL_ACESSO || '';

  const hide = (section) => {
    const el = document.querySelector(`.nav-item[data-section="${section}"]`);
    if (el) el.style.display = 'none';
  };
  const show = (section) => {
    const el = document.querySelector(`.nav-item[data-section="${section}"]`);
    if (el) el.style.display = '';
  };

  ['transferencias', 'funcionarios', 'doacoes', 'permissoes', 'biblioteca'].forEach(show);

  if (nivel === 'Assistente') {
    hide('transferencias');
    hide('funcionarios');
    hide('doacoes');
    hide('permissoes');
    hide('biblioteca');
  } else if (nivel === 'Bibliotecario') {
    hide('transferencias');
    hide('funcionarios');
    hide('permissoes');
    hide('biblioteca');
  } else if (nivel === 'Coordenador') {
    hide('permissoes');
  }
}

function configurarNavegacao() {
  document.querySelectorAll('.nav-item[data-section]').forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      navegarPara(link.dataset.section);
    });
  });
  window.addEventListener('hashchange', () => {
    navegarPara(location.hash.slice(1) || 'dashboard');
  });
}

function navegarPara(section) {
  if (!sectionLoaders[section]) section = 'dashboard';
  location.hash = section;

  document.querySelectorAll('.section').forEach(s => s.classList.add('hidden'));
  const sec = document.getElementById(`section-${section}`);
  if (sec) { sec.classList.remove('hidden'); sec.classList.add('fade-in'); }

  document.querySelectorAll('.nav-item[data-section]').forEach(l => {
    l.classList.toggle('active', l.dataset.section === section);
  });

  const bib = utilizadorActual?.NOME_BIBLIOTECA || '';
  const tb = SECTION_TOPBAR[section];
  if (tb) setTopbar(tb.titulo, bib ? `Bib. ${bib}` : '');

  sectionLoaders[section]?.();
}

// ════════════════════════════════════════════════
// MODAL GENÉRICO — utilitários
// ════════════════════════════════════════════════
function abrirModal() {
  document.getElementById('modal-overlay').classList.remove('hidden');
  document.getElementById('modal-btn-salvar').onclick = async () => {
    document.getElementById('modal-erro').classList.add('hidden');
    try {
      await modalSalvarFn?.();
    } catch (err) {
      mostrarErroModal(err.message);
    }
  };
}

function fecharModal(e) {
  if (e && e.target !== document.getElementById('modal-overlay')) return;
  document.getElementById('modal-overlay').classList.add('hidden');
  modalSalvarFn = null;
}

function mostrarErroModal(msg) {
  document.getElementById('modal-erro-msg').textContent = msg;
  document.getElementById('modal-erro').classList.remove('hidden');
}

// ════════════════════════════════════════════════
// INICIALIZAÇÃO
// ════════════════════════════════════════════════
async function inicializarHTML() {
  const seccoes = ['dashboard','leitores','materiais','emprestimos','funcionarios','eventos','doacoes','transferencias','programas','permissoes','biblioteca'];

  const loginHtml = await fetch('sections/login.html').then(r => r.text());
  document.getElementById('app').insertAdjacentHTML('beforebegin', loginHtml);

  const main = document.getElementById('main-content');
  const htmls = await Promise.all(
    seccoes.map(s => fetch(`sections/${s}.html`).then(r => r.text()))
  );
  main.innerHTML = htmls.join('');

  const modals = await fetch('sections/modals.html').then(r => r.text());
  document.body.insertAdjacentHTML('beforeend', modals);
}

inicializarHTML().then(() => { bindEventos(); init(); });
