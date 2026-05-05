// ════════════════════════════════════════════════
// DOAÇÕES
// ════════════════════════════════════════════════
let tabDoacoesActual = 'doacoes';

function switchTabDoacoes(tab) {
  tabDoacoesActual = tab;
  ['doacoes','doadores','certificados'].forEach(t => {
    document.getElementById(`sub-${t}`).classList.toggle('hidden', t !== tab);
    const btn = document.getElementById(`tab-${t}-btn`);
    if (btn) btn.classList.toggle('tab-active', t === tab);
  });
  if (tab === 'doacoes')            carregarDoacoes();
  else if (tab === 'doadores')      carregarDoadores();
  else if (tab === 'certificados')  carregarCertificados();
}

async function carregarDoacoes() {
  try {
    const rows = await get('/api/doacoes');
    const tbody = document.getElementById('tabela-doacoes');
    tbody.innerHTML = rows.length
      ? rows.map(r => `
        <tr>
          <td class="text-slate-500 text-xs">${r.ID_DOACAO}</td>
          <td class="font-medium">${r.NOME_DOADOR || '—'}</td>
          <td class="text-slate-400">${fmtData(r.DATA_DOACAO)}</td>
          <td class="text-green-400">${fmtMoeda(r.VALOR_TOTAL)}</td>
          <td class="text-slate-400">${r.NOME_BIBLIOTECA || '—'}</td>
        </tr>`).join('')
      : linhaVazia(5);
  } catch (err) {
    toast('Erro a carregar doações: ' + err.message, 'erro');
  }
}

async function carregarDoadores() {
  try {
    const rows = await get('/api/doacoes/doadores');
    const tbody = document.getElementById('tabela-doadores');
    tbody.innerHTML = rows.length
      ? rows.map(r => `
        <tr>
          <td class="text-slate-500 text-xs">${r.ID_DOADOR}</td>
          <td class="font-medium">${r.NOME || '—'}</td>
          <td>${badgeTipo(r.TIPO)}</td>
          <td class="text-slate-400">${r.CONTACTO || '—'}</td>
          <td class="text-slate-400">${r.EMAIL || '—'}</td>
        </tr>`).join('')
      : linhaVazia(5);
  } catch (err) {
    toast('Erro a carregar doadores: ' + err.message, 'erro');
  }
}

async function carregarCertificados() {
  try {
    const rows = await get('/api/doacoes/certificados');
    const tbody = document.getElementById('tabela-certificados');
    tbody.innerHTML = rows.length
      ? rows.map(r => `
        <tr>
          <td class="text-slate-500 text-xs">${r.ID_CERTIFICADO}</td>
          <td class="font-mono text-xs text-slate-300">${r.NUMERO_SERIE || '—'}</td>
          <td class="font-medium">${r.NOME_DOADOR || '—'}</td>
          <td class="text-slate-400">${fmtData(r.DATA_EMISSAO)}</td>
          <td>
            <button onclick="reemitirCertificado(${r.ID_CERTIFICADO})" class="btn-secondary btn-sm"><i class="fa-solid fa-rotate mr-1"></i>Reemitir</button>
          </td>
        </tr>`).join('')
      : linhaVazia(5);
  } catch (err) {
    toast('Erro a carregar certificados: ' + err.message, 'erro');
  }
}

function reemitirCertificado(id) {
  const modal = document.getElementById('modal-reemissao');
  const input = document.getElementById('modal-reemissao-motivo');
  input.value = '';
  modal.classList.remove('hidden');
  const close = () => modal.classList.add('hidden');
  document.getElementById('modal-reemissao-fechar').onclick = close;
  document.getElementById('modal-reemissao-cancelar').onclick = close;
  document.getElementById('modal-reemissao-ok').onclick = async () => {
    const motivo = input.value.trim();
    if (!motivo) { input.focus(); return; }
    close();
    try {
      await post(`/api/doacoes/certificados/${id}/reemitir`, { motivo });
      toast('Certificado reemitido com sucesso.');
      carregarCertificados();
    } catch (err) {
      toast(err.message, 'erro');
    }
  };
}

