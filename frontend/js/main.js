/* ════════════════════════════════════════════════
   Saber Comunitário — main.js
   Estado global, helpers, auth, router, modais genéricos.
   Lógica de cada secção → js/<secção>.js
   Componentes reutilizáveis → js/componentes.js
═══════════════════════════════════════════════ */

// ── Estado global ─────────────────────────────
let utilizadorActual = null;
let modalSalvarFn = null;
let noActual = null; // { no_nome, db_user } — carregado via /api/no/info na inicialização

// ── Helpers de restrição por nó ───────────────
function _noEh(nomeNo) {
  return (noActual?.no_nome || 'BibliotecaNacionalDB') === nomeNo;
}

// Botão activo ou disabled+tooltip consoante o nó activo
function _btnNo(nomeNo, classes, iconeHtml, label, onclickStr) {
  if (_noEh(nomeNo)) {
    return `<button class="${classes}" onclick="${onclickStr}">${iconeHtml}${label}</button>`;
  }
  return `<button class="${classes}" disabled style="opacity:.45;cursor:not-allowed"
    title="Só disponível no nó ${nomeNo}">${iconeHtml}${label}</button>`;
}

// Item de ctx-menu activo ou desabilitado consoante o nó activo
function _ctxItemNo(nomeNo, icone, label, onclickStr, extraClass = '') {
  if (_noEh(nomeNo)) {
    return `<div class="ctx-menu-item ${extraClass}" onclick="${onclickStr}">
      <i class="fa-solid ${icone}" style="width:14px"></i> ${label}</div>`;
  }
  return `<div class="ctx-menu-item" style="opacity:.4;cursor:not-allowed"
    title="Só disponível no nó ${nomeNo}">
    <i class="fa-solid ${icone}" style="width:14px"></i> ${label}
    <i class="fa-solid fa-circle-info" style="font-size:9px;margin-left:4px;color:var(--text-muted)"></i>
  </div>`;
}

