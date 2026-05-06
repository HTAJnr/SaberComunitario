// ════════════════════════════════════════════════
// DOAÇÕES (TELA 07)
// ════════════════════════════════════════════════

let _doacTab      = 'doacoes';
let _doacRows     = [];
let _drawerDoacId   = null;
let _drawerDoacTab  = 'info';
let _drawerDoacData = null;
let _certDoacId     = null;
let _wizStep        = 1;
let _wizDoador      = null;
let _wizItens       = [];
let _wizBibliotecas = [];
let _wizBibOpts     = '';

// ── Helpers de apresentação ────────────────────

function _dcampo(label, valor, estilo) {
  return `<div style="display:flex;justify-content:space-between;align-items:baseline;
                      padding:5px 0;border-bottom:0.5px solid #f0f0f0;font-size:12px">
    <span style="color:var(--text-muted);flex-shrink:0;margin-right:8px">${label}</span>
    <span style="text-align:right;${estilo || ''}">${valor ?? '—'}</span>
  </div>`;
}

function _dsecao(titulo) {
  return `<div style="font-size:10px;font-weight:500;color:var(--text-muted);text-transform:uppercase;
                      letter-spacing:.06em;margin:14px 0 6px">${titulo}</div>`;
}

function _badgeTipoDoador(tipo) {
  if (!tipo) return '—';
  const m = { INDIVIDUAL: 'bdg-activo-emp', INSTITUCIONAL: 'bdg-suspenso' };
  const label = tipo === 'INDIVIDUAL' ? 'Individual' : 'Institucional';
  return `<span class="bdg ${m[tipo] || ''}">${label}</span>`;
}

function _badgeCertificado(numCert) {
  if (numCert) return `<span class="bdg bdg-devolvido" style="font-size:10px">Emitido</span>`;
  return `<span class="bdg" style="font-size:10px;background:#e5e7eb;color:var(--text-secondary)">Pendente</span>`;
}

// ── Tab switching ──────────────────────────────

function switchTabDoacoes(tab) {
  _doacTab = tab;

  ['doacoes','doadores','certificados'].forEach(t => {
    const sub = document.getElementById(`sub-${t}`);
    const btn = document.getElementById(`tab-${t}-btn`);
    if (sub) sub.style.display = t === tab ? '' : 'none';
    if (btn) btn.classList.toggle('tab-active', t === tab);
  });

  const nivel = utilizadorActual?.NIVEL_ACESSO || '';
  const podeGerir = ['Administrador','Coordenador'].includes(nivel);

  const btnWiz = document.getElementById('btn-registar-doacao-wrap');
  if (btnWiz) btnWiz.style.display = (tab === 'doacoes' && podeGerir) ? '' : 'none';

  const btnNovoDoador = document.getElementById('btn-novo-doador');
  if (btnNovoDoador) btnNovoDoador.style.display = podeGerir ? '' : 'none';

  if (tab === 'doacoes')           carregarDoacoes();
  else if (tab === 'doadores')     carregarDoadores();
  else if (tab === 'certificados') carregarCertificados();
}

// ── 07-A Lista ─────────────────────────────────

async function carregarDoacoes() {
  try {
    const resp = await get('/api/doacoes');
    _doacRows = resp.dados || [];
    _renderizarTabelaDoacoes();
  } catch (err) {
    toast('Erro a carregar doações: ' + err.message, 'erro');
  }
}

function _renderizarTabelaDoacoes() {
  const q = (document.getElementById('filtro-doac-q')?.value || '').toLowerCase();
  let rows = _doacRows;
  if (q) rows = rows.filter(r => (r.NOME_DOADOR || '').toLowerCase().includes(q));

  const tbody = document.getElementById('tabela-doacoes');
  if (!tbody) return;
  tbody.innerHTML = rows.length ? rows.map(_linhaDoacoes).join('') : linhaVazia(8);
}

function _linhaDoacoes(r) {
  const nomeDoador = r.NOME_DOADOR || 'Anónimo';
  const tipoBadge  = r.TIPO_DOADOR
    ? _badgeTipoDoador(r.TIPO_DOADOR)
    : '<span style="color:var(--text-muted);font-size:11px;font-style:italic">Anónimo</span>';

  return `<tr>
    <td style="font-size:11px;color:var(--text-muted);font-family:monospace">${r.ID_DOACAO}</td>
    <td style="font-weight:500">${nomeDoador}</td>
    <td>${tipoBadge}</td>
    <td style="color:var(--text-muted)">${fmtData(r.DATA_DOACAO)}</td>
    <td style="text-align:center;color:var(--text-muted)">${r.TOTAL_ITENS ?? '—'}</td>
    <td style="color:#3fb27a;font-weight:500">${fmtMoeda(r.VALOR_TOTAL)}</td>
    <td>${_badgeCertificado(r.CERTIFICADO_NUMERO)}</td>
    <td style="text-align:right">
      <button class="btn-ghost btn-sm" onclick="abrirCtxMenuDoacao(event,${r.ID_DOACAO})">···</button>
    </td>
  </tr>`;
}

