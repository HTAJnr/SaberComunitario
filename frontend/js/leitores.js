// ════════════════════════════════════════════════
// LEITORES
// ════════════════════════════════════════════════

let _wizardStep = 1, _wizardDados = {}, _wizardInteresses = [], _wizardDisciplinas = [];
let _drawerNumCartao = null, _drawerLeitor = null, _drawerTabActual = 'perfil';

function _calcularIdade(dataStr) {
  if (!dataStr) return null;
  const nasc = new Date(dataStr);
  if (isNaN(nasc)) return null;
  const hoje = new Date();
  let idade = hoje.getFullYear() - nasc.getFullYear();
  const m = hoje.getMonth() - nasc.getMonth();
  if (m < 0 || (m === 0 && hoje.getDate() < nasc.getDate())) idade--;
  return idade;
}

function bdgPontualidade(h) {
  const m = { Pontual: 'bdg-activo', Irregular: 'bdg-suspenso', Mau: 'bdg-bloqueado' };
  return `<span class="bdg ${m[h] || ''}">${h || '—'}</span>`;
}

async function carregarLeitores() {
  const isAdmin = utilizadorActual?.NIVEL_ACESSO === 'Administrador';
  const selBib  = document.getElementById('filtro-leitor-bib');

  if (isAdmin && selBib) {
    selBib.style.display = '';
    if (selBib.options.length === 1) {
      try {
        const bibs = await get('/api/funcionarios/bibliotecas');
        bibs.forEach(b => {
          const o = document.createElement('option');
          o.value = b.COD_BIBLIOTECA; o.textContent = b.NOME;
          selBib.appendChild(o);
        });
      } catch (_) {}
    }
  }

  const search    = document.getElementById('filtro-leitor-q')?.value || '';
  const status    = document.getElementById('filtro-leitor-estado')?.value || '';
  const tipo      = document.getElementById('filtro-leitor-tipo')?.value || '';
  const historico = document.getElementById('filtro-leitor-historico')?.value || '';
  const biblioteca = isAdmin ? (selBib?.value || '') : '';
  const params = new URLSearchParams();
  if (search)     params.set('search', search);
  if (status)     params.set('status', status);
  if (tipo)       params.set('tipo', tipo);
  if (historico)  params.set('historico', historico);
  if (biblioteca) params.set('biblioteca', biblioteca);
  try {
    const { leitores: rows } = await get(`/api/leitores?${params}`);
    const tbody = document.getElementById('tabela-leitores');
    tbody.innerHTML = rows && rows.length
      ? rows.map(r => `
        <tr>
          <td style="font-family:monospace;font-size:11px;color:var(--text-muted)">${r.NUM_CARTAO || '—'}</td>
          <td style="font-weight:500">${r.NOME_COMPLETO || '—'}</td>
          <td>${bdgTipo(r.TIPO_LEITOR)}</td>
          <td>${bdgPontualidade(r.HISTORICO_PONTUALIDADE)}</td>
          <td>${bdgEstado(r.STATUS_LEITOR)}</td>
          <td style="text-align:right">
            <button class="btn-ghost btn-sm" onclick="abrirCtxMenuLeitor(event,'${r.NUM_CARTAO}','${(r.NOME_COMPLETO||'').replace(/'/g,"\\'")}','${r.STATUS_LEITOR||''}')">···</button>
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
  const podeEliminar = nivel === 'Administrador' && _noEh('BibliotecaNacionalDB');

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
  return wizardIndicador(step, 3, ['Dados Base', 'Tipo e Detalhes', 'Confirmação']);
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
          <input id="wz-data-nasc" type="date" lang="pt-PT" class="input-field" value="${_wizardDados.data_nasc || ''}"/>
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
      <button class="btn-ghost" onclick="fecharModalLeitor()">Cancelar</button>
      <button class="btn-primary" onclick="_wizardAvancar()">Próximo <i class="fa-solid fa-arrow-right" style="margin-left:4px"></i></button>`;

  } else if (_wizardStep === 2) {
    const idade = _calcularIdade(_wizardDados.data_nasc);
    const menor = idade !== null && idade < 18;
    // forçar tipo compatível com a idade
    if (menor && _wizardDados.tipo !== 'Crianca') _wizardDados.tipo = 'Crianca';
    if (!menor && _wizardDados.tipo === 'Crianca') _wizardDados.tipo = 'Adulto';
    const tipo = _wizardDados.tipo || (menor ? 'Crianca' : 'Adulto');
    const tiposDisponiveis = menor ? ['Crianca'] : ['Adulto','Professor'];
    const notaIdade = menor
      ? `<p style="font-size:11px;color:var(--text-muted);margin:4px 0 0;font-style:italic">Registo de menor — tipo fixado automaticamente.</p>`
      : '';
    conteudo.innerHTML = _wizardIndicador(2) + `
      <div class="form-group" style="margin-bottom:14px">
        <label class="form-label">Tipo de leitor *</label>
        <div style="display:flex;gap:16px;margin-top:6px">
          ${tiposDisponiveis.map(t => `
            <label style="display:flex;align-items:center;gap:6px;cursor:pointer;font-size:13px">
              <input type="radio" name="wz-tipo" value="${t}" ${tipo===t?'checked':''} onchange="_renderizarCamposTipo()"/>
              ${t==='Crianca'?'Criança':t}
            </label>`).join('')}
        </div>
        ${notaIdade}
      </div>
      <div id="wz-campos-tipo"></div>`;
    _renderizarCamposTipo();
    footer.innerHTML = `
      <button class="btn-ghost" onclick="_wizardRecuar()"><i class="fa-solid fa-arrow-left" style="margin-right:4px"></i> Anterior</button>
      <button class="btn-primary" onclick="_wizardAvancar()">Próximo <i class="fa-solid fa-arrow-right" style="margin-left:4px"></i></button>`;

  } else {
    const tipo = _wizardDados.tipo || 'Adulto';
    conteudo.innerHTML = _wizardIndicador(3) + `
      <div style="background:var(--surface-raised);border-radius:8px;padding:16px;font-size:13px;line-height:2.2">
        <div><b>Nome:</b> ${_wizardDados.nome_completo || '—'}</div>
        <div><b>Tipo:</b> ${tipo === 'Crianca' ? 'Criança' : tipo}</div>
        <div><b>Género:</b> ${_wizardDados.genero || '—'}</div>
        <div><b>Nível escolar:</b> ${_wizardDados.nivel_escolar || '—'}</div>
        <div><b>Localização:</b> ${_wizardDados.localizacao_leitor || '—'}</div>
        ${_wizardDados.contacto ? `<div><b>Contacto:</b> ${_wizardDados.contacto}</div>` : ''}
      </div>
      <div style="margin-top:12px;font-size:11px;color:var(--text-muted);background:var(--surface-raised);border:1px solid var(--border);border-radius:6px;padding:8px 12px">
        <i class="fa-solid fa-circle-info" style="margin-right:6px"></i>O número de cartão será gerado automaticamente pelo sistema.
      </div>`;
    footer.innerHTML = `
      <button class="btn-ghost" onclick="_wizardRecuar()"><i class="fa-solid fa-arrow-left" style="margin-right:4px"></i> Anterior</button>
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
          ${['Basico','Funcional','Avancado'].map(v=>`<option ${_wizardDados.nivel_literacia===v?'selected':''}>${v}</option>`).join('')}
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Interesses</label>
        <div style="display:flex;gap:6px;margin-bottom:6px">
          <input id="wz-interesse-input" class="input-field" style="flex:1" placeholder="Escrever e adicionar…"/>
          <button type="button" class="btn-ghost btn-sm" onclick="_adicionarInteresse()">Adicionar</button>
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
            ${['Basico','Funcional','Avancado'].map(v=>`<option ${_wizardDados.nivel_literacia===v?'selected':''}>${v}</option>`).join('')}
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
            ${['Primario','Secundario','Tecnico','Universitario'].map(v=>`<option ${_wizardDados.nivel_ensino===v?'selected':''}>${v}</option>`).join('')}
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
          <button type="button" class="btn-ghost btn-sm" onclick="_adicionarInteresse()">Adicionar</button>
        </div>
        <div id="wz-interesses-chips" class="chips-wrap">${_renderChips(_wizardInteresses,'_removerInteresse')}</div>
      </div>
      <div class="form-group">
        <label class="form-label">Disciplinas</label>
        <div style="display:flex;gap:6px;margin-bottom:6px">
          <input id="wz-disciplina-input" class="input-field" style="flex:1" placeholder="Escrever e adicionar…"/>
          <button type="button" class="btn-ghost btn-sm" onclick="_adicionarDisciplina()">Adicionar</button>
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
    const idade = _calcularIdade(_wizardDados.data_nasc);
    if (idade !== null && idade >= 18 && _wizardDados.tipo === 'Crianca') {
      mostrarErroLeitor('Leitor adulto não pode ser registado como Criança.'); return;
    }
    if (idade !== null && idade < 18 && _wizardDados.tipo !== 'Crianca') {
      mostrarErroLeitor('Leitor menor de idade deve ser registado como Criança.'); return;
    }
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
    carregarLeitores();
    _mostrarModalCartaoLeitor(res.num_cartao, body.nome_completo || '');
  } catch (err) { mostrarErroLeitor(err.message); }
}

function _mostrarModalCartaoLeitor(numCartao, nome) {
  const overlay = document.createElement('div');
  overlay.id = 'modal-cartao-leitor-overlay';
  overlay.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,.55);z-index:900;display:flex;align-items:center;justify-content:center';
  overlay.innerHTML = `
    <div style="background:var(--surface);border-radius:12px;padding:28px 24px;width:360px;max-width:94vw;box-shadow:0 8px 32px rgba(0,0,0,.3)">
      <div style="display:flex;align-items:center;gap:10px;margin-bottom:16px">
        <i class="fa-solid fa-circle-check" style="color:#22c55e;font-size:20px"></i>
        <div>
          <div style="font-weight:600;font-size:14px;color:var(--text-primary)">Leitor registado</div>
          <div style="font-size:11px;color:var(--text-muted)">${nome}</div>
        </div>
      </div>
      <div style="font-size:11px;color:var(--text-muted);margin-bottom:12px">
        Guarde o nº de cartão — é necessário para empréstimos.
      </div>
      <div style="margin-bottom:10px">
        <div style="font-size:10px;color:var(--text-muted);margin-bottom:4px">Nº Cartão</div>
        <div style="display:flex;align-items:center;gap:8px;background:var(--canvas);border:1px solid var(--border);border-radius:6px;padding:8px 10px">
          <span style="flex:1;font-family:monospace;font-size:13px;font-weight:600;color:var(--text-primary)">${numCartao}</span>
          <button onclick="navigator.clipboard.writeText('${numCartao}').then(()=>toast('Copiado!'))"
                  class="btn-ghost btn-sm" title="Copiar">
            <i class="fa-solid fa-copy"></i>
          </button>
        </div>
      </div>
      <button onclick="document.getElementById('modal-cartao-leitor-overlay').remove()"
              class="btn-primary" style="width:100%;margin-top:16px">
        <i class="fa-solid fa-check" style="margin-right:6px"></i>Fechar
      </button>
    </div>`;
  document.body.appendChild(overlay);
}

// ── Modal 02-D — Editar leitor ─────────────────
async function abrirModalEditarLeitor(numCartao) {
  abrirModalLeitorBase('Editar Leitor');
  document.getElementById('modal-leitor-conteudo').innerHTML = '<p style="padding:20px;text-align:center;color:var(--text-muted);font-size:13px">A carregar…</p>';

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
        <input id="ef-data-nasc" type="date" lang="pt-PT" class="input-field" value="${leitor.DATA_NASC ? leitor.DATA_NASC.slice(0,10) : ''}"/>
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
        <button type="button" class="btn-ghost btn-sm" onclick="_efAdicionarInteresse()">Adicionar</button>
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
          ${['Primario','Secundario','Tecnico','Universitario'].map(v=>`<option ${leitor.NIVEL_ENSINO===v?'selected':''}>${v}</option>`).join('')}
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
        <button type="button" class="btn-ghost btn-sm" onclick="_efAdicionarDisciplina()">Adicionar</button>
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
    <button class="btn-ghost" onclick="fecharModalLeitor()">Cancelar</button>
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
  document.getElementById('modal-leitor-conteudo').innerHTML = '<p style="padding:20px;text-align:center;color:var(--text-muted);font-size:13px">A carregar…</p>';

  let leitor;
  try { leitor = await get(`/api/leitores/${numCartao}`); }
  catch (err) { mostrarErroLeitor(err.message); return; }

  const temSuspActive = leitor.SUSPENSOES_ATIVAS && leitor.SUSPENSOES_ATIVAS.length > 0;

  document.getElementById('modal-leitor-conteudo').innerHTML = `
    <div style="margin-bottom:14px">
      <span style="font-size:12px;color:var(--text-muted)">Estado actual: </span>${bdgEstado(statusActual)}
    </div>
    ${temSuspActive ? `<div style="background:#2d1015;border:1px solid #5c2020;border-radius:6px;padding:10px 14px;margin-bottom:14px;font-size:12px;color:#f85149">
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
    <button class="btn-ghost" onclick="fecharModalLeitor()">Cancelar</button>
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
  document.getElementById('modal-leitor-conteudo').innerHTML = '<p style="padding:20px;text-align:center;color:var(--text-muted);font-size:13px">A carregar…</p>';
  document.getElementById('modal-leitor-footer').innerHTML = `<button class="btn-ghost" onclick="fecharModalLeitor()">Fechar</button>`;

  let suspensoes;
  try { suspensoes = await get(`/api/leitores/${numCartao}/suspensoes?todas=true`); }
  catch (err) { mostrarErroLeitor(err.message); return; }

  if (!suspensoes || !suspensoes.length) {
    document.getElementById('modal-leitor-conteudo').innerHTML = '<p style="padding:20px;text-align:center;color:var(--text-muted);font-size:13px">Sem suspensões registadas.</p>';
    return;
  }

  document.getElementById('modal-leitor-conteudo').innerHTML = suspensoes.map(s => {
    const isActiva = s.ESTADO_SUSPENSAO === 'Activa';
    return `<div style="background:${isActiva?'#fff4e0':'#f8f9fa'};border:1px solid ${isActiva?'#ffe08a':'#e9ecef'};border-radius:8px;padding:12px 14px;margin-bottom:10px">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
        <span style="font-size:12px;font-weight:600">${fmtData(s.DATA_INICIO)} → ${fmtData(s.DATA_FIM)}</span>
        ${bdgEstado(s.ESTADO_SUSPENSAO)}
      </div>
      <div style="font-size:11px;color:var(--text-muted)">${s.DIAS_SUSPENSAO} dias${s.MOTIVO ? ' · ' + s.MOTIVO : ''}</div>
      ${isActiva ? `
        <div id="reduzir-form-${s.ID_SUSPENSAO}" style="margin-top:10px;display:none">
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:8px">
            <div>
              <label class="form-label" style="font-size:11px">Nova data fim</label>
              <input id="reduzir-data-${s.ID_SUSPENSAO}" type="date" lang="pt-PT" class="input-field" style="font-size:12px"/>
            </div>
            <div>
              <label class="form-label" style="font-size:11px">Justificativa</label>
              <input id="reduzir-obs-${s.ID_SUSPENSAO}" class="input-field" style="font-size:12px" placeholder="Obrigatório"/>
            </div>
          </div>
          <div style="display:flex;gap:6px">
            <button class="btn-primary btn-sm" onclick="_confirmarReduzirSuspensao(${s.ID_SUSPENSAO},'${numCartao}')">Confirmar</button>
            <button class="btn-ghost btn-sm" onclick="document.getElementById('reduzir-form-${s.ID_SUSPENSAO}').style.display='none'">Cancelar</button>
          </div>
        </div>
        <button id="btn-reduzir-${s.ID_SUSPENSAO}" class="btn-ghost btn-sm" style="margin-top:8px;font-size:11px"
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
  document.getElementById('drawer-leitor-header').innerHTML = '<p style="padding:16px;text-align:center;color:var(--text-muted);font-size:13px">A carregar…</p>';
  document.getElementById('drawer-leitor-tabs').innerHTML = '';
  document.getElementById('drawer-leitor-conteudo').innerHTML = '';
  try {
    _drawerLeitor = await get(`/api/leitores/${numCartao}`);
    _renderizarDrawerHeader();
    _renderizarDrawerTabs();
    _renderizarDrawerConteudo();
  } catch (err) {
    document.getElementById('drawer-leitor-header').innerHTML = `<p style="color:#f85149;font-size:12px;padding:10px">${err.message}</p>`;
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
        <div style="font-size:10px;font-family:monospace;color:var(--text-muted)">${l.NUM_CARTAO || '—'}</div>
        <div style="font-size:15px;font-weight:600;color:var(--text-primary)">${l.NOME_COMPLETO || '—'}</div>
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
    el.innerHTML = `<div style="font-size:13px;line-height:2;color:var(--text-primary)">
      <div style="margin-bottom:6px">${bdgPontualidade(l.HISTORICO_PONTUALIDADE)} <span style="font-size:11px;color:var(--text-muted)">pontualidade</span></div>
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
      el.innerHTML = '<div style="text-align:center;padding:30px;color:var(--text-muted);font-size:13px"><i class="fa-solid fa-book-open" style="font-size:28px;display:block;margin-bottom:8px"></i>Sem empréstimo activo</div>';
    } else {
      const hoje  = new Date();
      const prazo = new Date(emp.PRAZO_DEVOLUCAO || emp.DATA_PRAZO);
      const dias  = Math.round((prazo - hoje) / 86400000);
      const diasStr = dias >= 0
        ? `<span style="color:#3fb27a;font-weight:600">${dias} dia(s) restante(s)</span>`
        : `<span style="color:#f85149;font-weight:600">Atrasado ${Math.abs(dias)} dia(s)</span>`;
      el.innerHTML = `<div style="background:var(--surface-raised);border-radius:8px;padding:14px;font-size:13px;line-height:2">
        <div style="font-weight:600;font-size:14px;margin-bottom:6px">${emp.TITULO || emp.NOME_MATERIAL || '—'}</div>
        <div><b>Retirada:</b> ${fmtData(emp.DATA_RETIRADA)}</div>
        <div><b>Prazo:</b> ${fmtData(emp.PRAZO_DEVOLUCAO || emp.DATA_PRAZO)}</div>
        <div>${diasStr}</div>
      </div>`;
    }

  } else if (_drawerTabActual === 'historico') {
    const hist = l.HISTORICO || [];
    if (!hist.length) {
      el.innerHTML = '<div style="text-align:center;padding:30px;color:var(--text-muted);font-size:13px">Sem histórico.</div>';
    } else {
      el.innerHTML = `<div style="overflow-x:auto"><table class="tbl" style="font-size:11px">
        <thead><tr><th>Material</th><th>Retirada</th><th>Devolução</th><th>Atraso</th><th>Multa</th><th>Paga</th></tr></thead>
        <tbody>${hist.map(h => `<tr>
          <td style="max-width:120px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${h.TITULO||h.NOME_MATERIAL||'—'}</td>
          <td>${fmtData(h.DATA_RETIRADA)}</td>
          <td>${fmtData(h.DATA_DEVOLUCAO)}</td>
          <td>${h.DIAS_ATRASO||0}</td>
          <td>${fmtMoeda(h.VALOR_MULTA)}</td>
          <td>${h.MULTA_PAGA==='TRUE'||h.MULTA_PAGA===true?'Sim':h.VALOR_MULTA?'Não':'—'}</td>
        </tr>`).join('')}</tbody>
      </table></div>`;
    }

  } else if (_drawerTabActual === 'suspensoes') {
    const susps = l.SUSPENSOES_ATIVAS || [];
    if (!susps.length) {
      el.innerHTML = '<div style="text-align:center;padding:30px;color:var(--text-muted);font-size:13px">Sem suspensões activas.</div>';
    } else {
      el.innerHTML = susps.map(s => `
        <div style="background:${s.ESTADO_SUSPENSAO==='Activa'?'#fff4e0':'#f8f9fa'};border:1px solid #e0e0e0;border-radius:8px;padding:10px 12px;margin-bottom:8px;font-size:12px">
          <div style="display:flex;justify-content:space-between;align-items:center">
            <span>${fmtData(s.DATA_INICIO)} → ${fmtData(s.DATA_FIM)}</span>${bdgEstado(s.ESTADO_SUSPENSAO)}
          </div>
          <div style="color:var(--text-muted);margin-top:3px">${s.DIAS_SUSPENSAO} dias</div>
        </div>`).join('');
    }

  } else if (_drawerTabActual === 'multas') {
    const nivel    = utilizadorActual?.NIVEL_ACESSO || '';
    const podePagar = ['Administrador','Coordenador','Bibliotecario'].includes(nivel);
    const multas   = (l.HISTORICO || []).filter(h => (h.MULTA_PAGA === 'FALSE' || h.MULTA_PAGA === false) && h.VALOR_MULTA);
    if (!multas.length) {
      el.innerHTML = '<div style="text-align:center;padding:30px;color:var(--text-muted);font-size:13px">Sem multas em aberto.</div>';
    } else {
      const total = multas.reduce((s, h) => s + parseFloat(h.VALOR_MULTA || 0), 0);
      el.innerHTML = multas.map(h => `
        <div style="display:flex;align-items:center;justify-content:space-between;padding:8px 0;border-bottom:1px solid var(--border-soft);font-size:12px">
          <div>
            <div style="font-weight:500">${h.TITULO||h.NOME_MATERIAL||'—'}</div>
            <div style="color:var(--text-muted)">${fmtData(h.DATA_RETIRADA)}</div>
          </div>
          <div style="display:flex;align-items:center;gap:8px">
            <span style="font-weight:600;color:#f85149">${fmtMoeda(h.VALOR_MULTA)}</span>
            ${podePagar ? `<button class="btn-ghost btn-sm" onclick="_marcarMultaPaga(${h.ID_EMPRESTIMO},'${_drawerNumCartao}')">Marcar paga</button>` : ''}
          </div>
        </div>`).join('')
        + `<div style="text-align:right;padding-top:10px;font-size:13px;font-weight:700;color:#f85149">Total: ${fmtMoeda(total)}</div>`;
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
