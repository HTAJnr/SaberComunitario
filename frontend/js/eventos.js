// ════════════════════════════════════════════════
// EVENTOS (TELA 06)
// ════════════════════════════════════════════════

let _evTab    = 'todos';
let _evRows   = [];
let _drawerEvId   = null;
let _drawerEvTab  = 'info';
let _drawerEvData = null;
let _evHorarios   = [];
let _evRecursos   = [];

// ── 06-A Lista ─────────────────────────────────

async function carregarEventos(tab) {
  tab = tab || _evTab || 'todos';
  _evTab = tab;

  ['todos','Planeado','Realizado','Cancelado'].forEach(t => {
    const key = t === 'todos' ? 'todos' : t.toLowerCase();
    document.getElementById(`tab-ev-${key}`)?.classList.toggle('tab-active', t === tab);
  });

  try {
    const qs = tab === 'todos' ? '' : `?status=${encodeURIComponent(tab)}`;
    _evRows = await get(`/api/eventos${qs}`);
    _renderizarTabelaEventos();
  } catch (err) {
    toast('Erro a carregar eventos: ' + err.message, 'erro');
  }
}

function _renderizarTabelaEventos() {
  const q = (document.getElementById('filtro-ev-q')?.value || '').toLowerCase();
  let rows = _evRows || [];
  if (q) {
    rows = rows.filter(r =>
      (r.TITULO_EVENTO  || r.NOME || '').toLowerCase().includes(q) ||
      (r.LOCAL_EVENTO   || '').toLowerCase().includes(q) ||
      (r.NOME_BIBLIOTECA|| '').toLowerCase().includes(q)
    );
  }
  const tbody = document.getElementById('tabela-eventos');
  if (!tbody) return;
  tbody.innerHTML = rows.length ? rows.map(_linhaEvento).join('') : linhaVazia(7);
}

function _linhaEvento(r) {
  const status  = r.STATUS_EVENTO || '';
  const _cls = { Planeado:'bdg-suspenso', Realizado:'bdg-devolvido', Cancelado:'bdg-vencido' };
  const bdgStatus  = `<span class="bdg ${_cls[status] || ''}">${status}</span>`;

  const publico = r.PUBLICO_ALVO || '';
  const bdgPub = publico ? `<span class="bdg bdg-activo-emp" style="font-size:10px">${publico}</span>` : '—';

  const rec = (r.RECORRENTE || 'N') === 'S'
    ? '<i class="fa-solid fa-rotate" title="Recorrente" style="color:#a78bfa;margin-left:4px"></i>'
    : '';

  const insc = r.INSCRITOS ?? '—';
  const cap  = r.CAPACIDADE ? r.CAPACIDADE : '∞';

  return `<tr>
    <td style="font-weight:500;max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">
      ${r.TITULO_EVENTO || r.NOME || '—'}${rec}
    </td>
    <td>${fmtData(r.DATA_EVENTO || r.DATA_INICIO)}</td>
    <td style="max-width:140px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${r.LOCAL_EVENTO || '—'}</td>
    <td>${bdgPub}</td>
    <td>${insc}/${cap}</td>
    <td>${bdgStatus}</td>
    <td style="text-align:right">
      <button class="btn-ghost btn-sm"
              onclick="abrirCtxMenuEvento(event,${r.ID_EVENTO})">···</button>
    </td>
  </tr>`;
}

// ── Context menu ───────────────────────────────

