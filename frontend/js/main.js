/* ════════════════════════════════════════════════
   Saber Comunitário — main.js
   SPA com router hash + CRUD completo
═══════════════════════════════════════════════ */

// ── Estado global ─────────────────────────────
let utilizadorActual = null;
let eventoActualId = null;
let emprestimoDevolverID = null;
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
const put  = (p, b) => api(p, { method: 'PUT', body: b });
const del  = (p)    => api(p, { method: 'DELETE' });

// ── Toast ─────────────────────────────────────
function toast(msg, tipo = 'ok') {
  const t = document.getElementById('toast');
  const icon = tipo === 'ok' ? 'fa-circle-check' : 'fa-circle-xmark';
  t.className = tipo === 'ok'
    ? 'fixed bottom-6 right-6 z-50 px-5 py-3 rounded-xl text-sm font-medium shadow-2xl bg-green-800 text-green-100 flex items-center gap-2'
    : 'fixed bottom-6 right-6 z-50 px-5 py-3 rounded-xl text-sm font-medium shadow-2xl bg-red-900 text-red-100 flex items-center gap-2';
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
    SUSPENSO: 'amarelo', EMPRESTADO: 'amarelo', Suspenso: 'amarelo',
    DEVOLVIDO: 'azul',
    INATIVO: 'cinza',
    INDISPONIVEL: 'vermelho', PERDIDO: 'vermelho', Bloqueado: 'vermelho',
  };
  return badge(estado || '—', m[estado] || 'cinza');
}
function badgeTipo(tipo) {
  const m = { ADULTO: 'azul', CRIANCA: 'verde', PROFESSOR: 'amarelo',
    LIVRO_FISICO: 'azul', EBOOK: 'verde', PERIODICO: 'amarelo',
    INDIVIDUAL: 'azul', INSTITUCIONAL: 'verde' };
  const labels = { LIVRO_FISICO: 'Livro Físico', EBOOK: 'Ebook', PERIODICO: 'Periódico',
    INDIVIDUAL: 'Individual', INSTITUCIONAL: 'Institucional' };
  return badge(labels[tipo] || tipo || '—', m[tipo] || 'cinza');
}
function linhaVazia(colunas, msg = 'Sem registos.') {
  return `<tr><td colspan="${colunas}" style="padding:24px;text-align:center;color:#888;font-size:12px">${msg}</td></tr>`;
}

