// ════════════════════════════════════════════════
// TRANSFERÊNCIAS (TELA 05)
// ════════════════════════════════════════════════

let tabTransfActual = 'todas';
let _transfRows = [];

let _drawerTransfId = null;
let _drawerTransf   = null;

let _transfMatSel = null;
let _transfMatRes = [];

// ── 05-A Lista ─────────────────────────────────

function switchTabTransf(direcao) {
  carregarTransferencias(direcao);
}

async function carregarTransferencias(direcao = 'todas') {
  direcao = (direcao || 'todas').toLowerCase();
  tabTransfActual = direcao;
  ['todas', 'enviadas', 'recebidas'].forEach(t => {
    document.getElementById(`tab-transf-${t}`)?.classList.toggle('tab-active', t === direcao);
  });
  try {
    _transfRows = await get(`/api/transferencias?direcao=${direcao}&limit=100`);
    _renderizarTabelaTransf();
  } catch (err) {
    toast('Erro a carregar transferências: ' + err.message, 'erro');
  }
}

function _renderizarTabelaTransf() {
  const q = (document.getElementById('filtro-transf-q')?.value || '').toLowerCase();

  let rows = _transfRows || [];
  if (q) {
    rows = rows.filter(r =>
      (r.MATERIAL_TITULO             || '').toLowerCase().includes(q) ||
      (r.BIBLIOTECA_ORIGEM_NOME      || '').toLowerCase().includes(q) ||
      (r.BIBLIOTECA_DESTINO_NOME     || '').toLowerCase().includes(q) ||
      (r.FUNCIONARIO_SOLICITANTE_NOME || '').toLowerCase().includes(q)
    );
  }

  const tbody = document.getElementById('tabela-transferencias');
  if (!tbody) return;
  tbody.innerHTML = rows.length ? rows.map(_linhaTransf).join('') : linhaVazia(8);
}

function _linhaTransf(r) {
  const estado = r.ESTADO_TRANSFERENCIA || '';
  const _cls = {
    'Pendente':  'bdg-suspenso',
    'Aprovada':  'bdg-activo-emp',
    'Rejeitada': 'bdg-vencido',
    'Concluida': 'bdg-devolvido',
  };
  const estadoBdg = `<span class="bdg ${_cls[estado] || ''}">${estado}</span>`;

  return `<tr>
    <td class="mono">${r.ID_TRANSFERENCIA}</td>
    <td>${r.MATERIAL_TITULO || '—'}</td>
    <td>${r.BIBLIOTECA_ORIGEM_NOME || '—'}</td>
    <td>${r.BIBLIOTECA_DESTINO_NOME || '—'}</td>
    <td>${r.FUNCIONARIO_SOLICITANTE_NOME || '—'}</td>
    <td>${fmtData(r.DATA_SOLICITACAO)}</td>
    <td>${estadoBdg}</td>
    <td style="text-align:right">
      <button class="btn-secondary btn-sm"
              onclick="abrirCtxMenuTransf(event,${r.ID_TRANSFERENCIA})">···</button>
    </td>
  </tr>`;
}

// ── Context menu ───────────────────────────────

function abrirCtxMenuTransf(evt, id) {
  evt.stopPropagation();
  const nivel = utilizadorActual?.NIVEL_ACESSO || '';
  const r     = _transfRows.find(x => x.ID_TRANSFERENCIA === id);
  if (!r) return;

  const estado       = r.ESTADO_TRANSFERENCIA || '';
  const podeGerir    = ['Administrador', 'Coordenador'].includes(nivel);
  const podeAprovar  = podeGerir && estado === 'Pendente';
  const podeConcluir = podeGerir && estado === 'Aprovada';

  const menu = document.getElementById('ctx-menu-transf');
  menu.innerHTML = `
    <div class="ctx-menu-item" onclick="fecharCtxMenuTransf();abrirDrawerTransf(${id})">
      <i class="fa-solid fa-eye" style="width:14px"></i> Ver detalhe
    </div>
    ${podeAprovar ? `
    <div class="ctx-menu-item" onclick="fecharCtxMenuTransf();aprovarTransf(${id})">
      <i class="fa-solid fa-circle-check" style="width:14px"></i> Aprovar
    </div>
    <div class="ctx-menu-item ctx-menu-danger" onclick="fecharCtxMenuTransf();abrirModalRejeitarTransf(${id})">
      <i class="fa-solid fa-circle-xmark" style="width:14px"></i> Rejeitar
    </div>` : ''}
    ${podeConcluir ? `
    <div class="ctx-menu-item" onclick="fecharCtxMenuTransf();concluirTransf(${id})">
      <i class="fa-solid fa-flag-checkered" style="width:14px"></i> Marcar concluída
    </div>` : ''}
  `;

  const btn  = evt.currentTarget;
  const rect = btn.getBoundingClientRect();
  menu.style.display  = 'block';
  menu.style.position = 'fixed';
  menu.style.top      = (rect.bottom + 4) + 'px';
  menu.style.left     = Math.max(4, rect.right - 180) + 'px';

  setTimeout(() => document.addEventListener('click', fecharCtxMenuTransf, { once: true }), 0);
}