function abrirCtxMenuEvento(evt, id) {
  evt.stopPropagation();
  const nivel = utilizadorActual?.NIVEL_ACESSO || '';
  const r     = _evRows.find(x => x.ID_EVENTO === id);
  if (!r) return;

  const status    = r.STATUS_EVENTO || '';
  const podeGerir = ['Administrador','Coordenador','Bibliotecario'].includes(nivel);
  const planeado  = status === 'Planeado';

  const menu = document.getElementById('ctx-menu-ev');
  menu.innerHTML = `
    <div class="ctx-menu-item" onclick="fecharCtxMenuEvento();abrirDrawerEvento(${id})">
      <i class="fa-solid fa-eye" style="width:14px"></i> Ver detalhe
    </div>
    ${podeGerir && planeado ? `
    <div class="ctx-menu-item" onclick="fecharCtxMenuEvento();abrirModalEditarEvento(${id})">
      <i class="fa-solid fa-pen" style="width:14px"></i> Editar
    </div>
    <div class="ctx-menu-item" onclick="fecharCtxMenuEvento();marcarRealizadoEvento(${id})">
      <i class="fa-solid fa-circle-check" style="width:14px"></i> Marcar realizado
    </div>
    <div class="ctx-menu-item ctx-menu-danger" onclick="fecharCtxMenuEvento();cancelarEvento(${id})">
      <i class="fa-solid fa-ban" style="width:14px"></i> Cancelar
    </div>` : ''}
    ${podeGerir ? `
    <div class="ctx-menu-item ctx-menu-danger" onclick="fecharCtxMenuEvento();eliminarEvento(${id})">
      <i class="fa-solid fa-trash" style="width:14px"></i> Apagar
    </div>` : ''}
  `;

  const btn  = evt.currentTarget;
  const rect = btn.getBoundingClientRect();
  menu.style.display  = 'block';
  menu.style.position = 'fixed';
  menu.style.top      = (rect.bottom + 4) + 'px';
  menu.style.left     = Math.max(4, rect.right - 180) + 'px';

  setTimeout(() => document.addEventListener('click', fecharCtxMenuEvento, { once: true }), 0);
}

function fecharCtxMenuEvento() {
  const m = document.getElementById('ctx-menu-ev');
  if (m) m.style.display = 'none';
}

// ── Drawer 06-B ────────────────────────────────

async function abrirDrawerEvento(id) {
  _drawerEvId  = id;
  _drawerEvTab = 'info';
  _drawerEvData = null;

  document.getElementById('drawer-ev-overlay').style.display = 'block';
  document.getElementById('drawer-ev').classList.add('open');

  ['info','horarios','participantes','avaliacoes'].forEach(t => {
    document.getElementById(`dtab-ev-${t}`)?.classList.toggle('tab-active', t === 'info');
  });

  const conteudo = document.getElementById('drawer-ev-conteudo');
  conteudo.innerHTML = '<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:24px">A carregar…</p>';

  try {
    _drawerEvData = await get(`/api/eventos/${id}`);
    document.getElementById('drawer-ev-titulo').textContent = _drawerEvData.TITULO_EVENTO || 'Evento';
    _renderizarDrawerInfoEvento(_drawerEvData);
  } catch (err) {
    conteudo.innerHTML = `<p style="text-align:center;color:#f85149;font-size:12px;padding:24px">Erro: ${err.message}</p>`;
  }
}

function fecharDrawerEvento() {
  document.getElementById('drawer-ev-overlay').style.display = 'none';
  document.getElementById('drawer-ev').classList.remove('open');
  _drawerEvId   = null;
  _drawerEvData = null;
}

function mudarTabDrawerEvento(tab) {
  _drawerEvTab = tab;
  ['info','horarios','participantes','avaliacoes'].forEach(t => {
    document.getElementById(`dtab-ev-${t}`)?.classList.toggle('tab-active', t === tab);
  });

  if (tab === 'info')          _renderizarDrawerInfoEvento(_drawerEvData);
  else if (tab === 'horarios') _renderizarDrawerHorariosEvento(_drawerEvId);
  else if (tab === 'participantes') _renderizarDrawerParticipantesEvento(_drawerEvId);
  else if (tab === 'avaliacoes')    _renderizarDrawerAvaliacoesEvento(_drawerEvId);
}

const _campo = campoDetalhe;
const _secao = secaoDetalhe;