function iniciais(nome) {
  if (!nome) return '?';
  const parts = nome.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

function calcularRegiao(provincia) {
  const SUL    = ['Maputo Cidade', 'Maputo Provincia', 'Gaza', 'Inhambane'];
  const CENTRO = ['Sofala', 'Manica', 'Tete', 'Zambezia'];
  if (SUL.includes(provincia))    return 'Sul';
  if (CENTRO.includes(provincia)) return 'Centro';
  return 'Norte';
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
  const SUL    = ['Maputo Cidade', 'Maputo Provincia', 'Gaza', 'Inhambane'];
  const CENTRO = ['Sofala', 'Manica', 'Tete', 'Zambezia'];
  if (SUL.includes(provincia))    return 'theme-sul';
  if (CENTRO.includes(provincia)) return 'theme-centro';
  return 'theme-norte';
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
  transferencias:  () => {},
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
};

function configurarNavPorRole() {
  const nivel = utilizadorActual?.NIVEL_ACESSO || '';
  const isAdmin = nivel === 'Administrador';
  const isCoord = nivel === 'Coordenador';

  const hide = (section) => {
    const el = document.querySelector(`.nav-item[data-section="${section}"]`);
    if (el) el.style.display = 'none';
  };
  const show = (section) => {
    const el = document.querySelector(`.nav-item[data-section="${section}"]`);
    if (el) el.style.display = '';
  };

  // Mostrar tudo primeiro
  ['transferencias', 'funcionarios', 'doacoes'].forEach(show);

  if (nivel === 'Assistente') {
    hide('transferencias');
    hide('funcionarios');
    hide('doacoes');
  } else if (nivel === 'Bibliotecario') {
    hide('transferencias');
    hide('funcionarios');
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
// DASHBOARD
// ════════════════════════════════════════════════
async function carregarDashboard() {
  const nivel = utilizadorActual?.NIVEL_ACESSO;
  if (nivel === 'Administrador') {
    document.getElementById('dash-rede-view').classList.remove('hidden');
    document.getElementById('dash-bib-view').classList.add('hidden');
    await carregarDashboardAdmin();
  } else {
    document.getElementById('dash-bib-view').classList.remove('hidden');
    document.getElementById('dash-rede-view').classList.add('hidden');
    await carregarDashboardBib(nivel);
  }
}

async function carregarDashboardAdmin() {
  try {
    const stats = await get('/api/dashboard/rede').catch(() => ({}));
    const cards = [
      { label: 'Bibliotecas activas',        valor: stats.TOTAL_BIBLIOTECAS         ?? '—' },
      { label: 'Empréstimos activos na rede', valor: stats.EMPRESTIMOS_ATIVOS         ?? '—' },
      { label: 'Transferências pendentes',   valor: stats.TRANSFERENCIAS_PENDENTES   ?? '—',
        alerta: (stats.TRANSFERENCIAS_PENDENTES > 0) ? 'laranja' : null },
      { label: 'Materiais no acervo',         valor: stats.MATERIAIS_ACERVO            ?? '—' },
    ];
    document.getElementById('dash-rede-stats').innerHTML = cards.map(renderStatCard).join('');
    document.getElementById('dash-rede-table').innerHTML = `
      <div class="empty-state">
        <div class="empty-state-icon">⇆</div>
        <div class="empty-state-text">Módulo de rede disponível em breve</div>
        <div class="empty-state-sub">Gestão de bibliotecas na TELA 11</div>
      </div>`;
  } catch (err) {
    toast('Erro a carregar dashboard: ' + err.message, 'erro');
  }
}

async function carregarDashboardBib(nivel) {
  const isAssistente = nivel === 'Assistente';
  try {
    const [stats, devHoje, leitores, transferencias] = await Promise.all([
      get('/api/dashboard/biblioteca').catch(() => ({})),
      get('/api/dashboard/devolucoes-hoje').catch(() => []),
      isAssistente ? Promise.resolve([]) : get('/api/dashboard/leitores-recentes').catch(() => []),
      isAssistente ? Promise.resolve([]) : get('/api/dashboard/transferencias-recentes').catch(() => []),
    ]);

    // Stat cards
    const allCards = [
      { label: 'Empréstimos activos',       valor: stats.EMPRESTIMOS_ATIVOS      ?? '—' },
      { label: 'Em atraso',                  valor: stats.EMPRESTIMOS_VENCIDOS     ?? '—',
        alerta: (stats.EMPRESTIMOS_VENCIDOS > 0) ? 'vermelho' : null },
      { label: 'Materiais disponíveis',      valor: stats.MATERIAIS_DISPONIVEIS    ?? '—' },
      { label: 'Transferências pendentes',   valor: stats.TRANSFERENCIAS_PENDENTES ?? '—',
        alerta: (stats.TRANSFERENCIAS_PENDENTES > 0) ? 'laranja' : null },
    ];
    document.getElementById('dash-stats').innerHTML =
      (isAssistente ? allCards.slice(0, 2) : allCards).map(renderStatCard).join('');

    // Devoluções hoje
    renderDevolucoes(devHoje || []);

    // Painel de gráfico e linha 2: esconder para Assistente
    const grafico = document.getElementById('dash-grafico-panel');
    const linha2  = document.getElementById('dash-linha2');
    if (isAssistente) {
      if (grafico) grafico.style.display = 'none';
      if (linha2)  linha2.style.display  = 'none';
    } else {
      if (grafico) grafico.style.display = '';
      if (linha2)  linha2.style.display  = '';
      renderBarChart(stats.EMPRESTIMOS_SEMANA || []);
      renderLeitoresRecentes(leitores || []);
      renderTransferenciasRecentes(transferencias || []);
    }
  } catch (err) {
    toast('Erro a carregar dashboard: ' + err.message, 'erro');
  }
}

function renderStatCard({ label, valor, alerta }) {
  let alertHtml = '';
  if (alerta === 'vermelho') alertHtml = `<div class="stat-card-alert-red">↑ requer atenção</div>`;
  if (alerta === 'laranja')  alertHtml = `<div class="stat-card-alert-warn">⚠ pendente</div>`;
  return `
    <div class="stat-card">
      <div class="stat-card-bar"></div>
      <div class="stat-card-label">${label}</div>
      <div class="stat-card-value">${valor ?? '—'}</div>
      ${alertHtml}
    </div>`;
}

function renderDevolucoes(lista) {
  const el = document.getElementById('dash-devolucoes-hoje');
  if (!lista.length) {
    el.innerHTML = `<div class="empty-state">
      <div class="empty-state-icon">○</div>
      <div class="empty-state-text">Sem devoluções previstas hoje</div>
    </div>`;
    return;
  }
  const hoje = new Date(); hoje.setHours(0, 0, 0, 0);
  el.innerHTML = lista.map(emp => {
    const ini = iniciais(emp.NOME_LEITOR || '');
    const titulo = (emp.TITULO || '—').substring(0, 32);
    const prazo = new Date(emp.PRAZO_DEVOLUCAO); prazo.setHours(0, 0, 0, 0);
    const diff = Math.round((prazo - hoje) / 86400000);
    let badgeTxt, badgeCls;
    if (diff < 0)     { badgeTxt = `${Math.abs(diff)}d atraso`; badgeCls = 'bdg-bloqueado'; }
    else if (diff === 0) { badgeTxt = 'Hoje';    badgeCls = 'bdg-suspenso'; }
    else              { badgeTxt = 'Pontual'; badgeCls = 'bdg-activo'; }
    return `
      <div style="display:flex;align-items:center;gap:10px;padding:7px 0;border-bottom:0.5px solid #f0f0f0">
        <div class="avatar-initials" style="width:26px;height:26px;font-size:9px;flex-shrink:0">${ini}</div>
        <div style="flex:1;min-width:0">
          <div style="font-size:12px;color:#111;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${emp.NOME_LEITOR || '—'}</div>
          <div style="font-size:10px;color:#888;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${titulo}</div>
        </div>
        <span class="bdg ${badgeCls}" style="flex-shrink:0">${badgeTxt}</span>
      </div>`;
  }).join('');
}

function renderBarChart(semana) {
  const el = document.getElementById('dash-bar-chart');
  if (!el) return;
  const dias = ['D-6', 'D-5', 'D-4', 'D-3', 'D-2', 'D-1', 'Hoje'];
  while (semana.length < 7) semana.unshift(0);
  const max = Math.max(...semana, 1);
  el.innerHTML = semana.map((val, i) => {
    const pct = Math.max(Math.round((val / max) * 100), val > 0 ? 4 : 2);
    return `
      <div class="bar-chart-col">
        <div class="bar-chart-val">${val > 0 ? val : ''}</div>
        <div class="bar-chart-bar" style="height:${pct}%"></div>
        <div class="bar-chart-label">${dias[i]}</div>
      </div>`;
  }).join('');
}

function renderLeitoresRecentes(lista) {
  const tbody = document.getElementById('dash-leitores-tbody');
  if (!lista.length) {
    tbody.innerHTML = linhaVazia(4, 'Sem leitores recentes');
    return;
  }
  tbody.innerHTML = lista.map(l => `
    <tr>
      <td><span class="cod">${l.NUM_CARTAO || '—'}</span></td>
      <td>${l.NOME_COMPLETO || '—'}</td>
      <td>${bdgTipo(l.TIPO)}</td>
      <td>${bdgEstado(l.STATUS_LEITOR)}</td>
    </tr>`).join('');
}

function renderTransferenciasRecentes(lista) {
  const el = document.getElementById('dash-transferencias');
  if (!lista.length) {
    el.innerHTML = `<div class="empty-state">
      <div class="empty-state-icon">○</div>
      <div class="empty-state-text">Sem transferências recentes</div>
    </div>`;
    return;
  }
  const bibActual = utilizadorActual?.COD_BIBLIOTECA;
  el.innerHTML = lista.map(t => {
    const enviada = t.COD_BIBLIOTECA_ORIGEM === bibActual;
    const seta    = enviada ? '↗' : '↙';
    const cor     = enviada ? '#1aab96' : '#e07820';
    const outra   = enviada ? (t.NOME_DESTINO || t.NOME_BIBLIOTECA_DESTINO) : (t.NOME_ORIGEM || t.NOME_BIBLIOTECA_ORIGEM);
    const titulo  = (t.TITULO || '—').substring(0, 30);
    return `
      <div style="display:flex;align-items:center;gap:10px;padding:7px 0;border-bottom:0.5px solid #f0f0f0">
        <div style="font-size:16px;color:${cor};flex-shrink:0;width:16px;text-align:center">${seta}</div>
        <div style="flex:1;min-width:0">
          <div style="font-size:12px;color:#111;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${titulo}</div>
          <div style="font-size:10px;color:#888;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${outra || '—'}</div>
        </div>
        ${bdgEstado(t.ESTADO_TRANSFERENCIA)}
      </div>`;
  }).join('');
}

// ════════════════════════════════════════════════
// LEITORES
// ════════════════════════════════════════════════

let _wizardStep = 1, _wizardDados = {}, _wizardInteresses = [], _wizardDisciplinas = [];
let _drawerNumCartao = null, _drawerLeitor = null, _drawerTabActual = 'perfil';

function bdgPontualidade(h) {
  const m = { Pontual: 'bdg-activo', Irregular: 'bdg-suspenso', Mau: 'bdg-bloqueado' };
  return `<span class="bdg ${m[h] || ''}">${h || '—'}</span>`;
}

async function carregarLeitores() {
  const search    = document.getElementById('filtro-leitor-q')?.value || '';
  const status    = document.getElementById('filtro-leitor-estado')?.value || '';
  const tipo      = document.getElementById('filtro-leitor-tipo')?.value || '';
  const historico = document.getElementById('filtro-leitor-historico')?.value || '';
  const params = new URLSearchParams();
  if (search)    params.set('search', search);
  if (status)    params.set('status', status);
  if (tipo)      params.set('tipo', tipo);
  if (historico) params.set('historico', historico);
  try {
    const { leitores: rows } = await get(`/api/leitores?${params}`);
    const tbody = document.getElementById('tabela-leitores');
    tbody.innerHTML = rows && rows.length
      ? rows.map(r => `
        <tr>
          <td style="font-family:monospace;font-size:11px;color:#888">${r.NUM_CARTAO || '—'}</td>
          <td style="font-weight:500">${r.NOME_COMPLETO || '—'}</td>
          <td>${bdgTipo(r.TIPO_LEITOR)}</td>
          <td>${bdgPontualidade(r.HISTORICO_PONTUALIDADE)}</td>
          <td>${bdgEstado(r.STATUS_LEITOR)}</td>
          <td style="text-align:right">
            <button class="btn-secondary btn-sm" onclick="abrirCtxMenuLeitor(event,'${r.NUM_CARTAO}','${(r.NOME_COMPLETO||'').replace(/'/g,"\\'")}','${r.STATUS_LEITOR||''}')">···</button>
          </td>
        </tr>`).join('')
      : linhaVazia(6);
  } catch (err) {
    toast('Erro a carregar leitores: ' + err.message, 'erro');
  }
}

// ── Context menu ───────────────────────────────
function abrirCtxMenuLeitor(evt, numCartao, nome, statusActual) {
  evt.stopPropagation();
  const nivel = utilizadorActual?.NIVEL_ACESSO || '';
  const podeEditar   = ['Administrador','Coordenador','Bibliotecario'].includes(nivel);
  const podeStatus   = ['Administrador','Coordenador'].includes(nivel);
  const podeEliminar = nivel === 'Administrador';

  const menu = document.getElementById('ctx-menu-leitor');
  menu.innerHTML = `
    <div class="ctx-menu-item" onclick="fecharCtxMenuLeitor();abrirDrawerLeitor('${numCartao}')">
      <i class="fa-solid fa-eye" style="width:14px"></i> Ver perfil
    </div>
    ${podeEditar ? `<div class="ctx-menu-item" onclick="fecharCtxMenuLeitor();abrirModalEditarLeitor('${numCartao}')">
      <i class="fa-solid fa-pen" style="width:14px"></i> Editar
    </div>` : ''}
    ${podeStatus ? `<div class="ctx-menu-item" onclick="fecharCtxMenuLeitor();abrirModalAlterarStatus('${numCartao}','${statusActual}')">
      <i class="fa-solid fa-toggle-on" style="width:14px"></i> Alterar estado
    </div>
    <div class="ctx-menu-item" onclick="fecharCtxMenuLeitor();abrirModalSuspensoes('${numCartao}')">
      <i class="fa-solid fa-ban" style="width:14px"></i> Ver suspensões
    </div>` : ''}
    ${podeEliminar ? `<div class="ctx-menu-item ctx-menu-danger" onclick="fecharCtxMenuLeitor();confirmarEliminarLeitor('${numCartao}','${nome.replace(/'/g,"\\'")}')">
      <i class="fa-solid fa-trash" style="width:14px"></i> Eliminar
    </div>` : ''}
  `;

  const btn = evt.currentTarget;
  const rect = btn.getBoundingClientRect();
  menu.style.display = 'block';
  menu.style.position = 'fixed';
  menu.style.top  = (rect.bottom + 4) + 'px';
  menu.style.left = Math.max(4, rect.right - 170) + 'px';

  setTimeout(() => document.addEventListener('click', fecharCtxMenuLeitor, { once: true }), 0);
}

function fecharCtxMenuLeitor() {
  const menu = document.getElementById('ctx-menu-leitor');
  if (menu) menu.style.display = 'none';
}

// ── Modal leitor — utilitários ─────────────────
function abrirModalLeitorBase(titulo) {
  document.getElementById('modal-leitor-titulo').textContent = titulo;
  document.getElementById('modal-leitor-erro').classList.add('hidden');
  document.getElementById('modal-leitor-conteudo').innerHTML = '';
  document.getElementById('modal-leitor-footer').innerHTML = '';
  document.getElementById('modal-leitor-overlay').classList.remove('hidden');
}

function fecharModalLeitor(e) {
  if (e && e.target !== document.getElementById('modal-leitor-overlay')) return;
  document.getElementById('modal-leitor-overlay').classList.add('hidden');
}

function mostrarErroLeitor(msg) {
  document.getElementById('modal-leitor-erro-msg').textContent = msg;
  document.getElementById('modal-leitor-erro').classList.remove('hidden');
}

// ── Wizard 02-B ────────────────────────────────
function abrirWizardLeitor() {
  _wizardStep = 1; _wizardDados = {}; _wizardInteresses = []; _wizardDisciplinas = [];
  abrirModalLeitorBase('Cadastrar Leitor');
  _renderizarWizardStep();
}

function _wizardIndicador(step) {
  const titulos = ['Dados Base', 'Tipo e Detalhes', 'Confirmação'];
  const dots = [1,2,3].map(i => {
    const cls = i < step ? 'done' : i === step ? 'active' : 'pending';
    return `<div class="step-dot ${cls}"></div>${i < 3 ? '<div class="step-line"></div>' : ''}`;
  }).join('');
  return `<div class="wizard-steps">${dots}</div>
    <div style="font-size:11px;color:#888;margin-bottom:16px">Passo ${step} de 3 — ${titulos[step-1]}</div>`;
}

function _renderizarWizardStep() {
  const conteudo = document.getElementById('modal-leitor-conteudo');
  const footer   = document.getElementById('modal-leitor-footer');
  document.getElementById('modal-leitor-erro').classList.add('hidden');

  if (_wizardStep === 1) {
    conteudo.innerHTML = _wizardIndicador(1) + `
      <div class="form-group">
        <label class="form-label">Nome completo *</label>
        <input id="wz-nome" class="input-field" value="${_wizardDados.nome_completo || ''}"/>
      </div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
        <div class="form-group">
          <label class="form-label">Data de nascimento *</label>
          <input id="wz-data-nasc" type="date" class="input-field" value="${_wizardDados.data_nasc || ''}"/>
        </div>
        <div class="form-group">
          <label class="form-label">Género *</label>
          <select id="wz-genero" class="input-field">
            <option value="">— Seleccionar —</option>
            <option value="Masculino" ${_wizardDados.genero==='Masculino'?'selected':''}>Masculino</option>
            <option value="Feminino"  ${_wizardDados.genero==='Feminino'?'selected':''}>Feminino</option>
          </select>
        </div>
      </div>
      <div class="form-group">
        <label class="form-label">Nível escolar *</label>
        <input id="wz-nivel-escolar" class="input-field" placeholder="Ex: Primário Completo" value="${_wizardDados.nivel_escolar || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Localização *</label>
        <textarea id="wz-localizacao" class="input-field" rows="2" style="resize:vertical">${_wizardDados.localizacao_leitor || ''}</textarea>
      </div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
        <div class="form-group">
          <label class="form-label">Contacto</label>
          <input id="wz-contacto" class="input-field" value="${_wizardDados.contacto || ''}"/>
        </div>
        <div class="form-group">
          <label class="form-label">Distância à biblioteca (km)</label>
          <input id="wz-distancia" type="number" min="0" class="input-field" value="${_wizardDados.distancia_biblioteca || ''}"/>
        </div>
      </div>`;
    footer.innerHTML = `
      <button class="btn-secondary" onclick="fecharModalLeitor()">Cancelar</button>
      <button class="btn-primary" onclick="_wizardAvancar()">Próximo <i class="fa-solid fa-arrow-right" style="margin-left:4px"></i></button>`;

  } else if (_wizardStep === 2) {
    const tipo = _wizardDados.tipo || 'Adulto';
    conteudo.innerHTML = _wizardIndicador(2) + `
      <div class="form-group" style="margin-bottom:14px">
        <label class="form-label">Tipo de leitor *</label>
        <div style="display:flex;gap:16px;margin-top:6px">
          ${['Adulto','Professor','Crianca'].map(t => `
            <label style="display:flex;align-items:center;gap:6px;cursor:pointer;font-size:13px">
              <input type="radio" name="wz-tipo" value="${t}" ${tipo===t?'checked':''} onchange="_renderizarCamposTipo()"/>
              ${t==='Crianca'?'Criança':t}
            </label>`).join('')}
        </div>
      </div>
      <div id="wz-campos-tipo"></div>`;
    _renderizarCamposTipo();
    footer.innerHTML = `
      <button class="btn-secondary" onclick="_wizardRecuar()"><i class="fa-solid fa-arrow-left" style="margin-right:4px"></i> Anterior</button>
      <button class="btn-primary" onclick="_wizardAvancar()">Próximo <i class="fa-solid fa-arrow-right" style="margin-left:4px"></i></button>`;

  } else {
    const tipo = _wizardDados.tipo || 'Adulto';
    conteudo.innerHTML = _wizardIndicador(3) + `
      <div style="background:#f8f9fa;border-radius:8px;padding:16px;font-size:13px;line-height:2.2">
        <div><b>Nome:</b> ${_wizardDados.nome_completo || '—'}</div>
        <div><b>Tipo:</b> ${tipo === 'Crianca' ? 'Criança' : tipo}</div>
        <div><b>Género:</b> ${_wizardDados.genero || '—'}</div>
        <div><b>Nível escolar:</b> ${_wizardDados.nivel_escolar || '—'}</div>
        <div><b>Localização:</b> ${_wizardDados.localizacao_leitor || '—'}</div>
        ${_wizardDados.contacto ? `<div><b>Contacto:</b> ${_wizardDados.contacto}</div>` : ''}
      </div>
      <div style="margin-top:12px;font-size:11px;color:#888;background:#fffbe6;border:1px solid #ffe08a;border-radius:6px;padding:8px 12px">
        <i class="fa-solid fa-circle-info" style="margin-right:6px"></i>O número de cartão será gerado automaticamente pelo sistema.
      </div>`;
    footer.innerHTML = `
      <button class="btn-secondary" onclick="_wizardRecuar()"><i class="fa-solid fa-arrow-left" style="margin-right:4px"></i> Anterior</button>
      <button class="btn-primary" onclick="_wizardConfirmar()"><i class="fa-solid fa-check" style="margin-right:4px"></i> Confirmar registo</button>`;
  }
}

function _renderizarCamposTipo() {
  const tipo = document.querySelector('input[name="wz-tipo"]:checked')?.value || _wizardDados.tipo || 'Adulto';
  const cont = document.getElementById('wz-campos-tipo');
  if (!cont) return;

  if (tipo === 'Adulto') {
    cont.innerHTML = `
      <div class="form-group">
        <label class="form-label">Profissão</label>
        <input id="wz-profissao" class="input-field" value="${_wizardDados.profissao || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Nível de literacia</label>
        <select id="wz-nivel-literacia" class="input-field">
          <option value="">—</option>
          ${['Analfabeto','Alfabetizado','Básico','Médio','Superior'].map(v=>`<option ${_wizardDados.nivel_literacia===v?'selected':''}>${v}</option>`).join('')}
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Interesses</label>
        <div style="display:flex;gap:6px;margin-bottom:6px">
          <input id="wz-interesse-input" class="input-field" style="flex:1" placeholder="Escrever e adicionar…"/>
          <button type="button" class="btn-secondary btn-sm" onclick="_adicionarInteresse()">Adicionar</button>
        </div>
        <div id="wz-interesses-chips" class="chips-wrap">${_renderChips(_wizardInteresses,'_removerInteresse')}</div>
      </div>`;
  } else if (tipo === 'Professor') {
    cont.innerHTML = `
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
        <div class="form-group">
          <label class="form-label">Profissão</label>
          <input id="wz-profissao" class="input-field" value="${_wizardDados.profissao||'Professor'}"/>
        </div>
        <div class="form-group">
          <label class="form-label">Nível de literacia</label>
          <select id="wz-nivel-literacia" class="input-field">
            <option value="">—</option>
            ${['Analfabeto','Alfabetizado','Básico','Médio','Superior'].map(v=>`<option ${_wizardDados.nivel_literacia===v?'selected':''}>${v}</option>`).join('')}
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Escola / Instituto</label>
          <input id="wz-escola-instituto" class="input-field" value="${_wizardDados.escola_instituto||''}"/>
        </div>
        <div class="form-group">
          <label class="form-label">Nível de ensino</label>
          <select id="wz-nivel-ensino" class="input-field">
            <option value="">—</option>
            ${['Pré-escolar','Primário','Secundário','Superior'].map(v=>`<option ${_wizardDados.nivel_ensino===v?'selected':''}>${v}</option>`).join('')}
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Nº alunos</label>
          <input id="wz-num-alunos" type="number" min="0" class="input-field" value="${_wizardDados.num_alunos||''}"/>
        </div>
      </div>
      <div class="form-group">
        <label class="form-label">Interesses</label>
        <div style="display:flex;gap:6px;margin-bottom:6px">
          <input id="wz-interesse-input" class="input-field" style="flex:1" placeholder="Escrever e adicionar…"/>
          <button type="button" class="btn-secondary btn-sm" onclick="_adicionarInteresse()">Adicionar</button>
        </div>
        <div id="wz-interesses-chips" class="chips-wrap">${_renderChips(_wizardInteresses,'_removerInteresse')}</div>
      </div>
      <div class="form-group">
        <label class="form-label">Disciplinas</label>
        <div style="display:flex;gap:6px;margin-bottom:6px">
          <input id="wz-disciplina-input" class="input-field" style="flex:1" placeholder="Escrever e adicionar…"/>
          <button type="button" class="btn-secondary btn-sm" onclick="_adicionarDisciplina()">Adicionar</button>
        </div>
        <div id="wz-disciplinas-chips" class="chips-wrap">${_renderChips(_wizardDisciplinas,'_removerDisciplina')}</div>
      </div>`;
  } else {
    cont.innerHTML = `
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
        <div class="form-group">
          <label class="form-label">Nome do responsável *</label>
          <input id="wz-nome-responsavel" class="input-field" value="${_wizardDados.nome_responsavel||''}"/>
        </div>
        <div class="form-group">
          <label class="form-label">Telefone do responsável</label>
          <input id="wz-telefone-responsavel" class="input-field" value="${_wizardDados.telefone_responsavel||''}"/>
        </div>
        <div class="form-group">
          <label class="form-label">Escola que frequenta</label>
          <input id="wz-escola-frequenta" class="input-field" value="${_wizardDados.escola_frequenta||''}"/>
        </div>
        <div class="form-group">
          <label class="form-label">Classe</label>
          <input id="wz-classe" class="input-field" value="${_wizardDados.classe||''}"/>
        </div>
      </div>`;
  }
}

function _renderChips(arr, removeFn) {
  return arr.map((v,i) => `<span class="chip">${v}<span class="chip-x" onclick="${removeFn}(${i})">×</span></span>`).join('');
}
function _adicionarInteresse() {
  const inp = document.getElementById('wz-interesse-input');
  const v = inp?.value.trim();
  if (v && !_wizardInteresses.includes(v)) { _wizardInteresses.push(v); inp.value = ''; }
  const el = document.getElementById('wz-interesses-chips');
  if (el) el.innerHTML = _renderChips(_wizardInteresses, '_removerInteresse');
}
function _removerInteresse(i) {
  _wizardInteresses.splice(i, 1);
  const el = document.getElementById('wz-interesses-chips');
  if (el) el.innerHTML = _renderChips(_wizardInteresses, '_removerInteresse');
}
function _adicionarDisciplina() {
  const inp = document.getElementById('wz-disciplina-input');
  const v = inp?.value.trim();
  if (v && !_wizardDisciplinas.includes(v)) { _wizardDisciplinas.push(v); inp.value = ''; }
  const el = document.getElementById('wz-disciplinas-chips');
  if (el) el.innerHTML = _renderChips(_wizardDisciplinas, '_removerDisciplina');
}
function _removerDisciplina(i) {
  _wizardDisciplinas.splice(i, 1);
  const el = document.getElementById('wz-disciplinas-chips');
  if (el) el.innerHTML = _renderChips(_wizardDisciplinas, '_removerDisciplina');
}

function _wizardRecolherStep1() {
  _wizardDados.nome_completo       = document.getElementById('wz-nome')?.value.trim() || '';
  _wizardDados.data_nasc           = document.getElementById('wz-data-nasc')?.value || '';
  _wizardDados.genero              = document.getElementById('wz-genero')?.value || '';
  _wizardDados.nivel_escolar       = document.getElementById('wz-nivel-escolar')?.value.trim() || '';
  _wizardDados.localizacao_leitor  = document.getElementById('wz-localizacao')?.value.trim() || '';
  _wizardDados.contacto            = document.getElementById('wz-contacto')?.value.trim() || '';
  _wizardDados.distancia_biblioteca = document.getElementById('wz-distancia')?.value || '';
}

function _wizardRecolherStep2() {
  _wizardDados.tipo = document.querySelector('input[name="wz-tipo"]:checked')?.value || 'Adulto';
  const t = _wizardDados.tipo;
  if (t === 'Adulto' || t === 'Professor') {
    _wizardDados.profissao       = document.getElementById('wz-profissao')?.value.trim() || '';
    _wizardDados.nivel_literacia = document.getElementById('wz-nivel-literacia')?.value || '';
    _wizardDados.interesses      = [..._wizardInteresses];
  }
  if (t === 'Professor') {
    _wizardDados.escola_instituto = document.getElementById('wz-escola-instituto')?.value.trim() || '';
    _wizardDados.nivel_ensino     = document.getElementById('wz-nivel-ensino')?.value || '';
    _wizardDados.num_alunos       = document.getElementById('wz-num-alunos')?.value || '';
    _wizardDados.disciplinas      = [..._wizardDisciplinas];
  }
  if (t === 'Crianca') {
    _wizardDados.nome_responsavel     = document.getElementById('wz-nome-responsavel')?.value.trim() || '';
    _wizardDados.telefone_responsavel = document.getElementById('wz-telefone-responsavel')?.value.trim() || '';
    _wizardDados.escola_frequenta     = document.getElementById('wz-escola-frequenta')?.value.trim() || '';
    _wizardDados.classe               = document.getElementById('wz-classe')?.value.trim() || '';
  }
}

function _wizardAvancar() {
  if (_wizardStep === 1) {
    _wizardRecolherStep1();
    if (!_wizardDados.nome_completo)       { mostrarErroLeitor('Nome completo é obrigatório.'); return; }
    if (!_wizardDados.data_nasc)           { mostrarErroLeitor('Data de nascimento é obrigatória.'); return; }
    if (!_wizardDados.genero)              { mostrarErroLeitor('Género é obrigatório.'); return; }
    if (!_wizardDados.nivel_escolar)       { mostrarErroLeitor('Nível escolar é obrigatório.'); return; }
    if (!_wizardDados.localizacao_leitor)  { mostrarErroLeitor('Localização é obrigatória.'); return; }
  } else if (_wizardStep === 2) {
    _wizardRecolherStep2();
    if (_wizardDados.tipo === 'Crianca' && !_wizardDados.nome_responsavel) {
      mostrarErroLeitor('Nome do responsável é obrigatório para Criança.'); return;
    }
  }
  _wizardStep++;
  _renderizarWizardStep();
}

function _wizardRecuar() { _wizardStep--; _renderizarWizardStep(); }

async function _wizardConfirmar() {
  const body = { ..._wizardDados };
  if (!body.distancia_biblioteca) delete body.distancia_biblioteca;
  if (!body.interesses?.length)   delete body.interesses;
  if (!body.disciplinas?.length)  delete body.disciplinas;
  try {
    const res = await post('/api/leitores', body);
    fecharModalLeitor();
    toast(`Leitor criado. Cartão: ${res.num_cartao}`);
    carregarLeitores();
  } catch (err) { mostrarErroLeitor(err.message); }
}

// ── Modal 02-D — Editar leitor ─────────────────
async function abrirModalEditarLeitor(numCartao) {
  abrirModalLeitorBase('Editar Leitor');
  document.getElementById('modal-leitor-conteudo').innerHTML = '<p style="padding:20px;text-align:center;color:#888;font-size:13px">A carregar…</p>';

  let leitor;
  try { leitor = await get(`/api/leitores/${numCartao}`); }
  catch (err) { mostrarErroLeitor(err.message); return; }

  const tipo = leitor.TIPO_LEITOR || 'Adulto';
  let _editInteresses  = leitor.INTERESSES  ? leitor.INTERESSES.map(i => i.INTERESSE || i)  : [];
  let _editDisciplinas = leitor.DISCIPLINAS ? leitor.DISCIPLINAS.map(d => d.DISCIPLINA || d) : [];

  document.getElementById('modal-leitor-conteudo').innerHTML = `
    <div class="form-group">
      <label class="form-label">Nome completo *</label>
      <input id="ef-nome" class="input-field" value="${leitor.NOME_COMPLETO || ''}"/>
    </div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
      <div class="form-group">
        <label class="form-label">Data nascimento</label>
        <input id="ef-data-nasc" type="date" class="input-field" value="${leitor.DATA_NASC ? leitor.DATA_NASC.slice(0,10) : ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Género</label>
        <select id="ef-genero" class="input-field">
          <option value="">—</option>
          <option value="Masculino" ${leitor.GENERO==='Masculino'?'selected':''}>Masculino</option>
          <option value="Feminino"  ${leitor.GENERO==='Feminino'?'selected':''}>Feminino</option>
        </select>
      </div>
    </div>
    <div class="form-group">
      <label class="form-label">Nível escolar</label>
      <input id="ef-nivel-escolar" class="input-field" value="${leitor.NIVEL_ESCOLAR || ''}"/>
    </div>
    <div class="form-group">
      <label class="form-label">Localização</label>
      <textarea id="ef-localizacao" class="input-field" rows="2">${leitor.LOCALIZACAO_LEITOR || ''}</textarea>
    </div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
      <div class="form-group">
        <label class="form-label">Contacto</label>
        <input id="ef-contacto" class="input-field" value="${leitor.CONTACTO || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Distância (km)</label>
        <input id="ef-distancia" type="number" min="0" class="input-field" value="${leitor.DISTANCIA_BIBLIOTECA || ''}"/>
      </div>
    </div>
    ${(tipo === 'Adulto' || tipo === 'Professor') ? `
    <div class="form-group">
      <label class="form-label">Profissão</label>
      <input id="ef-profissao" class="input-field" value="${leitor.PROFISSAO || ''}"/>
    </div>
    <div class="form-group">
      <label class="form-label">Interesses</label>
      <div style="display:flex;gap:6px;margin-bottom:6px">
        <input id="ef-interesse-input" class="input-field" style="flex:1" placeholder="Escrever e adicionar…"/>
        <button type="button" class="btn-secondary btn-sm" onclick="_efAdicionarInteresse()">Adicionar</button>
      </div>
      <div id="ef-interesses-chips" class="chips-wrap"></div>
    </div>` : ''}
    ${tipo === 'Professor' ? `
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
      <div class="form-group">
        <label class="form-label">Escola / Instituto</label>
        <input id="ef-escola-instituto" class="input-field" value="${leitor.ESCOLA_INSTITUTO || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Nível de ensino</label>
        <select id="ef-nivel-ensino" class="input-field">
          <option value="">—</option>
          ${['Pré-escolar','Primário','Secundário','Superior'].map(v=>`<option ${leitor.NIVEL_ENSINO===v?'selected':''}>${v}</option>`).join('')}
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Nº alunos</label>
        <input id="ef-num-alunos" type="number" min="0" class="input-field" value="${leitor.NUM_ALUNOS || ''}"/>
      </div>
    </div>
    <div class="form-group">
      <label class="form-label">Disciplinas</label>
      <div style="display:flex;gap:6px;margin-bottom:6px">
        <input id="ef-disciplina-input" class="input-field" style="flex:1" placeholder="Escrever e adicionar…"/>
        <button type="button" class="btn-secondary btn-sm" onclick="_efAdicionarDisciplina()">Adicionar</button>
      </div>
      <div id="ef-disciplinas-chips" class="chips-wrap"></div>
    </div>` : ''}
    ${tipo === 'Crianca' ? `
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
      <div class="form-group">
        <label class="form-label">Nome responsável</label>
        <input id="ef-nome-responsavel" class="input-field" value="${leitor.NOME_RESPONSAVEL || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Telefone responsável</label>
        <input id="ef-telefone-responsavel" class="input-field" value="${leitor.TELEFONE_RESPONSAVEL || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Escola</label>
        <input id="ef-escola-frequenta" class="input-field" value="${leitor.ESCOLA_FREQUENTA || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Classe</label>
        <input id="ef-classe" class="input-field" value="${leitor.CLASSE || ''}"/>
      </div>
    </div>` : ''}
  `;

  const efRenderInteresses  = () => { const el = document.getElementById('ef-interesses-chips');  if (el) el.innerHTML = _renderChips(_editInteresses,  '_efRemoverInteresse'); };
  const efRenderDisciplinas = () => { const el = document.getElementById('ef-disciplinas-chips'); if (el) el.innerHTML = _renderChips(_editDisciplinas, '_efRemoverDisciplina'); };
  efRenderInteresses(); efRenderDisciplinas();

  window._efAdicionarInteresse  = () => { const inp = document.getElementById('ef-interesse-input');  const v = inp?.value.trim(); if (v && !_editInteresses.includes(v))  { _editInteresses.push(v);  inp.value = ''; } efRenderInteresses(); };
  window._efRemoverInteresse    = (i) => { _editInteresses.splice(i,1);  efRenderInteresses(); };
  window._efAdicionarDisciplina = () => { const inp = document.getElementById('ef-disciplina-input'); const v = inp?.value.trim(); if (v && !_editDisciplinas.includes(v)) { _editDisciplinas.push(v); inp.value = ''; } efRenderDisciplinas(); };
  window._efRemoverDisciplina   = (i) => { _editDisciplinas.splice(i,1); efRenderDisciplinas(); };

  document.getElementById('modal-leitor-footer').innerHTML = `
    <button class="btn-secondary" onclick="fecharModalLeitor()">Cancelar</button>
    <button class="btn-primary"   onclick="_guardarEdicaoLeitor('${numCartao}')">Guardar</button>`;

  window._guardarEdicaoLeitor = async (nc) => {
    const body = {
      nome_completo:        document.getElementById('ef-nome')?.value.trim(),
      data_nasc:            document.getElementById('ef-data-nasc')?.value,
      genero:               document.getElementById('ef-genero')?.value,
      nivel_escolar:        document.getElementById('ef-nivel-escolar')?.value.trim(),
      localizacao_leitor:   document.getElementById('ef-localizacao')?.value.trim(),
      contacto:             document.getElementById('ef-contacto')?.value.trim(),
      distancia_biblioteca: document.getElementById('ef-distancia')?.value || undefined,
    };
    if (!body.nome_completo) { mostrarErroLeitor('Nome completo é obrigatório.'); return; }
    if (tipo === 'Adulto' || tipo === 'Professor') {
      body.profissao   = document.getElementById('ef-profissao')?.value.trim();
      body.interesses  = _editInteresses;
    }
    if (tipo === 'Professor') {
      body.escola_instituto = document.getElementById('ef-escola-instituto')?.value.trim();
      body.nivel_ensino     = document.getElementById('ef-nivel-ensino')?.value;
      body.num_alunos       = document.getElementById('ef-num-alunos')?.value;
      body.disciplinas      = _editDisciplinas;
    }
    if (tipo === 'Crianca') {
      body.nome_responsavel     = document.getElementById('ef-nome-responsavel')?.value.trim();
      body.telefone_responsavel = document.getElementById('ef-telefone-responsavel')?.value.trim();
      body.escola_frequenta     = document.getElementById('ef-escola-frequenta')?.value.trim();
      body.classe               = document.getElementById('ef-classe')?.value.trim();
    }
    try {
      await api(`/api/leitores/${nc}`, { method: 'PATCH', body });
      fecharModalLeitor();
      toast('Leitor actualizado.');
      carregarLeitores();
      if (_drawerNumCartao === nc) { _drawerLeitor = await get(`/api/leitores/${nc}`); _renderizarDrawerConteudo(); }
    } catch (err) { mostrarErroLeitor(err.message); }
  };
}

// ── Modal 02-E — Alterar estado ────────────────
async function abrirModalAlterarStatus(numCartao, statusActual) {
  abrirModalLeitorBase('Alterar Estado');
  document.getElementById('modal-leitor-conteudo').innerHTML = '<p style="padding:20px;text-align:center;color:#888;font-size:13px">A carregar…</p>';

  let leitor;
  try { leitor = await get(`/api/leitores/${numCartao}`); }
  catch (err) { mostrarErroLeitor(err.message); return; }

  const temSuspActive = leitor.SUSPENSOES_ATIVAS && leitor.SUSPENSOES_ATIVAS.length > 0;

  document.getElementById('modal-leitor-conteudo').innerHTML = `
    <div style="margin-bottom:14px">
      <span style="font-size:12px;color:#888">Estado actual: </span>${bdgEstado(statusActual)}
    </div>
    ${temSuspActive ? `<div style="background:#fff0f0;border:1px solid #ffc0c0;border-radius:6px;padding:10px 14px;margin-bottom:14px;font-size:12px;color:#c0392b">
      <i class="fa-solid fa-triangle-exclamation" style="margin-right:6px"></i>
      Este leitor tem <b>${leitor.SUSPENSOES_ATIVAS.length}</b> suspensão(ões) activa(s). Não é possível activar até estas terminarem.
    </div>` : ''}
    <div class="form-group">
      <label class="form-label">Novo estado *</label>
      <select id="st-status" class="input-field">
        <option value="Activo"    ${statusActual==='Activo'?'selected':''}>Activo</option>
        <option value="Suspenso"  ${statusActual==='Suspenso'?'selected':''}>Suspenso</option>
        <option value="Bloqueado" ${statusActual==='Bloqueado'?'selected':''}>Bloqueado</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Observações *</label>
      <textarea id="st-observacoes" class="input-field" rows="3" placeholder="Justificativa obrigatória…"></textarea>
    </div>`;

  document.getElementById('modal-leitor-footer').innerHTML = `
    <button class="btn-secondary" onclick="fecharModalLeitor()">Cancelar</button>
    <button class="btn-primary"   onclick="_confirmarAlterarStatus('${numCartao}',${temSuspActive})">Alterar</button>`;
}

window._confirmarAlterarStatus = async (numCartao, temSuspActive) => {
  const status_leitor = document.getElementById('st-status')?.value;
  const observacoes   = document.getElementById('st-observacoes')?.value.trim();
  if (!observacoes) { mostrarErroLeitor('Observações são obrigatórias.'); return; }
  if (temSuspActive && status_leitor === 'Activo') { mostrarErroLeitor('Não é possível activar um leitor com suspensões activas.'); return; }
  try {
    await api(`/api/leitores/${numCartao}/status`, { method: 'PATCH', body: { status_leitor, observacoes } });
    fecharModalLeitor();
    toast('Estado actualizado.');
    carregarLeitores();
    if (_drawerNumCartao === numCartao) abrirDrawerLeitor(numCartao);
  } catch (err) { mostrarErroLeitor(err.message); }
};

// ── Modal 02-F — Suspensões ────────────────────
async function abrirModalSuspensoes(numCartao) {
  abrirModalLeitorBase('Suspensões do Leitor');
  document.getElementById('modal-leitor-conteudo').innerHTML = '<p style="padding:20px;text-align:center;color:#888;font-size:13px">A carregar…</p>';
  document.getElementById('modal-leitor-footer').innerHTML = `<button class="btn-secondary" onclick="fecharModalLeitor()">Fechar</button>`;

  let suspensoes;
  try { suspensoes = await get(`/api/leitores/${numCartao}/suspensoes?todas=true`); }
  catch (err) { mostrarErroLeitor(err.message); return; }

  if (!suspensoes || !suspensoes.length) {
    document.getElementById('modal-leitor-conteudo').innerHTML = '<p style="padding:20px;text-align:center;color:#888;font-size:13px">Sem suspensões registadas.</p>';
    return;
  }

  document.getElementById('modal-leitor-conteudo').innerHTML = suspensoes.map(s => {
    const isActiva = s.ESTADO_SUSPENSAO === 'Activa';
    return `<div style="background:${isActiva?'#fff4e0':'#f8f9fa'};border:1px solid ${isActiva?'#ffe08a':'#e9ecef'};border-radius:8px;padding:12px 14px;margin-bottom:10px">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
        <span style="font-size:12px;font-weight:600">${fmtData(s.DATA_INICIO)} → ${fmtData(s.DATA_FIM)}</span>
        ${bdgEstado(s.ESTADO_SUSPENSAO)}
      </div>
      <div style="font-size:11px;color:#888">${s.DIAS_SUSPENSAO} dias${s.MOTIVO ? ' · ' + s.MOTIVO : ''}</div>
      ${isActiva ? `
        <div id="reduzir-form-${s.ID_SUSPENSAO}" style="margin-top:10px;display:none">
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:8px">
            <div>
              <label class="form-label" style="font-size:11px">Nova data fim</label>
              <input id="reduzir-data-${s.ID_SUSPENSAO}" type="date" class="input-field" style="font-size:12px"/>
            </div>
            <div>
              <label class="form-label" style="font-size:11px">Justificativa</label>
              <input id="reduzir-obs-${s.ID_SUSPENSAO}" class="input-field" style="font-size:12px" placeholder="Obrigatório"/>
            </div>
          </div>
          <div style="display:flex;gap:6px">
            <button class="btn-primary btn-sm" onclick="_confirmarReduzirSuspensao(${s.ID_SUSPENSAO},'${numCartao}')">Confirmar</button>
            <button class="btn-secondary btn-sm" onclick="document.getElementById('reduzir-form-${s.ID_SUSPENSAO}').style.display='none'">Cancelar</button>
          </div>
        </div>
        <button id="btn-reduzir-${s.ID_SUSPENSAO}" class="btn-secondary btn-sm" style="margin-top:8px;font-size:11px"
          onclick="document.getElementById('reduzir-form-${s.ID_SUSPENSAO}').style.display='block';this.style.display='none'">
          <i class="fa-solid fa-scissors" style="margin-right:4px"></i>Reduzir suspensão
        </button>` : ''}
    </div>`;
  }).join('');
}

window._confirmarReduzirSuspensao = async (idSuspensao, numCartao) => {
  const nova_data_fim = document.getElementById(`reduzir-data-${idSuspensao}`)?.value;
  const observacoes   = document.getElementById(`reduzir-obs-${idSuspensao}`)?.value.trim();
  if (!nova_data_fim) { mostrarErroLeitor('Nova data fim é obrigatória.'); return; }
  if (!observacoes)   { mostrarErroLeitor('Justificativa é obrigatória.'); return; }
  try {
    await api(`/api/suspensoes/${idSuspensao}/reduzir`, { method: 'PATCH', body: { nova_data_fim, observacoes } });
    toast('Suspensão reduzida.');
    abrirModalSuspensoes(numCartao);
  } catch (err) { mostrarErroLeitor(err.message); }
};

// ── Drawer 02-C ────────────────────────────────
async function abrirDrawerLeitor(numCartao) {
  _drawerNumCartao = numCartao;
  _drawerTabActual = 'perfil';
  document.getElementById('drawer-leitor').classList.add('open');
  document.getElementById('drawer-leitor-overlay').style.display = 'block';
  document.getElementById('drawer-leitor-header').innerHTML = '<p style="padding:16px;text-align:center;color:#888;font-size:13px">A carregar…</p>';
  document.getElementById('drawer-leitor-tabs').innerHTML = '';
  document.getElementById('drawer-leitor-conteudo').innerHTML = '';
  try {
    _drawerLeitor = await get(`/api/leitores/${numCartao}`);
    _renderizarDrawerHeader();
    _renderizarDrawerTabs();
    _renderizarDrawerConteudo();
  } catch (err) {
    document.getElementById('drawer-leitor-header').innerHTML = `<p style="color:#c0392b;font-size:12px;padding:10px">${err.message}</p>`;
  }
}

function fecharDrawerLeitor() {
  document.getElementById('drawer-leitor').classList.remove('open');
  document.getElementById('drawer-leitor-overlay').style.display = 'none';
  _drawerNumCartao = null; _drawerLeitor = null;
}

function mudarTabDrawerLeitor(tab) {
  _drawerTabActual = tab;
  document.querySelectorAll('#drawer-leitor-tabs .tab-btn').forEach(b => b.classList.toggle('tab-active', b.dataset.tab === tab));
  _renderizarDrawerConteudo();
}

function _renderizarDrawerHeader() {
  const l = _drawerLeitor;
  document.getElementById('drawer-leitor-header').innerHTML = `
    <div style="display:flex;align-items:center;gap:12px">
      <div style="width:48px;height:48px;border-radius:50%;background:var(--cor-primaria,#1a73e8);color:#fff;display:flex;align-items:center;justify-content:center;font-size:18px;font-weight:700;flex-shrink:0">${iniciais(l.NOME_COMPLETO)}</div>
      <div>
        <div style="font-size:10px;font-family:monospace;color:#888">${l.NUM_CARTAO || '—'}</div>
        <div style="font-size:15px;font-weight:600;color:#111">${l.NOME_COMPLETO || '—'}</div>
        <div style="display:flex;gap:6px;margin-top:4px;flex-wrap:wrap">${bdgTipo(l.TIPO_LEITOR)}${bdgEstado(l.STATUS_LEITOR)}</div>
      </div>
    </div>`;
}

function _renderizarDrawerTabs() {
  const tabs = [
    { id: 'perfil',     label: 'Perfil' },
    { id: 'emprestimo', label: 'Empréstimo' },
    { id: 'historico',  label: 'Histórico' },
    { id: 'suspensoes', label: 'Suspensões' },
    { id: 'multas',     label: 'Multas' },
  ];
  document.getElementById('drawer-leitor-tabs').innerHTML = tabs.map(t =>
    `<button class="tab-btn${t.id===_drawerTabActual?' tab-active':''}" data-tab="${t.id}" onclick="mudarTabDrawerLeitor('${t.id}')">${t.label}</button>`
  ).join('');
}

function _renderizarDrawerConteudo() {
  const l = _drawerLeitor;
  const el = document.getElementById('drawer-leitor-conteudo');

  if (_drawerTabActual === 'perfil') {
    const tipo = l.TIPO_LEITOR;
    let extra = '';
    if (tipo === 'Adulto') {
      extra = [
        l.PROFISSAO          && `<div><b>Profissão:</b> ${l.PROFISSAO}</div>`,
        l.NIVEL_LITERACIA    && `<div><b>Literacia:</b> ${l.NIVEL_LITERACIA}</div>`,
        l.INTERESSES?.length && `<div><b>Interesses:</b> ${l.INTERESSES.map(i=>i.INTERESSE||i).join(', ')}</div>`,
      ].filter(Boolean).join('');
    } else if (tipo === 'Professor') {
      extra = [
        l.ESCOLA_INSTITUTO   && `<div><b>Escola/Instituto:</b> ${l.ESCOLA_INSTITUTO}</div>`,
        l.NIVEL_ENSINO       && `<div><b>Nível ensino:</b> ${l.NIVEL_ENSINO}</div>`,
        l.NUM_ALUNOS         && `<div><b>Nº alunos:</b> ${l.NUM_ALUNOS}</div>`,
        l.DISCIPLINAS?.length && `<div><b>Disciplinas:</b> ${l.DISCIPLINAS.map(d=>d.DISCIPLINA||d).join(', ')}</div>`,
        l.INTERESSES?.length && `<div><b>Interesses:</b> ${l.INTERESSES.map(i=>i.INTERESSE||i).join(', ')}</div>`,
      ].filter(Boolean).join('');
    } else if (tipo === 'Crianca') {
      extra = [
        l.NOME_RESPONSAVEL      && `<div><b>Responsável:</b> ${l.NOME_RESPONSAVEL}</div>`,
        l.TELEFONE_RESPONSAVEL  && `<div><b>Tel. responsável:</b> ${l.TELEFONE_RESPONSAVEL}</div>`,
        l.ESCOLA_FREQUENTA      && `<div><b>Escola:</b> ${l.ESCOLA_FREQUENTA}</div>`,
        l.CLASSE                && `<div><b>Classe:</b> ${l.CLASSE}</div>`,
      ].filter(Boolean).join('');
    }
    el.innerHTML = `<div style="font-size:13px;line-height:2;color:#333">
      <div style="margin-bottom:6px">${bdgPontualidade(l.HISTORICO_PONTUALIDADE)} <span style="font-size:11px;color:#888">pontualidade</span></div>
      ${l.DATA_NASC           ? `<div><b>Nascimento:</b> ${fmtData(l.DATA_NASC)}</div>` : ''}
      ${l.GENERO              ? `<div><b>Género:</b> ${l.GENERO}</div>` : ''}
      ${l.NIVEL_ESCOLAR       ? `<div><b>Nível escolar:</b> ${l.NIVEL_ESCOLAR}</div>` : ''}
      ${l.LOCALIZACAO_LEITOR  ? `<div><b>Localização:</b> ${l.LOCALIZACAO_LEITOR}</div>` : ''}
      ${l.CONTACTO            ? `<div><b>Contacto:</b> ${l.CONTACTO}</div>` : ''}
      ${l.NOME_BIBLIOTECA     ? `<div><b>Biblioteca:</b> ${l.NOME_BIBLIOTECA}</div>` : ''}
      ${extra}
    </div>`;

  } else if (_drawerTabActual === 'emprestimo') {
    const emp = l.EMPRESTIMO_ATIVO;
    if (!emp) {
      el.innerHTML = '<div style="text-align:center;padding:30px;color:#aaa;font-size:13px"><i class="fa-solid fa-book-open" style="font-size:28px;display:block;margin-bottom:8px"></i>Sem empréstimo activo</div>';
    } else {
      const hoje  = new Date();
      const prazo = new Date(emp.PRAZO_DEVOLUCAO || emp.DATA_PRAZO);
      const dias  = Math.round((prazo - hoje) / 86400000);
      const diasStr = dias >= 0
        ? `<span style="color:#2d9b4e;font-weight:600">${dias} dia(s) restante(s)</span>`
        : `<span style="color:#e74c3c;font-weight:600">Atrasado ${Math.abs(dias)} dia(s)</span>`;
      el.innerHTML = `<div style="background:#f8f9fa;border-radius:8px;padding:14px;font-size:13px;line-height:2">
        <div style="font-weight:600;font-size:14px;margin-bottom:6px">${emp.TITULO || emp.NOME_MATERIAL || '—'}</div>
        <div><b>Retirada:</b> ${fmtData(emp.DATA_RETIRADA)}</div>
        <div><b>Prazo:</b> ${fmtData(emp.PRAZO_DEVOLUCAO || emp.DATA_PRAZO)}</div>
        <div>${diasStr}</div>
      </div>`;
    }

  } else if (_drawerTabActual === 'historico') {
    const hist = l.HISTORICO || [];
    if (!hist.length) {
      el.innerHTML = '<div style="text-align:center;padding:30px;color:#aaa;font-size:13px">Sem histórico.</div>';
    } else {
      el.innerHTML = `<div style="overflow-x:auto"><table class="tbl" style="font-size:11px">
        <thead><tr><th>Material</th><th>Retirada</th><th>Devolução</th><th>Atraso</th><th>Multa</th><th>Paga</th></tr></thead>
        <tbody>${hist.map(h => `<tr>
          <td style="max-width:120px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${h.TITULO||h.NOME_MATERIAL||'—'}</td>
          <td>${fmtData(h.DATA_RETIRADA)}</td>
          <td>${fmtData(h.DATA_DEVOLUCAO)}</td>
          <td>${h.DIAS_ATRASO||0}</td>
          <td>${fmtMoeda(h.VALOR_MULTA)}</td>
          <td>${h.MULTA_PAGA==='S'||h.MULTA_PAGA===true?'Sim':h.VALOR_MULTA?'Não':'—'}</td>
        </tr>`).join('')}</tbody>
      </table></div>`;
    }

  } else if (_drawerTabActual === 'suspensoes') {
    const susps = l.SUSPENSOES_ATIVAS || [];
    if (!susps.length) {
      el.innerHTML = '<div style="text-align:center;padding:30px;color:#aaa;font-size:13px">Sem suspensões activas.</div>';
    } else {
      el.innerHTML = susps.map(s => `
        <div style="background:${s.ESTADO_SUSPENSAO==='Activa'?'#fff4e0':'#f8f9fa'};border:1px solid #e0e0e0;border-radius:8px;padding:10px 12px;margin-bottom:8px;font-size:12px">
          <div style="display:flex;justify-content:space-between;align-items:center">
            <span>${fmtData(s.DATA_INICIO)} → ${fmtData(s.DATA_FIM)}</span>${bdgEstado(s.ESTADO_SUSPENSAO)}
          </div>
          <div style="color:#888;margin-top:3px">${s.DIAS_SUSPENSAO} dias</div>
        </div>`).join('');
    }

  } else if (_drawerTabActual === 'multas') {
    const nivel    = utilizadorActual?.NIVEL_ACESSO || '';
    const podePagar = ['Administrador','Coordenador','Bibliotecario'].includes(nivel);
    const multas   = (l.HISTORICO || []).filter(h => (h.MULTA_PAGA === 'N' || h.MULTA_PAGA === false) && h.VALOR_MULTA);
    if (!multas.length) {
      el.innerHTML = '<div style="text-align:center;padding:30px;color:#aaa;font-size:13px">Sem multas em aberto.</div>';
    } else {
      const total = multas.reduce((s, h) => s + parseFloat(h.VALOR_MULTA || 0), 0);
      el.innerHTML = multas.map(h => `
        <div style="display:flex;align-items:center;justify-content:space-between;padding:8px 0;border-bottom:1px solid #f0f0f0;font-size:12px">
          <div>
            <div style="font-weight:500">${h.TITULO||h.NOME_MATERIAL||'—'}</div>
            <div style="color:#888">${fmtData(h.DATA_RETIRADA)}</div>
          </div>
          <div style="display:flex;align-items:center;gap:8px">
            <span style="font-weight:600;color:#c0392b">${fmtMoeda(h.VALOR_MULTA)}</span>
            ${podePagar ? `<button class="btn-secondary btn-sm" onclick="_marcarMultaPaga(${h.ID_EMPRESTIMO},'${_drawerNumCartao}')">Marcar paga</button>` : ''}
          </div>
        </div>`).join('')
        + `<div style="text-align:right;padding-top:10px;font-size:13px;font-weight:700;color:#c0392b">Total: ${fmtMoeda(total)}</div>`;
    }
  }
}

window._marcarMultaPaga = async (idEmprestimo, numCartao) => {
  try {
    await api(`/api/emprestimos/${idEmprestimo}/pagar-multa`, { method: 'PATCH', body: {} });
    toast('Multa marcada como paga.');
    _drawerLeitor = await get(`/api/leitores/${numCartao}`);
    _renderizarDrawerConteudo();
    carregarLeitores();
  } catch (err) { toast(err.message, 'erro'); }
};

// ── Eliminar leitor ────────────────────────────
async function confirmarEliminarLeitor(nc, nome) {
  confirmar(`Apagar o leitor "${nome}"? Esta acção é irreversível.`, async () => {
    try {
      await del(`/api/leitores/${nc}`);
      toast('Leitor eliminado.');
      carregarLeitores();
    } catch (err) {
      toast(err.message, 'erro');
    }
  });
}

// ════════════════════════════════════════════════
// MATERIAIS
// ════════════════════════════════════════════════
async function carregarMateriais() {
  const q           = document.getElementById('filtro-mat-q')?.value || '';
  const tipo        = document.getElementById('filtro-mat-tipo')?.value || '';
  const conservacao = document.getElementById('filtro-mat-conservacao')?.value || '';
  const disponivel  = document.getElementById('filtro-mat-disponivel')?.value || '';
  const params = new URLSearchParams();
  if (q)           params.set('q', q);
  if (tipo)        params.set('tipo', tipo);
  if (conservacao) params.set('conservacao', conservacao);
  if (disponivel)  params.set('disponivel', disponivel);
  try {
    const rows = await get(`/api/materiais?${params}`);
    const tbody = document.getElementById('tabela-materiais');
    tbody.innerHTML = rows.length
      ? rows.map(r => {
          const dispBadge = r.DISPONIVEL_EMPRESTIMO === 'S'
            ? '<span class="badge badge-verde">Disponível</span>'
            : '<span class="badge badge-vermelho">Indisponível</span>';
          return `
        <tr>
          <td class="text-slate-500 text-xs">${r.ID_MATERIAL}</td>
          <td class="font-medium max-w-[200px] truncate">${r.TITULO || '—'}</td>
          <td class="text-slate-400">${r.AUTOR || '—'}</td>
          <td>${badgeTipo(r.TIPO)}</td>
          <td>${badgeEstado(r.ESTADO)} ${dispBadge}</td>
          <td class="space-x-2">
            <button onclick="abrirModalMaterial(${r.ID_MATERIAL})" class="btn-secondary btn-sm"><i class="fa-solid fa-pen mr-1"></i>Editar</button>
            <button onclick="eliminarMaterial(${r.ID_MATERIAL})" class="btn-danger btn-sm"><i class="fa-solid fa-trash mr-1"></i>Apagar</button>
          </td>
        </tr>`;
        }).join('')
      : linhaVazia(6);
  } catch (err) {
    toast('Erro a carregar materiais: ' + err.message, 'erro');
  }
}

async function abrirModalMaterial(id = null) {
  document.getElementById('modal-titulo').textContent = id ? 'Editar Material' : 'Novo Material';
  document.getElementById('modal-erro').classList.add('hidden');

  let cats = [];
  try { cats = await get('/api/materiais/categorias'); } catch {}

  document.getElementById('modal-conteudo').innerHTML = `
    <div class="grid grid-cols-2 gap-3">
      <div class="col-span-2">
        <label class="label-dark">Título *</label>
        <input id="mf-titulo" class="input-dark w-full" placeholder="Título do material"/>
      </div>
      <div>
        <label class="label-dark">Autor</label>
        <input id="mf-autor" class="input-dark w-full"/>
      </div>
      <div>
        <label class="label-dark">Ano Publicação</label>
        <input id="mf-ano" type="number" class="input-dark w-full" placeholder="2024"/>
      </div>
      <div>
        <label class="label-dark">ISBN</label>
        <input id="mf-isbn" class="input-dark w-full"/>
      </div>
      <div>
        <label class="label-dark">Tipo *</label>
        <select id="mf-tipo" class="input-dark w-full" onchange="toggleCamposMaterial()">
          <option value="LIVRO_FISICO">Livro Físico</option>
          <option value="EBOOK">Ebook</option>
          <option value="PERIODICO">Periódico</option>
        </select>
      </div>
      <div class="col-span-2">
        <label class="label-dark">Categoria</label>
        <select id="mf-categoria" class="input-dark w-full">
          <option value="">Sem categoria</option>
          ${cats.map(c => `<option value="${c.ID_CATEGORIA}">${c.NOME}</option>`).join('')}
        </select>
      </div>
      ${id ? `<div class="col-span-2">
        <label class="label-dark">Estado</label>
        <select id="mf-estado" class="input-dark w-full">
          <option value="DISPONIVEL">Disponível</option>
          <option value="EMPRESTADO">Emprestado</option>
          <option value="INDISPONIVEL">Indisponível</option>
        </select>
      </div>` : ''}
    </div>

    <div id="campos-livro" class="mt-3 grid grid-cols-2 gap-3">
      <div class="col-span-2">
        <label class="label-dark">Localização</label>
        <input id="mf-localizacao" class="input-dark w-full" placeholder="Prateleira A-12"/>
      </div>
      <div class="col-span-2">
        <label class="label-dark">Condição</label>
        <select id="mf-condicao" class="input-dark w-full">
          <option value="BOM">Bom</option>
          <option value="RAZOAVEL">Razoável</option>
          <option value="MAU">Mau</option>
        </select>
      </div>
    </div>
    <div id="campos-ebook" class="mt-3 grid grid-cols-2 gap-3 hidden">
      <div>
        <label class="label-dark">Formato</label>
        <select id="mf-formato" class="input-dark w-full">
          <option value="PDF">PDF</option>
          <option value="EPUB">EPUB</option>
          <option value="MOBI">MOBI</option>
        </select>
      </div>
      <div>
        <label class="label-dark">Tamanho (MB)</label>
        <input id="mf-tamanho" type="number" class="input-dark w-full" placeholder="5.2"/>
      </div>
      <div class="col-span-2">
        <label class="label-dark">URL de Acesso</label>
        <input id="mf-url" class="input-dark w-full" placeholder="https://..."/>
      </div>
    </div>
    <div id="campos-periodico" class="mt-3 grid grid-cols-2 gap-3 hidden">
      <div>
        <label class="label-dark">Volume</label>
        <input id="mf-volume" class="input-dark w-full"/>
      </div>
      <div>
        <label class="label-dark">Nº Edição</label>
        <input id="mf-edicao" class="input-dark w-full"/>
      </div>
      <div>
        <label class="label-dark">ISSN</label>
        <input id="mf-issn" class="input-dark w-full"/>
      </div>
      <div>
        <label class="label-dark">Periodicidade</label>
        <select id="mf-periodicidade" class="input-dark w-full">
          <option value="">—</option>
          <option value="DIARIA">Diária</option>
          <option value="SEMANAL">Semanal</option>
          <option value="MENSAL">Mensal</option>
          <option value="TRIMESTRAL">Trimestral</option>
          <option value="ANUAL">Anual</option>
        </select>
      </div>
    </div>
  `;

  if (id) {
    get(`/api/materiais/${id}`).then(m => {
      document.getElementById('mf-titulo').value = m.TITULO || '';
      document.getElementById('mf-autor').value = m.AUTOR || '';
      document.getElementById('mf-ano').value = m.ANO_PUB || '';
      document.getElementById('mf-isbn').value = m.ISBN || '';
      document.getElementById('mf-tipo').value = m.TIPO || 'LIVRO_FISICO';
      if (m.ID_CATEGORIA) document.getElementById('mf-categoria').value = m.ID_CATEGORIA;
      if (m.ESTADO) document.getElementById('mf-estado').value = m.ESTADO;
      document.getElementById('mf-localizacao').value = m.LOCALIZACAO || '';
      if (m.CONDICAO) document.getElementById('mf-condicao').value = m.CONDICAO;
      document.getElementById('mf-formato').value = m.FORMATO || 'PDF';
      document.getElementById('mf-tamanho').value = m.TAMANHO_MB || '';
      document.getElementById('mf-url').value = m.URL_ACESSO || '';
      document.getElementById('mf-volume').value = m.VOLUME || '';
      document.getElementById('mf-edicao').value = m.NUMERO_EDICAO || '';
      document.getElementById('mf-issn').value = m.ISSN || '';
      if (m.PERIODICIDADE) document.getElementById('mf-periodicidade').value = m.PERIODICIDADE;
      toggleCamposMaterial();
    }).catch(err => mostrarErroModal(err.message));
  }

  toggleCamposMaterial();

  modalSalvarFn = async () => {
    const tipo = document.getElementById('mf-tipo').value;
    const body = {
      titulo: document.getElementById('mf-titulo').value,
      autor: document.getElementById('mf-autor').value,
      ano_pub: document.getElementById('mf-ano').value,
      isbn: document.getElementById('mf-isbn').value,
      id_categoria: document.getElementById('mf-categoria').value || null,
      tipo,
      estado: document.getElementById('mf-estado')?.value,
      localizacao: document.getElementById('mf-localizacao')?.value,
      condicao: document.getElementById('mf-condicao')?.value,
      formato: document.getElementById('mf-formato')?.value,
      tamanho_mb: document.getElementById('mf-tamanho')?.value,
      url_acesso: document.getElementById('mf-url')?.value,
      volume: document.getElementById('mf-volume')?.value,
      numero_edicao: document.getElementById('mf-edicao')?.value,
      issn: document.getElementById('mf-issn')?.value,
      periodicidade: document.getElementById('mf-periodicidade')?.value,
    };
    if (!body.titulo) { mostrarErroModal('Título é obrigatório.'); return; }
    if (id) await put(`/api/materiais/${id}`, body);
    else    await post('/api/materiais', body);
    fecharModal();
    toast(id ? 'Material actualizado.' : 'Material criado com sucesso.');
    carregarMateriais();
  };

  abrirModal();
}

function toggleCamposMaterial() {
  const tipo = document.getElementById('mf-tipo')?.value;
  document.getElementById('campos-livro').classList.toggle('hidden', tipo !== 'LIVRO_FISICO');
  document.getElementById('campos-ebook').classList.toggle('hidden', tipo !== 'EBOOK');
  document.getElementById('campos-periodico').classList.toggle('hidden', tipo !== 'PERIODICO');
}

async function eliminarMaterial(id) {
  confirmar('Apagar este material? Esta acção é irreversível.', async () => {
    try {
      await del(`/api/materiais/${id}`);
      toast('Material eliminado.');
      carregarMateriais();
    } catch (err) {
      toast(err.message, 'erro');
    }
  });
}

// ════════════════════════════════════════════════
// EMPRÉSTIMOS
// ════════════════════════════════════════════════
let tabEmprestimosActual = 'ACTIVO';

function switchTabEmprestimos(tab) {
  tabEmprestimosActual = tab;
  document.getElementById('tab-emp-ativos').classList.toggle('tab-active', tab === 'ACTIVO');
  document.getElementById('tab-emp-hist').classList.toggle('tab-active', tab === 'HISTORICO');
  carregarEmprestimos(tab);
}

async function carregarEmprestimos(estado = 'ACTIVO') {
  try {
    const rows = await get(`/api/emprestimos?estado=${estado}`);
    const tbody = document.getElementById('tabela-emprestimos');
    tbody.innerHTML = rows.length
      ? rows.map(r => {
          const atrasado = r.DIAS_ATRASO > 0;
          return `<tr class="${atrasado ? 'bg-red-950/20' : ''}">
            <td class="text-slate-500 text-xs">${r.ID_EMPRESTIMO}</td>
            <td>${r.NOME_LEITOR || r.NUM_CARTAO || '—'}</td>
            <td class="max-w-[150px] truncate">${r.TITULO || r.ID_MATERIAL || '—'}</td>
            <td class="text-slate-400">${fmtData(r.DATA_EMP)}</td>
            <td class="${atrasado ? 'text-red-400' : 'text-slate-400'}">${fmtData(r.DATA_DEVOLUCAO_PREV)}</td>
            <td class="text-amber-400">${r.MULTA || r.MULTA_ATUAL ? fmtMoeda(r.MULTA || r.MULTA_ATUAL) : '—'}</td>
            <td>${badgeEstado(r.ESTADO)}</td>
            <td>
              ${r.ESTADO === 'ACTIVO' || r.ESTADO === 'ATIVO'
                ? `<button onclick="abrirModalDevolucao(${r.ID_EMPRESTIMO}, '${(r.NOME_LEITOR||'').replace(/'/g,"\\'")}', '${(r.TITULO||'').replace(/'/g,"\\'")}', ${r.MULTA_ATUAL||0})" class="btn-primary btn-sm"><i class="fa-solid fa-rotate-left mr-1"></i>Devolver</button>`
                : ''}
            </td>
          </tr>`;
        }).join('')
      : linhaVazia(8);
  } catch (err) {
    toast('Erro a carregar empréstimos: ' + err.message, 'erro');
  }
}

function abrirModalEmprestimo() {
  document.getElementById('modal-titulo').textContent = 'Registar Empréstimo';
  document.getElementById('modal-erro').classList.add('hidden');

  document.getElementById('modal-conteudo').innerHTML = `
    <div class="space-y-3">
      <div>
        <label class="label-dark">Nº Cartão do Leitor *</label>
        <input id="ef-cartao" class="input-dark w-full" placeholder="Ex: ABC2024XXXXX"/>
      </div>
      <div>
        <label class="label-dark">ID do Material *</label>
        <input id="ef-material" type="number" class="input-dark w-full" placeholder="Ex: 12"/>
      </div>
      <div>
        <label class="label-dark">Data Prevista de Devolução</label>
        <input id="ef-data-dev" type="date" class="input-dark w-full"/>
      </div>
    </div>
  `;

  // Pré-preencher data prevista (+15 dias)
  const dataPrev = new Date();
  dataPrev.setDate(dataPrev.getDate() + 15);
  document.getElementById('ef-data-dev').value = dataPrev.toISOString().slice(0,10);

  modalSalvarFn = async () => {
    const body = {
      num_cartao: document.getElementById('ef-cartao').value,
      id_material: document.getElementById('ef-material').value,
      data_devolucao_prev: document.getElementById('ef-data-dev').value,
      id_funcionario: utilizadorActual?.ID_FUNCIONARIO,
    };
    if (!body.num_cartao || !body.id_material) {
      mostrarErroModal('Cartão e material são obrigatórios.');
      return;
    }
    await post('/api/emprestimos', body);
    fecharModal();
    toast('Empréstimo registado com sucesso.');
    carregarEmprestimos('ACTIVO');
  };

  abrirModal();
}

function abrirModalDevolucao(id, leitor, titulo, multaActual) {
  emprestimoDevolverID = id;
  document.getElementById('dev-info').textContent = `Leitor: ${leitor} | Material: ${titulo}`;
  const multaEl = document.getElementById('dev-multa-info');
  if (multaActual > 0) {
    multaEl.textContent = `Multa actual: ${fmtMoeda(multaActual)}`;
    multaEl.classList.remove('hidden');
  } else {
    multaEl.classList.add('hidden');
  }
  document.getElementById('modal-devolucao').classList.remove('hidden');
}

function fecharModalDevolucao() {
  document.getElementById('modal-devolucao').classList.add('hidden');
  emprestimoDevolverID = null;
}

async function confirmarDevolucao() {
  if (!emprestimoDevolverID) return;
  const condicao = document.getElementById('dev-condicao').value;
  try {
    const res = await put(`/api/emprestimos/${emprestimoDevolverID}/devolver`, { condicao_devolucao: condicao });
    fecharModalDevolucao();
    const multa = res.MULTA || 0;
    toast(`Devolução registada.${multa > 0 ? ` Multa: ${fmtMoeda(multa)}` : ''}`);
    carregarEmprestimos(tabEmprestimosActual);
  } catch (err) {
    toast(err.message, 'erro');
  }
}

// ════════════════════════════════════════════════
// FUNCIONÁRIOS
// ════════════════════════════════════════════════
async function carregarFuncionarios() {
  try {
    const rows = await get('/api/funcionarios');
    const tbody = document.getElementById('tabela-funcionarios');
    tbody.innerHTML = rows.length
      ? rows.map(r => `
        <tr>
          <td class="text-slate-500 text-xs">${r.ID_FUNCIONARIO}</td>
          <td class="font-medium">${r.NOME || '—'}</td>
          <td class="text-slate-400">${r.EMAIL || '—'}</td>
          <td>${r.FUNCAO || r.DESCRICAO || '—'}</td>
          <td class="text-slate-400">${r.NOME_BIBLIOTECA || '—'}</td>
          <td class="space-x-2">
            <button onclick="abrirModalFuncionario(${r.ID_FUNCIONARIO})" class="btn-secondary btn-sm"><i class="fa-solid fa-pen mr-1"></i>Editar</button>
            <button onclick="desactivarFuncionario(${r.ID_FUNCIONARIO})" class="btn-danger btn-sm"><i class="fa-solid fa-user-slash mr-1"></i>Desactivar</button>
          </td>
        </tr>`).join('')
      : linhaVazia(6);
  } catch (err) {
    toast('Erro a carregar funcionários: ' + err.message, 'erro');
  }
}

async function abrirModalFuncionario(id = null) {
  document.getElementById('modal-titulo').textContent = id ? 'Editar Funcionário' : 'Novo Funcionário';
  document.getElementById('modal-erro').classList.add('hidden');

  let funcoes = [], bibliotecas = [];
  try { funcoes = await get('/api/funcionarios/funcoes'); } catch {}
  try { bibliotecas = await get('/api/funcionarios/bibliotecas'); } catch {}

  document.getElementById('modal-conteudo').innerHTML = `
    <div class="space-y-3">
      <div>
        <label class="label-dark">Nome *</label>
        <input id="ff-nome" class="input-dark w-full"/>
      </div>
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label-dark">Email *</label>
          <input id="ff-email" type="email" class="input-dark w-full"/>
        </div>
        <div>
          <label class="label-dark">Contacto</label>
          <input id="ff-contacto" class="input-dark w-full"/>
        </div>
      </div>
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label-dark">${id ? 'Nova Senha (deixar vazio = manter)' : 'Senha *'}</label>
          <input id="ff-senha" type="password" class="input-dark w-full"/>
        </div>
        <div>
          <label class="label-dark">Data Admissão</label>
          <input id="ff-data-adm" type="date" class="input-dark w-full"/>
        </div>
      </div>
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label-dark">Função</label>
          <select id="ff-funcao" class="input-dark w-full">
            <option value="">— Seleccionar —</option>
            ${funcoes.map(f => `<option value="${f.ID_FUNCAO}">${f.DESCRICAO}</option>`).join('')}
          </select>
        </div>
        <div>
          <label class="label-dark">Biblioteca</label>
          <select id="ff-biblioteca" class="input-dark w-full">
            <option value="">— Seleccionar —</option>
            ${bibliotecas.map(b => `<option value="${b.ID_BIBLIOTECA}">${b.NOME}</option>`).join('')}
          </select>
        </div>
      </div>
    </div>
  `;

  if (id) {
    get(`/api/funcionarios/${id}`).then(f => {
      document.getElementById('ff-nome').value = f.NOME || '';
      document.getElementById('ff-email').value = f.EMAIL || '';
      document.getElementById('ff-contacto').value = f.CONTACTO || '';
      if (f.DATA_ADMISSAO) document.getElementById('ff-data-adm').value = f.DATA_ADMISSAO.slice(0,10);
      if (f.ID_FUNCAO) document.getElementById('ff-funcao').value = f.ID_FUNCAO;
      if (f.ID_BIBLIOTECA) document.getElementById('ff-biblioteca').value = f.ID_BIBLIOTECA;
    }).catch(err => mostrarErroModal(err.message));
  }

  modalSalvarFn = async () => {
    const body = {
      nome: document.getElementById('ff-nome').value,
      email: document.getElementById('ff-email').value,
      contacto: document.getElementById('ff-contacto').value,
      senha: document.getElementById('ff-senha').value || undefined,
      data_admissao: document.getElementById('ff-data-adm').value,
      id_funcao: document.getElementById('ff-funcao').value || null,
      id_biblioteca: document.getElementById('ff-biblioteca').value || null,
    };
    if (!body.nome || !body.email) { mostrarErroModal('Nome e email são obrigatórios.'); return; }
    if (!id && !body.senha) { mostrarErroModal('Senha é obrigatória.'); return; }
    if (id) await put(`/api/funcionarios/${id}`, body);
    else    await post('/api/funcionarios', body);
    fecharModal();
    toast(id ? 'Funcionário actualizado.' : 'Funcionário criado.');
    carregarFuncionarios();
  };

  abrirModal();
}

async function desactivarFuncionario(id) {
  confirmar('Desactivar este funcionário?', async () => {
    try {
      await del(`/api/funcionarios/${id}`);
      toast('Funcionário desactivado.');
      carregarFuncionarios();
    } catch (err) {
      toast(err.message, 'erro');
    }
  });
}

// ════════════════════════════════════════════════
// EVENTOS
// ════════════════════════════════════════════════
async function carregarEventos() {
  try {
    const rows = await get('/api/eventos');
    const tbody = document.getElementById('tabela-eventos');
    tbody.innerHTML = rows.length
      ? rows.map(r => `
        <tr>
          <td class="font-medium max-w-[180px] truncate">${r.NOME || '—'}</td>
          <td class="text-slate-400">${fmtData(r.DATA_INICIO)}</td>
          <td>${r.TIPO ? badge(r.TIPO, 'azul') : '—'}</td>
          <td class="text-slate-400">${r.PUBLICO_ALVO || '—'}</td>
          <td class="text-slate-400">${r.INSCRITOS ?? '—'}/${r.CAPACIDADE ?? '∞'}</td>
          <td class="text-slate-400 text-sm">${r.NOME_BIBLIOTECA || '—'}</td>
          <td class="whitespace-nowrap">
            <div class="flex flex-wrap gap-1">
              <button onclick="abrirModalParticipacoes(${r.ID_EVENTO})" class="btn-secondary btn-sm"><i class="fa-solid fa-users mr-1"></i>Participantes</button>
              <button onclick="abrirModalEvento(${r.ID_EVENTO})" class="btn-secondary btn-sm"><i class="fa-solid fa-pen mr-1"></i>Editar</button>
              <button onclick="eliminarEvento(${r.ID_EVENTO})" class="btn-danger btn-sm"><i class="fa-solid fa-trash mr-1"></i>Apagar</button>
            </div>
          </td>
        </tr>`).join('')
      : linhaVazia(7);
  } catch (err) {
    toast('Erro a carregar eventos: ' + err.message, 'erro');
  }
}

async function abrirModalEvento(id = null) {
  document.getElementById('modal-titulo').textContent = id ? 'Editar Evento' : 'Novo Evento';
  document.getElementById('modal-erro').classList.add('hidden');

  let bibliotecas = [];
  try { bibliotecas = await get('/api/funcionarios/bibliotecas'); } catch {}

  document.getElementById('modal-conteudo').innerHTML = `
    <div class="space-y-3">
      <div>
        <label class="label-dark">Nome do Evento *</label>
        <input id="evf-nome" class="input-dark w-full"/>
      </div>
      <div>
        <label class="label-dark">Descrição</label>
        <textarea id="evf-desc" class="input-dark w-full h-20 resize-none"></textarea>
      </div>
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label-dark">Data Início *</label>
          <input id="evf-inicio" type="date" class="input-dark w-full"/>
        </div>
        <div>
          <label class="label-dark">Data Fim</label>
          <input id="evf-fim" type="date" class="input-dark w-full"/>
        </div>
        <div>
          <label class="label-dark">Capacidade</label>
          <input id="evf-cap" type="number" class="input-dark w-full" placeholder="Ex: 50"/>
        </div>
        <div>
          <label class="label-dark">Tipo</label>
          <select id="evf-tipo" class="input-dark w-full">
            <option value="">—</option>
            <option value="WORKSHOP">Workshop</option>
            <option value="LEITURA">Leitura</option>
            <option value="PALESTRA">Palestra</option>
            <option value="EXPOSICAO">Exposição</option>
            <option value="OUTRO">Outro</option>
          </select>
        </div>
        <div>
          <label class="label-dark">Público-Alvo</label>
          <select id="evf-publico" class="input-dark w-full">
            <option value="">Geral</option>
            <option value="CRIANCA">Crianças</option>
            <option value="ADULTO">Adultos</option>
            <option value="PROFESSOR">Professores</option>
          </select>
        </div>
        <div>
          <label class="label-dark">Recorrente</label>
          <select id="evf-recorrente" class="input-dark w-full">
            <option value="0">Não</option>
            <option value="1">Semanal</option>
            <option value="2">Mensal</option>
          </select>
        </div>
      </div>
      <div>
        <label class="label-dark">Biblioteca</label>
        <select id="evf-biblioteca" class="input-dark w-full">
          <option value="">— Seleccionar —</option>
          ${bibliotecas.map(b => `<option value="${b.ID_BIBLIOTECA}">${b.NOME}</option>`).join('')}
        </select>
      </div>
    </div>
  `;

  if (id) {
    get(`/api/eventos/${id}`).then(ev => {
      document.getElementById('evf-nome').value = ev.NOME || '';
      document.getElementById('evf-desc').value = ev.DESCRICAO || '';
      if (ev.DATA_INICIO) document.getElementById('evf-inicio').value = ev.DATA_INICIO.slice(0,10);
      if (ev.DATA_FIM) document.getElementById('evf-fim').value = ev.DATA_FIM.slice(0,10);
      document.getElementById('evf-cap').value = ev.CAPACIDADE || '';
      if (ev.TIPO) document.getElementById('evf-tipo').value = ev.TIPO;
      if (ev.PUBLICO_ALVO) document.getElementById('evf-publico').value = ev.PUBLICO_ALVO;
      document.getElementById('evf-recorrente').value = ev.RECORRENTE || 0;
      if (ev.ID_BIBLIOTECA) document.getElementById('evf-biblioteca').value = ev.ID_BIBLIOTECA;
    }).catch(err => mostrarErroModal(err.message));
  }

  modalSalvarFn = async () => {
    const body = {
      nome: document.getElementById('evf-nome').value,
      descricao: document.getElementById('evf-desc').value,
      data_inicio: document.getElementById('evf-inicio').value,
      data_fim: document.getElementById('evf-fim').value,
      capacidade: document.getElementById('evf-cap').value || null,
      tipo: document.getElementById('evf-tipo').value,
      publico_alvo: document.getElementById('evf-publico').value,
      recorrente: document.getElementById('evf-recorrente').value,
      id_biblioteca: document.getElementById('evf-biblioteca').value || null,
    };
    if (!body.nome || !body.data_inicio) { mostrarErroModal('Nome e data de início são obrigatórios.'); return; }
    if (id) await put(`/api/eventos/${id}`, body);
    else    await post('/api/eventos', body);
    fecharModal();
    toast(id ? 'Evento actualizado.' : 'Evento criado.');
    carregarEventos();
  };

  abrirModal();
}

async function eliminarEvento(id) {
  confirmar('Apagar este evento? Esta acção é irreversível.', async () => {
    try {
      await del(`/api/eventos/${id}`);
      toast('Evento eliminado.');
      carregarEventos();
    } catch (err) {
      toast(err.message, 'erro');
    }
  });
}

async function abrirModalParticipacoes(idEvento) {
  eventoActualId = idEvento;
  await carregarParticipacoes();
  document.getElementById('modal-participacoes').classList.remove('hidden');
}

function fecharModalParticipacoes() {
  document.getElementById('modal-participacoes').classList.add('hidden');
  eventoActualId = null;
}

async function carregarParticipacoes() {
  if (!eventoActualId) return;
  try {
    const rows = await get(`/api/eventos/${eventoActualId}/participacoes`);
    const lista = document.getElementById('lista-participacoes');
    lista.innerHTML = rows.length
      ? rows.map(p => `
          <div class="flex items-center justify-between py-2 border-b border-slate-700">
            <div>
              <span class="font-medium text-sm">${p.NOME_LEITOR || '—'}</span>
              <span class="text-slate-500 text-xs ml-2">${p.NUM_CARTAO}</span>
            </div>
            <button onclick="removerParticipacao('${p.NUM_CARTAO}')" class="btn-danger btn-sm"><i class="fa-solid fa-user-minus mr-1"></i>Remover</button>
          </div>`).join('')
      : '<p class="text-slate-500 text-sm">Sem participantes inscritos.</p>';
  } catch (err) {
    toast('Erro: ' + err.message, 'erro');
  }
}

async function inscreverLeitorEvento() {
  const nc = document.getElementById('input-nc-inscricao').value.trim();
  if (!nc || !eventoActualId) return;
  try {
    await post(`/api/eventos/${eventoActualId}/participacoes`, { num_cartao: nc });
    document.getElementById('input-nc-inscricao').value = '';
    toast('Leitor inscrito com sucesso.');
    await carregarParticipacoes();
  } catch (err) {
    toast(err.message, 'erro');
  }
}

async function removerParticipacao(numCartao) {
  if (!eventoActualId) return;
  confirmar('Remover esta inscrição?', async () => {
    try {
      await del(`/api/eventos/${eventoActualId}/participacoes/${numCartao}`);
      toast('Inscrição removida.');
      await carregarParticipacoes();
    } catch (err) {
      toast(err.message, 'erro');
    }
  });
}

// ════════════════════════════════════════════════
// DOAÇÕES
// ════════════════════════════════════════════════
let tabDoacoesActual = 'doacoes';

function switchTabDoacoes(tab) {
  tabDoacoesActual = tab;
  ['doacoes','doadores','certificados'].forEach(t => {
    document.getElementById(`sub-${t}`).classList.toggle('hidden', t !== tab);
    const btn = document.getElementById(`tab-${t}-btn`);
    if (btn) btn.classList.toggle('tab-active', t === tab);
  });
  if (tab === 'doacoes')       carregarDoacoes();
  else if (tab === 'doadores') carregarDoadores();
  else if (tab === 'certificados') carregarCertificados();
}

async function carregarDoacoes() {
  try {
    const rows = await get('/api/doacoes');
    const tbody = document.getElementById('tabela-doacoes');
    tbody.innerHTML = rows.length
      ? rows.map(r => `
        <tr>
          <td class="text-slate-500 text-xs">${r.ID_DOACAO}</td>
          <td class="font-medium">${r.NOME_DOADOR || '—'}</td>
          <td class="text-slate-400">${fmtData(r.DATA_DOACAO)}</td>
          <td class="text-green-400">${fmtMoeda(r.VALOR_TOTAL)}</td>
          <td class="text-slate-400">${r.NOME_BIBLIOTECA || '—'}</td>
        </tr>`).join('')
      : linhaVazia(5);
  } catch (err) {
    toast('Erro a carregar doações: ' + err.message, 'erro');
  }
}

async function carregarDoadores() {
  try {
    const rows = await get('/api/doacoes/doadores');
    const tbody = document.getElementById('tabela-doadores');
    tbody.innerHTML = rows.length
      ? rows.map(r => `
        <tr>
          <td class="text-slate-500 text-xs">${r.ID_DOADOR}</td>
          <td class="font-medium">${r.NOME || '—'}</td>
          <td>${badgeTipo(r.TIPO)}</td>
          <td class="text-slate-400">${r.CONTACTO || '—'}</td>
          <td class="text-slate-400">${r.EMAIL || '—'}</td>
        </tr>`).join('')
      : linhaVazia(5);
  } catch (err) {
    toast('Erro a carregar doadores: ' + err.message, 'erro');
  }
}

async function carregarCertificados() {
  try {
    const rows = await get('/api/doacoes/certificados');
    const tbody = document.getElementById('tabela-certificados');
    tbody.innerHTML = rows.length
      ? rows.map(r => `
        <tr>
          <td class="text-slate-500 text-xs">${r.ID_CERTIFICADO}</td>
          <td class="font-mono text-xs text-slate-300">${r.NUMERO_SERIE || '—'}</td>
          <td class="font-medium">${r.NOME_DOADOR || '—'}</td>
          <td class="text-slate-400">${fmtData(r.DATA_EMISSAO)}</td>
          <td>
            <button onclick="reemitirCertificado(${r.ID_CERTIFICADO})" class="btn-secondary btn-sm"><i class="fa-solid fa-rotate mr-1"></i>Reemitir</button>
          </td>
        </tr>`).join('')
      : linhaVazia(5);
  } catch (err) {
    toast('Erro a carregar certificados: ' + err.message, 'erro');
  }
}

function reemitirCertificado(id) {
  const modal = document.getElementById('modal-reemissao');
  const input = document.getElementById('modal-reemissao-motivo');
  input.value = '';
  modal.classList.remove('hidden');
  const close = () => modal.classList.add('hidden');
  document.getElementById('modal-reemissao-fechar').onclick = close;
  document.getElementById('modal-reemissao-cancelar').onclick = close;
  document.getElementById('modal-reemissao-ok').onclick = async () => {
    const motivo = input.value.trim();
    if (!motivo) { input.focus(); return; }
    close();
    try {
      await post(`/api/doacoes/certificados/${id}/reemitir`, { motivo });
      toast('Certificado reemitido com sucesso.');
      carregarCertificados();
    } catch (err) {
      toast(err.message, 'erro');
    }
  };
}

function abrirModalDoador() {
  document.getElementById('modal-titulo').textContent = 'Novo Doador';
  document.getElementById('modal-erro').classList.add('hidden');
  document.getElementById('modal-conteudo').innerHTML = `
    <div class="space-y-3">
      <div>
        <label class="label-dark">Nome *</label>
        <input id="df-nome" class="input-dark w-full"/>
      </div>
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label-dark">Tipo *</label>
          <select id="df-tipo" class="input-dark w-full">
            <option value="INDIVIDUAL">Individual</option>
            <option value="INSTITUCIONAL">Institucional</option>
          </select>
        </div>
        <div>
          <label class="label-dark">Contacto</label>
          <input id="df-contacto" class="input-dark w-full"/>
        </div>
        <div>
          <label class="label-dark">Email</label>
          <input id="df-email" type="email" class="input-dark w-full"/>
        </div>
        <div>
          <label class="label-dark">NUIT</label>
          <input id="df-nuit" class="input-dark w-full"/>
        </div>
      </div>
      <div>
        <label class="label-dark">Morada</label>
        <input id="df-morada" class="input-dark w-full"/>
      </div>
    </div>
  `;
  modalSalvarFn = async () => {
    const body = {
      nome: document.getElementById('df-nome').value,
      tipo: document.getElementById('df-tipo').value,
      contacto: document.getElementById('df-contacto').value,
      email: document.getElementById('df-email').value,
      morada: document.getElementById('df-morada').value,
      nuit: document.getElementById('df-nuit').value,
    };
    if (!body.nome) { mostrarErroModal('Nome é obrigatório.'); return; }
    await post('/api/doacoes/doadores', body);
    fecharModal();
    toast('Doador criado com sucesso.');
    carregarDoadores();
  };
  abrirModal();
}

async function abrirModalDoacao() {
  document.getElementById('modal-titulo').textContent = 'Nova Doação';
  document.getElementById('modal-erro').classList.add('hidden');

  let doadores = [], bibliotecas = [];
  try { doadores = await get('/api/doacoes/doadores'); } catch {}
  try { bibliotecas = await get('/api/funcionarios/bibliotecas'); } catch {}

  document.getElementById('modal-conteudo').innerHTML = `
    <div class="space-y-3">
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label-dark">Doador *</label>
          <select id="dacf-doador" class="input-dark w-full">
            <option value="">— Seleccionar —</option>
            ${doadores.map(d => `<option value="${d.ID_DOADOR}">${d.NOME}</option>`).join('')}
          </select>
        </div>
        <div>
          <label class="label-dark">Biblioteca</label>
          <select id="dacf-bib" class="input-dark w-full">
            <option value="">— Seleccionar —</option>
            ${bibliotecas.map(b => `<option value="${b.ID_BIBLIOTECA}">${b.NOME}</option>`).join('')}
          </select>
        </div>
        <div class="col-span-2">
          <label class="label-dark">Data da Doação</label>
          <input id="dacf-data" type="date" class="input-dark w-full"/>
        </div>
      </div>
      <hr class="border-slate-700"/>
      <p class="text-sm text-slate-400 font-medium">Itens Doados</p>
      <div id="itens-doacao" class="space-y-2">
        <div class="grid grid-cols-3 gap-2 item-doacao">
          <div>
            <label class="label-dark">ID Material</label>
            <input class="input-dark w-full itd-material" type="number" placeholder="ID"/>
          </div>
          <div>
            <label class="label-dark">Qtd.</label>
            <input class="input-dark w-full itd-qtd" type="number" value="1" min="1"/>
          </div>
          <div>
            <label class="label-dark">Valor Unit. (MT)</label>
            <input class="input-dark w-full itd-valor" type="number" step="0.01" placeholder="0.00"/>
          </div>
        </div>
      </div>
      <button onclick="adicionarItemDoacao()" class="btn-secondary text-sm">+ Adicionar Item</button>
    </div>
  `;

  // Pré-preencher data
  document.getElementById('dacf-data').value = new Date().toISOString().slice(0,10);

  modalSalvarFn = async () => {
    const id_doador = document.getElementById('dacf-doador').value;
    if (!id_doador) { mostrarErroModal('Selecciona um doador.'); return; }

    const itemEls = document.querySelectorAll('.item-doacao');
    const itens = Array.from(itemEls).map(el => ({
      id_material: el.querySelector('.itd-material').value,
      quantidade: parseInt(el.querySelector('.itd-qtd').value) || 1,
      valor_unitario: parseFloat(el.querySelector('.itd-valor').value) || 0,
    })).filter(i => i.id_material);

    if (!itens.length) { mostrarErroModal('Adiciona pelo menos um item.'); return; }

    await post('/api/doacoes', {
      id_doador,
      id_biblioteca: document.getElementById('dacf-bib').value || null,
      data_doacao: document.getElementById('dacf-data').value,
      itens,
    });
    fecharModal();
    toast('Doação registada com sucesso.');
    carregarDoacoes();
  };

  abrirModal();
}

function adicionarItemDoacao() {
  const cont = document.getElementById('itens-doacao');
  const div = document.createElement('div');
  div.className = 'grid grid-cols-3 gap-2 item-doacao';
  div.innerHTML = `
    <div><input class="input-dark w-full itd-material" type="number" placeholder="ID Material"/></div>
    <div><input class="input-dark w-full itd-qtd" type="number" value="1" min="1"/></div>
    <div><input class="input-dark w-full itd-valor" type="number" step="0.01" placeholder="0.00"/></div>
  `;
  cont.appendChild(div);
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
  const seccoes = ['dashboard','leitores','materiais','emprestimos','funcionarios','eventos','doacoes','transferencias'];

  // Login — inserido antes do bloco #app
  const loginHtml = await fetch('sections/login.html').then(r => r.text());
  document.getElementById('app').insertAdjacentHTML('beforebegin', loginHtml);

  // Secções principais
  const main = document.getElementById('main-content');
  const htmls = await Promise.all(
    seccoes.map(s => fetch(`sections/${s}.html`).then(r => r.text()))
  );
  main.innerHTML = htmls.join('');

  // Modais + toast
  const modals = await fetch('sections/modals.html').then(r => r.text());
  document.body.insertAdjacentHTML('beforeend', modals);
}

inicializarHTML().then(() => { bindEventos(); init(); });
