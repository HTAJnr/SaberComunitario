// ════════════════════════════════════════════════
// TELA 04 — MATERIAIS
// ════════════════════════════════════════════════

// ── Estado local ─────────────────────────────────
let _matCache = [];
let _wzMatStep = 1;
let _wzMatDados = {};

// ── Helpers internos ─────────────────────────────
function _mostrarErroModalMat(msg) {
  const el = document.getElementById('modal-mat-erro');
  const ms = document.getElementById('modal-mat-erro-msg');
  if (el && ms) { ms.textContent = msg; el.classList.remove('hidden'); }
}
function _ocultarErroModalMat() {
  document.getElementById('modal-mat-erro')?.classList.add('hidden');
}
function fecharModalMat(e) {
  if (e && e.target !== document.getElementById('modal-mat-overlay')) return;
  document.getElementById('modal-mat-overlay')?.classList.add('hidden');
}
function _fecharModalMatForce() {
  document.getElementById('modal-mat-overlay')?.classList.add('hidden');
}

const _secaoMat = secaoDetalhe;
const _campoMat = (l, v, e) => campoDetalhe(l, v, `font-weight:500;color:var(--text-primary);${e || ''}`);

// ── 04-A LISTA ────────────────────────────────────
async function carregarMateriais() {
  try {
    const [result, cats] = await Promise.all([
      get('/api/materiais'),
      get('/api/materiais/categorias').catch(() => []),
    ]);
    _matCache = result.materiais || [];

    const sel = document.getElementById('filtro-mat-categoria');
    if (sel && cats.length) {
      const actual = sel.value;
      sel.innerHTML = '<option value="">Todas as categorias</option>' +
        cats.map(c => `<option value="${c.ID_CATEGORIA}"${actual==c.ID_CATEGORIA?' selected':''}>${c.AREA_TEMATICA}</option>`).join('');
    }

    _renderizarTabelaMat();
  } catch (err) {
    toast('Erro a carregar materiais: ' + err.message, 'erro');
  }
}

function _renderizarTabelaMat() {
  const q       = (document.getElementById('filtro-mat-q')?.value || '').toLowerCase();
  const tipo    = document.getElementById('filtro-mat-tipo')?.value || '';
  const estado  = document.getElementById('filtro-mat-estado')?.value || '';
  const disp    = document.getElementById('filtro-mat-disponivel')?.value || '';
  const catId   = document.getElementById('filtro-mat-categoria')?.value || '';

  let rows = _matCache;
  if (q)     rows = rows.filter(r => (r.TITULO||'').toLowerCase().includes(q) || (r.AUTOR||'').toLowerCase().includes(q) || (r.COD_MATERIAL||'').toLowerCase().includes(q));
  if (tipo)  rows = rows.filter(r => r.TIPO === tipo);
  if (estado) rows = rows.filter(r => r.ESTADO === estado);
  if (disp)  rows = rows.filter(r => r.DISPONIVEL_EMPRESTIMO === disp);
  if (catId) rows = rows.filter(r => String(r.COD_CATEGORIA) === String(catId));

  const nivel = utilizadorActual?.NIVEL_ACESSO || '';

  const btnAdicionar = document.getElementById('btn-adicionar-mat');
  if (btnAdicionar) btnAdicionar.style.display = nivel === 'Assistente' ? 'none' : '';

  const tbody = document.getElementById('tabela-materiais');
  if (!tbody) return;

  tbody.innerHTML = rows.length
    ? rows.map(r => {
        const dispBadge = r.DISPONIVEL_EMPRESTIMO === 'S'
          ? '<span class="bdg bdg-activo">Disponível</span>'
          : '<span class="bdg bdg-vencido">Indisponível</span>';
        return `
          <tr>
            <td style="font-family:monospace;font-size:10px;color:var(--text-muted)">${r.COD_MATERIAL||'—'}</td>
            <td style="font-weight:500;max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${r.TITULO||'—'}</td>
            <td style="color:var(--text-secondary)">${r.AUTOR||'—'}</td>
            <td>${badgeTipo(r.TIPO)}</td>
            <td style="color:var(--text-muted);font-size:11px">${r.CATEGORIA_AREA_TEMATICA||'—'}</td>
            <td>${badgeEstado(r.ESTADO)}</td>
            <td>${dispBadge}</td>
            <td style="text-align:right">
              <button class="btn-ghost btn-sm"
                      onclick="abrirCtxMenuMat(event,'${r.COD_MATERIAL}',${r.DISPONIVEL_EMPRESTIMO==='S'})">···</button>
            </td>
          </tr>`;
      }).join('')
    : `<tr><td colspan="8" style="padding:24px;text-align:center;color:var(--text-muted);font-size:12px">Sem materiais.</td></tr>`;
}

// ── Context menu ──────────────────────────────────
function abrirCtxMenuMat(evt, cod, disponivel) {
  evt.stopPropagation();
  const nivel = utilizadorActual?.NIVEL_ACESSO || '';
  const menu  = document.getElementById('ctx-menu-mat');
  if (!menu) return;

  menu.innerHTML = `
    <div class="ctx-menu-item" onclick="fecharCtxMenuMat();abrirDrawerMat('${cod}')">
      <i class="fa-solid fa-eye" style="width:14px"></i> Ver detalhe
    </div>
    ${['Administrador','Coordenador','Bibliotecario'].includes(nivel) ? `
    <div class="ctx-menu-item" onclick="fecharCtxMenuMat();abrirModalEditarMat('${cod}')">
      <i class="fa-solid fa-pen" style="width:14px"></i> Editar
    </div>` : ''}
    ${['Administrador','Coordenador'].includes(nivel) ? `
    <div class="ctx-menu-item ctx-menu-danger" onclick="fecharCtxMenuMat();eliminarMaterial('${cod}')">
      <i class="fa-solid fa-trash" style="width:14px"></i> Eliminar
    </div>` : ''}
  `;

  const btn  = evt.currentTarget;
  const rect = btn.getBoundingClientRect();
  menu.style.display  = 'block';
  menu.style.position = 'fixed';
  menu.style.top      = (rect.bottom + 4) + 'px';
  menu.style.left     = Math.max(4, rect.right - 170) + 'px';

  setTimeout(() => document.addEventListener('click', fecharCtxMenuMat, { once: true }), 0);
}

