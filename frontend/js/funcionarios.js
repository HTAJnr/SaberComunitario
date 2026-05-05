// ════════════════════════════════════════════════
// FUNCIONÁRIOS
// ════════════════════════════════════════════════
async function carregarFuncionarios() {
  try {
    const rows = await get('/api/funcionarios');
    const tbody = document.getElementById('tabela-funcionarios');
    tbody.innerHTML = rows.length
      ? rows.map(r => `
        <tr>
          <td class="text-slate-500 text-xs">${r.ID_FUNCIONARIO}</td>
          <td class="font-medium">${r.NOME || '—'}</td>
          <td class="text-slate-400">${r.EMAIL || '—'}</td>
          <td>${r.FUNCAO || r.DESCRICAO || '—'}</td>
          <td class="text-slate-400">${r.NOME_BIBLIOTECA || '—'}</td>
          <td class="space-x-2">
            <button onclick="abrirModalFuncionario(${r.ID_FUNCIONARIO})" class="btn-secondary btn-sm"><i class="fa-solid fa-pen mr-1"></i>Editar</button>
            <button onclick="desactivarFuncionario(${r.ID_FUNCIONARIO})" class="btn-danger btn-sm"><i class="fa-solid fa-user-slash mr-1"></i>Desactivar</button>
          </td>
        </tr>`).join('')
      : linhaVazia(6);
  } catch (err) {
    toast('Erro a carregar funcionários: ' + err.message, 'erro');
  }
}

async function abrirModalFuncionario(id = null) {
  document.getElementById('modal-titulo').textContent = id ? 'Editar Funcionário' : 'Novo Funcionário';
  document.getElementById('modal-erro').classList.add('hidden');

  let funcoes = [], bibliotecas = [];
  try { funcoes = await get('/api/funcionarios/funcoes'); } catch {}
  try { bibliotecas = await get('/api/funcionarios/bibliotecas'); } catch {}

  document.getElementById('modal-conteudo').innerHTML = `
    <div class="space-y-3">
      <div>
        <label class="label-dark">Nome *</label>
        <input id="ff-nome" class="input-dark w-full"/>
      </div>
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label-dark">Email *</label>
          <input id="ff-email" type="email" class="input-dark w-full"/>
        </div>
        <div>
          <label class="label-dark">Contacto</label>
          <input id="ff-contacto" class="input-dark w-full"/>
        </div>
      </div>
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label-dark">${id ? 'Nova Senha (deixar vazio = manter)' : 'Senha *'}</label>
          <input id="ff-senha" type="password" class="input-dark w-full"/>
        </div>
        <div>
          <label class="label-dark">Data Admissão</label>
          <input id="ff-data-adm" type="date" class="input-dark w-full"/>
        </div>
      </div>
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label-dark">Função</label>
          <select id="ff-funcao" class="input-dark w-full">
            <option value="">— Seleccionar —</option>
            ${funcoes.map(f => `<option value="${f.ID_FUNCAO}">${f.DESCRICAO}</option>`).join('')}
          </select>
        </div>
        <div>
          <label class="label-dark">Biblioteca</label>
          <select id="ff-biblioteca" class="input-dark w-full">
            <option value="">— Seleccionar —</option>
            ${bibliotecas.map(b => `<option value="${b.ID_BIBLIOTECA}">${b.NOME}</option>`).join('')}
          </select>
        </div>
      </div>
    </div>
  `;

  if (id) {
    get(`/api/funcionarios/${id}`).then(f => {
      document.getElementById('ff-nome').value = f.NOME || '';
      document.getElementById('ff-email').value = f.EMAIL || '';
      document.getElementById('ff-contacto').value = f.CONTACTO || '';
      if (f.DATA_ADMISSAO) document.getElementById('ff-data-adm').value = f.DATA_ADMISSAO.slice(0,10);
      if (f.ID_FUNCAO) document.getElementById('ff-funcao').value = f.ID_FUNCAO;
      if (f.ID_BIBLIOTECA) document.getElementById('ff-biblioteca').value = f.ID_BIBLIOTECA;
    }).catch(err => mostrarErroModal(err.message));
  }

  modalSalvarFn = async () => {
    const body = {
      nome: document.getElementById('ff-nome').value,
      email: document.getElementById('ff-email').value,
      contacto: document.getElementById('ff-contacto').value,
      senha: document.getElementById('ff-senha').value || undefined,
      data_admissao: document.getElementById('ff-data-adm').value,
      id_funcao: document.getElementById('ff-funcao').value || null,
      id_biblioteca: document.getElementById('ff-biblioteca').value || null,
    };
    if (!body.nome || !body.email) { mostrarErroModal('Nome e email são obrigatórios.'); return; }
    if (!id && !body.senha) { mostrarErroModal('Senha é obrigatória.'); return; }
    if (id) await put(`/api/funcionarios/${id}`, body);
    else    await post('/api/funcionarios', body);
    fecharModal();
    toast(id ? 'Funcionário actualizado.' : 'Funcionário criado.');
    carregarFuncionarios();
  };

  abrirModal();
}

async function desactivarFuncionario(id) {
  confirmar('Desactivar este funcionário?', async () => {
    try {
      await del(`/api/funcionarios/${id}`);
      toast('Funcionário desactivado.');
      carregarFuncionarios();
    } catch (err) {
      toast(err.message, 'erro');
    }
  });
}