function _renderizarDrawerInfoEvento(ev) {
  if (!ev) return;
  const _cls = { Planeado:'bdg-suspenso', Realizado:'bdg-devolvido', Cancelado:'bdg-vencido' };
  const bdgStatus = `<span class="bdg ${_cls[ev.STATUS_EVENTO] || ''}">${ev.STATUS_EVENTO || '—'}</span>`;
  const rec = ev.RECORRENTE === 'S' ? 'Sim' : 'Não';

  document.getElementById('drawer-ev-conteudo').innerHTML = `
    ${_secao('Evento')}
    ${_campo('Título',      ev.TITULO_EVENTO)}
    ${_campo('Estado',      bdgStatus)}
    ${_campo('Data',        fmtData(ev.DATA_EVENTO))}
    ${_campo('Local',       ev.LOCAL_EVENTO)}
    ${_campo('Público-alvo',ev.PUBLICO_ALVO)}
    ${_campo('Capacidade',  ev.CAPACIDADE ? ev.CAPACIDADE + ' lugares' : 'Sem limite')}
    ${_campo('Inscritos',   ev.TOTAL_INSCRITOS ?? '0')}
    ${_campo('Recorrente',  rec)}
    ${ev.MEDIA_AVALIACAO ? _campo('Avaliação média', '★ ' + ev.MEDIA_AVALIACAO) : ''}
    ${ev.DESCRICAO_EVENTO ? `
    ${_secao('Descrição')}
    <div style="font-size:12px;color:var(--text-secondary);padding:6px 0;line-height:1.5">${ev.DESCRICAO_EVENTO}</div>` : ''}
    ${_secao('Biblioteca e Responsável')}
    ${_campo('Biblioteca',   ev.NOME_BIBLIOTECA)}
    ${_campo('Responsável',  ev.NOME_RESPONSAVEL)}
  `;
}

async function _renderizarDrawerHorariosEvento(id) {
  const conteudo = document.getElementById('drawer-ev-conteudo');
  conteudo.innerHTML = '<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:24px">A carregar…</p>';
  try {
    const rows = await get(`/api/eventos/${id}/horarios`);
    if (!rows.length) {
      conteudo.innerHTML = emptyState('📅', 'Sem horários registados');
      return;
    }
    conteudo.innerHTML = `
      <div style="font-size:12px">
        ${rows.map(h => `
          <div style="padding:8px 0;border-bottom:0.5px solid var(--border-soft)">
            <div style="font-weight:500">${h.DIA_SEMANA || '—'}
              ${h.DATA_OCORRENCIA ? `<span style="color:var(--text-muted);font-weight:400"> — ${h.DATA_OCORRENCIA}</span>` : ''}
            </div>
            <div style="color:var(--text-muted);margin-top:2px">
              ${h.HORA_INICIO || '—'} → ${h.HORA_FIM || '—'}
            </div>
          </div>`).join('')}
      </div>`;
  } catch (err) {
    conteudo.innerHTML = `<p style="color:#f85149;font-size:12px;padding:12px">Erro: ${err.message}</p>`;
  }
}

