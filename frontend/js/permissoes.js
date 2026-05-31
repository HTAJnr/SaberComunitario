// ════════════════════════════════════════════════
// TELA 10 — PERMISSÕES (só Administrador)
// ════════════════════════════════════════════════

let _permRows  = [];
let _cargosRows = [];
let _permTab    = 'cargos';
let _matrizCargoId = null;
let _matrizActual  = {}; // { 'modulo:accao': 0|1 }

const MODULOS_ACCOES = {
  leitores:       ['ver','criar','editar','eliminar','alterar_status'],
  emprestimos:    ['ver','criar','devolver','eliminar'],
  materiais:      ['ver','criar','editar','eliminar'],
  transferencias: ['ver','solicitar','aprovar'],
  eventos:        ['ver','criar','editar','cancelar','gerir_participantes'],
  doacoes:        ['ver','registar','emitir_certificado'],
  programas:      ['ver','criar','editar','gerir_participantes'],
  funcionarios:   ['ver','criar','editar','eliminar'],
  permissoes:     ['ver','gerir'],
  bibliotecas:    ['ver','editar','alterar_estado'],
  auditoria:      ['ver'],
};

const _NIVEIS_CARGO = ['Administrador','Coordenador','Bibliotecario','Assistente'];

// ── Entry point ──
async function carregarPermissoes() {
  if (utilizadorActual?.NIVEL_ACESSO !== 'Administrador') {
    toast('Acesso não autorizado.', 'erro');
    navegarPara('dashboard');
    return;
  }
  // mostra os botões Admin
  document.getElementById('btn-novo-cargo')?.classList.remove('hidden');
  document.getElementById('btn-guardar-matriz')?.classList.remove('hidden');

  switchTabPermissoes(_permTab);
}

function switchTabPermissoes(tab) {
  _permTab = tab;
  ['cargos','matriz','funcs'].forEach(t => {
    const sub = document.getElementById(`sub-perm-${t}`);
    const btn = document.getElementById(`tab-perm-${t}-btn`);
    if (sub) sub.style.display = t === tab ? '' : 'none';
    if (btn) btn.classList.toggle('tab-active', t === tab);
  });
  if (tab === 'cargos')      carregarCargos();
  else if (tab === 'matriz') carregarSelectCargos();
  else if (tab === 'funcs')  carregarFuncionariosPerm();
}

// ── Tab 1 — CARGOS ──
async function carregarCargos() {
  try {
    _cargosRows = await get('/api/permissoes/cargos');
    _renderizarTabelaCargos();
  } catch (err) {
    toast('Erro a carregar cargos: ' + err.message, 'erro');
  }
}

function _renderizarTabelaCargos() {
  const tbody = document.getElementById('tabela-cargos');
  if (!tbody) return;
  if (!_cargosRows.length) {
    tbody.innerHTML = linhaVazia(6, 'Sem cargos registados.');
    return;
  }
  tbody.innerHTML = _cargosRows.map(c => `
    <tr>
      <td style="font-family:monospace;font-size:11px;color:var(--text-muted)">${c.ID_FUNCAO}</td>
      <td style="font-weight:500">${c.NOME_FUNCAO || '—'}</td>
      <td>${_badgeNivelCargo(c.NIVEL_ACESSO)}</td>
      <td style="color:var(--text-secondary);font-size:12px">${c.DESCRICAO || '<em style="color:var(--text-muted)">—</em>'}</td>
      <td style="text-align:center">${c.NUM_FUNCIONARIOS ?? 0}</td>
      <td style="text-align:right;padding-right:10px">
        <button class="btn-ghost btn-sm" onclick="abrirModalCargo(${c.ID_FUNCAO})">
          <i class="fa-solid fa-pen"></i>
        </button>
        <button class="btn-ghost btn-sm" onclick="eliminarCargo(${c.ID_FUNCAO})" style="color:#f85149">
          <i class="fa-solid fa-trash"></i>
        </button>
      </td>
    </tr>`).join('');
}

function _badgeNivelCargo(nivel) {
  if (!nivel) return '—';
  const cores = {
    'Administrador':  'background:#3d1f4a;color:#c084fc',
    'Coordenador':    'background:#1f3a5a;color:#60a5fa',
    'Bibliotecario':  'background:#1f4a3a;color:#3fb27a',
    'Assistente':     'background:#3a3a1f;color:#d29922',
  };
  return `<span class="bdg" style="font-size:10px;${cores[nivel] || ''}">${nivel}</span>`;
}

