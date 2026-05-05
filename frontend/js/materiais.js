// ════════════════════════════════════════════════
// MATERIAIS
// ════════════════════════════════════════════════
async function carregarMateriais() {
  const q           = document.getElementById('filtro-mat-q')?.value || '';
  const tipo        = document.getElementById('filtro-mat-tipo')?.value || '';
  const conservacao = document.getElementById('filtro-mat-conservacao')?.value || '';
  const disponivel  = document.getElementById('filtro-mat-disponivel')?.value || '';
  const params = new URLSearchParams();
  if (q)           params.set('q', q);
  if (tipo)        params.set('tipo', tipo);
  if (conservacao) params.set('conservacao', conservacao);
  if (disponivel)  params.set('disponivel', disponivel);
  try {
    const rows = await get(`/api/materiais?${params}`);
    const tbody = document.getElementById('tabela-materiais');
    tbody.innerHTML = rows.length
      ? rows.map(r => {
          const dispBadge = r.DISPONIVEL_EMPRESTIMO === 'S'
            ? '<span class="badge badge-verde">Disponível</span>'
            : '<span class="badge badge-vermelho">Indisponível</span>';
          return `
        <tr>
          <td class="text-slate-500 text-xs">${r.ID_MATERIAL}</td>
          <td class="font-medium max-w-[200px] truncate">${r.TITULO || '—'}</td>
          <td class="text-slate-400">${r.AUTOR || '—'}</td>
          <td>${badgeTipo(r.TIPO)}</td>
          <td>${badgeEstado(r.ESTADO)} ${dispBadge}</td>
          <td class="space-x-2">
            <button onclick="abrirModalMaterial(${r.ID_MATERIAL})" class="btn-secondary btn-sm"><i class="fa-solid fa-pen mr-1"></i>Editar</button>
            <button onclick="eliminarMaterial(${r.ID_MATERIAL})" class="btn-danger btn-sm"><i class="fa-solid fa-trash mr-1"></i>Apagar</button>
          </td>
        </tr>`;
        }).join('')
      : linhaVazia(6);
  } catch (err) {
    toast('Erro a carregar materiais: ' + err.message, 'erro');
  }
}

