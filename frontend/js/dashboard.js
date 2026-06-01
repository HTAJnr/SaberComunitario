// ════════════════════════════════════════════════
// DASHBOARD
// ════════════════════════════════════════════════
function switchDashTab(tab) {
  const tabs = ['rede', 'biblioteca', 'sistema'];
  tabs.forEach(t => {
    const panel = document.getElementById(`dash-tab-${t}`);
    const btn   = document.getElementById(`tab-dash-${t}`);
    if (panel) panel.classList.toggle('hidden', t !== tab);
    if (btn)   btn.classList.toggle('tab-active', t === tab);
  });
  if (tab === 'sistema') carregarSnapshotsInfo();
  if (tab === 'biblioteca') carregarDashboardBibAdmin();
}

// Admin: renderiza o painel de biblioteca dentro do tab "Biblioteca" reutilizando o HTML existente
async function carregarDashboardBibAdmin() {
  const tabPanel = document.getElementById('dash-tab-biblioteca');
  const bibView  = document.getElementById('dash-bib-view');
  if (!tabPanel || !bibView) return;
  if (!tabPanel.contains(bibView)) {
    tabPanel.appendChild(bibView);
  }
  bibView.classList.remove('hidden'); // sempre — pode ter sido ocultado por carregarDashboard()
  await carregarDashboardBib(utilizadorActual?.NIVEL_ACESSO);
}

const _SNAPSHOT_TTL_MS = 90 * 60 * 1000; // 1h30m

async function _verificarSnapshots() {
  if (utilizadorActual?.NIVEL_ACESSO !== 'Administrador') return;
  try {
    const lista = await get('/api/manutencao/snapshots');
    if (!lista.length) return;
    const agora = Date.now();
    const precisaRefresh = lista.some(s =>
      !s.ULTIMO_REFRESH || (agora - new Date(s.ULTIMO_REFRESH).getTime() > _SNAPSHOT_TTL_MS)
    );
    if (!precisaRefresh) return;

    document.getElementById('loading-sync').classList.remove('hidden');
    try {
      await post('/api/manutencao/refresh-snapshots', {});
    } catch (err) {
      console.warn('[SNAPSHOT TTL] refresh falhou:', err.message);
    } finally {
      document.getElementById('loading-sync').classList.add('hidden');
    }
  } catch { /* silencioso — endpoint indisponível ou utilizador sem acesso */ }
}