function fecharCtxMenuMat() {
  const m = document.getElementById('ctx-menu-mat');
  if (m) m.style.display = 'none';
}

// ── 04-B DRAWER ───────────────────────────────────
async function abrirDrawerMat(cod) {
  document.getElementById('drawer-mat-overlay').style.display = 'block';
  document.getElementById('drawer-mat').classList.add('open');
  document.getElementById('drawer-mat-conteudo').innerHTML =
    '<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:24px">A carregar…</p>';
  try {
    const m = await get(`/api/materiais/${cod}`);
    _renderizarDrawerMat(m);
  } catch (err) {
    document.getElementById('drawer-mat-conteudo').innerHTML =
      `<p style="color:#f85149;font-size:12px;padding:8px">${err.message}</p>`;
  }
}

function fecharDrawerMat() {
  document.getElementById('drawer-mat-overlay').style.display = 'none';
  document.getElementById('drawer-mat')?.classList.remove('open');
}

function _renderizarDrawerMat(m) {
  const conteudo = document.getElementById('drawer-mat-conteudo');
  if (!conteudo) return;

  const tabsHtml = ['info','historico','transferencias'].map((t, i) => {
    const labels = ['Informação','Histórico','Transferências'];
    return `<button id="tab-dmat-${t}" class="tab-btn${i===0?' tab-active':''}"
      onclick="_switchTabDrawerMat('${t}',_matDrawerActual)"
      style="font-size:12px;padding:5px 10px">${labels[i]}</button>`;
  }).join('');

  conteudo.innerHTML = `
    <div style="display:flex;gap:4px;margin-bottom:14px;flex-wrap:wrap">${tabsHtml}</div>
    <div id="drawer-mat-tab-body"></div>
  `;

  window._matDrawerActual = m;
  _renderizarTabInfoMat(m);
}

function _switchTabDrawerMat(tab, m) {
  ['info','historico','transferencias'].forEach(t =>
    document.getElementById(`tab-dmat-${t}`)?.classList.toggle('tab-active', t === tab)
  );
  if (tab === 'info')           _renderizarTabInfoMat(m);
  else if (tab === 'historico') _renderizarTabHistoricoMat(m);
  else                          _renderizarTabTransfMat(m);
}

function _renderizarTabInfoMat(m) {
  const c = document.getElementById('drawer-mat-tab-body');
  if (!c) return;

  const estado = m.ESTADO_MATERIAL_CONSERVACAO || m.ESTADO || '—';

  let motivoHtml = '';
  if (estado === 'Indisponivel' && m.MOTIVO_INDISPONIBILIDADE) {
    motivoHtml = `<div style="background:#2a1d08;border:1px solid #6a3808;border-radius:6px;
                              padding:8px 10px;font-size:11px;color:#d29922;margin-bottom:10px">
      <i class="fa-solid fa-triangle-exclamation" style="margin-right:4px"></i>${m.MOTIVO_INDISPONIBILIDADE}
    </div>`;
  }

  let subtipoHtml = '';
  if (m.TIPO === 'Ebook') {
    subtipoHtml = `
      ${_secaoMat('Ebook')}
      ${_campoMat('Formato', m.EBOOK_FORMATO || '—')}
      ${_campoMat('Tamanho', m.EBOOK_TAMANHO ? m.EBOOK_TAMANHO + ' MB' : '—')}
      ${_campoMat('URL Acesso', m.EBOOK_URL ? `<a href="${m.EBOOK_URL}" target="_blank" style="color:#a78bfa">Abrir link</a>` : '—')}`;
  } else if (m.TIPO === 'Periodico') {
    subtipoHtml = `
      ${_secaoMat('Periódico')}
      ${_campoMat('Edição', m.PERIODICO_EDICAO || '—')}
      ${_campoMat('Periodicidade', m.PERIODICO_PERIODICIDADE || '—')}
      ${_campoMat('Data Publicação', fmtData(m.PERIODICO_DATA_PUBLICACAO))}
      ${_campoMat('ISSN', m.PERIODICO_ISSN || '—')}`;
  }

  let origemHtml = m.ORIGEM_MATERIAL || '—';
  if (m.ORIGEM_MATERIAL === 'Doado' && m.doacao) {
    origemHtml += ` <span style="color:var(--text-muted);font-size:11px">— ${m.doacao.NOME_DOADOR||'doador'} (${fmtData(m.doacao.DATA_DOACAO)})</span>`;
  }

  c.innerHTML = `
    <div style="margin-bottom:14px">
      <div style="font-family:monospace;font-size:11px;color:var(--text-muted);margin-bottom:4px">${m.COD_MATERIAL||'—'}</div>
      <div style="font-size:15px;font-weight:600;color:var(--text-primary);margin-bottom:6px">${m.TITULO||'—'}</div>
      <div style="display:flex;gap:6px;flex-wrap:wrap">${badgeTipo(m.TIPO)} ${badgeEstado(estado)}</div>
    </div>
    ${motivoHtml}
    ${_secaoMat('Identificação')}
    ${_campoMat('Autor',        m.AUTOR           || '—')}
    ${_campoMat('Editora',      m.EDITORA         || '—')}
    ${_campoMat('Ano',          m.ANO_PUBLICACAO  || '—')}
    ${_campoMat('ISBN',         `<span style="font-family:monospace;font-size:10px">${m.ISBN||'—'}</span>`)}
    ${_campoMat('Idioma',       m.IDIOMA          || '—')}
    ${_campoMat('Nº Páginas',   m.NUM_PAGINAS     || '—')}
    ${_secaoMat('Localização e Aquisição')}
    ${_campoMat('Localização',  m.LOCALIZACAO_ESTANTE || '—')}
    ${_campoMat('Valor',        fmtMoeda(m.VALOR_AQUISICAO))}
    ${_campoMat('Data Aq.',     fmtData(m.DATA_AQUISICAO))}
    ${m.CATEGORIA_AREA_TEMATICA ? `
      ${_secaoMat('Categoria')}
      ${_campoMat('Área Temática', m.CATEGORIA_AREA_TEMATICA)}
      ${_campoMat('Faixa Etária',  m.CATEGORIA_FAIXA_ETARIA  || '—')}
      ${_campoMat('Nível Leitura', m.CATEGORIA_NIVEL_LEITURA || '—')}` : ''}
    ${subtipoHtml}
    ${_secaoMat('Origem')}
    ${_campoMat('Origem', origemHtml)}
  `;
}

