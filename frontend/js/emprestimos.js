// ════════════════════════════════════════════════
// EMPRÉSTIMOS (TELA 03)
// ════════════════════════════════════════════════

let tabEmprestimosActual = 'activo';
let _empRows = [];

let _drawerEmpId  = null;
let _drawerEmp    = null;

let _wzEmpStep            = 1;
let _wzEmpLeitor          = null;
let _wzEmpLeitorValidado  = false;
let _wzEmpMaterial        = null;
let _wzEmpMateriaisRes    = [];

let _devolucaoId  = null;
let _devolucaoEmp = null;

// ── 03-A Lista ─────────────────────────────────

function switchTabEmprestimos(tab) {
  carregarEmprestimos(tab);
}

async function carregarEmprestimos(estado = 'activo') {
  estado = (estado || 'activo').toLowerCase();
  tabEmprestimosActual = estado;
  ['activo','vencido','devolvido','todos'].forEach(t => {
    document.getElementById(`tab-emp-${t}`)?.classList.toggle('tab-active', t === estado);
  });
  try {
    _empRows = await get(`/api/emprestimos?estado=${estado}`);
    _renderizarTabelaEmp();
  } catch (err) {
    toast('Erro a carregar empréstimos: ' + err.message, 'erro');
  }
}

function _renderizarTabelaEmp() {
  const search = (document.getElementById('filtro-emp-q')?.value || '').toLowerCase();
  const data   = document.getElementById('filtro-emp-data')?.value || '';

  let rows = _empRows || [];
  if (search) {
    rows = rows.filter(r =>
      (r.NOME_LEITOR || '').toLowerCase().includes(search) ||
      (r.TITULO      || '').toLowerCase().includes(search) ||
      (r.NUM_CARTAO  || '').toLowerCase().includes(search)
    );
  }
  if (data) {
    rows = rows.filter(r => (r.DATA_RETIRADA || r.DATA_EMP || '').slice(0, 10) === data);
  }

  const tbody = document.getElementById('tabela-emprestimos');
  if (!tbody) return;
  tbody.innerHTML = rows.length ? rows.map(_linhaEmp).join('') : linhaVazia(8);
}

function _linhaEmp(r) {
  const atrasado  = (r.DIAS_ATRASO || 0) > 0;
  const devolvido = !!r.DATA_DEVOLUCAO;

  const prazoStr = r.DATA_DEVOLUCAO_PREV || r.PRAZO_DEVOLUCAO;
  let prazoBdg   = fmtData(prazoStr);
  if (!devolvido && prazoStr) {
    if (atrasado) {
      prazoBdg = `<span class="bdg bdg-vencido">${fmtData(prazoStr)}</span>`;
    } else {
      const diasRest = Math.ceil((new Date(prazoStr) - new Date()) / 86400000);
      prazoBdg = diasRest <= 3
        ? `<span class="bdg bdg-suspenso">${fmtData(prazoStr)}</span>`
        : `<span class="bdg bdg-activo-emp">${fmtData(prazoStr)}</span>`;
    }
  }

  let estadoVal = r.ESTADO || (devolvido ? 'DEVOLVIDO' : atrasado ? 'VENCIDO' : 'ACTIVO');
  const _estadoLabel = { ACTIVO:'Activo', VENCIDO:'Vencido', DEVOLVIDO:'Devolvido', HISTORICO:'Devolvido' };
  const _estadoCls   = { ACTIVO:'bdg-activo-emp', VENCIDO:'bdg-vencido', DEVOLVIDO:'bdg-devolvido', HISTORICO:'bdg-devolvido' };
  const estadoBdg = `<span class="bdg ${_estadoCls[estadoVal] || ''}">${_estadoLabel[estadoVal] || estadoVal}</span>`;

  const multa     = r.MULTA || r.MULTA_VALOR || 0;
  const multaHtml = multa > 0
    ? `<span style="color:#e07820;font-weight:500">${fmtMoeda(multa)}</span>`
    : '—';

  const podeDev   = !devolvido;
  const podePagar = multa > 0 && r.MULTA_PAGA === 'N';

  return `<tr style="${atrasado && !devolvido ? 'background:var(--surface-raised)' : ''}">
    <td style="font-family:monospace;font-size:10px;color:var(--text-muted)">${r.ID_EMPRESTIMO}</td>
    <td style="font-weight:500">${r.NOME_LEITOR || r.NUM_CARTAO || '—'}</td>
    <td style="max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${r.TITULO || '—'}</td>
    <td style="color:var(--text-muted);font-size:11px">${fmtData(r.DATA_RETIRADA || r.DATA_EMP)}</td>
    <td>${prazoBdg}</td>
    <td>${estadoBdg}</td>
    <td>${multaHtml}</td>
    <td style="text-align:right">
      <button class="btn-ghost btn-sm"
              onclick="abrirCtxMenuEmp(event,${r.ID_EMPRESTIMO},${podeDev},${podePagar})">···</button>
    </td>
  </tr>`;
}