// ── Context menu ───────────────────────────────

function abrirCtxMenuDoacao(evt, id) {
  evt.stopPropagation();
  const nivel = utilizadorActual?.NIVEL_ACESSO || '';
  const podeGerir = ['Administrador','Coordenador'].includes(nivel);

  const menu = document.getElementById('ctx-menu-doac');
  menu.innerHTML = `
    <div class="ctx-menu-item" onclick="fecharCtxMenuDoacao();abrirDrawerDoacao(${id})">
      <i class="fa-solid fa-eye" style="width:14px"></i> Ver detalhe
    </div>
    ${podeGerir ? `
    <div class="ctx-menu-item" onclick="fecharCtxMenuDoacao();abrirModalCertificado(${id})">
      <i class="fa-solid fa-certificate" style="width:14px"></i> Emitir certificado
    </div>` : ''}
  `;

  const btn  = evt.currentTarget;
  const rect = btn.getBoundingClientRect();
  menu.style.display  = 'block';
  menu.style.position = 'fixed';
  menu.style.top      = (rect.bottom + 4) + 'px';
  menu.style.left     = Math.max(4, rect.right - 200) + 'px';

  setTimeout(() => document.addEventListener('click', fecharCtxMenuDoacao, { once: true }), 0);
}

function fecharCtxMenuDoacao() {
  const m = document.getElementById('ctx-menu-doac');
  if (m) m.style.display = 'none';
}

// ── Drawer 07-B ────────────────────────────────

async function abrirDrawerDoacao(id) {
  _drawerDoacId   = id;
  _drawerDoacTab  = 'info';
  _drawerDoacData = null;

  document.getElementById('drawer-doac-overlay').style.display = 'block';
  document.getElementById('drawer-doac').classList.add('open');

  ['info','itens','certs'].forEach(t =>
    document.getElementById(`dtab-doac-${t}`)?.classList.toggle('tab-active', t === 'info')
  );

  const conteudo = document.getElementById('drawer-doac-conteudo');
  conteudo.innerHTML = '<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:24px">A carregar…</p>';

  try {
    _drawerDoacData = await get(`/api/doacoes/${id}`);
    document.getElementById('drawer-doac-titulo').textContent = `Doação #${_drawerDoacData.ID_DOACAO}`;
    _renderizarDrawerInfoDoacao(_drawerDoacData);
  } catch (err) {
    conteudo.innerHTML = `<p style="text-align:center;color:#f85149;font-size:12px;padding:24px">Erro: ${err.message}</p>`;
  }
}

function fecharDrawerDoacao() {
  document.getElementById('drawer-doac-overlay').style.display = 'none';
  document.getElementById('drawer-doac').classList.remove('open');
  _drawerDoacId   = null;
  _drawerDoacData = null;
}

function mudarTabDrawerDoacao(tab) {
  _drawerDoacTab = tab;
  ['info','itens','certs'].forEach(t =>
    document.getElementById(`dtab-doac-${t}`)?.classList.toggle('tab-active', t === tab)
  );

  if (!_drawerDoacData) return;
  if (tab === 'info')        _renderizarDrawerInfoDoacao(_drawerDoacData);
  else if (tab === 'itens')  _renderizarDrawerItensDoacao(_drawerDoacData);
  else if (tab === 'certs')  _renderizarDrawerCertsDoacao(_drawerDoacData);
}