async function _renderizarDrawerParticipantesEvento(id) {
  const conteudo = document.getElementById('drawer-ev-conteudo');
  conteudo.innerHTML = '<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:24px">A carregar…</p>';
  try {
    const rows = await get(`/api/eventos/${id}/participantes`);
    const nivel = utilizadorActual?.NIVEL_ACESSO || '';
    const podeGerir = ['Administrador','Coordenador','Bibliotecario'].includes(nivel);
    const podeInsc  = true;

    const lista = rows.length
      ? rows.map(p => {
          const pres   = p.PRESENCA_CONFIRMACAO === 'S';
          const bdgPres = pres
            ? '<span class="bdg bdg-devolvido" style="font-size:10px">Presente</span>'
            : '<span class="bdg" style="font-size:10px;background:var(--surface-hover);color:var(--text-secondary)">Pendente</span>';
          const toggleLabel = pres ? 'Anular presença' : 'Confirmar presença';
          return `
            <div style="display:flex;align-items:center;justify-content:space-between;
                        padding:8px 0;border-bottom:0.5px solid var(--border-soft);gap:6px">
              <div style="min-width:0">
                <div style="font-size:12px;font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">
                  ${p.NOME_LEITOR || '—'}
                </div>
                <div style="font-size:11px;color:var(--text-muted)">
                  <span class="mono">${p.NUM_CARTAO}</span>
                  · ${fmtData(p.DATA_INSCRICAO)}
                  · ${bdgPres}
                </div>
              </div>
              <div style="display:flex;gap:4px;flex-shrink:0">
                ${podeGerir ? `
                <button onclick="_confirmarPresenca(${id},'${p.NUM_CARTAO}','${pres?'N':'S'}')"
                        class="btn-ghost btn-sm" style="font-size:10px;white-space:nowrap"
                        title="${toggleLabel}">
                  <i class="fa-solid fa-${pres?'user-slash':'user-check'}"></i>
                </button>` : ''}
                <button onclick="_removerParticipanteEvento(${id},'${p.NUM_CARTAO}')"
                        class="btn-ghost btn-sm" style="font-size:10px;color:#f85149">
                  <i class="fa-solid fa-user-minus"></i>
                </button>
              </div>
            </div>`;
        }).join('')
      : emptyState('👥', 'Sem participantes inscritos');

    conteudo.innerHTML = `
      <div style="margin-bottom:12px;display:flex;gap:6px">
        <input id="ev-inscr-nc" type="text" class="input-field" style="flex:1;font-size:12px"
               placeholder="N.º cartão do leitor…"
               onkeydown="if(event.key==='Enter'){event.preventDefault();_inscreverLeitorEvento(${id});}"/>
        <button onclick="_inscreverLeitorEvento(${id})" class="btn-primary" style="font-size:12px;white-space:nowrap">
          <i class="fa-solid fa-plus"></i> Inscrever
        </button>
      </div>
      <div id="ev-lista-part">${lista}</div>`;
  } catch (err) {
    conteudo.innerHTML = `<p style="color:#f85149;font-size:12px;padding:12px">Erro: ${err.message}</p>`;
  }
}

async function _renderizarDrawerAvaliacoesEvento(id) {
  const conteudo = document.getElementById('drawer-ev-conteudo');
  conteudo.innerHTML = '<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:24px">A carregar…</p>';
  try {
    const rows = await get(`/api/eventos/${id}/avaliacoes`);
    if (!rows.length) {
      conteudo.innerHTML = emptyState('⭐', 'Sem avaliações ainda');
      return;
    }
    function estrelas(n) {
      return '★'.repeat(n) + '☆'.repeat(5 - n);
    }
    conteudo.innerHTML = `
      <div style="font-size:12px">
        ${rows.map(a => `
          <div style="padding:8px 0;border-bottom:0.5px solid var(--border-soft)">
            <div style="display:flex;justify-content:space-between;align-items:baseline">
              <span style="font-weight:500">${a.NOME_LEITOR || a.NUM_CARTAO}</span>
              <span style="color:#d29922;font-size:14px">${estrelas(a.NOTA || 0)}</span>
            </div>
            ${a.COMENTARIO ? `<div style="color:var(--text-secondary);margin-top:3px;line-height:1.4">${a.COMENTARIO}</div>` : ''}
            <div style="color:var(--text-muted);font-size:11px;margin-top:2px">${a.DATA_AVALIACAO || ''}</div>
          </div>`).join('')}
      </div>`;
  } catch (err) {
    conteudo.innerHTML = `<p style="color:#f85149;font-size:12px;padding:12px">Erro: ${err.message}</p>`;
  }
}

// ── Participantes — acções ──────────────────────

