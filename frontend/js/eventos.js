// ════════════════════════════════════════════════
// EVENTOS
// ════════════════════════════════════════════════
let eventoActualId = null;

async function carregarEventos() {
  try {
    const rows = await get('/api/eventos');
    const tbody = document.getElementById('tabela-eventos');
    tbody.innerHTML = rows.length
      ? rows.map(r => `
        <tr>
          <td class="font-medium max-w-[180px] truncate">${r.NOME || '—'}</td>
          <td class="text-slate-400">${fmtData(r.DATA_INICIO)}</td>
          <td>${r.TIPO ? badge(r.TIPO, 'azul') : '—'}</td>
          <td class="text-slate-400">${r.PUBLICO_ALVO || '—'}</td>
          <td class="text-slate-400">${r.INSCRITOS ?? '—'}/${r.CAPACIDADE ?? '∞'}</td>
          <td class="text-slate-400 text-sm">${r.NOME_BIBLIOTECA || '—'}</td>
          <td class="whitespace-nowrap">
            <div class="flex flex-wrap gap-1">
              <button onclick="abrirModalParticipacoes(${r.ID_EVENTO})" class="btn-secondary btn-sm"><i class="fa-solid fa-users mr-1"></i>Participantes</button>
              <button onclick="abrirModalEvento(${r.ID_EVENTO})" class="btn-secondary btn-sm"><i class="fa-solid fa-pen mr-1"></i>Editar</button>
              <button onclick="eliminarEvento(${r.ID_EVENTO})" class="btn-danger btn-sm"><i class="fa-solid fa-trash mr-1"></i>Apagar</button>
            </div>
          </td>
        </tr>`).join('')
      : linhaVazia(7);
  } catch (err) {
    toast('Erro a carregar eventos: ' + err.message, 'erro');
  }
}

async function abrirModalEvento(id = null) {
  document.getElementById('modal-titulo').textContent = id ? 'Editar Evento' : 'Novo Evento';
  document.getElementById('modal-erro').classList.add('hidden');

  let bibliotecas = [];
  try { bibliotecas = await get('/api/funcionarios/bibliotecas'); } catch {}

  document.getElementById('modal-conteudo').innerHTML = `
    <div class="space-y-3">
      <div>
        <label class="label-dark">Nome do Evento *</label>
        <input id="evf-nome" class="input-dark w-full"/>
      </div>
      <div>
        <label class="label-dark">Descrição</label>
        <textarea id="evf-desc" class="input-dark w-full h-20 resize-none"></textarea>
      </div>
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label-dark">Data Início *</label>
          <input id="evf-inicio" type="date" class="input-dark w-full"/>
        </div>
        <div>
          <label class="label-dark">Data Fim</label>
          <input id="evf-fim" type="date" class="input-dark w-full"/>
        </div>
        <div>
          <label class="label-dark">Capacidade</label>
          <input id="evf-cap" type="number" class="input-dark w-full" placeholder="Ex: 50"/>
        </div>
        <div>
          <label class="label-dark">Tipo</label>
          <select id="evf-tipo" class="input-dark w-full">
            <option value="">—</option>
            <option value="WORKSHOP">Workshop</option>
            <option value="LEITURA">Leitura</option>
            <option value="PALESTRA">Palestra</option>
            <option value="EXPOSICAO">Exposição</option>
            <option value="OUTRO">Outro</option>
          </select>
        </div>
        <div>
          <label class="label-dark">Público-Alvo</label>
          <select id="evf-publico" class="input-dark w-full">
            <option value="">Geral</option>
            <option value="CRIANCA">Crianças</option>
            <option value="ADULTO">Adultos</option>
            <option value="PROFESSOR">Professores</option>
          </select>
        </div>
        <div>
          <label class="label-dark">Recorrente</label>
          <select id="evf-recorrente" class="input-dark w-full">
            <option value="0">Não</option>
            <option value="1">Semanal</option>
            <option value="2">Mensal</option>
          </select>
        </div>
      </div>
      <div>
        <label class="label-dark">Biblioteca</label>
        <select id="evf-biblioteca" class="input-dark w-full">
          <option value="">— Seleccionar —</option>
          ${bibliotecas.map(b => `<option value="${b.ID_BIBLIOTECA}">${b.NOME}</option>`).join('')}
        </select>
      </div>
    </div>
  `;

  if (id) {
    get(`/api/eventos/${id}`).then(ev => {
      document.getElementById('evf-nome').value = ev.NOME || '';
      document.getElementById('evf-desc').value = ev.DESCRICAO || '';
      if (ev.DATA_INICIO) document.getElementById('evf-inicio').value = ev.DATA_INICIO.slice(0,10);
      if (ev.DATA_FIM) document.getElementById('evf-fim').value = ev.DATA_FIM.slice(0,10);
      document.getElementById('evf-cap').value = ev.CAPACIDADE || '';
      if (ev.TIPO) document.getElementById('evf-tipo').value = ev.TIPO;
      if (ev.PUBLICO_ALVO) document.getElementById('evf-publico').value = ev.PUBLICO_ALVO;
      document.getElementById('evf-recorrente').value = ev.RECORRENTE || 0;
      if (ev.ID_BIBLIOTECA) document.getElementById('evf-biblioteca').value = ev.ID_BIBLIOTECA;
    }).catch(err => mostrarErroModal(err.message));
  }

  modalSalvarFn = async () => {
    const body = {
      nome: document.getElementById('evf-nome').value,
      descricao: document.getElementById('evf-desc').value,
      data_inicio: document.getElementById('evf-inicio').value,
      data_fim: document.getElementById('evf-fim').value,
      capacidade: document.getElementById('evf-cap').value || null,
      tipo: document.getElementById('evf-tipo').value,
      publico_alvo: document.getElementById('evf-publico').value,
      recorrente: document.getElementById('evf-recorrente').value,
      id_biblioteca: document.getElementById('evf-biblioteca').value || null,
    };
    if (!body.nome || !body.data_inicio) { mostrarErroModal('Nome e data de início são obrigatórios.'); return; }
    if (id) await put(`/api/eventos/${id}`, body);
    else    await post('/api/eventos', body);
    fecharModal();
    toast(id ? 'Evento actualizado.' : 'Evento criado.');
    carregarEventos();
  };

  abrirModal();
}