// ── Context menu ───────────────────────────────

function abrirCtxMenuEmp(evt, id, podeDev, podePagar) {
  evt.stopPropagation();
  const nivel       = utilizadorActual?.NIVEL_ACESSO || '';
  const podePagarM  = ['Administrador','Coordenador','Bibliotecario'].includes(nivel) && podePagar;
  const podeElim    = nivel === 'Administrador';

  const menu = document.getElementById('ctx-menu-emp');
  menu.innerHTML = `
    <div class="ctx-menu-item" onclick="fecharCtxMenuEmp();abrirDrawerEmp(${id})">
      <i class="fa-solid fa-eye" style="width:14px"></i> Ver detalhe
    </div>
    ${podeDev ? `<div class="ctx-menu-item" onclick="fecharCtxMenuEmp();abrirModalDevolucao(${id})">
      <i class="fa-solid fa-rotate-left" style="width:14px"></i> Registar devolução
    </div>` : ''}
    ${podePagarM ? `<div class="ctx-menu-item" onclick="fecharCtxMenuEmp();marcarMultaPagaEmp(${id})">
      <i class="fa-solid fa-circle-check" style="width:14px"></i> Marcar multa paga
    </div>` : ''}
    ${podeElim ? `<div class="ctx-menu-item ctx-menu-danger" onclick="fecharCtxMenuEmp();eliminarEmprestimo(${id})">
      <i class="fa-solid fa-trash" style="width:14px"></i> Eliminar
    </div>` : ''}
  `;

  const btn  = evt.currentTarget;
  const rect = btn.getBoundingClientRect();
  menu.style.display  = 'block';
  menu.style.position = 'fixed';
  menu.style.top      = (rect.bottom + 4) + 'px';
  menu.style.left     = Math.max(4, rect.right - 170) + 'px';

  setTimeout(() => document.addEventListener('click', fecharCtxMenuEmp, { once: true }), 0);
}

function fecharCtxMenuEmp() {
  const m = document.getElementById('ctx-menu-emp');
  if (m) m.style.display = 'none';
}

// ── Drawer 03-B ────────────────────────────────

async function abrirDrawerEmp(id) {
  _drawerEmpId = id;
  document.getElementById('drawer-emp-overlay').style.display = 'block';
  document.getElementById('drawer-emp').classList.add('open');
  document.getElementById('drawer-emp-conteudo').innerHTML =
    '<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:24px"><i class="fa-solid fa-spinner fa-spin" style="margin-right:6px"></i>A carregar…</p>';
  try {
    _drawerEmp = await get(`/api/emprestimos/${id}`);
    _renderizarDrawerEmp();
    if (!_drawerEmp.DATA_DEVOLUCAO && (_drawerEmp.DIAS_ATRASO || 0) > 0) {
      get(`/api/emprestimos/${id}/multa`).then(r => {
        const el = document.getElementById('drawer-emp-multa-corrente');
        if (!el) return;
        if ((r.multa || 0) > 0) {
          el.innerHTML = `<span style="font-weight:600">Multa a correr:</span> ${fmtMoeda(r.multa)} <span style="opacity:.7">(${r.dias_atraso} dias × taxa diária)</span>`;
        } else {
          el.remove();
        }
      }).catch(() => {
        const el = document.getElementById('drawer-emp-multa-corrente');
        if (el) el.remove();
      });
    }
  } catch (err) {
    document.getElementById('drawer-emp-conteudo').innerHTML =
      `<p style="color:#f85149;font-size:12px;padding:8px">${err.message}</p>`;
  }
}

function fecharDrawerEmp() {
  document.getElementById('drawer-emp-overlay').style.display = 'none';
  document.getElementById('drawer-emp').classList.remove('open');
  _drawerEmpId = null; _drawerEmp = null;
}