function _renderizarTabHistoricoMat(m) {
  const c = document.getElementById('drawer-mat-tab-body');
  if (!c) return;
  const emp = m.emprestimos || [];
  if (!emp.length) { c.innerHTML = emptyState('fa-book-open', 'Sem histórico de empréstimos.'); return; }
  c.innerHTML = `
    <table style="width:100%;font-size:11px;border-collapse:collapse">
      <thead>
        <tr style="color:var(--text-muted)">
          <th style="text-align:left;padding:5px 4px;border-bottom:1px solid #eee">Leitor</th>
          <th style="text-align:left;padding:5px 4px;border-bottom:1px solid #eee">Retirada</th>
          <th style="text-align:left;padding:5px 4px;border-bottom:1px solid #eee">Prazo</th>
          <th style="text-align:left;padding:5px 4px;border-bottom:1px solid #eee">Devolução</th>
          <th style="text-align:right;padding:5px 4px;border-bottom:1px solid #eee">Multa</th>
        </tr>
      </thead>
      <tbody>
        ${emp.map(e => `
          <tr style="border-bottom:0.5px solid #f0f0f0">
            <td style="padding:5px 4px;font-family:monospace;font-size:10px">${e.NUM_CARTAO||'—'}</td>
            <td style="padding:5px 4px">${fmtData(e.DATA_RETIRADA)}</td>
            <td style="padding:5px 4px">${fmtData(e.PRAZO_DEVOLUCAO)}</td>
            <td style="padding:5px 4px">${e.DATA_DEVOLUCAO ? fmtData(e.DATA_DEVOLUCAO) : '<span style="color:#e07820">—</span>'}</td>
            <td style="padding:5px 4px;text-align:right">${e.MULTA_VALOR > 0 ? fmtMoeda(e.MULTA_VALOR) : '—'}</td>
          </tr>`).join('')}
      </tbody>
    </table>
  `;
}

function _renderizarTabTransfMat(m) {
  const c = document.getElementById('drawer-mat-tab-body');
  if (!c) return;
  const transf = m.transferencias || [];
  if (!transf.length) { c.innerHTML = emptyState('fa-right-left', 'Sem transferências registadas.'); return; }
  c.innerHTML = transf.map(t => `
    <div style="background:var(--surface-raised);border:0.5px solid var(--border);border-radius:8px;padding:10px 12px;
                margin-bottom:8px;font-size:11px">
      <div style="display:flex;justify-content:space-between;margin-bottom:4px">
        <span style="font-family:monospace;color:var(--text-muted)">#${t.ID_TRANSFERENCIA}</span>
        ${bdgEstado(t.ESTADO_TRANSFERENCIA)}
      </div>
      <div style="color:var(--text-secondary)">
        ${t.COD_BIBLIOTECA_ORIGEM||'?'}
        <i class="fa-solid fa-arrow-right" style="margin:0 6px;color:#a78bfa"></i>
        ${t.COD_BIBLIOTECA_DESTINO||'?'}
      </div>
      <div style="color:var(--text-muted);margin-top:2px">${fmtData(t.DATA_SOLICITACAO)}</div>
    </div>`).join('');
}