async function carregarDashboard() {
  await _verificarSnapshots();
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

async function refreshSnapshots() {
  const btn = document.getElementById('btn-refresh-snapshots');
  if (btn) { btn.disabled = true; btn.textContent = 'A actualizar...'; }
  try {
    const r = await post('/api/manutencao/refresh-snapshots', {});
    toast(r.mensagem || 'Snapshots actualizados.', r.ok ? 'sucesso' : 'aviso');
    if (r.ok) await carregarSnapshotsInfo();
  } catch (err) {
    toast('Erro ao actualizar snapshots: ' + (err.message || err), 'erro');
  } finally {
    if (btn) { btn.disabled = false; btn.textContent = 'Actualizar Snapshots'; }
  }
}

async function carregarSnapshotsInfo() {
  if (utilizadorActual?.NIVEL_ACESSO !== 'Administrador') return;
  const el = document.getElementById('dash-snapshots-lista');
  if (!el) return;
  try {
    const lista = await get('/api/manutencao/snapshots');
    if (!lista.length) { el.innerHTML = '<p style="color:var(--text-secondary);font-size:12px">Sem snapshots neste nó.</p>'; return; }
    el.innerHTML = `<table class="tbl" style="font-size:11px">
      <thead><tr><th>Snapshot</th><th>Modo</th><th>Último Refresh</th><th>Estado</th></tr></thead>
      <tbody>${lista.map(s => `
        <tr>
          <td class="cod">${s.NOME}</td>
          <td>${s.MODO || '—'}</td>
          <td style="color:var(--text-secondary)">${s.ULTIMO_REFRESH ? new Date(s.ULTIMO_REFRESH).toLocaleString('pt-PT') : '—'}</td>
          <td><span class="badge ${s.ESTADO === 'FRESH' ? 'badge-green' : s.ESTADO === 'STALE' ? 'badge-red' : 'badge-gray'}">${s.ESTADO === 'FRESH' ? 'Actualizado' : s.ESTADO === 'STALE' ? 'Desactualizado' : s.ESTADO === 'UNDEFINED' || s.ESTADO === 'UNKNOWN' ? 'Não rastreável' : s.ESTADO || '—'}</span></td>
        </tr>`).join('')}
      </tbody></table>`;
  } catch (_) {
    el.innerHTML = '<p style="color:var(--text-secondary);font-size:12px">Não foi possível carregar snapshots.</p>';
  }
}

async function carregarDashboardAdmin() {
  try {
    const stats = await get('/api/dashboard/rede').catch(() => ({}));
    const cards = [
      { label: 'Bibliotecas activas',        valor: stats.total_bibliotecas         ?? '—' },
      { label: 'Empréstimos activos na rede', valor: stats.emprestimos_ativos         ?? '—' },
      { label: 'Transferências pendentes',   valor: stats.transferencias_pendentes   ?? '—',
        alerta: (stats.transferencias_pendentes > 0) ? 'laranja' : null },
      { label: 'Materiais no acervo',         valor: stats.materiais_acervo            ?? '—' },
    ];
    document.getElementById('dash-rede-stats').innerHTML = cards.map(renderStatCard).join('');
    const [bibs, atrasos, proximosEv] = await Promise.all([
      get('/api/bibliotecas').catch(() => []),
      get('/api/dashboard/emprestimos-ativos').catch(() => []),
      get('/api/dashboard/eventos-proximos').catch(() => []),
    ]);
    _renderBibliotecasRede(Array.isArray(bibs) ? bibs : (bibs.bibliotecas || []));
    renderEmprestimosAtrasados('dash-atrasos-rede', atrasos || []);
    renderProximosEventos('dash-proximos-eventos-rede', proximosEv || []);
  } catch (err) {
    toast('Erro a carregar dashboard: ' + err.message, 'erro');
  }
}

async function carregarDashboardBib(nivel) {
  const isAssistente   = nivel === 'Assistente';
  const isBibliotecario = nivel === 'Bibliotecario';
  const podeVerTransf  = !isAssistente && !isBibliotecario;
  try {
    const [stats, devHoje, leitores, transferencias, atrasos, proximosEv] = await Promise.all([
      get('/api/dashboard/biblioteca').catch(() => ({})),
      get('/api/dashboard/devolucoes-hoje').catch(() => []),
      get('/api/dashboard/leitores-recentes').catch(() => []),
      podeVerTransf ? get('/api/dashboard/transferencias-recentes').catch(() => []) : Promise.resolve([]),
      get('/api/dashboard/emprestimos-ativos').catch(() => []),
      get('/api/dashboard/eventos-proximos').catch(() => []),
    ]);

    const allCards = [
      { label: 'Empréstimos activos',       valor: stats.emprestimos_ativos      ?? '—' },
      { label: 'Em atraso',                  valor: stats.emprestimos_vencidos     ?? '—',
        alerta: (stats.emprestimos_vencidos > 0) ? 'vermelho' : null },
      { label: 'Materiais disponíveis',      valor: stats.materiais_disponiveis    ?? '—' },
      { label: 'Transferências pendentes',   valor: stats.transferencias_pendentes ?? '—',
        alerta: (stats.transferencias_pendentes > 0) ? 'laranja' : null },
    ];

    let cards;
    if (isAssistente)    cards = allCards.slice(0, 3);
    else if (podeVerTransf) cards = allCards;
    else                 cards = allCards.slice(0, 3); // Bibliotecario: sem transferências

    try { document.getElementById('dash-stats').innerHTML = cards.map(renderStatCard).join(''); } catch {}

    try { renderDevolucoes(devHoje || []); } catch {}

    const grafico     = document.getElementById('dash-grafico-panel');
    const linha2      = document.getElementById('dash-linha2');
    const panelTransf = document.getElementById('dash-transferencias')?.closest?.('.panel');

    if (grafico) grafico.style.display = isAssistente ? 'none' : '';
    if (linha2)  linha2.style.display  = '';
    if (!isAssistente) try { renderBarChart(stats.emprestimos_semana || []); } catch {}
    try { renderLeitoresRecentes(leitores || []); } catch {}
    if (podeVerTransf) {
      if (panelTransf) panelTransf.style.display = '';
      try { renderTransferenciasRecentes(transferencias || []); } catch {}
    } else {
      if (panelTransf) panelTransf.style.display = 'none';
    }
    try { renderEmprestimosAtrasados('dash-atrasos', atrasos || []); } catch {}
    try { renderProximosEventos('dash-proximos-eventos', proximosEv || []); } catch {}
  } catch (err) {
    toast('Erro a carregar dashboard: ' + err.message, 'erro');
  }
}

function renderEmprestimosAtrasados(elId, lista) {
  const el = document.getElementById(elId);
  if (!el) return;
  if (!lista.length) {
    el.innerHTML = emptyState('○', 'Sem empréstimos em atraso');
    return;
  }
  el.innerHTML = `<div style="overflow-x:auto"><table class="tbl" style="font-size:11px">
    <thead><tr><th>ID</th><th>Leitor</th><th>Material</th><th>Prazo</th><th>Atraso</th></tr></thead>
    <tbody>
      ${lista.map(r => `
        <tr>
          <td class="cod">${r.ID_EMPRESTIMO}</td>
          <td>${r.NOME_LEITOR || '—'}</td>
          <td style="max-width:140px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${r.TITULO || '—'}</td>
          <td style="color:var(--text-secondary)">${fmtData(r.DATA_DEVOLUCAO_PREV)}</td>
          <td><span class="bdg bdg-bloqueado">${r.DIAS_ATRASO}d</span></td>
        </tr>`).join('')}
    </tbody>
  </table></div>`;
}

function renderProximosEventos(elId, lista) {
  const el = document.getElementById(elId);
  if (!el) return;
  if (!lista.length) {
    el.innerHTML = emptyState('○', 'Sem eventos próximos');
    return;
  }
  el.innerHTML = lista.map(ev => `
    <div style="display:flex;align-items:flex-start;gap:10px;padding:7px 0;border-bottom:0.5px solid var(--border-soft)">
      <div style="min-width:38px;text-align:center;background:var(--theme-accent-soft);border-radius:6px;padding:3px 6px">
        <div style="font-size:16px;font-weight:700;color:var(--theme-accent-text);line-height:1">${new Date(ev.DATA_INICIO).getDate()}</div>
        <div style="font-size:9px;color:var(--theme-accent-text);text-transform:uppercase">${new Date(ev.DATA_INICIO).toLocaleString('pt-MZ',{month:'short'})}</div>
      </div>
      <div style="flex:1;min-width:0">
        <div style="font-size:12px;font-weight:500;color:var(--text-primary);white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${ev.NOME || '—'}</div>
        <div style="font-size:10px;color:var(--text-muted)">${ev.NOME_BIBLIOTECA || ''}</div>
      </div>
    </div>`).join('');
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
    el.innerHTML = emptyState('○', 'Sem devoluções previstas hoje');
    return;
  }
  const hoje = new Date(); hoje.setHours(0, 0, 0, 0);
  el.innerHTML = lista.map(emp => {
    const ini = iniciais(emp.NOME_LEITOR || '');
    const titulo = (emp.TITULO || '—').substring(0, 32);
    const prazo = new Date(emp.PRAZO_DEVOLUCAO); prazo.setHours(0, 0, 0, 0);
    const diff = Math.round((prazo - hoje) / 86400000);
    let badgeTxt, badgeCls;
    if (diff < 0)        { badgeTxt = `${Math.abs(diff)}d atraso`; badgeCls = 'bdg-bloqueado'; }
    else if (diff === 0) { badgeTxt = 'Hoje';    badgeCls = 'bdg-suspenso'; }
    else                 { badgeTxt = 'Pontual'; badgeCls = 'bdg-activo'; }
    return `
      <div style="display:flex;align-items:center;gap:10px;padding:7px 0;border-bottom:0.5px solid var(--border-soft)">
        <div class="avatar-initials" style="width:26px;height:26px;font-size:9px;flex-shrink:0">${ini}</div>
        <div style="flex:1;min-width:0">
          <div style="font-size:12px;color:var(--text-primary);white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${emp.NOME_LEITOR || '—'}</div>
          <div style="font-size:10px;color:var(--text-muted);white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${titulo}</div>
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

function _renderBibliotecasRede(lista) {
  const el = document.getElementById('dash-rede-table');
  if (!el) return;
  if (!lista.length) {
    el.innerHTML = emptyState('⊞', 'Sem bibliotecas registadas na rede');
    return;
  }
  el.innerHTML = `
    <table class="tbl">
      <thead>
        <tr>
          <th>Código</th>
          <th>Nome</th>
          <th>Província</th>
          <th>Responsável</th>
          <th style="text-align:right">Materiais</th>
          <th style="text-align:right">Leitores</th>
        </tr>
      </thead>
      <tbody>
        ${lista.map(b => `
          <tr>
            <td style="font-family:monospace;font-size:11px;color:var(--text-muted)">${b.COD_BIBLIOTECA || '—'}</td>
            <td style="font-weight:500">${b.NOME_BIBLIOTECA || '—'}</td>
            <td style="color:var(--text-secondary)">${b.PROVINCIA || '—'}</td>
            <td style="color:var(--text-secondary)">${b.RESPONSAVEL_ACTUAL || '—'}</td>
            <td style="text-align:right;color:var(--text-secondary)">${b.TOTAL_MATERIAIS ?? '—'}</td>
            <td style="text-align:right;color:var(--text-secondary)">${b.TOTAL_LEITORES ?? '—'}</td>
          </tr>`).join('')}
      </tbody>
    </table>`;
}

function renderTransferenciasRecentes(lista) {
  const el = document.getElementById('dash-transferencias');
  if (!lista.length) {
    el.innerHTML = emptyState('○', 'Sem transferências recentes');
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
      <div style="display:flex;align-items:center;gap:10px;padding:7px 0;border-bottom:0.5px solid var(--border-soft)">
        <div style="font-size:16px;color:${cor};flex-shrink:0;width:16px;text-align:center">${seta}</div>
        <div style="flex:1;min-width:0">
          <div style="font-size:12px;color:var(--text-primary);white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${titulo}</div>
          <div style="font-size:10px;color:var(--text-muted);white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${outra || '—'}</div>
        </div>
        ${bdgEstado(t.ESTADO_TRANSFERENCIA)}
      </div>`;
  }).join('');
}