// Modal de cargo (criar ou editar)
function abrirModalCargo(idCargo) {
  const isEdit = !!idCargo;
  const existente = isEdit ? _cargosRows.find(c => c.ID_FUNCAO === idCargo) : null;

  document.getElementById('modal-titulo').textContent = isEdit ? 'Editar Cargo' : 'Novo Cargo';
  document.getElementById('modal-erro').classList.add('hidden');
  document.getElementById('modal-conteudo').innerHTML = `
    <div class="space-y-3">
      <div>
        <label class="form-label">Nome do Cargo *</label>
        <select id="cargo-nome" class="input-field">
          ${_NIVEIS_CARGO.map(n =>
            `<option value="${n}"${existente?.NOME_FUNCAO === n ? ' selected' : ''}>${n}</option>`
          ).join('')}
        </select>
      </div>
      <div>
        <label class="form-label">Nível de Acesso *</label>
        <select id="cargo-nivel" class="input-field">
          ${_NIVEIS_CARGO.map(n =>
            `<option value="${n}"${existente?.NIVEL_ACESSO === n ? ' selected' : ''}>${n}</option>`
          ).join('')}
        </select>
      </div>
      <div>
        <label class="form-label">Descrição</label>
        <textarea id="cargo-desc" class="input-field" rows="3" style="resize:vertical">${existente?.DESCRICAO || ''}</textarea>
      </div>
    </div>
  `;
  modalSalvarFn = async () => {
    const nome = document.getElementById('cargo-nome').value;
    const nivel = document.getElementById('cargo-nivel').value;
    const desc = (document.getElementById('cargo-desc').value || '').trim() || null;
    try {
      if (isEdit) {
        await patch(`/api/permissoes/cargos/${idCargo}`, {
          nome_funcao: nome, nivel_acesso: nivel, descricao: desc
        });
        toast('Cargo actualizado.', 'sucesso');
      } else {
        await post('/api/permissoes/cargos', {
          nome_funcao: nome, nivel_acesso: nivel, descricao: desc
        });
        toast('Cargo criado.', 'sucesso');
      }
      fecharModal();
      carregarCargos();
    } catch (err) {
      mostrarErroModal(err.message);
    }
  };
  abrirModal();
}

function eliminarCargo(idCargo) {
  const c = _cargosRows.find(r => r.ID_FUNCAO === idCargo);
  if (!c) return;
  confirmar(`Eliminar o cargo "${c.NOME_FUNCAO}"? Esta acção não pode ser revertida.`, async () => {
    try {
      await del(`/api/permissoes/cargos/${idCargo}`);
      toast('Cargo eliminado.', 'sucesso');
      carregarCargos();
    } catch (err) {
      toast(err.message, 'erro');
    }
  }, { labelOk: 'Eliminar', danger: true });
}

// ── Tab 2 — MATRIZ DE PERMISSÕES POR CARGO ──
async function carregarSelectCargos() {
  try {
    if (!_cargosRows.length) _cargosRows = await get('/api/permissoes/cargos');
  } catch (err) {
    toast('Erro a carregar cargos: ' + err.message, 'erro');
    return;
  }
  const sel = document.getElementById('sel-cargo-matriz');
  if (!sel) return;
  sel.innerHTML = `<option value="">— Seleccionar cargo —</option>` +
    _cargosRows.map(c =>
      `<option value="${c.ID_FUNCAO}">${c.NOME_FUNCAO} (${c.NIVEL_ACESSO})</option>`
    ).join('');

  // renderizar área vazia
  const conteudo = document.getElementById('matriz-cargo-conteudo');
  if (conteudo) {
    conteudo.innerHTML = `<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:30px">
      Selecciona um cargo para ver e editar a sua matriz de permissões.
    </p>`;
  }
}

async function carregarMatrizCargo(idCargo) {
  if (!idCargo) {
    _matrizCargoId = null;
    _matrizActual = {};
    document.getElementById('matriz-cargo-conteudo').innerHTML =
      `<p style="text-align:center;color:var(--text-muted);font-size:12px;padding:30px">
        Selecciona um cargo para ver e editar a sua matriz de permissões.
      </p>`;
    return;
  }
  _matrizCargoId = parseInt(idCargo);
  try {
    const rows = await get(`/api/permissoes/cargos/${idCargo}/matriz`);
    _matrizActual = {};
    rows.forEach(r => {
      _matrizActual[`${r.MODULO}:${r.ACCAO}`] = r.PERMITIDO;
    });
    _renderizarMatrizEditavel();
  } catch (err) {
    toast('Erro a carregar matriz: ' + err.message, 'erro');
  }
}