// Aplica restrições de nó a botões estáticos do HTML (chamado uma vez após noActual ser carregado)
function _aplicarRestricoesNo() {
  const restricoes = [
    { id: 'btn-novo-emprestimo',  no: 'EmpréstimosProgramasDB' },
    { id: 'btn-novo-evento',      no: 'EventosBibliotecasDB' },
    { id: 'btn-solicitar-transf', no: 'MateriaisDB' },
    { id: 'btn-registar-doacao',  no: 'BibliotecaNacionalDB' },
    { id: 'btn-adicionar-mat',    no: 'MateriaisDB' },
    { id: 'btn-adicionar-bib',    no: 'EventosBibliotecasDB' },
    { id: 'btn-novo-prog',        no: 'EmpréstimosProgramasDB' },
  ];
  restricoes.forEach(({ id, no }) => {
    const btn = document.getElementById(id);
    if (!btn || _noEh(no)) return;
    btn.disabled = true;
    btn.style.opacity = '.45';
    btn.style.cursor  = 'not-allowed';
    btn.title = `Só disponível no nó ${no}`;
  });
}

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
  const ok = tipo === 'ok' || tipo === 'sucesso';
  const icon = ok ? 'fa-circle-check' : 'fa-circle-xmark';
  t.className = ok ? 'toast-ok' : 'toast-erro';
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
  const btnLogin = document.getElementById('login-btn');
  if (btnLogin) { btnLogin.disabled = false; btnLogin.textContent = 'Entrar'; }
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
    (utilizadorActual.NOME_BIBLIOTECA || '').replace(/\bBiblioteca\b/i, 'Bib.');
  const codeEl = document.getElementById('sidebar-library-code');
  if (codeEl) {
    const codBib = utilizadorActual.COD_BIBLIOTECA;
    codeEl.textContent = codBib ? `${codBib} · ${utilizadorActual.PROVINCIA || ''}` : '';
  }

  const isDemo = String(utilizadorActual.COD_FUNCIONARIO) === '0';
  const regionLabel = document.getElementById('sidebar-region-label');
  if (isDemo) {
    regionLabel.style.display = 'none';
  } else {
    regionLabel.style.display = '';
    regionLabel.textContent = `Região · ${regiao}`;
  }

  document.getElementById('topbar-region-pill').textContent = `${regiao} · ${prov}`;

  // Identidade do nó verificada via Oracle (SELECT USER FROM DUAL) — não falsificável via .env
  try { noActual = await get('/api/no/info'); } catch { noActual = { no_nome: 'BibliotecaNacionalDB', db_user: null }; }

  configurarNavPorRole();
  _aplicarRestricoesNo();
  _carregarNotificacoes();
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
    document.getElementById('login-email').value = '';
    document.getElementById('login-senha').value = '';
  });

  configurarNavegacao();
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
  auditoria:       carregarAuditoria,
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
  biblioteca:     { titulo: 'Bibliotecas' },
  auditoria:      { titulo: 'Auditoria' },
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

  ['transferencias', 'funcionarios', 'doacoes', 'permissoes', 'biblioteca', 'auditoria'].forEach(show);
  const labelGestao = document.getElementById('nav-label-gestao');
  if (labelGestao) labelGestao.style.display = '';

  // Auditoria: só Admin e Coordenador
  hide('auditoria');
  if (['Administrador', 'Coordenador'].includes(nivel)) show('auditoria');

  if (nivel === 'Assistente') {
    hide('transferencias');
    hide('funcionarios');
    hide('doacoes');
    hide('permissoes');
    hide('biblioteca');
    if (labelGestao) labelGestao.style.display = 'none';
  } else if (nivel === 'Bibliotecario') {
    hide('transferencias');
    hide('funcionarios');
    hide('permissoes');
    hide('biblioteca');
    if (labelGestao) labelGestao.style.display = 'none';
  } else if (nivel === 'Coordenador') {
    hide('permissoes');
    hide('biblioteca');
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
// NOTIFICAÇÕES / BADGES
// ════════════════════════════════════════════════
async function _carregarNotificacoes() {
  try {
    const stats = await get('/api/dashboard/biblioteca');
    const pendentes = [];
    const nivel = utilizadorActual?.NIVEL_ACESSO || '';
    const podeVerTransf = ['Administrador', 'Coordenador'].includes(nivel);

    const emp = Number(stats.emprestimos_vencidos || 0);
    const trf = Number(stats.transferencias_pendentes || 0);

    const badgeEmp = document.getElementById('nav-badge-emprestimos');
    if (badgeEmp) {
      if (emp > 0) { badgeEmp.textContent = emp; badgeEmp.classList.remove('hidden'); }
      else badgeEmp.classList.add('hidden');
    }

    const badgeTrf = document.getElementById('nav-badge-transferencias');
    if (badgeTrf) {
      if (podeVerTransf && trf > 0) { badgeTrf.textContent = trf; badgeTrf.classList.remove('hidden'); }
      else badgeTrf.classList.add('hidden');
    }

    if (emp > 0) pendentes.push({ label: `${emp} empréstimo${emp > 1 ? 's' : ''} vencido${emp > 1 ? 's' : ''}`, section: 'emprestimos' });
    if (podeVerTransf && trf > 0) pendentes.push({ label: `${trf} transferência${trf > 1 ? 's' : ''} pendente${trf > 1 ? 's' : ''}`, section: 'transferencias' });

    const dot = document.getElementById('notif-dot');
    const lista = document.getElementById('notif-lista');
    const bell = document.querySelector('#notif-btn .fa-bell');
    if (dot) dot.classList.toggle('hidden', pendentes.length === 0);
    if (bell && pendentes.length > 0) {
      bell.classList.remove('bell-ringing');
      void bell.offsetWidth; // força reflow para reiniciar animação
      bell.classList.add('bell-ringing');
    } else if (bell) {
      bell.classList.remove('bell-ringing');
    }
    if (lista) {
      lista.innerHTML = pendentes.length === 0
        ? `<div style="padding:14px;font-size:12px;color:var(--text-muted);text-align:center">Sem pendências</div>`
        : pendentes.map(p => `
            <div class="ctx-menu-item" onclick="_toggleNotifPanel();navegarPara('${p.section}')"
                 style="padding:10px 14px;font-size:12px;cursor:pointer;border-bottom:0.5px solid var(--border)">
              <i class="fa-solid fa-circle-dot" style="color:#ef4444;margin-right:8px;font-size:8px"></i>${p.label}
            </div>`).join('');
    }
  } catch { /* silencioso — dados de notificação são best-effort */ }
}

function _toggleNotifPanel() {
  const panel = document.getElementById('notif-panel');
  if (panel) panel.classList.toggle('hidden');
}

document.addEventListener('click', (e) => {
  const btn = document.getElementById('notif-btn');
  const panel = document.getElementById('notif-panel');
  if (panel && btn && !btn.contains(e.target) && !panel.contains(e.target)) {
    panel.classList.add('hidden');
  }
});

// ════════════════════════════════════════════════
// MODAL PERFIL
// ════════════════════════════════════════════════
let _perfilTab = 'info';

async function _carregarConteudoPerfil() {
  const isDemo = String(utilizadorActual?.COD_FUNCIONARIO) === '0';
  const conteudo = document.getElementById('modal-perfil-conteudo');
  const footer   = document.getElementById('modal-perfil-footer');
  if (isDemo) {
    conteudo.innerHTML = `
      <div style="padding:16px;background:var(--surface-raised);border-radius:8px;font-size:12px;color:var(--text-secondary);line-height:1.8">
        <div><b>Nome:</b> ${utilizadorActual.NOME_FUNCIONARIO || '—'}</div>
        <div><b>Email:</b> ${utilizadorActual.EMAIL || '—'}</div>
        <div><b>Função:</b> ${utilizadorActual.FUNCAO || '—'}</div>
        <div><b>Nível:</b> ${utilizadorActual.NIVEL_ACESSO || '—'}</div>
      </div>
      <p style="margin-top:12px;font-size:11px;color:var(--text-muted);text-align:center">Conta demo — edição desactivada.</p>`;
    if (footer) footer.style.display = 'none';
    return;
  }
  if (footer) footer.style.display = '';
  try {
    const d = await get('/api/funcionarios/me');
    conteudo.innerHTML = `
      <div class="form-group">
        <label class="form-label">Nome</label>
        <input class="input-field" value="${d.NOME_FUNCIONARIO || ''}" disabled style="opacity:.6"/>
      </div>
      <div class="form-group">
        <label class="form-label">Email</label>
        <input class="input-field" value="${d.EMAIL || ''}" disabled style="opacity:.6"/>
      </div>
      <div class="form-group">
        <label class="form-label">Contacto</label>
        <input id="perfil-contacto" class="input-field" value="${d.CONTACTO || ''}"/>
      </div>
      <div class="form-group">
        <label class="form-label">Endereço</label>
        <input id="perfil-endereco" class="input-field" value="${d.ENDERECO || ''}"/>
      </div>`;
  } catch (err) {
    conteudo.innerHTML = `<p style="color:#f85149;font-size:12px;padding:16px;text-align:center">Erro ao carregar perfil: ${err.message}</p>`;
  }
}

async function abrirModalPerfil() {
  _perfilTab = 'info';
  const overlay = document.getElementById('modal-perfil-overlay');
  if (!overlay) return;
  overlay.classList.remove('hidden');
  document.getElementById('modal-perfil-erro').classList.add('hidden');
  ['info','senha'].forEach(t =>
    document.getElementById(`ptab-${t}`)?.classList.toggle('tab-active', t === 'info')
  );
  await _carregarConteudoPerfil();
}

function fecharModalPerfil(e) {
  const overlay = document.getElementById('modal-perfil-overlay');
  if (e && e.target !== overlay) return;
  if (overlay) overlay.classList.add('hidden');
}

function _mudarTabPerfil(tab) {
  _perfilTab = tab;
  ['info','senha'].forEach(t =>
    document.getElementById(`ptab-${t}`)?.classList.toggle('tab-active', t === tab)
  );
  document.getElementById('modal-perfil-erro').classList.add('hidden');

  const isDemo = String(utilizadorActual?.COD_FUNCIONARIO) === '0';
  const footer = document.getElementById('modal-perfil-footer');
  if (isDemo) { if (footer) footer.style.display = 'none'; return; }
  if (footer) footer.style.display = '';

  if (tab === 'senha') {
    document.getElementById('modal-perfil-conteudo').innerHTML = `
      <div class="form-group">
        <label class="form-label">Senha actual *</label>
        <input id="perfil-senha-atual" type="password" class="input-field" placeholder="Senha actual"/>
      </div>
      <div class="form-group">
        <label class="form-label">Nova senha *</label>
        <input id="perfil-nova-senha" type="password" class="input-field" placeholder="Mínimo 6 caracteres"/>
      </div>
      <div class="form-group">
        <label class="form-label">Confirmar nova senha *</label>
        <input id="perfil-confirmar-senha" type="password" class="input-field" placeholder="Repetir nova senha"/>
      </div>`;
  } else {
    _carregarConteudoPerfil();
  }
}

async function _submeterPerfil() {
  document.getElementById('modal-perfil-erro').classList.add('hidden');
  if (_perfilTab === 'senha') {
    const atual  = document.getElementById('perfil-senha-atual')?.value || '';
    const nova   = document.getElementById('perfil-nova-senha')?.value || '';
    const conf   = document.getElementById('perfil-confirmar-senha')?.value || '';
    if (!atual || !nova) { _mostrarErroPerfil('Preencha a senha actual e a nova senha.'); return; }
    if (nova !== conf)   { _mostrarErroPerfil('As senhas não coincidem.'); return; }
    if (nova.length < 6) { _mostrarErroPerfil('A nova senha deve ter pelo menos 6 caracteres.'); return; }
    try {
      await patch('/api/funcionarios/me/senha', { senha_atual: atual, nova_senha: nova });
      fecharModalPerfil();
      toast('Senha alterada com sucesso.', 'sucesso');
    } catch (err) { _mostrarErroPerfil(err.message); }
  } else {
    const contacto = document.getElementById('perfil-contacto')?.value.trim() || null;
    const endereco = document.getElementById('perfil-endereco')?.value.trim() || null;
    try {
      await patch('/api/funcionarios/me', { contacto, endereco });
      fecharModalPerfil();
      toast('Perfil actualizado.', 'sucesso');
    } catch (err) { _mostrarErroPerfil(err.message); }
  }
}

function _mostrarErroPerfil(msg) {
  document.getElementById('modal-perfil-erro-msg').textContent = msg;
  document.getElementById('modal-perfil-erro').classList.remove('hidden');
}

// ════════════════════════════════════════════════
// INICIALIZAÇÃO
// ════════════════════════════════════════════════
async function inicializarHTML() {
  const seccoes = ['dashboard','leitores','materiais','emprestimos','funcionarios','eventos','doacoes','transferencias','programas','permissoes','biblioteca','auditoria'];

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