async function eliminarEvento(id) {
  confirmar('Apagar este evento? Esta acção é irreversível.', async () => {
    try {
      await del(`/api/eventos/${id}`);
      toast('Evento eliminado.');
      carregarEventos();
    } catch (err) {
      toast(err.message, 'erro');
    }
  });
}

async function abrirModalParticipacoes(idEvento) {
  eventoActualId = idEvento;
  await carregarParticipacoes();
  document.getElementById('modal-participacoes').classList.remove('hidden');
}

function fecharModalParticipacoes() {
  document.getElementById('modal-participacoes').classList.add('hidden');
  eventoActualId = null;
}

async function carregarParticipacoes() {
  if (!eventoActualId) return;
  try {
    const rows = await get(`/api/eventos/${eventoActualId}/participacoes`);
    const lista = document.getElementById('lista-participacoes');
    lista.innerHTML = rows.length
      ? rows.map(p => `
          <div class="flex items-center justify-between py-2 border-b border-slate-700">
            <div>
              <span class="font-medium text-sm">${p.NOME_LEITOR || '—'}</span>
              <span class="text-slate-500 text-xs ml-2">${p.NUM_CARTAO}</span>
            </div>
            <button onclick="removerParticipacao('${p.NUM_CARTAO}')" class="btn-danger btn-sm"><i class="fa-solid fa-user-minus mr-1"></i>Remover</button>
          </div>`).join('')
      : '<p class="text-slate-500 text-sm">Sem participantes inscritos.</p>';
  } catch (err) {
    toast('Erro: ' + err.message, 'erro');
  }
}

async function inscreverLeitorEvento() {
  const nc = document.getElementById('input-nc-inscricao').value.trim();
  if (!nc || !eventoActualId) return;
  try {
    await post(`/api/eventos/${eventoActualId}/participacoes`, { num_cartao: nc });
    document.getElementById('input-nc-inscricao').value = '';
    toast('Leitor inscrito com sucesso.');
    await carregarParticipacoes();
  } catch (err) {
    toast(err.message, 'erro');
  }
}

async function removerParticipacao(numCartao) {
  if (!eventoActualId) return;
  confirmar('Remover esta inscrição?', async () => {
    try {
      await del(`/api/eventos/${eventoActualId}/participacoes/${numCartao}`);
      toast('Inscrição removida.');
      await carregarParticipacoes();
    } catch (err) {
      toast(err.message, 'erro');
    }
  });
}