function abrirModalDoador() {
  document.getElementById('modal-titulo').textContent = 'Novo Doador';
  document.getElementById('modal-erro').classList.add('hidden');
  document.getElementById('modal-conteudo').innerHTML = `
    <div class="space-y-3">
      <div>
        <label class="label-dark">Nome *</label>
        <input id="df-nome" class="input-dark w-full"/>
      </div>
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label-dark">Tipo *</label>
          <select id="df-tipo" class="input-dark w-full">
            <option value="INDIVIDUAL">Individual</option>
            <option value="INSTITUCIONAL">Institucional</option>
          </select>
        </div>
        <div>
          <label class="label-dark">Contacto</label>
          <input id="df-contacto" class="input-dark w-full"/>
        </div>
        <div>
          <label class="label-dark">Email</label>
          <input id="df-email" type="email" class="input-dark w-full"/>
        </div>
        <div>
          <label class="label-dark">NUIT</label>
          <input id="df-nuit" class="input-dark w-full"/>
        </div>
      </div>
      <div>
        <label class="label-dark">Morada</label>
        <input id="df-morada" class="input-dark w-full"/>
      </div>
    </div>
  `;
  modalSalvarFn = async () => {
    const body = {
      nome: document.getElementById('df-nome').value,
      tipo: document.getElementById('df-tipo').value,
      contacto: document.getElementById('df-contacto').value,
      email: document.getElementById('df-email').value,
      morada: document.getElementById('df-morada').value,
      nuit: document.getElementById('df-nuit').value,
    };
    if (!body.nome) { mostrarErroModal('Nome é obrigatório.'); return; }
    await post('/api/doacoes/doadores', body);
    fecharModal();
    toast('Doador criado com sucesso.');
    carregarDoadores();
  };
  abrirModal();
}

async function abrirModalDoacao() {
  document.getElementById('modal-titulo').textContent = 'Nova Doação';
  document.getElementById('modal-erro').classList.add('hidden');

  let doadores = [], bibliotecas = [];
  try { doadores = await get('/api/doacoes/doadores'); } catch {}
  try { bibliotecas = await get('/api/funcionarios/bibliotecas'); } catch {}

  document.getElementById('modal-conteudo').innerHTML = `
    <div class="space-y-3">
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label-dark">Doador *</label>
          <select id="dacf-doador" class="input-dark w-full">
            <option value="">— Seleccionar —</option>
            ${doadores.map(d => `<option value="${d.ID_DOADOR}">${d.NOME}</option>`).join('')}
          </select>
        </div>
        <div>
          <label class="label-dark">Biblioteca</label>
          <select id="dacf-bib" class="input-dark w-full">
            <option value="">— Seleccionar —</option>
            ${bibliotecas.map(b => `<option value="${b.ID_BIBLIOTECA}">${b.NOME}</option>`).join('')}
          </select>
        </div>
        <div class="col-span-2">
          <label class="label-dark">Data da Doação</label>
          <input id="dacf-data" type="date" class="input-dark w-full"/>
        </div>
      </div>
      <hr class="border-slate-700"/>
      <p class="text-sm text-slate-400 font-medium">Itens Doados</p>
      <div id="itens-doacao" class="space-y-2">
        <div class="grid grid-cols-3 gap-2 item-doacao">
          <div>
            <label class="label-dark">ID Material</label>
            <input class="input-dark w-full itd-material" type="number" placeholder="ID"/>
          </div>
          <div>
            <label class="label-dark">Qtd.</label>
            <input class="input-dark w-full itd-qtd" type="number" value="1" min="1"/>
          </div>
          <div>
            <label class="label-dark">Valor Unit. (MT)</label>
            <input class="input-dark w-full itd-valor" type="number" step="0.01" placeholder="0.00"/>
          </div>
        </div>
      </div>
      <button onclick="adicionarItemDoacao()" class="btn-secondary text-sm">+ Adicionar Item</button>
    </div>
  `;

  document.getElementById('dacf-data').value = new Date().toISOString().slice(0,10);

  modalSalvarFn = async () => {
    const id_doador = document.getElementById('dacf-doador').value;
    if (!id_doador) { mostrarErroModal('Selecciona um doador.'); return; }

    const itemEls = document.querySelectorAll('.item-doacao');
    const itens = Array.from(itemEls).map(el => ({
      id_material: el.querySelector('.itd-material').value,
      quantidade: parseInt(el.querySelector('.itd-qtd').value) || 1,
      valor_unitario: parseFloat(el.querySelector('.itd-valor').value) || 0,
    })).filter(i => i.id_material);

    if (!itens.length) { mostrarErroModal('Adiciona pelo menos um item.'); return; }

    await post('/api/doacoes', {
      id_doador,
      id_biblioteca: document.getElementById('dacf-bib').value || null,
      data_doacao: document.getElementById('dacf-data').value,
      itens,
    });
    fecharModal();
    toast('Doação registada com sucesso.');
    carregarDoacoes();
  };

  abrirModal();
}

function adicionarItemDoacao() {
  const cont = document.getElementById('itens-doacao');
  const div = document.createElement('div');
  div.className = 'grid grid-cols-3 gap-2 item-doacao';
  div.innerHTML = `
    <div><input class="input-dark w-full itd-material" type="number" placeholder="ID Material"/></div>
    <div><input class="input-dark w-full itd-qtd" type="number" value="1" min="1"/></div>
    <div><input class="input-dark w-full itd-valor" type="number" step="0.01" placeholder="0.00"/></div>
  `;
  cont.appendChild(div);
}