async function abrirModalMaterial(id = null) {
  document.getElementById('modal-titulo').textContent = id ? 'Editar Material' : 'Novo Material';
  document.getElementById('modal-erro').classList.add('hidden');

  let cats = [];
  try { cats = await get('/api/materiais/categorias'); } catch {}

  document.getElementById('modal-conteudo').innerHTML = `
    <div class="grid grid-cols-2 gap-3">
      <div class="col-span-2">
        <label class="label-dark">Título *</label>
        <input id="mf-titulo" class="input-dark w-full" placeholder="Título do material"/>
      </div>
      <div>
        <label class="label-dark">Autor</label>
        <input id="mf-autor" class="input-dark w-full"/>
      </div>
      <div>
        <label class="label-dark">Ano Publicação</label>
        <input id="mf-ano" type="number" class="input-dark w-full" placeholder="2024"/>
      </div>
      <div>
        <label class="label-dark">ISBN</label>
        <input id="mf-isbn" class="input-dark w-full"/>
      </div>
      <div>
        <label class="label-dark">Tipo *</label>
        <select id="mf-tipo" class="input-dark w-full" onchange="toggleCamposMaterial()">
          <option value="LIVRO_FISICO">Livro Físico</option>
          <option value="EBOOK">Ebook</option>
          <option value="PERIODICO">Periódico</option>
        </select>
      </div>
      <div class="col-span-2">
        <label class="label-dark">Categoria</label>
        <select id="mf-categoria" class="input-dark w-full">
          <option value="">Sem categoria</option>
          ${cats.map(c => `<option value="${c.ID_CATEGORIA}">${c.NOME}</option>`).join('')}
        </select>
      </div>
      ${id ? `<div class="col-span-2">
        <label class="label-dark">Estado</label>
        <select id="mf-estado" class="input-dark w-full">
          <option value="DISPONIVEL">Disponível</option>
          <option value="EMPRESTADO">Emprestado</option>
          <option value="INDISPONIVEL">Indisponível</option>
        </select>
      </div>` : ''}
    </div>

    <div id="campos-livro" class="mt-3 grid grid-cols-2 gap-3">
      <div class="col-span-2">
        <label class="label-dark">Localização</label>
        <input id="mf-localizacao" class="input-dark w-full" placeholder="Prateleira A-12"/>
      </div>
      <div class="col-span-2">
        <label class="label-dark">Condição</label>
        <select id="mf-condicao" class="input-dark w-full">
          <option value="BOM">Bom</option>
          <option value="RAZOAVEL">Razoável</option>
          <option value="MAU">Mau</option>
        </select>
      </div>
    </div>
    <div id="campos-ebook" class="mt-3 grid grid-cols-2 gap-3 hidden">
      <div>
        <label class="label-dark">Formato</label>
        <select id="mf-formato" class="input-dark w-full">
          <option value="PDF">PDF</option>
          <option value="EPUB">EPUB</option>
          <option value="MOBI">MOBI</option>
        </select>
      </div>
      <div>
        <label class="label-dark">Tamanho (MB)</label>
        <input id="mf-tamanho" type="number" class="input-dark w-full" placeholder="5.2"/>
      </div>
      <div class="col-span-2">
        <label class="label-dark">URL de Acesso</label>
        <input id="mf-url" class="input-dark w-full" placeholder="https://..."/>
      </div>
    </div>
    <div id="campos-periodico" class="mt-3 grid grid-cols-2 gap-3 hidden">
      <div>
        <label class="label-dark">Volume</label>
        <input id="mf-volume" class="input-dark w-full"/>
      </div>
      <div>
        <label class="label-dark">Nº Edição</label>
        <input id="mf-edicao" class="input-dark w-full"/>
      </div>
      <div>
        <label class="label-dark">ISSN</label>
        <input id="mf-issn" class="input-dark w-full"/>
      </div>
      <div>
        <label class="label-dark">Periodicidade</label>
        <select id="mf-periodicidade" class="input-dark w-full">
          <option value="">—</option>
          <option value="DIARIA">Diária</option>
          <option value="SEMANAL">Semanal</option>
          <option value="MENSAL">Mensal</option>
          <option value="TRIMESTRAL">Trimestral</option>
          <option value="ANUAL">Anual</option>
        </select>
      </div>
    </div>
  `;

  if (id) {
    get(`/api/materiais/${id}`).then(m => {
      document.getElementById('mf-titulo').value = m.TITULO || '';
      document.getElementById('mf-autor').value = m.AUTOR || '';
      document.getElementById('mf-ano').value = m.ANO_PUB || '';
      document.getElementById('mf-isbn').value = m.ISBN || '';
      document.getElementById('mf-tipo').value = m.TIPO || 'LIVRO_FISICO';
      if (m.ID_CATEGORIA) document.getElementById('mf-categoria').value = m.ID_CATEGORIA;
      if (m.ESTADO) document.getElementById('mf-estado').value = m.ESTADO;
      document.getElementById('mf-localizacao').value = m.LOCALIZACAO || '';
      if (m.CONDICAO) document.getElementById('mf-condicao').value = m.CONDICAO;
      document.getElementById('mf-formato').value = m.FORMATO || 'PDF';
      document.getElementById('mf-tamanho').value = m.TAMANHO_MB || '';
      document.getElementById('mf-url').value = m.URL_ACESSO || '';
      document.getElementById('mf-volume').value = m.VOLUME || '';
      document.getElementById('mf-edicao').value = m.NUMERO_EDICAO || '';
      document.getElementById('mf-issn').value = m.ISSN || '';
      if (m.PERIODICIDADE) document.getElementById('mf-periodicidade').value = m.PERIODICIDADE;
      toggleCamposMaterial();
    }).catch(err => mostrarErroModal(err.message));
  }

  toggleCamposMaterial();

  modalSalvarFn = async () => {
    const tipo = document.getElementById('mf-tipo').value;
    const body = {
      titulo: document.getElementById('mf-titulo').value,
      autor: document.getElementById('mf-autor').value,
      ano_pub: document.getElementById('mf-ano').value,
      isbn: document.getElementById('mf-isbn').value,
      id_categoria: document.getElementById('mf-categoria').value || null,
      tipo,
      estado: document.getElementById('mf-estado')?.value,
      localizacao: document.getElementById('mf-localizacao')?.value,
      condicao: document.getElementById('mf-condicao')?.value,
      formato: document.getElementById('mf-formato')?.value,
      tamanho_mb: document.getElementById('mf-tamanho')?.value,
      url_acesso: document.getElementById('mf-url')?.value,
      volume: document.getElementById('mf-volume')?.value,
      numero_edicao: document.getElementById('mf-edicao')?.value,
      issn: document.getElementById('mf-issn')?.value,
      periodicidade: document.getElementById('mf-periodicidade')?.value,
    };
    if (!body.titulo) { mostrarErroModal('Título é obrigatório.'); return; }
    if (id) await put(`/api/materiais/${id}`, body);
    else    await post('/api/materiais', body);
    fecharModal();
    toast(id ? 'Material actualizado.' : 'Material criado com sucesso.');
    carregarMateriais();
  };

  abrirModal();
}

function toggleCamposMaterial() {
  const tipo = document.getElementById('mf-tipo')?.value;
  document.getElementById('campos-livro').classList.toggle('hidden', tipo !== 'LIVRO_FISICO');
  document.getElementById('campos-ebook').classList.toggle('hidden', tipo !== 'EBOOK');
  document.getElementById('campos-periodico').classList.toggle('hidden', tipo !== 'PERIODICO');
}

async function eliminarMaterial(id) {
  confirmar('Apagar este material? Esta acção é irreversível.', async () => {
    try {
      await del(`/api/materiais/${id}`);
      toast('Material eliminado.');
      carregarMateriais();
    } catch (err) {
      toast(err.message, 'erro');
    }
  });
}
