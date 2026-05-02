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
async function carregarLeitores() {
  const q      = document.getElementById('filtro-leitor-q')?.value || '';
  const tipo   = document.getElementById('filtro-leitor-tipo')?.value || '';
  const estado = document.getElementById('filtro-leitor-estado')?.value || '';
  const params = new URLSearchParams();
  if (q)      params.set('q', q);
  if (tipo)   params.set('tipo', tipo);
  if (estado) params.set('estado', estado);
  try {
    const rows = await get(`/api/leitores?${params}`);
    const tbody = document.getElementById('tabela-leitores');
    tbody.innerHTML = rows.length
      ? rows.map(r => `
        <tr>
          <td class="font-mono text-xs text-slate-400">${r.NUM_CARTAO || '—'}</td>
          <td class="font-medium">${r.NOME || '—'}</td>
          <td>${badgeTipo(r.TIPO)}</td>
          <td class="text-slate-400">${r.CONTACTO || r.EMAIL || '—'}</td>
          <td>${badgeEstado(r.ESTADO)}</td>
          <td class="space-x-2">
            <button onclick="abrirModalLeitor('${r.NUM_CARTAO}')" class="btn-secondary btn-sm"><i class="fa-solid fa-pen mr-1"></i>Editar</button>
            <button onclick="confirmarEliminarLeitor('${r.NUM_CARTAO}','${(r.NOME||'').replace(/'/g,"\\'")}')" class="btn-danger btn-sm"><i class="fa-solid fa-trash mr-1"></i>Apagar</button>
          </td>
        </tr>`).join('')
      : linhaVazia(6);
  } catch (err) {
    toast('Erro a carregar leitores: ' + err.message, 'erro');
  }
}