// ── 04-C MODAL EDITAR ─────────────────────────────
async function abrirModalEditarMat(cod) {
  _ocultarErroModalMat();
  document.getElementById('modal-mat-titulo').textContent = 'Editar Material';
  document.getElementById('modal-mat-conteudo').innerHTML =
    '<p style="padding:20px;text-align:center;color:var(--text-muted);font-size:12px"><i class="fa-solid fa-spinner fa-spin"></i></p>';
  document.getElementById('modal-mat-footer').innerHTML = '';
  document.getElementById('modal-mat-overlay').classList.remove('hidden');

  let m, cats;
  try {
    [m, cats] = await Promise.all([
      get(`/api/materiais/${cod}`),
      get('/api/materiais/categorias').catch(() => [])
    ]);
  } catch (err) {
    _mostrarErroModalMat(err.message);
    document.getElementById('modal-mat-conteudo').innerHTML = '';
    return;
  }

  const catOpts = `<option value="">Sem categoria</option>` +
    cats.map(c =>
      `<option value="${c.ID_CATEGORIA}"${m.COD_CATEGORIA==c.ID_CATEGORIA?' selected':''}>${c.AREA_TEMATICA} / ${c.FAIXA_ETARIA} / ${c.NIVEL_LEITURA}</option>`
    ).join('');

  const estadoActual = m.ESTADO_MATERIAL_CONSERVACAO || m.ESTADO || 'Bom';

  let subtipoHtml = '';
  if (m.TIPO === 'Ebook') {
    subtipoHtml = `
      <div style="margin-top:12px;padding-top:10px;border-top:0.5px solid #e2e8f0">
        <div style="font-size:10px;font-weight:500;color:var(--text-muted);text-transform:uppercase;letter-spacing:.06em;margin-bottom:8px">Ebook</div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
          <div>
            <label class="form-label">Formato</label>
            <select id="me-formato" class="input-field" style="width:100%">
              ${['PDF','EPUB','MOBI','CD','PEN'].map(f=>`<option${m.EBOOK_FORMATO===f?' selected':''}>${f}</option>`).join('')}
            </select>
          </div>
          <div>
            <label class="form-label">Tamanho (MB)</label>
            <input id="me-tamanho" type="number" class="input-field" style="width:100%" value="${m.EBOOK_TAMANHO||''}"/>
          </div>
          <div style="grid-column:1/-1">
            <label class="form-label">URL Acesso</label>
            <input id="me-url" class="input-field" style="width:100%" value="${(m.EBOOK_URL||'').replace(/"/g,'&quot;')}"/>
          </div>
        </div>
      </div>`;
  } else if (m.TIPO === 'Periodico') {
    subtipoHtml = `
      <div style="margin-top:12px;padding-top:10px;border-top:0.5px solid #e2e8f0">
        <div style="font-size:10px;font-weight:500;color:var(--text-muted);text-transform:uppercase;letter-spacing:.06em;margin-bottom:8px">Periódico</div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
          <div>
            <label class="form-label">Edição</label>
            <input id="me-edicao" class="input-field" style="width:100%" value="${m.PERIODICO_EDICAO||''}"/>
          </div>
          <div>
            <label class="form-label">Periodicidade</label>
            <select id="me-periodicidade" class="input-field" style="width:100%">
              <option value="">—</option>
              ${['Mensal','Trimestral','Anual'].map(p=>`<option${m.PERIODICO_PERIODICIDADE===p?' selected':''}>${p}</option>`).join('')}
            </select>
          </div>
          <div>
            <label class="form-label">Data Publicação</label>
            <input id="me-data-pub" type="date" class="input-field" style="width:100%" value="${m.PERIODICO_DATA_PUBLICACAO?m.PERIODICO_DATA_PUBLICACAO.split('T')[0]:''}"/>
          </div>
          <div>
            <label class="form-label">ISSN</label>
            <input id="me-issn" class="input-field" style="width:100%" value="${m.PERIODICO_ISSN||''}"/>
          </div>
        </div>
      </div>`;
  }

  document.getElementById('modal-mat-conteudo').innerHTML = `
    <div style="padding:16px 18px">
      <div style="display:flex;gap:8px;align-items:center;margin-bottom:14px">
        <span style="font-family:monospace;font-size:11px;color:var(--text-muted)">${m.COD_MATERIAL}</span>
        ${badgeTipo(m.TIPO)}
      </div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
        <div style="grid-column:1/-1">
          <label class="form-label">Título *</label>
          <input id="me-titulo" class="input-field" style="width:100%" value="${(m.TITULO||'').replace(/"/g,'&quot;')}"/>
        </div>
        <div>
          <label class="form-label">Autor</label>
          <input id="me-autor" class="input-field" style="width:100%" value="${(m.AUTOR||'').replace(/"/g,'&quot;')}"/>
        </div>
        <div>
          <label class="form-label">Editora</label>
          <input id="me-editora" class="input-field" style="width:100%" value="${(m.EDITORA||'').replace(/"/g,'&quot;')}"/>
        </div>
        <div>
          <label class="form-label">Ano Publicação</label>
          <input id="me-ano" type="number" class="input-field" style="width:100%" value="${m.ANO_PUBLICACAO||''}"/>
        </div>
        <div>
          <label class="form-label">ISBN</label>
          <input id="me-isbn" class="input-field" style="width:100%" value="${m.ISBN||''}"/>
        </div>
        <div>
          <label class="form-label">Idioma</label>
          <input id="me-idioma" class="input-field" style="width:100%" value="${m.IDIOMA||''}"/>
        </div>
        <div>
          <label class="form-label">Nº Páginas</label>
          <input id="me-paginas" type="number" class="input-field" style="width:100%" value="${m.NUM_PAGINAS||''}"/>
        </div>
        <div>
          <label class="form-label">Localização</label>
          <input id="me-localizacao" class="input-field" style="width:100%" value="${(m.LOCALIZACAO_ESTANTE||'').replace(/"/g,'&quot;')}"/>
        </div>
        <div style="grid-column:1/-1">
          <label class="form-label">Categoria</label>
          <select id="me-categoria" class="input-field" style="width:100%">${catOpts}</select>
        </div>
        <div>
          <label class="form-label">Estado Conservação</label>
          <select id="me-estado" class="input-field" style="width:100%" onchange="_toggleMotivoEditarMat()">
            <option${estadoActual==='Bom'?' selected':''}>Bom</option>
            <option${estadoActual==='Degradado'?' selected':''}>Degradado</option>
            <option${estadoActual==='Indisponivel'?' selected':''}>Indisponivel</option>
          </select>
        </div>
        <div id="me-motivo-wrap" style="${estadoActual==='Indisponivel'?'':'display:none'}">
          <label class="form-label">Motivo Indisponibilidade *</label>
          <input id="me-motivo" class="input-field" style="width:100%" value="${(m.MOTIVO_INDISPONIBILIDADE||'').replace(/"/g,'&quot;')}"/>
        </div>
      </div>
      ${subtipoHtml}
    </div>
  `;

  document.getElementById('modal-mat-footer').innerHTML = `
    <button onclick="_fecharModalMatForce()" class="btn-ghost">
      <i class="fa-solid fa-xmark" style="margin-right:4px"></i>Cancelar
    </button>
    <button onclick="_guardarEditarMat('${cod}','${m.TIPO}')" class="btn-primary">
      <i class="fa-solid fa-floppy-disk" style="margin-right:4px"></i>Guardar
    </button>
  `;
}