function _renderizarDrawerEmp() {
  const e = _drawerEmp;
  const atrasado  = (e.DIAS_ATRASO || 0) > 0;
  const devolvido = !!e.DATA_DEVOLUCAO;
  const multa     = e.MULTA_VALOR || 0;

  function campo(label, valor, estilo = '') {
    return `<div style="display:flex;justify-content:space-between;align-items:baseline;
                        padding:5px 0;border-bottom:0.5px solid var(--border-soft);font-size:12px">
      <span style="color:var(--text-muted);flex-shrink:0;margin-right:8px">${label}</span>
      <span style="font-weight:500;color:var(--text-primary);text-align:right;${estilo}">${valor}</span>
    </div>`;
  }

  function secao(titulo) {
    return `<div style="font-size:10px;font-weight:500;color:var(--text-muted);text-transform:uppercase;
                        letter-spacing:.06em;margin:14px 0 6px">${titulo}</div>`;
  }

  document.getElementById('drawer-emp-conteudo').innerHTML = `
    <div style="margin-bottom:16px">
      <div style="font-size:10px;color:var(--text-muted);margin-bottom:2px">Empréstimo</div>
      <div style="font-family:monospace;font-size:22px;font-weight:700;color:var(--text-primary)">#${e.ID_EMPRESTIMO}</div>
    </div>

    ${secao('Leitor')}
    ${campo('Nome',   e.NOME_LEITOR || '—')}
    ${campo('Cartão', `<span style="font-family:monospace;font-size:10px">${e.NUM_CARTAO || '—'}</span>`)}

    ${secao('Material')}
    ${campo('Título', e.TITULO || '—')}
    ${e.AUTOR        ? campo('Autor',  e.AUTOR) : ''}
    ${e.COD_MATERIAL ? campo('Código', `<span style="font-family:monospace;font-size:10px">${e.COD_MATERIAL}</span>`) : ''}

    ${secao('Datas')}
    ${campo('Retirada',  fmtData(e.DATA_RETIRADA))}
    ${campo('Prazo',     fmtData(e.PRAZO_DEVOLUCAO || e.DATA_DEVOLUCAO_PREV),
            atrasado && !devolvido ? 'color:#f85149' : '')}
    ${devolvido
      ? campo('Devolvido', fmtData(e.DATA_DEVOLUCAO), 'color:var(--theme-accent-text)')
      : atrasado
        ? campo('Atraso', `${e.DIAS_ATRASO} dias`, 'color:#f85149') : ''}
    ${!e.DATA_DEVOLUCAO && atrasado ? `<div id="drawer-emp-multa-corrente" style="margin-top:6px;padding:8px 10px;border-radius:7px;border:0.5px solid #e07820;background:#2a1500;font-size:12px;color:#e07820">A calcular multa…</div>` : ''}

    ${secao('Estado Material')}
    ${campo('Saída',   e.ESTADO_MATERIAL_SAIDA   || '—')}
    ${e.ESTADO_MATERIAL_RETORNO
      ? campo('Retorno', e.ESTADO_MATERIAL_RETORNO) : ''}
    ${e.OBSERVACOES_DEVOLUCAO
      ? `<div style="margin-top:6px;padding:6px 8px;background:var(--surface-raised);border-radius:6px;
                     font-size:11px;color:var(--text-secondary)">${e.OBSERVACOES_DEVOLUCAO}</div>` : ''}

    ${multa > 0 ? `
    <div style="margin-top:14px;padding:12px;
                background:${e.MULTA_PAGA === 'S' ? '#0d2820' : '#2a1500'};
                border-radius:8px;border:0.5px solid ${e.MULTA_PAGA === 'S' ? '#1a5a4a' : '#6a2020'}">
      ${secao('Multa').replace('margin:14px 0 6px', 'margin:0 0 6px')}
      ${campo('Valor',   fmtMoeda(multa), 'color:#e07820')}
      ${campo('Paga',    e.MULTA_PAGA === 'S' ? 'Sim' : 'Não',
              e.MULTA_PAGA === 'S' ? 'color:var(--theme-accent-text)' : 'color:#f85149')}
      ${e.DATA_PAGAMENTO_MULTA ? campo('Data pag.', fmtData(e.DATA_PAGAMENTO_MULTA)) : ''}
    </div>` : ''}
  `;
}

// ── Modal base (wizard + devolução) ────────────

function abrirModalEmpBase(titulo) {
  document.getElementById('modal-emp-titulo').textContent = titulo;
  document.getElementById('modal-emp-erro').classList.add('hidden');
  document.getElementById('modal-emp-conteudo').innerHTML = '';
  document.getElementById('modal-emp-footer').innerHTML   = '';
  document.getElementById('modal-emp-overlay').classList.remove('hidden');
}

function fecharModalEmp(e) {
  if (e && e.target !== document.getElementById('modal-emp-overlay')) return;
  document.getElementById('modal-emp-overlay').classList.add('hidden');
  _wzEmpStep = 1; _wzEmpLeitor = null; _wzEmpLeitorValidado = false;
  _wzEmpMaterial = null; _wzEmpMateriaisRes = [];
  _devolucaoId = null; _devolucaoEmp = null;
}

function mostrarErroEmp(msg) {
  document.getElementById('modal-emp-erro-msg').textContent = msg;
  document.getElementById('modal-emp-erro').classList.remove('hidden');
}

// Compatibilidade com modal-devolucao legado em modals.html
function fecharModalDevolucao() {
  document.getElementById('modal-devolucao')?.classList.add('hidden');
}

// ── Wizard 03-D ────────────────────────────────

function abrirWizardEmprestimo() {
  _wzEmpStep = 1; _wzEmpLeitor = null; _wzEmpLeitorValidado = false;
  _wzEmpMaterial = null; _wzEmpMateriaisRes = [];
  abrirModalEmpBase('Novo Empréstimo');
  _wzEmpRenderStep();
}

function _wzEmpIndicador(step) {
  return wizardIndicador(step, 3, ['Selec. Leitor', 'Selec. Material', 'Confirmar']);
}

async function _wzEmpRenderStep() {
  const conteudo = document.getElementById('modal-emp-conteudo');
  const footer   = document.getElementById('modal-emp-footer');
  document.getElementById('modal-emp-erro').classList.add('hidden');

  if (_wzEmpStep === 1) {
    conteudo.innerHTML = _wzEmpIndicador(1) + `
      <div class="form-group">
        <label class="form-label">Nº Cartão do Leitor *</label>
        <div style="display:flex;gap:8px">
          <input id="wzl-cartao" class="input-field" style="flex:1" placeholder="Ex: MAP20240001"
                 onkeydown="if(event.key==='Enter')_wzEmpValidarLeitor()"/>
          <button class="btn-ghost btn-sm" onclick="_wzEmpValidarLeitor()" style="white-space:nowrap;flex-shrink:0">
            <i class="fa-solid fa-magnifying-glass" style="margin-right:4px"></i>Verificar
          </button>
        </div>
      </div>
      <div id="wzl-card"></div>`;
    footer.innerHTML = `
      <button class="btn-ghost" onclick="fecharModalEmp()">Cancelar</button>
      <button class="btn-primary" id="wzl-btn-proximo" disabled onclick="_wzEmpAvancar()">
        Próximo <i class="fa-solid fa-arrow-right" style="margin-left:4px"></i>
      </button>`;

  } else if (_wzEmpStep === 2) {
    conteudo.innerHTML = _wzEmpIndicador(2) + `
      <div class="form-group">
        <label class="form-label">Pesquisar Material *</label>
        <div style="display:flex;gap:8px">
          <input id="wzm-search" class="input-field" style="flex:1" placeholder="Título, autor ou código…"
                 onkeydown="if(event.key==='Enter')_wzEmpPesquisarMaterial()"/>
          <button class="btn-ghost btn-sm" onclick="_wzEmpPesquisarMaterial()" style="white-space:nowrap;flex-shrink:0">
            <i class="fa-solid fa-magnifying-glass" style="margin-right:4px"></i>Pesquisar
          </button>
        </div>
      </div>
      <div id="wzm-lista"></div>
      <div id="wzm-card"></div>`;
    footer.innerHTML = `
      <button class="btn-ghost" onclick="_wzEmpRecuar()">
        <i class="fa-solid fa-arrow-left" style="margin-right:4px"></i>Anterior
      </button>
      <button class="btn-primary" id="wzm-btn-proximo" disabled onclick="_wzEmpAvancar()">
        Próximo <i class="fa-solid fa-arrow-right" style="margin-left:4px"></i>
      </button>`;

  } else {
    conteudo.innerHTML = _wzEmpIndicador(3) +
      `<div id="wzc-conteudo"><p style="text-align:center;color:var(--text-muted);font-size:12px;padding:16px">A calcular prazo…</p></div>`;
    footer.innerHTML = `
      <button class="btn-ghost" onclick="_wzEmpRecuar()">
        <i class="fa-solid fa-arrow-left" style="margin-right:4px"></i>Anterior
      </button>
      <button class="btn-primary" id="wzc-btn-confirmar" onclick="_wzEmpConfirmar()">
        <i class="fa-solid fa-check" style="margin-right:4px"></i>Confirmar Empréstimo
      </button>`;
    await _wzEmpCarregarStep3();
  }
}

async function _wzEmpValidarLeitor() {
  const val = document.getElementById('wzl-cartao')?.value.trim();
  if (!val) return;
  const card = document.getElementById('wzl-card');
  if (!card) return;
  card.innerHTML = '<p style="color:var(--text-muted);font-size:12px">A validar…</p>';
  const btnProximo = document.getElementById('wzl-btn-proximo');
  if (btnProximo) btnProximo.disabled = true;
  _wzEmpLeitorValidado = false;

  try {
    const validacao = await get(`/api/emprestimos/validar-leitor/${encodeURIComponent(val)}`);
    let leitorData = null;
    try { leitorData = await get(`/api/leitores/${encodeURIComponent(val)}`); } catch {}

    _wzEmpLeitor = leitorData
      ? { ...leitorData, NUM_CARTAO: leitorData.NUM_CARTAO || val }
      : { NUM_CARTAO: val };

    const pode = validacao.pode_emprestar !== false;
    _wzEmpLeitorValidado = pode;
    const nome = _wzEmpLeitor.NOME_COMPLETO || _wzEmpLeitor.NOME_LEITOR || val;

    card.innerHTML = `
      <div style="border:0.5px solid ${pode ? '#1a5a4a' : '#6a2020'};border-radius:8px;
                  padding:12px;background:${pode ? '#0d2820' : '#2a0a0a'}">
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:8px">
          <div class="avatar-initials" style="width:36px;height:36px;font-size:13px">${iniciais(nome)}</div>
          <div>
            <div style="font-weight:600;font-size:13px;color:var(--text-primary)">${nome}</div>
            <div style="font-family:monospace;font-size:10px;color:var(--text-muted)">${_wzEmpLeitor.NUM_CARTAO}</div>
          </div>
        </div>
        ${_wzEmpLeitor.TIPO_LEITOR ? `
        <div style="font-size:11px;color:var(--text-secondary);margin-bottom:6px">
          Tipo: ${_wzEmpLeitor.TIPO_LEITOR}
          · Pontualidade: ${_wzEmpLeitor.HISTORICO_PONTUALIDADE || '—'}
          ${_wzEmpLeitor.DISTANCIA_BIBLIOTECA
            ? ` · ${_wzEmpLeitor.DISTANCIA_BIBLIOTECA} km da biblioteca` : ''}
        </div>` : ''}
        ${!pode
          ? `<div style="padding:7px 10px;background:#2a0a0a;border-radius:5px;font-size:12px;color:#f85149">
               <i class="fa-solid fa-circle-xmark" style="margin-right:5px"></i>${validacao.motivo || 'Leitor não pode realizar empréstimo.'}
             </div>`
          : `<div style="padding:7px 10px;background:#0d2820;border-radius:5px;font-size:12px;color:var(--theme-accent-text)">
               <i class="fa-solid fa-circle-check" style="margin-right:5px"></i>Leitor disponível para empréstimo.
             </div>`}
      </div>`;

    if (btnProximo) btnProximo.disabled = !pode;
  } catch (err) {
    card.innerHTML = `<div style="padding:8px 10px;background:#2a0a0a;border-radius:6px;font-size:12px;color:#f85149">
      ${err.message}
    </div>`;
    _wzEmpLeitor = null;
  }
}

async function _wzEmpPesquisarMaterial() {
  const q = document.getElementById('wzm-search')?.value.trim();
  if (!q) return;
  const lista = document.getElementById('wzm-lista');
  if (!lista) return;
  lista.innerHTML = '<p style="color:var(--text-muted);font-size:12px">A pesquisar…</p>';
  try {
    const res = await get(`/api/materiais?search=${encodeURIComponent(q)}`);
    _wzEmpMateriaisRes = (Array.isArray(res) ? res : (res.materiais || []))
      .filter(m => m.ESTADO_MATERIAL_CONSERVACAO !== 'Indisponivel' && m.DISPONIVEL !== 'N')
      .slice(0, 8);

    if (!_wzEmpMateriaisRes.length) {
      lista.innerHTML = '<p style="color:var(--text-muted);font-size:12px;padding:6px 0">Nenhum material disponível encontrado.</p>';
      return;
    }
    lista.innerHTML =
      `<div style="border:0.5px solid var(--border);border-radius:8px;overflow:hidden;margin-bottom:8px">` +
      _wzEmpMateriaisRes.map((m, i) => `
        <div class="ctx-menu-item" style="border-bottom:0.5px solid var(--border-soft)" onclick="_wzEmpSelecionarMaterial(${i})">
          <div style="font-weight:500;font-size:12px;color:var(--text-primary)">${m.TITULO || '—'}</div>
          <div style="font-size:10px;color:var(--text-muted)">
            ${m.AUTOR ? m.AUTOR + ' · ' : ''}
            <span style="font-family:monospace">${m.COD_MATERIAL || ''}</span>
            ${m.TIPO_MATERIAL || m.TIPO ? ' · ' + (m.TIPO_MATERIAL || m.TIPO) : ''}
          </div>
        </div>`).join('') + `</div>`;
  } catch (err) {
    lista.innerHTML = `<div style="padding:8px;background:#2a0a0a;border-radius:6px;font-size:12px;color:#f85149">${err.message}</div>`;
  }
}

function _wzEmpSelecionarMaterial(idx) {
  const mat = _wzEmpMateriaisRes[idx];
  if (!mat) return;
  _wzEmpMaterial = mat;

  const lista = document.getElementById('wzm-lista');
  if (lista) lista.innerHTML = '';

  const card = document.getElementById('wzm-card');
  if (!card) return;
  card.innerHTML = `
    <div style="border:0.5px solid #1a5a3a;border-radius:8px;padding:12px;background:#0d2d1f">
      <div style="font-weight:600;font-size:13px;color:var(--text-primary);margin-bottom:4px">${mat.TITULO || '—'}</div>
      <div style="font-size:11px;color:var(--text-secondary);margin-bottom:8px">
        ${mat.AUTOR || ''}${mat.EDITORA ? ' · ' + mat.EDITORA : ''}
      </div>
      <div style="display:flex;gap:6px;flex-wrap:wrap;align-items:center;margin-bottom:6px">
        ${mat.TIPO_MATERIAL || mat.TIPO
          ? `<span class="bdg">${mat.TIPO_MATERIAL || mat.TIPO}</span>` : ''}
        ${mat.ESTADO_MATERIAL_CONSERVACAO
          ? `<span class="bdg">${mat.ESTADO_MATERIAL_CONSERVACAO}</span>` : ''}
        ${mat.LOCALIZACAO_ESTANTE
          ? `<span style="font-size:10px;color:var(--text-muted)">
               <i class="fa-solid fa-location-dot" style="margin-right:3px"></i>${mat.LOCALIZACAO_ESTANTE}
             </span>` : ''}
      </div>
      ${mat.NIVEL_LEITURA
        ? `<div style="font-size:11px;color:var(--text-muted);margin-bottom:8px">Nível de leitura: ${mat.NIVEL_LEITURA}</div>` : ''}
      <button class="btn-ghost btn-sm"
              onclick="_wzEmpMaterial=null;document.getElementById('wzm-card').innerHTML='';document.getElementById('wzm-btn-proximo').disabled=true">
        <i class="fa-solid fa-xmark" style="margin-right:4px"></i>Mudar material
      </button>
    </div>`;

  const btn = document.getElementById('wzm-btn-proximo');
  if (btn) btn.disabled = false;
}

async function _wzEmpCarregarStep3() {
  const nc = _wzEmpLeitor?.NUM_CARTAO;
  if (!nc) {
    document.getElementById('wzc-conteudo').innerHTML =
      '<p style="color:#f85149;font-size:12px">Leitor não identificado.</p>';
    return;
  }
  try {
    const prazo = await post('/api/emprestimos/calcular-prazo', { num_cartao: nc });
    const det   = prazo.detalhes || {};
    document.getElementById('wzc-conteudo').innerHTML = `
      <div style="border:0.5px solid var(--border);border-radius:8px;padding:12px;background:var(--surface);margin-bottom:12px">
        <div style="font-size:10px;font-weight:500;color:var(--text-muted);text-transform:uppercase;
                    letter-spacing:.06em;margin-bottom:8px">Resumo</div>
        <div style="font-size:12px;display:flex;justify-content:space-between;
                    padding:4px 0;border-bottom:0.5px solid var(--border-soft)">
          <span style="color:var(--text-muted)">Leitor</span>
          <span style="font-weight:500;color:var(--text-primary)">${_wzEmpLeitor.NOME_COMPLETO || _wzEmpLeitor.NOME_LEITOR || nc}</span>
        </div>
        <div style="font-size:12px;display:flex;justify-content:space-between;padding:4px 0">
          <span style="color:var(--text-muted)">Material</span>
          <span style="font-weight:500;color:var(--text-primary)">${_wzEmpMaterial?.TITULO || '—'}</span>
        </div>
      </div>
      <div style="border:0.5px solid var(--border);border-radius:8px;padding:12px;background:var(--surface);
                  margin-bottom:14px;font-family:monospace;font-size:12px;color:var(--text-secondary);line-height:1.9">
        14 dias (base)<br>
        + ${det.geografico || 0} dias (distância)<br>
        ${(det.professor || 0) > 0   ? `+ ${det.professor} dias (professor)<br>` : ''}
        ${(det.pontualidade || 0) < 0 ? `${det.pontualidade} dias (pontualidade)<br>` : ''}
        <span style="display:block;border-top:0.5px solid #e5e5e5;margin-top:4px;padding-top:6px;
                     font-size:13px;color:var(--text-primary);font-weight:700">
          = ${prazo.dias_prazo} dias →
          <span style="color:var(--theme-accent-text)">${fmtData(prazo.prazo_devolucao)}</span>
        </span>
      </div>
      <div class="form-group">
        <label class="form-label">Estado do material na saída *</label>
        <select id="wzc-estado-saida" class="input-field">
          <option value="Bom">Bom</option>
          <option value="Degradado">Degradado</option>
        </select>
      </div>`;
  } catch (err) {
    document.getElementById('wzc-conteudo').innerHTML =
      `<div style="padding:8px;background:#2a0a0a;border-radius:6px;font-size:12px;color:#f85149">${err.message}</div>`;
  }
}

async function _wzEmpAvancar() {
  if (_wzEmpStep === 1 && (!_wzEmpLeitor || !_wzEmpLeitorValidado)) {
    mostrarErroEmp('Seleccione um leitor válido antes de avançar.'); return;
  }
  if (_wzEmpStep === 2 && !_wzEmpMaterial) {
    mostrarErroEmp('Seleccione um material antes de avançar.'); return;
  }
  _wzEmpStep++;
  await _wzEmpRenderStep();
}

function _wzEmpRecuar() {
  _wzEmpStep--;
  _wzEmpRenderStep();
}

async function _wzEmpConfirmar() {
  if (!_wzEmpLeitor || !_wzEmpMaterial) { mostrarErroEmp('Dados incompletos.'); return; }
  const btn = document.getElementById('wzc-btn-confirmar');
  if (btn) btn.disabled = true;
  try {
    const res = await post('/api/emprestimos', {
      num_cartao:           _wzEmpLeitor.NUM_CARTAO,
      cod_material:         _wzEmpMaterial.COD_MATERIAL,
      estado_material_saida: document.getElementById('wzc-estado-saida')?.value || 'Bom',
    });
    fecharModalEmp();
    let msg = `Empréstimo registado. Prazo: ${fmtData(res.prazo_devolucao)}.`;
    if (res.aviso_nivel_leitura) msg += ' Atenção: nível de leitura incompatível.';
    toast(msg);
    carregarEmprestimos(tabEmprestimosActual);
  } catch (err) {
    if (btn) btn.disabled = false;
    mostrarErroEmp(err.message);
  }
}

// ── Modal devolução 03-C ───────────────────────

async function abrirModalDevolucao(id) {
  _devolucaoId = id;
  abrirModalEmpBase('Registar Devolução');
  document.getElementById('modal-emp-conteudo').innerHTML =
    '<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:16px"><i class="fa-solid fa-spinner fa-spin" style="margin-right:6px"></i>A carregar…</p>';
  try {
    _devolucaoEmp = await get(`/api/emprestimos/${id}`);
    _renderizarFormDevolucao();
  } catch (err) {
    mostrarErroEmp(err.message);
  }
}

function _renderizarFormDevolucao() {
  const e = _devolucaoEmp;
  const atrasado = (e.DIAS_ATRASO || 0) > 0;

  document.getElementById('modal-emp-conteudo').innerHTML = `
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:14px">
      <div style="border:0.5px solid var(--border);border-radius:8px;padding:10px;background:var(--surface-raised)">
        <div style="font-size:9px;font-weight:500;color:var(--text-muted);text-transform:uppercase;
                    letter-spacing:.06em;margin-bottom:4px">Leitor</div>
        <div style="font-weight:600;font-size:12px;color:var(--text-primary)">${e.NOME_LEITOR || '—'}</div>
        <div style="font-family:monospace;font-size:10px;color:var(--text-muted)">${e.NUM_CARTAO || '—'}</div>
      </div>
      <div style="border:0.5px solid var(--border);border-radius:8px;padding:10px;background:var(--surface-raised)">
        <div style="font-size:9px;font-weight:500;color:var(--text-muted);text-transform:uppercase;
                    letter-spacing:.06em;margin-bottom:4px">Material</div>
        <div style="font-weight:600;font-size:12px;color:var(--text-primary);
                    overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${e.TITULO || '—'}</div>
        <div style="font-size:10px;color:var(--text-muted)">Saída: ${e.ESTADO_MATERIAL_SAIDA || '—'}</div>
      </div>
    </div>
    ${atrasado ? `
    <div style="background:#2d1015;border:0.5px solid #5c2020;border-radius:6px;
                padding:8px 12px;margin-bottom:12px;font-size:12px;color:#f85149">
      <i class="fa-solid fa-clock" style="margin-right:6px"></i>
      <b>${e.DIAS_ATRASO} dias de atraso</b>
      ${e.DIAS_ATRASO > 60
        ? ' — Leitor será bloqueado automaticamente (RN03.3).' : ''}
    </div>` : ''}
    <div class="form-group">
      <label class="form-label">Estado do material na devolução *</label>
      <select id="dev-estado-retorno" class="input-field" onchange="_previewDevolucaoEmp()">
        <option value="Bom">Bom</option>
        <option value="Degradado">Degradado</option>
        <option value="Destruído">Destruído</option>
        <option value="Perdido">Perdido</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Observações</label>
      <textarea id="dev-observacoes" class="input-field" rows="2"
                placeholder="Notas opcionais…"></textarea>
    </div>
    <div id="dev-preview-multa"></div>
  `;

  document.getElementById('modal-emp-footer').innerHTML = `
    <button class="btn-ghost" onclick="fecharModalEmp()">Cancelar</button>
    <button class="btn-primary" onclick="confirmarDevolucao()">
      <i class="fa-solid fa-rotate-left" style="margin-right:4px"></i>Confirmar Devolução
    </button>`;

  _previewDevolucaoEmp();
}

async function _previewDevolucaoEmp() {
  const estado = document.getElementById('dev-estado-retorno')?.value || 'Bom';
  const prev   = document.getElementById('dev-preview-multa');
  if (!prev) return;
  try {
    const res = await post('/api/emprestimos/preview-devolucao', {
      id_emprestimo:         _devolucaoId,
      estado_material_retorno: estado,
    });
    const temMulta = (res.multa_total || 0) > 0;
    const grave    = estado === 'Destruído' || estado === 'Perdido';
    prev.innerHTML = `
      <div style="border:0.5px solid ${temMulta ? '#e07820' : '#1a5a4a'};border-radius:8px;
                  padding:12px;background:${temMulta ? '#2a1500' : '#0d2820'}">
        <div style="font-size:10px;font-weight:500;color:var(--text-muted);text-transform:uppercase;
                    letter-spacing:.06em;margin-bottom:8px">Preview da Multa</div>
        <div style="font-size:12px;display:flex;justify-content:space-between;margin-bottom:4px">
          <span style="color:var(--text-secondary)">
            Por atraso (${res.dias_atraso || 0} dias × ${fmtMoeda(res.detalhes?.taxa_diaria || 0)})
          </span>
          <span style="${(res.multa_atraso || 0) > 0 ? 'color:#e07820;font-weight:500' : 'color:var(--text-muted)'}">
            ${fmtMoeda(res.multa_atraso || 0)}
          </span>
        </div>
        <div style="font-size:12px;display:flex;justify-content:space-between;margin-bottom:8px">
          <span style="color:var(--text-secondary)">Por estado do material</span>
          <span style="${(res.multa_dano || 0) > 0 ? 'color:#e07820;font-weight:500' : 'color:var(--text-muted)'}">
            ${fmtMoeda(res.multa_dano || 0)}
          </span>
        </div>
        <div style="font-size:13px;display:flex;justify-content:space-between;
                    border-top:0.5px solid #e5e5e5;padding-top:6px;font-weight:700">
          <span style="color:var(--text-primary)">Total</span>
          <span style="${temMulta ? 'color:#e07820' : 'color:var(--theme-accent-text)'}">
            ${fmtMoeda(res.multa_total || 0)}
          </span>
        </div>
        ${grave ? `
        <div style="margin-top:8px;font-size:11px;color:#f85149">
          <i class="fa-solid fa-triangle-exclamation" style="margin-right:4px"></i>
          Material será marcado como Indisponível no catálogo.
        </div>` : ''}
      </div>`;
  } catch {
    prev.innerHTML = '';
  }
}

async function confirmarDevolucao() {
  if (!_devolucaoId) return;
  const estado_material_retorno = document.getElementById('dev-estado-retorno')?.value || 'Bom';
  const observacoes_devolucao   = document.getElementById('dev-observacoes')?.value?.trim() || '';
  const empId = _devolucaoId;
  try {
    const res = await api(`/api/emprestimos/${empId}/devolver`, {
      method: 'PATCH',
      body: { estado_material_retorno, observacoes_devolucao },
    });
    fecharModalEmp();
    let msg = 'Devolução registada.';
    if ((res.multa || 0) > 0) msg += ` Multa: ${fmtMoeda(res.multa)}.`;
    if (res.suspensao)        msg += ` Suspensão de ${res.suspensao.dias} dias aplicada.`;
    toast(msg);
    carregarEmprestimos(tabEmprestimosActual);
    if (_drawerEmpId === empId) abrirDrawerEmp(empId);
  } catch (err) {
    mostrarErroEmp(err.message);
  }
}

// ── Marcar multa paga ──────────────────────────

function marcarMultaPagaEmp(id) {
  confirmar('Confirmar pagamento da multa deste empréstimo?', async () => {
    try {
      await api(`/api/emprestimos/${id}/pagar-multa`, { method: 'PATCH', body: {} });
      toast('Multa marcada como paga.');
      carregarEmprestimos(tabEmprestimosActual);
      if (_drawerEmpId === id) abrirDrawerEmp(id);
    } catch (err) { toast(err.message, 'erro'); }
  }, { labelOk: 'Confirmar pagamento', danger: false });
}

// ── Eliminar ───────────────────────────────────

function eliminarEmprestimo(id) {
  confirmar(`Eliminar empréstimo #${id}? Esta acção é irreversível.`, async () => {
    try {
      await del(`/api/emprestimos/${id}`);
      toast('Empréstimo eliminado.');
      carregarEmprestimos(tabEmprestimosActual);
    } catch (err) { toast(err.message || 'Operação falhou.', 'erro'); }
  });
}