async function _inscreverLeitorEvento(id) {
  const nc = (document.getElementById('ev-inscr-nc')?.value || '').trim();
  if (!nc) return;
  try {
    await post(`/api/eventos/${id}/participantes`, { num_cartao: nc });
    toast('Leitor inscrito com sucesso.', 'sucesso');
    await _renderizarDrawerParticipantesEvento(id);
  } catch (err) {
    toast(err.message, 'erro');
  }
}

function _removerParticipanteEvento(id, nc) {
  confirmar('Remover esta inscrição?', async () => {
    try {
      await del(`/api/eventos/${id}/participantes/${nc}`);
      toast('Inscrição removida.');
      await _renderizarDrawerParticipantesEvento(id);
    } catch (err) {
      toast(err.message, 'erro');
    }
  });
}

async function _confirmarPresenca(id, nc, novoEstado) {
  try {
    await api(`/api/eventos/${id}/participantes/${nc}/presenca`, {
      method: 'PATCH', body: { presenca: novoEstado }
    });
    toast(novoEstado === 'S' ? 'Presença confirmada.' : 'Presença anulada.');
    await _renderizarDrawerParticipantesEvento(id);
  } catch (err) {
    toast(err.message, 'erro');
  }
}

// ── Modal 06-C Criar / Editar ──────────────────

async function abrirModalCriarEvento() {
  _evHorarios = [];
  _evRecursos = [];
  document.getElementById('modal-ev-titulo').textContent = 'Novo Evento';
  _mostrarErroModalEvento('');
  await _renderizarFormEvento(null);
  document.getElementById('modal-ev-footer').innerHTML = `
    <button class="btn-ghost" onclick="fecharModalEvento()">Cancelar</button>
    <button class="btn-primary" onclick="_salvarEvento(null)">
      <i class="fa-solid fa-floppy-disk" style="margin-right:5px"></i>Criar Evento
    </button>`;
  document.getElementById('modal-ev-overlay').classList.remove('hidden');
}

async function abrirModalEditarEvento(id) {
  _evHorarios = [];
  _evRecursos = [];
  document.getElementById('modal-ev-titulo').textContent = 'Editar Evento';
  _mostrarErroModalEvento('');
  document.getElementById('modal-ev-conteudo').innerHTML =
    '<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:24px">A carregar…</p>';
  document.getElementById('modal-ev-overlay').classList.remove('hidden');

  try {
    const ev = await get(`/api/eventos/${id}`);
    await _renderizarFormEvento(ev);
    document.getElementById('modal-ev-footer').innerHTML = `
      <button class="btn-ghost" onclick="fecharModalEvento()">Cancelar</button>
      <button class="btn-primary" onclick="_salvarEvento(${id})">
        <i class="fa-solid fa-floppy-disk" style="margin-right:5px"></i>Guardar
      </button>`;
  } catch (err) {
    document.getElementById('modal-ev-conteudo').innerHTML =
      `<p style="color:#f85149;font-size:12px;padding:12px">Erro: ${err.message}</p>`;
  }
}