function _toggleMotivoEditarMat() {
  const estado = document.getElementById('me-estado')?.value;
  const wrap   = document.getElementById('me-motivo-wrap');
  if (wrap) wrap.style.display = estado === 'Indisponivel' ? '' : 'none';
}

async function _guardarEditarMat(cod, tipo) {
  _ocultarErroModalMat();
  const titulo = document.getElementById('me-titulo')?.value?.trim();
  if (!titulo) { _mostrarErroModalMat('Título é obrigatório.'); return; }

  const estado = document.getElementById('me-estado')?.value;
  const motivo = document.getElementById('me-motivo')?.value?.trim();
  if (estado === 'Indisponivel' && !motivo) {
    _mostrarErroModalMat('Motivo de indisponibilidade é obrigatório.'); return;
  }

  const body = {
    titulo,
    autor:       document.getElementById('me-autor')?.value  || undefined,
    editora:     document.getElementById('me-editora')?.value || undefined,
    ano_publicacao: document.getElementById('me-ano')?.value  || undefined,
    isbn:        document.getElementById('me-isbn')?.value    || undefined,
    idioma:      document.getElementById('me-idioma')?.value  || undefined,
    num_paginas: document.getElementById('me-paginas')?.value || undefined,
    localizacao_estante: document.getElementById('me-localizacao')?.value || undefined,
    cod_categoria: document.getElementById('me-categoria')?.value || undefined,
    estado_material_conservacao: estado,
    motivo_indisponibilidade: motivo || undefined,
    tipo,
  };

  if (tipo === 'Ebook') {
    body.formato         = document.getElementById('me-formato')?.value;
    body.tamanho_arquivo = document.getElementById('me-tamanho')?.value || undefined;
    body.url_acesso      = document.getElementById('me-url')?.value     || undefined;
  } else if (tipo === 'Periodico') {
    body.edicao          = document.getElementById('me-edicao')?.value        || undefined;
    body.periodicidade   = document.getElementById('me-periodicidade')?.value || undefined;
    body.data_publicacao = document.getElementById('me-data-pub')?.value      || undefined;
    body.issn            = document.getElementById('me-issn')?.value          || undefined;
  }

  try {
    await api(`/api/materiais/${cod}`, { method: 'PATCH', body });
    _fecharModalMatForce();
    toast('Material actualizado.');
    carregarMateriais();
  } catch (err) {
    _mostrarErroModalMat(err.message);
  }
}

// ── 04-D WIZARD ───────────────────────────────────
async function abrirWizardMat() {
  if ((utilizadorActual?.NIVEL_ACESSO || '') === 'Assistente') return;
  _wzMatStep  = 1;
  _wzMatDados = {};
  _ocultarErroModalMat();
  document.getElementById('modal-mat-titulo').textContent = 'Adicionar Material';
  document.getElementById('modal-mat-overlay').classList.remove('hidden');

  try {
    _wzMatDados._cats = await get('/api/materiais/categorias');
  } catch {
    _wzMatDados._cats = [];
  }
  _renderizarWzMatStep(1);
}

function _wzMatIndicador(step) {
  const labels = ['Dados Base','Tipo','Origem'];
  return `<div style="display:flex;align-items:center;gap:6px;margin-bottom:18px;font-size:11px">
    ${labels.map((lbl, i) => {
      const n = i + 1;
      const ativo   = n === step;
      const passado = n < step;
      const cor = ativo ? '#818cf8' : passado ? '#22c55e' : '#475569';
      const bg  = ativo ? '#818cf820' : passado ? '#22c55e20' : 'transparent';
      return `
        <div style="display:flex;align-items:center;gap:4px">
          <div style="width:20px;height:20px;border-radius:50%;background:${bg};border:1.5px solid ${cor};
                      display:flex;align-items:center;justify-content:center;font-weight:600;color:${cor};font-size:11px">
            ${passado ? '<i class="fa-solid fa-check" style="font-size:9px"></i>' : n}
          </div>
          <span style="color:${ativo?'#818cf8':'#64748b'}">${lbl}</span>
        </div>
        ${i < 2 ? '<div style="flex:1;height:1px;background:var(--border);min-width:12px"></div>' : ''}`;
    }).join('')}
  </div>`;
}