function _renderizarMatrizEditavel() {
  const conteudo = document.getElementById('matriz-cargo-conteudo');
  if (!conteudo) return;

  // colunas = união de todas as acções existentes (apresentadas como cabeçalhos por módulo)
  const linhas = Object.entries(MODULOS_ACCOES).map(([modulo, accoes]) => `
    <tr>
      <td style="font-weight:500;font-size:12px;text-transform:capitalize;padding:6px 10px;
                 border-bottom:0.5px solid var(--border-soft)">${modulo}</td>
      <td style="padding:6px 10px;border-bottom:0.5px solid var(--border-soft)">
        <div style="display:flex;flex-wrap:wrap;gap:10px">
          ${accoes.map(accao => {
            const key = `${modulo}:${accao}`;
            const checked = _matrizActual[key] === 1 ? 'checked' : '';
            return `
              <label style="display:inline-flex;align-items:center;gap:5px;font-size:11px;
                            color:var(--text-secondary);cursor:pointer">
                <input type="checkbox" ${checked}
                       onchange="_togglePermissao('${modulo}','${accao}',this.checked)"/>
                ${accao}
              </label>`;
          }).join('')}
        </div>
      </td>
    </tr>
  `).join('');

  conteudo.innerHTML = `
    <table class="tbl" style="font-size:12px">
      <thead>
        <tr>
          <th style="width:160px">Módulo</th>
          <th>Acções</th>
        </tr>
      </thead>
      <tbody>${linhas}</tbody>
    </table>
    <p style="font-size:11px;color:var(--text-muted);margin-top:10px">
      <i class="fa-solid fa-circle-info" style="margin-right:4px"></i>
      Carrega em "Guardar Matriz" para aplicar as alterações.
    </p>
  `;
}

function _togglePermissao(modulo, accao, permitido) {
  _matrizActual[`${modulo}:${accao}`] = permitido ? 1 : 0;
}

async function guardarMatrizCargo() {
  if (!_matrizCargoId) {
    toast('Selecciona um cargo primeiro.', 'erro');
    return;
  }
  // construir array completo (incluindo as não-marcadas como permitido=0)
  const permissoes = [];
  for (const [modulo, accoes] of Object.entries(MODULOS_ACCOES)) {
    for (const accao of accoes) {
      const key = `${modulo}:${accao}`;
      permissoes.push({ modulo, accao, permitido: _matrizActual[key] === 1 ? 1 : 0 });
    }
  }
  try {
    await put(`/api/permissoes/cargos/${_matrizCargoId}/matriz`, { permissoes });
    toast('Matriz guardada com sucesso.', 'sucesso');
  } catch (err) {
    toast('Erro ao guardar: ' + err.message, 'erro');
  }
}

// ── Tab 3 — FUNCIONÁRIOS (vista original mantida) ──
async function carregarFuncionariosPerm() {
  try {
    _permRows = await get('/api/funcionarios');
    _renderizarTabelaPermissoes();
  } catch (err) {
    toast('Erro a carregar funcionários: ' + err.message, 'erro');
  }
}

function _renderizarTabelaPermissoes() {
  const tbody = document.getElementById('tabela-permissoes');
  if (!tbody) return;
  if (!_permRows.length) {
    tbody.innerHTML = linhaVazia(7, 'Sem funcionários registados.');
    return;
  }
  tbody.innerHTML = _permRows.map(r => _linhaPermissao(r)).join('');
}

function _linhaPermissao(r) {
  const av = avatarCirculo(r.NOME, 32);
  return `<tr>
    <td style="padding:6px 10px">${av}</td>
    <td style="font-family:monospace;font-size:11px;color:var(--text-secondary)">${r.COD_FUNCIONARIO || '—'}</td>
    <td style="font-weight:500">${r.NOME || '—'}</td>
    <td style="color:var(--text-secondary)">${r.FUNCAO || '—'}</td>
    <td>${_badgeNivelCargo(r.NIVEL_ACESSO)}</td>
    <td style="color:var(--text-muted)">${r.NOME_BIBLIOTECA || '—'}</td>
    <td style="text-align:right;padding-right:10px">
      ${String(r.COD_FUNCIONARIO) === String(utilizadorActual?.COD_FUNCIONARIO)
        ? `<span style="font-size:11px;color:var(--text-muted)">—</span>`
        : (typeof abrirModalPermissoes === 'function'
            ? `<button class="btn-ghost btn-sm"
                       onclick="abrirModalPermissoes('${r.COD_FUNCIONARIO}')">
                 <i class="fa-solid fa-shield-halved" style="margin-right:4px"></i>Gerir
               </button>`
            : '')}
    </td>
  </tr>`;
}