async function _renderizarFormEvento(ev) {
  const nivel = utilizadorActual?.NIVEL_ACESSO || '';
  const podeEscolherBib  = ['Administrador','Coordenador'].includes(nivel);
  const podeEscolherResp = ['Administrador','Coordenador'].includes(nivel);

  let bibliotecas = [];
  let funcionarios = [];
  if (podeEscolherBib) {
    try { bibliotecas = await get('/api/funcionarios/bibliotecas'); } catch {}
  }
  if (podeEscolherResp) {
    try { funcionarios = await get('/api/funcionarios'); } catch {}
  }

  // /api/funcionarios/bibliotecas retorna NOME (alias de NOME_BIBLIOTECA)
  const bibOpts = bibliotecas.map(b =>
    `<option value="${b.COD_BIBLIOTECA}"${ev && ev.COD_BIBLIOTECA === b.COD_BIBLIOTECA ? ' selected' : ''}>${b.NOME}</option>`
  ).join('');

  const funcOpts = funcionarios.map(f =>
    `<option value="${f.COD_FUNCIONARIO}"${ev && ev.COD_FUNCIONARIO === f.COD_FUNCIONARIO ? ' selected' : ''}>${f.NOME_FUNCIONARIO}</option>`
  ).join('');

  const dataVal = ev && ev.DATA_EVENTO
    ? (typeof ev.DATA_EVENTO === 'string' ? ev.DATA_EVENTO.slice(0,10) : '')
    : '';

  document.getElementById('modal-ev-conteudo').innerHTML = `
    <div style="display:flex;flex-direction:column;gap:12px;padding:4px 0">

      <div>
        <label class="form-label">Título <span style="color:#f85149">*</span></label>
        <input id="evf-titulo" class="input-field" value="${ev ? (ev.TITULO_EVENTO || '') : ''}"/>
      </div>

      <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
        <div>
          <label class="form-label">Data <span style="color:#f85149">*</span></label>
          <input id="evf-data" type="date" class="input-field" value="${dataVal}"/>
        </div>
        <div>
          <label class="form-label">Capacidade</label>
          <input id="evf-cap" type="number" class="input-field" placeholder="Sem limite"
                 value="${ev && ev.CAPACIDADE != null ? ev.CAPACIDADE : ''}"/>
        </div>
      </div>

      <div>
        <label class="form-label">Local <span style="color:#f85149">*</span></label>
        <input id="evf-local" class="input-field" value="${ev ? (ev.LOCAL_EVENTO || '') : ''}"/>
      </div>

      <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
        <div>
          <label class="form-label">Público-alvo <span style="color:#f85149">*</span></label>
          <select id="evf-publico" class="input-field">
            ${['Iniciantes','Intermedios','Avancados','Todos'].map(p =>
              `<option value="${p}"${ev && ev.PUBLICO_ALVO === p ? ' selected' : ''}>${p}</option>`
            ).join('')}
          </select>
        </div>
        <div>
          <label class="form-label">Recorrente</label>
          <select id="evf-rec" class="input-field">
            <option value="N"${!ev || ev.RECORRENTE !== 'S' ? ' selected' : ''}>Único</option>
            <option value="S"${ev && ev.RECORRENTE === 'S' ? ' selected' : ''}>Recorrente</option>
          </select>
        </div>
      </div>

      <div>
        <label class="form-label">Biblioteca <span style="color:#f85149">*</span></label>
        ${podeEscolherBib
          ? `<select id="evf-bib" class="input-field">
               <option value="">— Seleccionar —</option>
               ${bibOpts}
             </select>`
          : `<input id="evf-bib" type="hidden" value="${utilizadorActual?.COD_BIBLIOTECA || ''}"/>
             <div class="input-field" style="background:var(--surface-raised);color:var(--text-muted);cursor:default">
               ${utilizadorActual?.NOME_BIBLIOTECA || 'Biblioteca própria'}
             </div>`}
      </div>

      ${podeEscolherResp ? `
      <div>
        <label class="form-label">Funcionário responsável</label>
        <select id="evf-resp" class="input-field">
          <option value="">— Seleccionar —</option>
          ${funcOpts}
        </select>
      </div>` : ''}

      <div>
        <label class="form-label">Descrição</label>
        <textarea id="evf-desc" class="input-field" rows="3" style="resize:vertical">${ev ? (ev.DESCRICAO_EVENTO || '') : ''}</textarea>
      </div>

      ${!ev ? `
      <!-- Horários dinâmicos (só no criar) -->
      <div>
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
          <label class="form-label" style="margin:0">Horários</label>
          <button onclick="_adicionarHorario()" class="btn-ghost btn-sm" style="font-size:11px">
            <i class="fa-solid fa-plus" style="margin-right:3px"></i>Adicionar horário
          </button>
        </div>
        <div id="ev-horarios-lista" style="display:flex;flex-direction:column;gap:6px"></div>
      </div>

      <!-- Recursos dinâmicos (só no criar) -->
      <div>
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
          <label class="form-label" style="margin:0">Recursos</label>
          <button onclick="_adicionarRecurso()" class="btn-ghost btn-sm" style="font-size:11px">
            <i class="fa-solid fa-plus" style="margin-right:3px"></i>Adicionar recurso
          </button>
        </div>
        <div id="ev-recursos-lista" style="display:flex;flex-direction:column;gap:6px"></div>
      </div>` : ''}

    </div>
  `;
}