function _renderizarWzMatStep(step) {
  _ocultarErroModalMat();
  const cats = _wzMatDados._cats || [];
  const catOpts = `<option value="">Seleccionar categoria *</option>` +
    cats.map(c =>
      `<option value="${c.ID_CATEGORIA}"${_wzMatDados.cod_categoria==c.ID_CATEGORIA?' selected':''}>${c.AREA_TEMATICA} / ${c.FAIXA_ETARIA} / ${c.NIVEL_LEITURA}</option>`
    ).join('');

  let conteudo = '', footer = '';

  if (step === 1) {
    conteudo = `<div style="padding:16px 18px">
      ${_wzMatIndicador(1)}
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
        <div style="grid-column:1/-1">
          <label class="form-label">Título *</label>
          <input id="wz-titulo" class="input-field" style="width:100%" value="${(_wzMatDados.titulo||'').replace(/"/g,'&quot;')}" placeholder="Título do material"/>
        </div>
        <div>
          <label class="form-label">Autor</label>
          <input id="wz-autor" class="input-field" style="width:100%" value="${(_wzMatDados.autor||'').replace(/"/g,'&quot;')}"/>
        </div>
        <div>
          <label class="form-label">Editora</label>
          <input id="wz-editora" class="input-field" style="width:100%" value="${(_wzMatDados.editora||'').replace(/"/g,'&quot;')}"/>
        </div>
        <div>
          <label class="form-label">Ano Publicação</label>
          <input id="wz-ano" type="number" class="input-field" style="width:100%" value="${_wzMatDados.ano_publicacao||''}" placeholder="2024"/>
        </div>
        <div>
          <label class="form-label">ISBN</label>
          <input id="wz-isbn" class="input-field" style="width:100%" value="${_wzMatDados.isbn||''}"/>
        </div>
        <div>
          <label class="form-label">Idioma</label>
          <input id="wz-idioma" class="input-field" style="width:100%" value="${_wzMatDados.idioma||''}" placeholder="Português"/>
        </div>
        <div>
          <label class="form-label">Nº Páginas</label>
          <input id="wz-paginas" type="number" class="input-field" style="width:100%" value="${_wzMatDados.num_paginas||''}"/>
        </div>
        <div style="grid-column:1/-1">
          <label class="form-label">Categoria *</label>
          <select id="wz-categoria" class="input-field" style="width:100%">${catOpts}</select>
        </div>
        <div>
          <label class="form-label">Localização (estante)</label>
          <input id="wz-localizacao" class="input-field" style="width:100%" value="${(_wzMatDados.localizacao_estante||'').replace(/"/g,'&quot;')}" placeholder="Ex: A-12"/>
        </div>
        <div>
          <label class="form-label">Valor Aquisição (MT)</label>
          <input id="wz-valor" type="number" step="0.01" class="input-field" style="width:100%" value="${_wzMatDados.valor_aquisicao||''}"/>
        </div>
        <div style="grid-column:1/-1">
          <label class="form-label">Data Aquisição</label>
          <input id="wz-data-aq" type="date" class="input-field" style="width:100%" value="${_wzMatDados.data_aquisicao||''}"/>
        </div>
      </div>
    </div>`;
    footer = `
      <button onclick="_fecharModalMatForce()" class="btn-ghost"><i class="fa-solid fa-xmark" style="margin-right:4px"></i>Cancelar</button>
      <button onclick="_wzMatAvancar1()" class="btn-primary">Seguinte <i class="fa-solid fa-arrow-right" style="margin-left:4px"></i></button>`;

  } else if (step === 2) {
    const tipo = _wzMatDados.tipo || 'Livro';
    conteudo = `<div style="padding:16px 18px">
      ${_wzMatIndicador(2)}
      <div style="display:flex;gap:10px;margin-bottom:16px;flex-wrap:wrap">
        ${['Livro','Ebook','Periodico'].map(t => `
          <label style="display:flex;align-items:center;gap:6px;cursor:pointer;font-size:13px;
                        background:${tipo===t?'#818cf820':'#f8fafc'};border:1.5px solid ${tipo===t?'#818cf8':'#e2e8f0'};
                        border-radius:8px;padding:8px 14px">
            <input type="radio" name="wz-tipo" value="${t}" ${tipo===t?'checked':''} onchange="_wzMatToggleTipo()" style="accent-color:#a78bfa"/>
            ${t==='Livro'?'Livro Físico':t==='Periodico'?'Periódico':t}
          </label>`).join('')}
      </div>
      <div id="wz-tipo-campos">${_wzMatCamposTipo(tipo)}</div>
    </div>`;
    footer = `
      <button onclick="_wzMatRecuar()" class="btn-ghost"><i class="fa-solid fa-arrow-left" style="margin-right:4px"></i>Anterior</button>
      <button onclick="_wzMatAvancar2()" class="btn-primary">Seguinte <i class="fa-solid fa-arrow-right" style="margin-left:4px"></i></button>`;

  } else if (step === 3) {
    const origem = _wzMatDados.origem_material || 'Comprado';
    conteudo = `<div style="padding:16px 18px">
      ${_wzMatIndicador(3)}
      <div style="margin-bottom:16px">
        <label class="form-label" style="display:block;margin-bottom:8px">Origem do material *</label>
        <div style="display:flex;gap:10px;flex-wrap:wrap">
          ${['Comprado','Doado','Transferido'].map(o => `
            <label style="display:flex;align-items:center;gap:6px;cursor:pointer;font-size:13px;
                          background:${origem===o?'#818cf820':'#f8fafc'};border:1.5px solid ${origem===o?'#818cf8':'#e2e8f0'};
                          border-radius:8px;padding:8px 14px">
              <input type="radio" name="wz-origem" value="${o}" ${origem===o?'checked':''} onchange="_wzMatToggleOrigem()" style="accent-color:#a78bfa"/>
              ${o}
            </label>`).join('')}
        </div>
        <div id="wz-origem-campos" style="margin-top:12px"></div>
      </div>
      <div style="background:var(--surface-raised);border-radius:8px;padding:12px;font-size:11px;color:var(--text-secondary)">
        <div style="font-weight:600;color:var(--text-secondary);margin-bottom:6px">Resumo</div>
        <div>${_wzMatDados.titulo||'—'} · ${_wzMatDados.tipo==='Livro'?'Livro Físico':_wzMatDados.tipo==='Periodico'?'Periódico':_wzMatDados.tipo||'—'}</div>
      </div>
    </div>`;
    footer = `
      <button onclick="_wzMatRecuar()" class="btn-ghost"><i class="fa-solid fa-arrow-left" style="margin-right:4px"></i>Anterior</button>
      <button onclick="_wzMatConfirmar()" class="btn-primary"><i class="fa-solid fa-check" style="margin-right:4px"></i>Confirmar registo</button>`;
  }

  document.getElementById('modal-mat-conteudo').innerHTML = conteudo;
  document.getElementById('modal-mat-footer').innerHTML   = footer;

  if (step === 3) _renderizarCamposOrigem(_wzMatDados.origem_material || 'Comprado');
}