function _renderizarDrawerInfoDoacao(d) {
  document.getElementById('drawer-doac-conteudo').innerHTML = `
    ${_dsecao('Doação')}
    ${_dcampo('ID', `<span style="font-family:monospace">#${d.ID_DOACAO}</span>`)}
    ${_dcampo('Data', fmtData(d.DATA_DOACAO))}
    ${_dsecao('Doador')}
    ${_dcampo('Nome', d.NOME_DOADOR || '<em style="color:var(--text-muted)">Anónimo</em>')}
    ${d.TIPO_DOADOR ? _dcampo('Tipo', _badgeTipoDoador(d.TIPO_DOADOR)) : ''}
    ${d.CONTACTO   ? _dcampo('Contacto', d.CONTACTO) : ''}
    ${d.ENDERECO   ? _dcampo('Endereço', d.ENDERECO) : ''}
  `;
}

function _renderizarDrawerItensDoacao(d) {
  const itens = d.itens || [];
  const conteudo = document.getElementById('drawer-doac-conteudo');
  if (!itens.length) {
    conteudo.innerHTML = emptyState('📦', 'Sem itens registados');
    return;
  }
  const total = itens.reduce((acc, i) => acc + (i.VALOR_ESTIMADO || 0) * (i.QUANTIDADE || 1), 0);
  conteudo.innerHTML = `
    <div style="font-size:12px">
      ${itens.map(i => `
        <div style="padding:8px 0;border-bottom:0.5px solid #f0f0f0">
          <div style="display:flex;justify-content:space-between;align-items:baseline">
            <span style="font-weight:500">${i.NOME_BIBLIOTECA || i.COD_BIBLIOTECA || '—'}</span>
            <span style="color:#3fb27a">${fmtMoeda((i.VALOR_ESTIMADO || 0) * (i.QUANTIDADE || 1))}</span>
          </div>
          <div style="color:var(--text-muted);margin-top:2px">
            Qtd: ${i.QUANTIDADE || 1} · ${fmtMoeda(i.VALOR_ESTIMADO)} / un.
          </div>
          ${i.OBSERVACOES ? `<div style="color:var(--text-muted);font-size:11px;margin-top:2px">${i.OBSERVACOES}</div>` : ''}
        </div>`).join('')}
      <div style="display:flex;justify-content:space-between;padding:10px 0;font-size:12px;font-weight:600">
        <span>Total estimado</span>
        <span style="color:#3fb27a">${fmtMoeda(total)}</span>
      </div>
    </div>`;
}

function _renderizarDrawerCertsDoacao(d) {
  const certs = d.certs || [];
  const conteudo = document.getElementById('drawer-doac-conteudo');
  if (!certs.length) {
    conteudo.innerHTML = emptyState('📜', 'Nenhum certificado emitido');
    return;
  }
  conteudo.innerHTML = `
    <div style="font-size:12px">
      ${certs.map(c => `
        <div style="padding:8px 0;border-bottom:0.5px solid #f0f0f0">
          <div style="display:flex;justify-content:space-between;align-items:baseline">
            <span style="font-family:monospace;font-weight:500;color:#a78bfa">${c.NUM_CERTIFICADO || '—'}</span>
            <span class="bdg bdg-devolvido" style="font-size:10px">${c.TIPO_CERTIFICADO || '—'}</span>
          </div>
          <div style="color:var(--text-muted);margin-top:2px">${fmtData(c.DATA_EMISSAO)}</div>
          ${c.OBSERVACOES ? `<div style="color:var(--text-muted);font-size:11px;margin-top:2px">${c.OBSERVACOES}</div>` : ''}
        </div>`).join('')}
    </div>`;
}

// ── Modal 07-C — Emitir Certificado ───────────

function abrirModalCertificado(idDoacao) {
  _certDoacId = idDoacao;
  _mostrarErroCert('');
  document.getElementById('modal-cert-conteudo').innerHTML = `
    <div style="display:flex;flex-direction:column;gap:12px">
      <div>
        <label class="form-label">Tipo de Certificado <span style="color:#f85149">*</span></label>
        <select id="cert-tipo" class="input-field" onchange="_onChangeTipoCert()">
          <option value="Original">Original</option>
          <option value="Reemissao">Reemissão</option>
          <option value="Honorifico">Honorífico</option>
        </select>
      </div>
      <div id="cert-reemissao-wrap" style="display:none">
        <label class="form-label">Nº do certificado original (informativo)</label>
        <input id="cert-original-num" class="input-field" placeholder="CERT-AAAA-XXXX"/>
      </div>
      <div>
        <label class="form-label">Observações</label>
        <textarea id="cert-obs" class="input-field" rows="3" style="resize:vertical"></textarea>
      </div>
    </div>
  `;
  document.getElementById('modal-cert-overlay').classList.remove('hidden');
}

function _onChangeTipoCert() {
  const tipo = document.getElementById('cert-tipo')?.value;
  const wrap = document.getElementById('cert-reemissao-wrap');
  if (wrap) wrap.style.display = tipo === 'Reemissao' ? '' : 'none';
}

function fecharModalCertificado(evt) {
  if (evt && evt.target !== document.getElementById('modal-cert-overlay')) return;
  document.getElementById('modal-cert-overlay').classList.add('hidden');
  _certDoacId = null;
}

async function _submeterCertificado() {
  _mostrarErroCert('');
  const tipo = document.getElementById('cert-tipo')?.value;
  const obs  = (document.getElementById('cert-obs')?.value || '').trim() || null;
  if (!tipo) { _mostrarErroCert('Selecciona o tipo de certificado.'); return; }

  try {
    const r = await post(`/api/doacoes/${_certDoacId}/certificado`, { tipo_certificado: tipo, observacoes: obs });
    toast(`Certificado ${r.num_certificado || ''} emitido com sucesso.`, 'sucesso');
    fecharModalCertificado();
    carregarDoacoes();
  } catch (err) {
    _mostrarErroCert(err.message);
  }
}

function _mostrarErroCert(msg) {
  const el  = document.getElementById('modal-cert-erro');
  const txt = document.getElementById('modal-cert-erro-msg');
  if (!msg) { el?.classList.add('hidden'); return; }
  if (txt) txt.textContent = msg;
  el?.classList.remove('hidden');
}

// ── Wizard 07-D — Registar Doação ─────────────

async function abrirWizardDoacao() {
  _wizStep        = 1;
  _wizDoador      = null;
  _wizItens       = [];
  _wizBibliotecas = [];
  _wizBibOpts     = '';

  try { _wizBibliotecas = await get('/api/funcionarios/bibliotecas'); } catch {}
  _wizBibOpts = _wizBibliotecas.map(b =>
    `<option value="${b.COD_BIBLIOTECA}">${b.NOME || b.NOME_BIBLIOTECA}</option>`
  ).join('');

  document.getElementById('modal-wiz-overlay').classList.remove('hidden');
  _mostrarErroWiz('');
  _renderizarWizStep(1);
}

function fecharWizardDoacao(evt) {
  if (evt && evt.target !== document.getElementById('modal-wiz-overlay')) return;
  document.getElementById('modal-wiz-overlay').classList.add('hidden');
}

function _atualizarIndicadorWiz(step) {
  [1,2,3].forEach(n => {
    const ind = document.getElementById(`wiz-step-${n}-ind`);
    if (!ind) return;
    const circle = ind.querySelector('div');
    const label  = ind.querySelector('span');
    if (n < step) {
      circle.style.background = '#10b981'; circle.style.color = '#fff';
      if (label) label.style.color = '#10b981';
    } else if (n === step) {
      circle.style.background = '#6366f1'; circle.style.color = '#fff';
      if (label) label.style.color = '#6366f1';
    } else {
      circle.style.background = '#e5e7eb'; circle.style.color = '#888';
      if (label) label.style.color = '#aaa';
    }
  });
}

function _renderizarWizStep(n) {
  _wizStep = n;
  _atualizarIndicadorWiz(n);
  _mostrarErroWiz('');
  if (n === 1)      _renderizarWizStep1();
  else if (n === 2) _renderizarWizStep2();
  else if (n === 3) _renderizarWizStep3();
}

// Step 1 — Doador
function _renderizarWizStep1() {
  const anonimo = _wizDoador?.anonimo === true;

  document.getElementById('modal-wiz-conteudo').innerHTML = `
    <div style="display:flex;flex-direction:column;gap:14px;padding:4px 0">

      <div style="display:flex;gap:8px">
        <button onclick="_wizToggleAnonimo(false)" class="btn-ghost"
                style="flex:1;font-size:12px;${!anonimo ? 'border-color:#a78bfa;color:#a78bfa;font-weight:600' : ''}">
          <i class="fa-solid fa-user" style="margin-right:5px"></i>Doador Identificado
        </button>
        <button onclick="_wizToggleAnonimo(true)" class="btn-ghost"
                style="flex:1;font-size:12px;${anonimo ? 'border-color:#a78bfa;color:#a78bfa;font-weight:600' : ''}">
          <i class="fa-solid fa-user-secret" style="margin-right:5px"></i>Anónimo
        </button>
      </div>

      <div id="wiz-painel-identificado" style="${anonimo ? 'display:none' : ''}">
        <div style="display:flex;gap:6px;margin-bottom:8px">
          <input id="wiz-doador-pesq" type="text" class="input-field"
                 placeholder="Pesquisar doador pelo nome…"
                 style="flex:1;font-size:12px"
                 onkeydown="if(event.key==='Enter'){event.preventDefault();_wizPesquisarDoador();}"/>
          <button onclick="_wizPesquisarDoador()" class="btn-ghost" style="font-size:12px;white-space:nowrap">
            <i class="fa-solid fa-magnifying-glass"></i>
          </button>
        </div>
        <div id="wiz-doador-resultados" style="margin-bottom:10px"></div>

        ${_wizDoador && !_wizDoador.anonimo ? `
          <div style="background:#0d2d1f;border:1px solid #1a5a3a;border-radius:6px;
                      padding:10px;font-size:12px;margin-bottom:10px">
            <div style="font-weight:600;color:#3fb27a">
              <i class="fa-solid fa-circle-check" style="margin-right:5px;color:#3fb27a"></i>${_wizDoador.nome}
            </div>
            <div style="color:#3fb27a;margin-top:2px">${_wizDoador.tipo === 'INDIVIDUAL' ? 'Individual' : 'Institucional'}</div>
          </div>` : ''}

        <details>
          <summary style="font-size:11px;color:#a78bfa;cursor:pointer;list-style:none;
                          display:flex;align-items:center;gap:4px;padding:4px 0">
            <i class="fa-solid fa-plus" style="font-size:10px"></i> Criar novo doador
          </summary>
          <div style="display:flex;flex-direction:column;gap:8px;margin-top:10px;
                      padding:12px;background:var(--surface-raised);border-radius:6px;border:1px solid var(--border)">
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px">
              <div>
                <label class="form-label" style="font-size:11px">Nome *</label>
                <input id="wiz-nd-nome" class="input-field" style="font-size:12px"/>
              </div>
              <div>
                <label class="form-label" style="font-size:11px">Tipo *</label>
                <select id="wiz-nd-tipo" class="input-field" style="font-size:12px">
                  <option value="INDIVIDUAL">Individual</option>
                  <option value="INSTITUCIONAL">Institucional</option>
                </select>
              </div>
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px">
              <div>
                <label class="form-label" style="font-size:11px">Contacto</label>
                <input id="wiz-nd-contacto" class="input-field" style="font-size:12px"/>
              </div>
              <div>
                <label class="form-label" style="font-size:11px">Endereço</label>
                <input id="wiz-nd-endereco" class="input-field" style="font-size:12px"/>
              </div>
            </div>
            <button onclick="_wizCriarNovoDoador()" class="btn-primary"
                    style="font-size:12px;align-self:flex-end">
              <i class="fa-solid fa-floppy-disk" style="margin-right:4px"></i>Guardar Doador
            </button>
          </div>
        </details>
      </div>

      <div id="wiz-painel-anonimo" style="${anonimo ? '' : 'display:none'}">
        <div style="background:var(--surface-raised);border:1px solid var(--border);border-radius:6px;
                    padding:12px;font-size:12px;color:#d29922">
          <i class="fa-solid fa-circle-info" style="margin-right:6px"></i>
          A doação será registada sem identificação do doador (RN10). Não será gerado certificado automático.
        </div>
      </div>

    </div>
  `;

  document.getElementById('modal-wiz-footer').innerHTML = `
    <button class="btn-ghost" onclick="fecharWizardDoacao()">Cancelar</button>
    <button class="btn-primary" onclick="_wizAvancar()">
      Seguinte <i class="fa-solid fa-chevron-right" style="margin-left:4px"></i>
    </button>`;
}

function _wizToggleAnonimo(isAnonimo) {
  _wizDoador = isAnonimo ? { anonimo: true, id_doador: 0 } : null;
  _renderizarWizStep1();
}

async function _wizPesquisarDoador() {
  const q = (document.getElementById('wiz-doador-pesq')?.value || '').trim();
  const resultados = document.getElementById('wiz-doador-resultados');
  if (!resultados) return;
  if (!q) { resultados.innerHTML = ''; return; }

  resultados.innerHTML = '<p style="font-size:11px;color:var(--text-muted)">A pesquisar…</p>';
  try {
    const rows = await get(`/api/doacoes/doadores?search=${encodeURIComponent(q)}`);
    if (!rows.length) {
      resultados.innerHTML = '<p style="font-size:11px;color:var(--text-muted);padding:4px 0">Nenhum doador encontrado.</p>';
      return;
    }
    resultados.innerHTML = `
      <div style="border:1px solid #e5e7eb;border-radius:6px;overflow:hidden;
                  font-size:12px;max-height:160px;overflow-y:auto">
        ${rows.map(r => `
          <div onclick="_wizSelecionarDoador(${r.ID_DOADOR},'${(r.NOME||'').replace(/'/g,"\\'")}','${r.TIPO||''}')"
               style="padding:8px 10px;cursor:pointer;border-bottom:0.5px solid #f0f0f0;
                      display:flex;justify-content:space-between;align-items:center"
               onmouseover="this.style.background='#f9fafb'" onmouseout="this.style.background=''">
            <span style="font-weight:500">${r.NOME || '—'}</span>
            <span class="bdg" style="font-size:10px">${r.TIPO === 'INDIVIDUAL' ? 'Individual' : 'Institucional'}</span>
          </div>`).join('')}
      </div>`;
  } catch (err) {
    resultados.innerHTML = `<p style="font-size:11px;color:#f85149;padding:4px 0">Erro: ${err.message}</p>`;
  }
}

function _wizSelecionarDoador(id, nome, tipo) {
  _wizDoador = { id_doador: id, nome, tipo, anonimo: false };
  _renderizarWizStep1();
}

async function _wizCriarNovoDoador() {
  const nome     = (document.getElementById('wiz-nd-nome')?.value || '').trim();
  const tipo     = document.getElementById('wiz-nd-tipo')?.value;
  const contacto = document.getElementById('wiz-nd-contacto')?.value || null;
  const endereco = document.getElementById('wiz-nd-endereco')?.value || null;
  if (!nome) { _mostrarErroWiz('Nome do doador é obrigatório.'); return; }
  try {
    const r = await post('/api/doacoes/doadores', { nome_doador: nome, tipo_doador: tipo, contacto, endereco });
    _wizDoador = { id_doador: r.id_doador, nome, tipo, anonimo: false };
    toast('Doador criado.', 'sucesso');
    _renderizarWizStep1();
  } catch (err) {
    _mostrarErroWiz(err.message);
  }
}

// Step 2 — Itens
function _renderizarWizStep2() {
  document.getElementById('modal-wiz-conteudo').innerHTML = `
    <div style="display:flex;flex-direction:column;gap:10px;padding:4px 0">
      <div id="wiz-itens-lista" style="display:flex;flex-direction:column;gap:8px"></div>
      <button onclick="_wizAdicionarItem()" class="btn-ghost"
              style="font-size:12px;align-self:flex-start">
        <i class="fa-solid fa-plus" style="margin-right:4px"></i>Adicionar item
      </button>
      <div style="display:flex;justify-content:flex-end;padding-top:6px;border-top:1px solid var(--border-soft);gap:8px;align-items:center">
        <span style="font-size:12px;color:var(--text-muted)">Total estimado:</span>
        <span id="wiz-total-est" style="font-size:13px;font-weight:700;color:#3fb27a">MT 0,00</span>
      </div>
    </div>
  `;

  if (!_wizItens.length) _wizAdicionarItem();
  else _renderizarLinhasItens();

  document.getElementById('modal-wiz-footer').innerHTML = `
    <button class="btn-ghost" onclick="_renderizarWizStep(1)">
      <i class="fa-solid fa-chevron-left" style="margin-right:4px"></i>Anterior
    </button>
    <button class="btn-primary" onclick="_wizAvancar()">
      Seguinte <i class="fa-solid fa-chevron-right" style="margin-left:4px"></i>
    </button>`;
}

function _renderizarLinhasItens() {
  const lista = document.getElementById('wiz-itens-lista');
  if (!lista) return;
  lista.innerHTML = _wizItens.map((item, i) => `
    <div style="display:grid;grid-template-columns:60px 1fr 100px 80px auto;gap:6px;
                align-items:end;padding:10px;background:var(--surface-raised);border-radius:6px;font-size:12px">
      <div>
        <label class="form-label" style="font-size:10px">Qtd. *</label>
        <input type="number" min="1" class="input-field" style="font-size:11px"
               value="${item.quantidade || 1}"
               onchange="_wizItens[${i}].quantidade=Math.max(1,+this.value||1);_atualizarTotalWiz()"/>
      </div>
      <div>
        <label class="form-label" style="font-size:10px">Biblioteca destino *</label>
        <select class="input-field" style="font-size:11px"
                onchange="_wizItens[${i}].cod_biblioteca=this.value">
          <option value="">— Seleccionar —</option>
          ${_wizBibliotecas.map(b =>
            `<option value="${b.COD_BIBLIOTECA}"${item.cod_biblioteca === b.COD_BIBLIOTECA ? ' selected' : ''}>
              ${b.NOME || b.NOME_BIBLIOTECA}
            </option>`
          ).join('')}
        </select>
      </div>
      <div>
        <label class="form-label" style="font-size:10px">Valor un. (MT)</label>
        <input type="number" min="0" step="0.01" class="input-field" style="font-size:11px"
               value="${item.valor_estimado || ''}" placeholder="0.00"
               onchange="_wizItens[${i}].valor_estimado=+this.value||0;_atualizarTotalWiz()"/>
      </div>
      <div>
        <label class="form-label" style="font-size:10px">Obs.</label>
        <input type="text" class="input-field" style="font-size:11px"
               value="${item.observacoes || ''}"
               onchange="_wizItens[${i}].observacoes=this.value"/>
      </div>
      <button onclick="_wizRemoverItem(${i})"
              style="background:none;border:none;cursor:pointer;color:#f85149;
                     font-size:14px;padding:0 2px;margin-bottom:2px">
        <i class="fa-solid fa-xmark"></i>
      </button>
    </div>`).join('');
  _atualizarTotalWiz();
}

function _wizAdicionarItem() {
  _wizItens.push({ quantidade: 1, cod_biblioteca: '', valor_estimado: 0, observacoes: '' });
  _renderizarLinhasItens();
}

function _wizRemoverItem(idx) {
  _wizItens.splice(idx, 1);
  _renderizarLinhasItens();
}

function _atualizarTotalWiz() {
  const total = _wizItens.reduce((acc, i) => acc + (i.valor_estimado || 0) * (i.quantidade || 1), 0);
  const el = document.getElementById('wiz-total-est');
  if (el) el.textContent = fmtMoeda(total);
}

// Step 3 — Confirmar
function _renderizarWizStep3() {
  const nomeDoador = _wizDoador?.anonimo ? 'Anónimo' : (_wizDoador?.nome || '—');
  const tipoDoador = _wizDoador?.tipo;
  const totalVal   = _wizItens.reduce((acc, i) => acc + (i.valor_estimado || 0) * (i.quantidade || 1), 0);
  const autoCert   = tipoDoador === 'INDIVIDUAL' && totalVal >= 1000;

  document.getElementById('modal-wiz-conteudo').innerHTML = `
    <div style="display:flex;flex-direction:column;gap:4px;padding:4px 0;font-size:12px">
      ${_dsecao('Doador')}
      ${_dcampo('Nome', nomeDoador)}
      ${tipoDoador ? _dcampo('Tipo', _badgeTipoDoador(tipoDoador)) : ''}

      ${_dsecao(`Itens (${_wizItens.length})`)}
      ${_wizItens.map((item, i) => {
        const bib = _wizBibliotecas.find(b => b.COD_BIBLIOTECA === item.cod_biblioteca);
        const nomeBib = bib ? (bib.NOME || bib.NOME_BIBLIOTECA) : (item.cod_biblioteca || '—');
        return _dcampo(
          `Item ${i + 1}`,
          `${item.quantidade}× <span style="color:var(--text-muted)">${nomeBib}</span> — ${fmtMoeda(item.valor_estimado)}/un.`
        );
      }).join('')}
      ${_dcampo('Valor total estimado',
        `<strong style="color:#3fb27a;font-size:13px">${fmtMoeda(totalVal)}</strong>`
      )}

      ${autoCert ? `
      <div style="background:#0d2d1f;border:1px solid #1a5a3a;border-radius:6px;
                  padding:10px;color:#3fb27a;margin-top:10px">
        <i class="fa-solid fa-certificate" style="margin-right:6px;color:#3fb27a"></i>
        Certificado será emitido automaticamente pelo sistema (doador individual, total ≥ 1.000 MT).
      </div>` : ''}
    </div>
  `;

  document.getElementById('modal-wiz-footer').innerHTML = `
    <button class="btn-ghost" onclick="_renderizarWizStep(2)">
      <i class="fa-solid fa-chevron-left" style="margin-right:4px"></i>Anterior
    </button>
    <button class="btn-primary" onclick="_wizConfirmar()">
      <i class="fa-solid fa-floppy-disk" style="margin-right:5px"></i>Confirmar Doação
    </button>`;
}

function _wizAvancar() {
  _mostrarErroWiz('');

  if (_wizStep === 1) {
    if (!_wizDoador) {
      _mostrarErroWiz('Selecciona um doador, cria um novo, ou escolhe "Anónimo".');
      return;
    }
    _renderizarWizStep(2);

  } else if (_wizStep === 2) {
    if (!_wizItens.length) { _mostrarErroWiz('Adiciona pelo menos um item.'); return; }
    for (let i = 0; i < _wizItens.length; i++) {
      if (!_wizItens[i].cod_biblioteca) {
        _mostrarErroWiz(`Item ${i + 1}: selecciona a biblioteca de destino.`);
        return;
      }
    }
    _renderizarWizStep(3);
  }
}

async function _wizConfirmar() {
  _mostrarErroWiz('');
  try {
    await post('/api/doacoes', {
      id_doador: _wizDoador.id_doador,
      itens: _wizItens.map(i => ({
        cod_biblioteca:  i.cod_biblioteca,
        quantidade:      i.quantidade,
        valor_estimado:  i.valor_estimado,
        observacoes:     i.observacoes || null,
      })),
    });
    toast('Doação registada com sucesso.', 'sucesso');
    fecharWizardDoacao();
    carregarDoacoes();
  } catch (err) {
    _mostrarErroWiz(err.message);
  }
}

function _mostrarErroWiz(msg) {
  const el  = document.getElementById('modal-wiz-erro');
  const txt = document.getElementById('modal-wiz-erro-msg');
  if (!msg) { el?.classList.add('hidden'); return; }
  if (txt) txt.textContent = msg;
  el?.classList.remove('hidden');
}

// ── Doadores ──────────────────────────────────

async function carregarDoadores() {
  try {
    const rows = await get('/api/doacoes/doadores');
    const tbody = document.getElementById('tabela-doadores');
    if (!tbody) return;
    tbody.innerHTML = rows.length
      ? rows.map(r => `
          <tr>
            <td style="font-size:11px;color:var(--text-muted);font-family:monospace">${r.ID_DOADOR}</td>
            <td style="font-weight:500">${r.NOME || '—'}</td>
            <td>${_badgeTipoDoador(r.TIPO)}</td>
            <td style="color:var(--text-muted)">${r.CONTACTO || '—'}</td>
          </tr>`).join('')
      : linhaVazia(4);
  } catch (err) {
    toast('Erro a carregar doadores: ' + err.message, 'erro');
  }
}

function abrirModalDoador() {
  document.getElementById('modal-titulo').textContent = 'Novo Doador';
  document.getElementById('modal-erro').classList.add('hidden');
  document.getElementById('modal-conteudo').innerHTML = `
    <div class="space-y-3">
      <div>
        <label class="form-label">Nome *</label>
        <input id="df-nome" class="input-field"/>
      </div>
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="form-label">Tipo *</label>
          <select id="df-tipo" class="input-field">
            <option value="INDIVIDUAL">Individual</option>
            <option value="INSTITUCIONAL">Institucional</option>
          </select>
        </div>
        <div>
          <label class="form-label">Contacto</label>
          <input id="df-contacto" class="input-field"/>
        </div>
      </div>
      <div>
        <label class="form-label">Endereço</label>
        <input id="df-endereco" class="input-field"/>
      </div>
      <div>
        <label class="form-label">Observações</label>
        <textarea id="df-obs" class="input-field" rows="2"></textarea>
      </div>
    </div>
  `;
  modalSalvarFn = async () => {
    const nome = (document.getElementById('df-nome')?.value || '').trim();
    if (!nome) { mostrarErroModal('Nome é obrigatório.'); return; }
    await post('/api/doacoes/doadores', {
      nome_doador:  nome,
      tipo_doador:  document.getElementById('df-tipo').value,
      contacto:     document.getElementById('df-contacto').value || null,
      endereco:     document.getElementById('df-endereco').value || null,
      observacoes:  document.getElementById('df-obs').value || null,
    });
    fecharModal();
    toast('Doador criado com sucesso.', 'sucesso');
    carregarDoadores();
  };
  abrirModal();
}

// ── Certificados ──────────────────────────────

async function carregarCertificados() {
  try {
    const rows = await get('/api/doacoes/certificados');
    const tbody = document.getElementById('tabela-certificados');
    if (!tbody) return;
    tbody.innerHTML = rows.length
      ? rows.map(r => `
          <tr>
            <td style="font-family:monospace;font-size:11px;color:#a78bfa">${r.NUMERO_SERIE || '—'}</td>
            <td style="font-weight:500">${r.NOME_DOADOR || '—'}</td>
            <td><span class="bdg bdg-devolvido" style="font-size:10px">${r.TIPO_CERTIFICADO || '—'}</span></td>
            <td style="color:var(--text-muted)">${fmtData(r.DATA_EMISSAO)}</td>
            <td style="text-align:right">
              <button onclick="reemitirCertificado(${r.ID_CERTIFICADO})"
                      class="btn-ghost btn-sm" style="font-size:11px">
                <i class="fa-solid fa-rotate" style="margin-right:3px"></i>Reemitir
              </button>
            </td>
          </tr>`).join('')
      : linhaVazia(5);
  } catch (err) {
    toast('Erro a carregar certificados: ' + err.message, 'erro');
  }
}

function reemitirCertificado(id) {
  confirmar('Reemitir este certificado?', async () => {
    try {
      await post(`/api/doacoes/certificados/${id}/reemitir`, {});
      toast('Certificado reemitido com sucesso.', 'sucesso');
      carregarCertificados();
    } catch (err) {
      toast(err.message, 'erro');
    }
  }, { labelOk: 'Reemitir', danger: false });
}