function _renderizarLinhasHorarios() {
  const lista = document.getElementById('ev-horarios-lista');
  if (!lista) return;
  lista.innerHTML = _evHorarios.map((h, i) => `
    <div style="display:grid;grid-template-columns:1fr 1fr 1fr 1fr auto;gap:6px;align-items:center">
      <select class="input-field" style="font-size:11px" onchange="_evHorarios[${i}].dia_semana=this.value">
        ${['Segunda','Terca','Quarta','Quinta','Sexta','Sabado','Domingo'].map(d =>
          `<option value="${d}"${h.dia_semana===d?' selected':''}>${d}</option>`
        ).join('')}
      </select>
      <input type="date" class="input-field" style="font-size:11px" value="${h.data_ocorrencia||''}"
             onchange="_evHorarios[${i}].data_ocorrencia=this.value"/>
      <input type="time" class="input-field" style="font-size:11px" value="${h.hora_inicio||''}"
             placeholder="Início" onchange="_evHorarios[${i}].hora_inicio=this.value"/>
      <input type="time" class="input-field" style="font-size:11px" value="${h.hora_fim||''}"
             placeholder="Fim" onchange="_evHorarios[${i}].hora_fim=this.value"/>
      <button onclick="_removerHorario(${i})" style="background:none;border:none;cursor:pointer;color:#f85149;font-size:14px;padding:0 2px">
        <i class="fa-solid fa-xmark"></i>
      </button>
    </div>`).join('');
}

function _adicionarHorario() {
  _evHorarios.push({ dia_semana:'Segunda', data_ocorrencia:'', hora_inicio:'', hora_fim:'' });
  _renderizarLinhasHorarios();
}

function _removerHorario(idx) {
  _evHorarios.splice(idx, 1);
  _renderizarLinhasHorarios();
}

function _renderizarLinhasRecursos() {
  const lista = document.getElementById('ev-recursos-lista');
  if (!lista) return;
  lista.innerHTML = _evRecursos.map((r, i) => `
    <div style="display:grid;grid-template-columns:1fr 80px auto;gap:6px;align-items:center">
      <input type="text" class="input-field" style="font-size:11px" placeholder="Nome do recurso"
             value="${r.nome_recurso||''}" onchange="_evRecursos[${i}].nome_recurso=this.value"/>
      <input type="number" class="input-field" style="font-size:11px" placeholder="Qtd"
             value="${r.quantidade||''}" min="1" onchange="_evRecursos[${i}].quantidade=+this.value"/>
      <button onclick="_removerRecurso(${i})" style="background:none;border:none;cursor:pointer;color:#f85149;font-size:14px;padding:0 2px">
        <i class="fa-solid fa-xmark"></i>
      </button>
    </div>`).join('');
}

function _adicionarRecurso() {
  _evRecursos.push({ nome_recurso:'', quantidade:1 });
  _renderizarLinhasRecursos();
}

function _removerRecurso(idx) {
  _evRecursos.splice(idx, 1);
  _renderizarLinhasRecursos();
}

