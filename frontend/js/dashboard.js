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
      { label: 'Bibliotecas activas',        valor: stats.total_bibliotecas         ?? '—' },
      { label: 'Empréstimos activos na rede', valor: stats.emprestimos_ativos         ?? '—' },
      { label: 'Transferências pendentes',   valor: stats.transferencias_pendentes   ?? '—',
        alerta: (stats.transferencias_pendentes > 0) ? 'laranja' : null },
      { label: 'Materiais no acervo',         valor: stats.materiais_acervo            ?? '—' },
    ];
    document.getElementById('dash-rede-stats').innerHTML = cards.map(renderStatCard).join('');
    const bibs = await get('/api/bibliotecas').catch(() => []);
    _renderBibliotecasRede(Array.isArray(bibs) ? bibs : (bibs.bibliotecas || []));
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

    const allCards = [
      { label: 'Empréstimos activos',       valor: stats.emprestimos_ativos      ?? '—' },
      { label: 'Em atraso',                  valor: stats.emprestimos_vencidos     ?? '—',
        alerta: (stats.emprestimos_vencidos > 0) ? 'vermelho' : null },
      { label: 'Materiais disponíveis',      valor: stats.materiais_disponiveis    ?? '—' },
      { label: 'Transferências pendentes',   valor: stats.transferencias_pendentes ?? '—',
        alerta: (stats.transferencias_pendentes > 0) ? 'laranja' : null },
    ];
    document.getElementById('dash-stats').innerHTML =
      (isAssistente ? allCards.slice(0, 2) : allCards).map(renderStatCard).join('');

    renderDevolucoes(devHoje || []);

    const grafico = document.getElementById('dash-grafico-panel');
    const linha2  = document.getElementById('dash-linha2');
    if (isAssistente) {
      if (grafico) grafico.style.display = 'none';
      if (linha2)  linha2.style.display  = 'none';
    } else {
      if (grafico) grafico.style.display = '';
      if (linha2)  linha2.style.display  = '';
      renderBarChart(stats.emprestimos_semana || []);
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