function _wzMatCamposTipo(tipo) {
  if (tipo === 'Ebook') {
    return `<div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
      <div>
        <label class="form-label">Formato *</label>
        <select id="wz-formato" class="input-field" style="width:100%">
          ${['PDF','EPUB','MOBI','CD','PEN'].map(f=>`<option${_wzMatDados.formato===f?' selected':''}>${f}</option>`).join('')}
        </select>
      </div>
      <div>
        <label class="form-label">Tamanho (MB)</label>
        <input id="wz-tamanho" type="number" class="input-field" style="width:100%" value="${_wzMatDados.tamanho_arquivo||''}"/>
      </div>
      <div style="grid-column:1/-1">
        <label class="form-label">URL Acesso *</label>
        <input id="wz-url" class="input-field" style="width:100%" value="${_wzMatDados.url_acesso||''}" placeholder="https://…"/>
      </div>
    </div>`;
  } else if (tipo === 'Periodico') {
    return `<div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
      <div>
        <label class="form-label">Edição *</label>
        <input id="wz-edicao" class="input-field" style="width:100%" value="${_wzMatDados.edicao||''}"/>
      </div>
      <div>
        <label class="form-label">Periodicidade *</label>
        <select id="wz-periodicidade" class="input-field" style="width:100%">
          <option value="">—</option>
          ${['Mensal','Trimestral','Anual'].map(p=>`<option${_wzMatDados.periodicidade===p?' selected':''}>${p}</option>`).join('')}
        </select>
      </div>
      <div>
        <label class="form-label">Data Publicação *</label>
        <input id="wz-data-pub" type="date" class="input-field" style="width:100%" value="${_wzMatDados.data_publicacao||''}"/>
      </div>
      <div>
        <label class="form-label">ISSN</label>
        <input id="wz-issn" class="input-field" style="width:100%" value="${_wzMatDados.issn||''}"/>
      </div>
    </div>`;
  }
  return `<p style="font-size:12px;color:var(--text-muted);padding:8px 0">Sem campos adicionais para Livro Físico.</p>`;
}

function _wzMatToggleTipo() {
  const tipo = document.querySelector('input[name="wz-tipo"]:checked')?.value || 'Livro';
  document.getElementById('wz-tipo-campos').innerHTML = _wzMatCamposTipo(tipo);
}

function _wzMatToggleOrigem() {
  const origem = document.querySelector('input[name="wz-origem"]:checked')?.value || 'Comprado';
  _wzMatDados.origem_material = origem;
  _renderizarCamposOrigem(origem);
}

function _renderizarCamposOrigem(origem) {
  const el = document.getElementById('wz-origem-campos');
  if (!el) return;
  if (origem === 'Doado') {
    el.innerHTML = `<div style="background:#f8fafc;border-radius:8px;padding:10px;font-size:12px;color:var(--text-muted);text-align:center">
      <i class="fa-solid fa-spinner fa-spin"></i> A carregar doações…
    </div>`;
    _wzMatCarregarDoacoes();
  } else if (origem === 'Transferido') {
    el.innerHTML = `<div style="font-size:12px;color:var(--text-muted);padding:6px 0">
      <i class="fa-solid fa-circle-info" style="margin-right:4px"></i>
      Referência à transferência será associada manualmente.
    </div>`;
  } else {
    el.innerHTML = '';
  }
}

async function _wzMatCarregarDoacoes() {
  const el = document.getElementById('wz-origem-campos');
  if (!el) return;
  try {
    const result = await get('/api/doacoes');
    const doacoes = result.dados || result.doacoes || [];
    if (!doacoes.length) {
      el.innerHTML = `<div style="font-size:12px;color:#e07820;padding:6px 0">Sem doações disponíveis. Use "Comprado".</div>`;
      return;
    }
    el.innerHTML = `
      <div style="margin-bottom:8px">
        <label class="form-label">Doação *</label>
        <select id="wz-doacao-id" class="input-field" style="width:100%" onchange="_wzMatCarregarItensDoacao()">
          <option value="">Seleccionar doação…</option>
          ${doacoes.map(d=>`<option value="${d.ID_DOACAO}">${d.NOME_DOADOR||'Anónimo'} — ${fmtData(d.DATA_DOACAO)}</option>`).join('')}
        </select>
      </div>
      <div id="wz-item-doado-wrap" style="display:none">
        <label class="form-label">Item da doação *</label>
        <select id="wz-item-doado" class="input-field" style="width:100%">
          <option value="">Seleccionar item…</option>
        </select>
      </div>`;
  } catch {
    el.innerHTML = `<div style="font-size:12px;color:#e07820;padding:6px 0">Sem acesso a doações. Use "Comprado".</div>`;
  }
}

