// ════════════════════════════════════════════════
// EMPRÉSTIMOS
// ════════════════════════════════════════════════
let tabEmprestimosActual = 'ACTIVO';
let emprestimoDevolverID = null;

function switchTabEmprestimos(tab) {
  tabEmprestimosActual = tab;
  document.getElementById('tab-emp-ativos').classList.toggle('tab-active', tab === 'ACTIVO');
  document.getElementById('tab-emp-hist').classList.toggle('tab-active', tab === 'HISTORICO');
  carregarEmprestimos(tab);
}

async function carregarEmprestimos(estado = 'ACTIVO') {
  try {
    const rows = await get(`/api/emprestimos?estado=${estado}`);
    const tbody = document.getElementById('tabela-emprestimos');
    tbody.innerHTML = rows.length
      ? rows.map(r => {
          const atrasado = r.DIAS_ATRASO > 0;
          return `<tr class="${atrasado ? 'bg-red-950/20' : ''}">
            <td class="text-slate-500 text-xs">${r.ID_EMPRESTIMO}</td>
            <td>${r.NOME_LEITOR || r.NUM_CARTAO || '—'}</td>
            <td class="max-w-[150px] truncate">${r.TITULO || r.ID_MATERIAL || '—'}</td>
            <td class="text-slate-400">${fmtData(r.DATA_EMP)}</td>
            <td class="${atrasado ? 'text-red-400' : 'text-slate-400'}">${fmtData(r.DATA_DEVOLUCAO_PREV)}</td>
            <td class="text-amber-400">${r.MULTA || r.MULTA_ATUAL ? fmtMoeda(r.MULTA || r.MULTA_ATUAL) : '—'}</td>
            <td>${badgeEstado(r.ESTADO)}</td>
            <td>
              ${r.ESTADO === 'ACTIVO' || r.ESTADO === 'ATIVO'
                ? `<button onclick="abrirModalDevolucao(${r.ID_EMPRESTIMO}, '${(r.NOME_LEITOR||'').replace(/'/g,"\\'")}', '${(r.TITULO||'').replace(/'/g,"\\'")}', ${r.MULTA_ATUAL||0})" class="btn-primary btn-sm"><i class="fa-solid fa-rotate-left mr-1"></i>Devolver</button>`
                : ''}
            </td>
          </tr>`;
        }).join('')
      : linhaVazia(8);
  } catch (err) {
    toast('Erro a carregar empréstimos: ' + err.message, 'erro');
  }
}

function abrirModalEmprestimo() {
  document.getElementById('modal-titulo').textContent = 'Registar Empréstimo';
  document.getElementById('modal-erro').classList.add('hidden');

  document.getElementById('modal-conteudo').innerHTML = `
    <div class="space-y-3">
      <div>
        <label class="label-dark">Nº Cartão do Leitor *</label>
        <input id="ef-cartao" class="input-dark w-full" placeholder="Ex: ABC2024XXXXX"/>
      </div>
      <div>
        <label class="label-dark">ID do Material *</label>
        <input id="ef-material" type="number" class="input-dark w-full" placeholder="Ex: 12"/>
      </div>
      <div>
        <label class="label-dark">Data Prevista de Devolução</label>
        <input id="ef-data-dev" type="date" class="input-dark w-full"/>
      </div>
    </div>
  `;

  const dataPrev = new Date();
  dataPrev.setDate(dataPrev.getDate() + 15);
  document.getElementById('ef-data-dev').value = dataPrev.toISOString().slice(0,10);

  modalSalvarFn = async () => {
    const body = {
      num_cartao: document.getElementById('ef-cartao').value,
      id_material: document.getElementById('ef-material').value,
      data_devolucao_prev: document.getElementById('ef-data-dev').value,
      id_funcionario: utilizadorActual?.ID_FUNCIONARIO,
    };
    if (!body.num_cartao || !body.id_material) {
      mostrarErroModal('Cartão e material são obrigatórios.');
      return;
    }
    await post('/api/emprestimos', body);
    fecharModal();
    toast('Empréstimo registado com sucesso.');
    carregarEmprestimos('ACTIVO');
  };

  abrirModal();
}

function abrirModalDevolucao(id, leitor, titulo, multaActual) {
  emprestimoDevolverID = id;
  document.getElementById('dev-info').textContent = `Leitor: ${leitor} | Material: ${titulo}`;
  const multaEl = document.getElementById('dev-multa-info');
  if (multaActual > 0) {
    multaEl.textContent = `Multa actual: ${fmtMoeda(multaActual)}`;
    multaEl.classList.remove('hidden');
  } else {
    multaEl.classList.add('hidden');
  }
  document.getElementById('modal-devolucao').classList.remove('hidden');
}

function fecharModalDevolucao() {
  document.getElementById('modal-devolucao').classList.add('hidden');
  emprestimoDevolverID = null;
}

async function confirmarDevolucao() {
  if (!emprestimoDevolverID) return;
  const condicao = document.getElementById('dev-condicao').value;
  try {
    const res = await put(`/api/emprestimos/${emprestimoDevolverID}/devolver`, { condicao_devolucao: condicao });
    fecharModalDevolucao();
    const multa = res.MULTA || 0;
    toast(`Devolução registada.${multa > 0 ? ` Multa: ${fmtMoeda(multa)}` : ''}`);
    carregarEmprestimos(tabEmprestimosActual);
  } catch (err) {
    toast(err.message, 'erro');
  }
}