async function _salvarEvento(id) {
  _mostrarErroModalEvento('');

  const titulo   = (document.getElementById('evf-titulo')?.value || '').trim();
  const local    = (document.getElementById('evf-local')?.value  || '').trim();
  const data     = document.getElementById('evf-data')?.value;
  const publico  = document.getElementById('evf-publico')?.value;
  const codBib   = document.getElementById('evf-bib')?.value;

  if (!titulo) return _mostrarErroModalEvento('O título é obrigatório.');
  if (!local)  return _mostrarErroModalEvento('O local é obrigatório.');
  if (!data)   return _mostrarErroModalEvento('A data é obrigatória.');
  if (!publico)return _mostrarErroModalEvento('O público-alvo é obrigatório.');
  if (!codBib) return _mostrarErroModalEvento('Seleccione a biblioteca.');

  const nivel = utilizadorActual?.NIVEL_ACESSO || '';
  const podeEscolherResp = ['Administrador','Coordenador'].includes(nivel);

  const body = {
    titulo_evento:    titulo,
    local_evento:     local,
    data_evento:      data,
    publico_alvo:     publico,
    cod_biblioteca:   codBib,
    descricao_evento: document.getElementById('evf-desc')?.value || null,
    capacidade:       document.getElementById('evf-cap')?.value  || null,
    recorrente:       document.getElementById('evf-rec')?.value  || 'N',
  };
  if (podeEscolherResp) {
    body.cod_funcionario_responsavel = document.getElementById('evf-resp')?.value || null;
  }

  if (!id) {
    body.horarios = _evHorarios.filter(h => h.hora_inicio && h.hora_fim);
    body.recursos = _evRecursos.filter(r => r.nome_recurso);
  }

  try {
    if (id) {
      await api(`/api/eventos/${id}`, { method: 'PUT', body });
      toast('Evento actualizado.', 'sucesso');
    } else {
      await post('/api/eventos', body);
      toast('Evento criado com sucesso.', 'sucesso');
    }
    fecharModalEvento();
    carregarEventos(_evTab);
  } catch (err) {
    _mostrarErroModalEvento(err.message);
  }
}

// ── Acções de status ───────────────────────────

function cancelarEvento(id) {
  confirmar('Cancelar este evento? O estado será alterado para Cancelado.', async () => {
    try {
      await api(`/api/eventos/${id}/status`, { method: 'PATCH', body: { status_evento: 'Cancelado' } });
      toast('Evento cancelado.', 'sucesso');
      carregarEventos(_evTab);
    } catch (err) {
      toast('Erro: ' + err.message, 'erro');
    }
  }, { labelOk: 'Cancelar evento', danger: true });
}

function marcarRealizadoEvento(id) {
  confirmar('Marcar evento como Realizado?', async () => {
    try {
      await api(`/api/eventos/${id}/status`, { method: 'PATCH', body: { status_evento: 'Realizado' } });
      toast('Evento marcado como realizado.', 'sucesso');
      carregarEventos(_evTab);
    } catch (err) {
      toast('Erro: ' + err.message, 'erro');
    }
  }, { labelOk: 'Confirmar', danger: false });
}

function eliminarEvento(id) {
  confirmar('Apagar este evento permanentemente?', async () => {
    try {
      await del(`/api/eventos/${id}`);
      toast('Evento eliminado.');
      carregarEventos(_evTab);
    } catch (err) {
      toast(err.message, 'erro');
    }
  }, { labelOk: 'Apagar', danger: true });
}

// ── Modal utilitários ──────────────────────────

function fecharModalEvento(evt) {
  if (evt && evt.target !== document.getElementById('modal-ev-overlay')) return;
  document.getElementById('modal-ev-overlay').classList.add('hidden');
  _evHorarios = [];
  _evRecursos = [];
}

function _mostrarErroModalEvento(msg) {
  const el  = document.getElementById('modal-ev-erro');
  const txt = document.getElementById('modal-ev-erro-msg');
  if (!msg) { el?.classList.add('hidden'); return; }
  if (txt) txt.textContent = msg;
  el?.classList.remove('hidden');
}