async function _wzMatCarregarItensDoacao() {
  const idDoacao = document.getElementById('wz-doacao-id')?.value;
  const wrap = document.getElementById('wz-item-doado-wrap');
  const sel  = document.getElementById('wz-item-doado');
  if (!idDoacao || !wrap || !sel) return;
  wrap.style.display = 'block';
  sel.innerHTML = '<option value="">A carregar…</option>';
  try {
    const d = await get(`/api/doacoes/${idDoacao}`);
    const itens = d.itens || [];
    sel.innerHTML = `<option value="">Seleccionar item…</option>` +
      itens.map(i=>`<option value="${i.ID_ITEMDOADO}">${i.QUANTIDADE}x — ${fmtMoeda(i.VALOR_ESTIMADO)}${i.OBSERVACOES?' — '+i.OBSERVACOES:''}</option>`).join('');
  } catch {
    sel.innerHTML = '<option value="">Erro a carregar itens.</option>';
  }
}

function _wzMatAvancar1() {
  const titulo    = document.getElementById('wz-titulo')?.value?.trim();
  const categoria = document.getElementById('wz-categoria')?.value;
  if (!titulo)    { _mostrarErroModalMat('Título é obrigatório.'); return; }
  if (!categoria) { _mostrarErroModalMat('Seleccione uma categoria.'); return; }

  Object.assign(_wzMatDados, {
    titulo,
    autor:              document.getElementById('wz-autor')?.value     || '',
    editora:            document.getElementById('wz-editora')?.value   || '',
    ano_publicacao:     document.getElementById('wz-ano')?.value       || '',
    isbn:               document.getElementById('wz-isbn')?.value      || '',
    idioma:             document.getElementById('wz-idioma')?.value    || '',
    num_paginas:        document.getElementById('wz-paginas')?.value   || '',
    cod_categoria:      categoria,
    localizacao_estante: document.getElementById('wz-localizacao')?.value || '',
    valor_aquisicao:    document.getElementById('wz-valor')?.value     || '',
    data_aquisicao:     document.getElementById('wz-data-aq')?.value   || '',
  });

  _wzMatStep = 2;
  _renderizarWzMatStep(2);
}

function _wzMatAvancar2() {
  const tipo = document.querySelector('input[name="wz-tipo"]:checked')?.value || 'Livro';
  _wzMatDados.tipo = tipo;

  if (tipo === 'Ebook') {
    const url = document.getElementById('wz-url')?.value?.trim();
    const fmt = document.getElementById('wz-formato')?.value;
    if (['PDF','EPUB','MOBI'].includes(fmt) && !url) {
      _mostrarErroModalMat('URL de acesso é obrigatório para este formato.'); return;
    }
    _wzMatDados.formato          = fmt;
    _wzMatDados.url_acesso       = url;
    _wzMatDados.tamanho_arquivo  = document.getElementById('wz-tamanho')?.value || '';
  } else if (tipo === 'Periodico') {
    const edicao = document.getElementById('wz-edicao')?.value?.trim();
    const per    = document.getElementById('wz-periodicidade')?.value;
    const datap  = document.getElementById('wz-data-pub')?.value;
    if (!edicao || !per || !datap) {
      _mostrarErroModalMat('Edição, periodicidade e data de publicação são obrigatórios.'); return;
    }
    Object.assign(_wzMatDados, {
      edicao, periodicidade: per, data_publicacao: datap,
      issn: document.getElementById('wz-issn')?.value || '',
    });
  }

  _wzMatStep = 3;
  _renderizarWzMatStep(3);
}

function _wzMatRecuar() {
  _wzMatStep = Math.max(1, _wzMatStep - 1);
  _renderizarWzMatStep(_wzMatStep);
}

async function _wzMatConfirmar() {
  _ocultarErroModalMat();
  const origem = document.querySelector('input[name="wz-origem"]:checked')?.value || 'Comprado';

  let id_itemDoado = null;
  if (origem === 'Doado') {
    id_itemDoado = document.getElementById('wz-item-doado')?.value;
    if (!id_itemDoado) { _mostrarErroModalMat('Seleccione o item da doação.'); return; }
  }

  const d = _wzMatDados;
  const body = {
    titulo:              d.titulo,
    autor:               d.autor               || undefined,
    editora:             d.editora             || undefined,
    ano_publicacao:      d.ano_publicacao       || undefined,
    isbn:                d.isbn                || undefined,
    idioma:              d.idioma              || undefined,
    num_paginas:         d.num_paginas         || undefined,
    cod_categoria:       d.cod_categoria,
    localizacao_estante: d.localizacao_estante || undefined,
    valor_aquisicao:     d.valor_aquisicao     || undefined,
    data_aquisicao:      d.data_aquisicao      || undefined,
    tipo:                d.tipo,
    origem_material:     origem,
    cod_biblioteca:      utilizadorActual?.COD_BIBLIOTECA,
    id_itemDoado:        id_itemDoado ? Number(id_itemDoado) : undefined,
    formato:             d.formato,
    url_acesso:          d.url_acesso          || undefined,
    tamanho_arquivo:     d.tamanho_arquivo     || undefined,
    edicao:              d.edicao              || undefined,
    periodicidade:       d.periodicidade       || undefined,
    data_publicacao:     d.data_publicacao     || undefined,
    issn:                d.issn                || undefined,
  };

  try {
    const res = await post('/api/materiais', body);
    _fecharModalMatForce();
    toast(`Material criado: ${res.cod_material}`);
    carregarMateriais();
  } catch (err) {
    _mostrarErroModalMat(err.message);
  }
}

// ── ELIMINAR ──────────────────────────────────────
async function eliminarMaterial(cod) {
  confirmar(`Eliminar o material ${cod}? Esta acção é irreversível.`, async () => {
    try {
      await del(`/api/materiais/${cod}`);
      toast('Material eliminado.');
      carregarMateriais();
    } catch (err) {
      toast(err.message, 'erro');
    }
  });
}