function fecharCtxMenuTransf() {
  const m = document.getElementById('ctx-menu-transf');
  if (m) m.style.display = 'none';
}

// ── Drawer ─────────────────────────────────────

function abrirDrawerTransf(id) {
  _drawerTransfId = id;
  _drawerTransf   = _transfRows.find(r => r.ID_TRANSFERENCIA === id) || null;

  document.getElementById('drawer-transf-overlay').style.display = 'block';
  document.getElementById('drawer-transf').classList.add('open');

  if (!_drawerTransf) {
    document.getElementById('drawer-transf-conteudo').innerHTML =
      '<p style="text-align:center;color:#888;font-size:12px;padding:24px">Não encontrado.</p>';
    return;
  }

  _renderizarDrawerTransf();
}

function _renderizarDrawerTransf() {
  const t = _drawerTransf;

  function campo(label, valor, estilo = '') {
    return `<div style="display:flex;justify-content:space-between;align-items:baseline;
                        padding:5px 0;border-bottom:0.5px solid #f0f0f0;font-size:12px">
      <span style="color:#888;flex-shrink:0;margin-right:8px">${label}</span>
      <span style="text-align:right;${estilo}">${valor ?? '—'}</span>
    </div>`;
  }

  function secao(titulo) {
    return `<div style="font-size:10px;font-weight:500;color:#aaa;text-transform:uppercase;
                        letter-spacing:.06em;margin:14px 0 6px">${titulo}</div>`;
  }

  const _cls = {
    'Pendente':  'bdg-suspenso',
    'Aprovada':  'bdg-activo-emp',
    'Rejeitada': 'bdg-vencido',
    'Concluida': 'bdg-devolvido',
  };
  const estado = t.ESTADO_TRANSFERENCIA || '';
  const estadoBdg = `<span class="bdg ${_cls[estado] || ''}">${estado}</span>`;

  let html = `
    ${secao('Material')}
    ${campo('Código',  `<span class="mono">${t.MATERIAL_CODIGO || '—'}</span>`)}
    ${campo('Título',  t.MATERIAL_TITULO)}
    ${campo('Estado do material', t.MATERIAL_ESTADO)}

    ${secao('Transferência')}
    ${campo('ID',      `<span class="mono">#${t.ID_TRANSFERENCIA}</span>`)}
    ${campo('Estado',  estadoBdg)}
    ${campo('Solicitação', fmtData(t.DATA_SOLICITACAO))}
    ${t.DIAS_PENDENTE != null ? campo('Dias pendente', t.DIAS_PENDENTE + ' dias') : ''}

    ${secao('Bibliotecas')}
    ${campo('Origem',  t.BIBLIOTECA_ORIGEM_NOME)}
    ${campo('Destino', t.BIBLIOTECA_DESTINO_NOME)}

    ${secao('Pessoas')}
    ${campo('Solicitante', t.FUNCIONARIO_SOLICITANTE_NOME)}
    ${t.FUNCIONARIO_APROVADOR_NOME ? campo('Aprovador/Rejeitante', t.FUNCIONARIO_APROVADOR_NOME) : ''}
  `;

  if (estado === 'Aprovada' || estado === 'Concluida') {
    html += campo('Data aprovação', fmtData(t.DATA_APROVACAO_DESTINO));
  }
  if (estado === 'Concluida') {
    html += campo('Data conclusão', fmtData(t.DATA_CONCLUSAO));
  }

  if (t.MOTIVO) {
    html += `${secao('Motivo')}
    <div style="font-size:12px;color:#444;padding:6px 0;line-height:1.5">${t.MOTIVO}</div>`;
  }

  document.getElementById('drawer-transf-conteudo').innerHTML = html;
}

function fecharDrawerTransf() {
  document.getElementById('drawer-transf-overlay').style.display = 'none';
  document.getElementById('drawer-transf').classList.remove('open');
  _drawerTransfId = null;
  _drawerTransf   = null;
}

// ── Modal Solicitar (05-B) ──────────────────────

function abrirModalSolicitarTransf() {
  _transfMatSel = null;
  _transfMatRes = [];

  document.getElementById('modal-transf-titulo').textContent = 'Solicitar Transferência';
  document.getElementById('modal-transf-erro').classList.add('hidden');

  document.getElementById('modal-transf-conteudo').innerHTML = `
    <div style="margin-bottom:14px">
      <label class="form-label">Material (pesquise pelo título ou código)</label>
      <div style="display:flex;gap:6px">
        <input id="transf-mat-q" type="text" class="input-field" style="flex:1"
               placeholder="Título ou código…"
               onkeydown="if(event.key==='Enter'){event.preventDefault();_pesquisarMaterialTransf();}"/>
        <button class="btn-secondary" onclick="_pesquisarMaterialTransf()">
          <i class="fa-solid fa-magnifying-glass"></i>
        </button>
      </div>
      <div id="transf-mat-lista" style="margin-top:6px"></div>
      <div id="transf-mat-sel-label" style="font-size:12px;color:#2e7d32;margin-top:4px"></div>
    </div>
    <div style="margin-bottom:14px">
      <label class="form-label">Biblioteca de destino</label>
      <select id="transf-bib-dest" class="input-field">
        <option value="">A carregar…</option>
      </select>
    </div>
    <div>
      <label class="form-label">Motivo da transferência</label>
      <textarea id="transf-motivo" class="input-field" rows="3"
                placeholder="Justificativa da transferência…"
                style="resize:vertical"></textarea>
    </div>
  `;

  document.getElementById('modal-transf-footer').innerHTML = `
    <button class="btn-secondary" onclick="fecharModalTransf()">Cancelar</button>
    <button class="btn-primary" onclick="_confirmarSolicitarTransf()">
      <i class="fa-solid fa-paper-plane" style="margin-right:5px"></i>Solicitar
    </button>
  `;

  document.getElementById('modal-transf-overlay').classList.remove('hidden');
  _carregarBibliotecasTransf();
}

async function _pesquisarMaterialTransf() {
  const q = (document.getElementById('transf-mat-q')?.value || '').trim();
  if (!q) return;
  const lista = document.getElementById('transf-mat-lista');
  lista.innerHTML = '<p style="font-size:12px;color:#888">A pesquisar…</p>';
  try {
    const res = await get(`/api/materiais?q=${encodeURIComponent(q)}&limit=5`);
    _transfMatRes = res.materiais || res || [];
    if (!_transfMatRes.length) {
      lista.innerHTML = '<p style="font-size:12px;color:#888">Nenhum resultado.</p>';
      return;
    }
    lista.innerHTML = `<div style="border:1px solid #e5e7eb;border-radius:6px;overflow:hidden;margin-top:2px">
      ${_transfMatRes.map(m => `
        <div onclick="_selecionarMaterialTransf('${m.COD_MATERIAL}','${(m.TITULO || '').replace(/'/g,"\\'")}','${(m.BIBLIOTECA_NOME || '').replace(/'/g,"\\'")}' )"
             style="padding:8px 12px;font-size:12px;cursor:pointer;border-bottom:1px solid #f0f0f0;
                    display:flex;justify-content:space-between;align-items:center"
             onmouseover="this.style.background='#f9fafb'" onmouseout="this.style.background=''">
          <span><strong class="mono">${m.COD_MATERIAL}</strong> — ${m.TITULO || '—'}</span>
          <span style="color:#888;font-size:11px">${m.BIBLIOTECA_NOME || ''}</span>
        </div>`).join('')}
    </div>`;
  } catch (err) {
    lista.innerHTML = `<p style="font-size:12px;color:#c62828">Erro: ${err.message}</p>`;
  }
}

function _selecionarMaterialTransf(cod, titulo, bib) {
  _transfMatSel = cod;
  document.getElementById('transf-mat-lista').innerHTML = '';
  document.getElementById('transf-mat-sel-label').innerHTML =
    `<i class="fa-solid fa-circle-check" style="margin-right:4px"></i>
     <strong class="mono">${cod}</strong> — ${titulo} <span style="color:#888">(${bib})</span>`;
}

async function _carregarBibliotecasTransf() {
  const sel = document.getElementById('transf-bib-dest');
  if (!sel) return;
  try {
    const lista = await get('/api/bibliotecas');
    const propria = utilizadorActual?.COD_BIBLIOTECA || '';
    const outras  = lista.filter(b => b.COD_BIBLIOTECA !== propria);
    sel.innerHTML = `<option value="">Seleccionar…</option>` +
      outras.map(b => `<option value="${b.COD_BIBLIOTECA}">${b.NOME_BIBLIOTECA}</option>`).join('');
  } catch {
    sel.innerHTML = '<option value="">Erro a carregar</option>';
  }
}

async function _confirmarSolicitarTransf() {
  _mostrarErroModalTransf('');

  if (!_transfMatSel) {
    return _mostrarErroModalTransf('Seleccione um material.');
  }
  const codDest = document.getElementById('transf-bib-dest')?.value;
  if (!codDest) {
    return _mostrarErroModalTransf('Seleccione a biblioteca de destino.');
  }
  const motivo = (document.getElementById('transf-motivo')?.value || '').trim();

  try {
    await post('/api/transferencias', {
      cod_material:           _transfMatSel,
      cod_biblioteca_destino: codDest,
      motivo:                 motivo || null,
    });
    toast('Transferência solicitada com sucesso.', 'sucesso');
    fecharModalTransf();
    carregarTransferencias(tabTransfActual);
  } catch (err) {
    _mostrarErroModalTransf(err.message);
  }
}

// ── Aprovar ────────────────────────────────────

function aprovarTransf(id) {
  confirmar('Aprovar esta transferência?', async () => {
    try {
      await api(`/api/transferencias/${id}/aprovar`, { method: 'PATCH', body: {} });
      toast('Transferência aprovada.', 'sucesso');
      carregarTransferencias(tabTransfActual);
    } catch (err) {
      toast('Erro: ' + err.message, 'erro');
    }
  }, { labelOk: 'Aprovar', danger: false });
}

// ── Rejeitar ───────────────────────────────────

function abrirModalRejeitarTransf(id) {
  document.getElementById('modal-transf-titulo').textContent = 'Rejeitar Transferência';
  document.getElementById('modal-transf-erro').classList.add('hidden');

  document.getElementById('modal-transf-conteudo').innerHTML = `
    <div>
      <label class="form-label">Motivo da rejeição <span style="color:#c62828">*</span></label>
      <textarea id="transf-rejeitar-motivo" class="input-field" rows="4"
                placeholder="Indique o motivo…" style="resize:vertical"></textarea>
    </div>
  `;

  document.getElementById('modal-transf-footer').innerHTML = `
    <button class="btn-secondary" onclick="fecharModalTransf()">Cancelar</button>
    <button class="btn-primary" style="background:#c62828" onclick="_confirmarRejeitarTransf(${id})">
      <i class="fa-solid fa-circle-xmark" style="margin-right:5px"></i>Rejeitar
    </button>
  `;

  document.getElementById('modal-transf-overlay').classList.remove('hidden');
}

async function _confirmarRejeitarTransf(id) {
  _mostrarErroModalTransf('');
  const motivo = (document.getElementById('transf-rejeitar-motivo')?.value || '').trim();
  if (!motivo) {
    return _mostrarErroModalTransf('O motivo é obrigatório para rejeitar.');
  }
  try {
    await api(`/api/transferencias/${id}/rejeitar`, { method: 'PATCH', body: { motivo } });
    toast('Transferência rejeitada.', 'sucesso');
    fecharModalTransf();
    carregarTransferencias(tabTransfActual);
  } catch (err) {
    _mostrarErroModalTransf(err.message);
  }
}

// ── Concluir ───────────────────────────────────

function concluirTransf(id) {
  confirmar(
    'Marcar como concluída? O material será movido para a biblioteca de destino.',
    async () => {
      try {
        await api(`/api/transferencias/${id}/concluir`, { method: 'PATCH', body: {} });
        toast('Transferência concluída. Material movido.', 'sucesso');
        carregarTransferencias(tabTransfActual);
      } catch (err) {
        toast('Erro: ' + err.message, 'erro');
      }
    },
    { labelOk: 'Concluir', danger: false }
  );
}

// ── Modal utilitários ──────────────────────────

function fecharModalTransf(evt) {
  if (evt && evt.target !== document.getElementById('modal-transf-overlay')) return;
  document.getElementById('modal-transf-overlay').classList.add('hidden');
  _transfMatSel = null;
  _transfMatRes = [];
}

function _mostrarErroModalTransf(msg) {
  const el  = document.getElementById('modal-transf-erro');
  const txt = document.getElementById('modal-transf-erro-msg');
  if (!msg) { el?.classList.add('hidden'); return; }
  if (txt) txt.textContent = msg;
  el?.classList.remove('hidden');
}