async function abrirModalLeitor(numCartao = null) {
  document.getElementById('modal-titulo').textContent = numCartao ? 'Editar Leitor' : 'Novo Leitor';
  document.getElementById('modal-erro').classList.add('hidden');

  let bibliotecas = [];
  try { bibliotecas = await get('/api/funcionarios/bibliotecas'); } catch {}

  document.getElementById('modal-conteudo').innerHTML = `
    <div class="grid grid-cols-2 gap-3">
      <div class="col-span-2">
        <label class="label-dark">Nome *</label>
        <input id="lf-nome" class="input-dark w-full" placeholder="Nome completo"/>
      </div>
      <div>
        <label class="label-dark">Tipo *</label>
        <select id="lf-tipo" class="input-dark w-full" onchange="toggleCamposLeitor()">
          <option value="ADULTO">Adulto</option>
          <option value="CRIANCA">Criança</option>
          <option value="PROFESSOR">Professor</option>
        </select>
      </div>
      <div>
        <label class="label-dark">Género</label>
        <select id="lf-genero" class="input-dark w-full">
          <option value="">—</option>
          <option value="M">Masculino</option>
          <option value="F">Feminino</option>
        </select>
      </div>
      <div>
        <label class="label-dark">Data Nascimento</label>
        <input id="lf-data-nasc" type="date" class="input-dark w-full"/>
      </div>
      <div>
        <label class="label-dark">Tipo Documento</label>
        <select id="lf-tipo-doc" class="input-dark w-full">
          <option value="">—</option>
          <option value="BI">BI</option>
          <option value="PASSAPORTE">Passaporte</option>
          <option value="NUIT">NUIT</option>
        </select>
      </div>
      <div>
        <label class="label-dark">Nº Documento</label>
        <input id="lf-doc-id" class="input-dark w-full" placeholder="Número do documento"/>
      </div>
      <div>
        <label class="label-dark">Email</label>
        <input id="lf-email" type="email" class="input-dark w-full" placeholder="email@exemplo.com"/>
      </div>
      <div>
        <label class="label-dark">Contacto</label>
        <input id="lf-contacto" class="input-dark w-full" placeholder="8XXXXXXXX"/>
      </div>
      <div class="col-span-2">
        <label class="label-dark">Morada</label>
        <input id="lf-morada" class="input-dark w-full" placeholder="Bairro, Cidade"/>
      </div>
      <div class="col-span-2">
        <label class="label-dark">Biblioteca *</label>
        <select id="lf-id-biblioteca" class="input-dark w-full" required>
          <option value="">— Seleccionar —</option>
          ${bibliotecas.map(b => `<option value="${b.ID_BIBLIOTECA}">${b.NOME}</option>`).join('')}
        </select>
      </div>
      ${!numCartao ? `<div class="col-span-2">
        <label class="label-dark">Nº Cartão *</label>
        <input id="lf-num-cartao" class="input-dark w-full font-mono" placeholder="ABC2024XXXXX"/>
      </div>` : ''}
    </div>

    <!-- Campos dinâmicos por tipo -->
    <div id="campos-adulto" class="mt-3 space-y-3">
      <div>
        <label class="label-dark">Profissão</label>
        <input id="lf-profissao" class="input-dark w-full" placeholder="Ex: Professor, Engenheiro"/>
      </div>
    </div>
    <div id="campos-crianca" class="mt-3 space-y-3 hidden">
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label-dark">Nome do Responsável</label>
          <input id="lf-nome-resp" class="input-dark w-full"/>
        </div>
        <div>
          <label class="label-dark">Contacto do Responsável</label>
          <input id="lf-cont-resp" class="input-dark w-full"/>
        </div>
        <div class="col-span-2">
          <label class="label-dark">Escola</label>
          <input id="lf-escola-c" class="input-dark w-full"/>
        </div>
      </div>
    </div>
    <div id="campos-professor" class="mt-3 space-y-3 hidden">
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label-dark">Escola</label>
          <input id="lf-escola-p" class="input-dark w-full"/>
        </div>
        <div>
          <label class="label-dark">Disciplina</label>
          <input id="lf-disciplina" class="input-dark w-full"/>
        </div>
        <div class="col-span-2">
          <label class="label-dark">Tipo de Ensino</label>
          <select id="lf-tipo-ensino" class="input-dark w-full">
            <option value="">—</option>
            <option value="PRIMARIO">Primário</option>
            <option value="SECUNDARIO">Secundário</option>
            <option value="SUPERIOR">Superior</option>
          </select>
        </div>
      </div>
    </div>

    ${numCartao ? `
    <div class="mt-3">
      <label class="label-dark">Estado</label>
      <select id="lf-estado" class="input-dark w-full">
        <option value="Activo">Activo</option>
        <option value="Suspenso">Suspenso</option>
        <option value="Bloqueado">Bloqueado</option>
      </select>
    </div>` : ''}
  `;

  if (numCartao) {
    get(`/api/leitores/${numCartao}`).then(l => {
      document.getElementById('lf-nome').value = l.NOME || '';
      document.getElementById('lf-tipo').value = l.TIPO || 'ADULTO';
      document.getElementById('lf-genero').value = l.GENERO || '';
      if (l.DATA_NASC) document.getElementById('lf-data-nasc').value = l.DATA_NASC.slice(0,10);
      document.getElementById('lf-tipo-doc').value = l.TIPO_DOC || '';
      document.getElementById('lf-doc-id').value = l.DOCUMENTO_ID || '';
      document.getElementById('lf-email').value = l.EMAIL || '';
      document.getElementById('lf-contacto').value = l.CONTACTO || '';
      document.getElementById('lf-morada').value = l.MORADA || '';
      document.getElementById('lf-profissao').value = l.PROFISSAO || '';
      document.getElementById('lf-nome-resp').value = l.NOME_RESPONSAVEL || '';
      document.getElementById('lf-cont-resp').value = l.CONTACTO_RESPONSAVEL || '';
      document.getElementById('lf-escola-c').value = l.ESCOLA_CRIANCA || '';
      document.getElementById('lf-escola-p').value = l.ESCOLA_PROFESSOR || '';
      document.getElementById('lf-disciplina').value = l.DISCIPLINA || '';
      document.getElementById('lf-tipo-ensino').value = l.TIPO_ENSINO || '';
      if (l.ID_BIBLIOTECA) document.getElementById('lf-id-biblioteca').value = l.ID_BIBLIOTECA;
      const statusVal = l.STATUS_LEITOR || l.ESTADO || '';
      if (statusVal) document.getElementById('lf-estado').value = statusVal;
      toggleCamposLeitor();
    }).catch(err => mostrarErroModal(err.message));
  }

  toggleCamposLeitor();

  modalSalvarFn = async () => {
    const tipo = document.getElementById('lf-tipo').value;
    const body = {
      nome_completo: document.getElementById('lf-nome').value,
      genero: document.getElementById('lf-genero').value,
      data_nasc: document.getElementById('lf-data-nasc').value,
      tipo_doc: document.getElementById('lf-tipo-doc').value,
      documento_id: document.getElementById('lf-doc-id').value,
      email: document.getElementById('lf-email').value,
      contacto: document.getElementById('lf-contacto').value,
      localizacao_leitor: document.getElementById('lf-morada').value,
      id_biblioteca: document.getElementById('lf-id-biblioteca')?.value || null,
      tipo,
      profissao: document.getElementById('lf-profissao')?.value,
      nome_responsavel: document.getElementById('lf-nome-resp')?.value,
      telefone_responsavel: document.getElementById('lf-cont-resp')?.value,
      escola_frequenta: tipo === 'CRIANCA' ? document.getElementById('lf-escola-c')?.value : undefined,
      escola_instituto: tipo === 'PROFESSOR' ? document.getElementById('lf-escola-p')?.value : undefined,
      disciplina: document.getElementById('lf-disciplina')?.value,
      tipo_ensino: document.getElementById('lf-tipo-ensino')?.value,
    };
    if (!numCartao) body.num_cartao = document.getElementById('lf-num-cartao')?.value;
    if (numCartao) body.status_leitor = document.getElementById('lf-estado')?.value;
    if (!body.nome_completo) { mostrarErroModal('Nome é obrigatório.'); return; }
    if (!body.id_biblioteca) { mostrarErroModal('Biblioteca é obrigatória.'); return; }
    if (!numCartao && !body.num_cartao) { mostrarErroModal('Nº Cartão é obrigatório.'); return; }
    if (numCartao) await put(`/api/leitores/${numCartao}`, body);
    else           await post('/api/leitores', body);
    fecharModal();
    toast(numCartao ? 'Leitor actualizado.' : 'Leitor criado com sucesso.');
    carregarLeitores();
  };

  abrirModal();
}

function toggleCamposLeitor() {
  const tipo = document.getElementById('lf-tipo')?.value;
  document.getElementById('campos-adulto').classList.toggle('hidden', tipo !== 'ADULTO');
  document.getElementById('campos-crianca').classList.toggle('hidden', tipo !== 'CRIANCA');
  document.getElementById('campos-professor').classList.toggle('hidden', tipo !== 'PROFESSOR');
}

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
