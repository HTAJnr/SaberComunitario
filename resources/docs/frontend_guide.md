# Saber Comunitário — Guia de Interface para o Backend
**Versão 1.0** | Stack: Node.js + HTML/CSS (Tailwind) + JS

> Este documento descreve o que o frontend vai precisar do backend: rotas, payloads, lógica de autenticação, controlo de permissões e comportamentos esperados por módulo. O backend deve preparar as APIs de acordo com esta especificação antes de o frontend ser integrado.

---

## 1. Autenticação e Sessão

### Login
- **POST** `/api/auth/login`
- Body: `{ email, senha }`
- Resposta esperada (sucesso):
```json
{
  "ok": true,
  "funcionario": {
    "COD_FUNCIONARIO": "FUC20250001",
    "NOME_FUNCIONARIO": "Ana Machava",
    "EMAIL": "ana.machava@sabercomunitario.mz",
    "NIVEL_ACESSO": "Coordenador",
    "FUNCAO": "Coordenador",
    "COD_BIBLIOTECA": "BIBMPM0001",
    "NOME_BIBLIOTECA": "Biblioteca Esperança de Maputo",
    "PROVINCIA": "Maputo Cidade"
  }
}
```
- O campo `NIVEL_ACESSO` é o que o frontend usa para controlar permissões. Vem na resposta e na sessão do servidor.
- Auth usa sessões de servidor (cookie). Sem JWT nesta versão.
- `PROVINCIA` determina o tema de região aplicado no login (Sul / Centro / Norte).

### JWT
- Todos os endpoints autenticados esperam header: `Authorization: Bearer <token>`
- Token deve incluir: `cod_funcionario`, `nivel_acesso`, `cod_biblioteca`
- Expiração sugerida: 8 horas (turno de trabalho)

### Logout
- **POST** `/api/auth/logout` (invalida token no servidor se usar blacklist, ou apenas limpa no frontend)

---

## 2. Perfil do Utilizador Logado

O funcionário pode ver e editar os seus próprios dados a partir de qualquer tela via ícone no header.

### Ver perfil próprio
- **GET** `/api/funcionarios/me`
- Resposta: dados completos do funcionário logado, incluindo habilidades e horários

```json
{
  "cod_funcionario": "FUC20250001",
  "nome_funcionario": "Ana Machava",
  "genero": "Feminino",
  "data_nasc": "1990-05-14",
  "contacto": "+258 84 123 4567",
  "endereco": "Av. Eduardo Mondlane, nº 42, Maputo",
  "formacao": "Licenciatura em Biblioteconomia",
  "experiencia": "5 anos em gestão de acervos comunitários",
  "data_contratacao": "2020-01-15",
  "email": "ana.machava@sabercomunitario.mz",
  "nome_funcao": "Coordenador",
  "nivel_acesso": "Coordenador",
  "nome_biblioteca": "Biblioteca Esperança de Maputo",
  "habilidades": ["Catalogação", "Língua Inglesa"],
  "horarios": [
    { "dia_semana": "Segunda-feira", "hora_entrada": "08:00", "hora_saida": "16:00" },
    { "dia_semana": "Terça-feira", "hora_entrada": "08:00", "hora_saida": "16:00" }
  ]
}
```

### Editar perfil próprio
- **PATCH** `/api/funcionarios/me`
- Campos editáveis pelo próprio: `contacto`, `endereco`, `foto_path`
- Campos **não editáveis** pelo próprio via esta rota: `email` (gerado pelo sistema), `nivel_acesso`, `nome_funcao`, `cod_biblioteca`, `data_contratacao`
- Body exemplo:
```json
{
  "contacto": "+258 84 999 8888",
  "endereco": "Rua da Paz, nº 10, Maputo"
}
```

### Alterar senha
- **PATCH** `/api/funcionarios/me/senha`
- Body: `{ senha_atual, nova_senha }`
- Backend valida senha actual antes de actualizar
- Nova senha armazenada como hash SHA-256 conforme DD

---

## 3. Controlo de Permissões

O frontend controla visibilidade de elementos com base no `nivel_acesso` vindo do token. A lógica é:

```
Administrador  → acesso total a tudo na rede
Coordenador    → acesso total à sua biblioteca
Bibliotecario  → acesso operacional à sua biblioteca (sem gestão de funcionários, transferências, doações)
Assistente     → acesso limitado: ver + criar leitores/empréstimos, gerir participantes em eventos
```

### Matriz de permissões por módulo

| Módulo | Administrador | Coordenador | Bibliotecário | Assistente |
|---|---|---|---|---|
| Dashboard rede | ✅ | ❌ | ❌ | ❌ |
| Dashboard biblioteca | ✅ | ✅ | ✅ (limitado) | ✅ (só hoje) |
| Leitores — ver lista | ✅ | ✅ | ✅ | ✅ |
| Leitores — cadastrar | ✅ | ✅ | ✅ | ✅ |
| Leitores — editar | ✅ | ✅ | ✅ | ❌ |
| Leitores — alterar status | ✅ | ✅ | ❌ | ❌ |
| Leitores — eliminar | ✅ | ❌ | ❌ | ❌ |
| Empréstimos — ver | ✅ | ✅ | ✅ | ✅ |
| Empréstimos — criar | ✅ | ✅ | ✅ | ✅ |
| Empréstimos — devolver | ✅ | ✅ | ✅ | ✅ |
| Empréstimos — editar/apagar | ✅ | ✅ | ✅ | ❌ |
| Materiais — ver catálogo | ✅ | ✅ | ✅ | ✅ |
| Materiais — adicionar/editar | ✅ | ✅ | ✅ | ❌ |
| Materiais — eliminar | ✅ | ✅ | ❌ | ❌ |
| Transferências | ✅ | ✅ | ❌ | ❌ |
| Eventos — ver | ✅ | ✅ | ✅ | ✅ |
| Eventos — criar/editar | ✅ | ✅ | ✅ | ❌ |
| Eventos — gerir participantes | ✅ | ✅ | ✅ | ✅ |
| Eventos — cancelar | ✅ | ✅ | ✅ | ❌ |
| Doações | ✅ | ✅ | ❌ | ❌ |
| Programas de Alfabetização — ver | ✅ | ✅ | ✅ | ✅ |
| Programas de Alfabetização — gerir | ✅ | ✅ | ✅ | ❌ |
| Funcionários — ver | ✅ | ✅ | ❌ | ❌ |
| Funcionários — gerir | ✅ | ✅ | ❌ | ❌ |
| Funcionários — alterar nível de acesso | ✅ | ❌ | ❌ | ❌ |
| Bibliotecas — ver rede | ✅ | ❌ | ❌ | ❌ |
| Bibliotecas — gerir própria | ✅ | ✅ | ❌ | ❌ |
| Bibliotecas — adicionar/remover da rede | ✅ | ❌ | ❌ | ❌ |
| Suspensões — ver | ✅ | ✅ | ✅ | ❌ |
| Suspensões — reduzir/remover | ✅ | ✅ | ❌ | ❌ |

> **Importante:** O backend deve validar permissões em cada rota, independentemente do que o frontend mostra ou esconde. O frontend esconde botões para UX — o backend rejeita requisições não autorizadas para segurança.

---

## 4. Módulo Dashboard

### Estatísticas globais (só Administrador)
- **GET** `/api/dashboard/rede`
- Resposta:
```json
{
  "total_bibliotecas": 4,
  "total_leitores": 1240,
  "emprestimos_ativos": 87,
  "emprestimos_vencidos": 12,
  "transferencias_pendentes": 3,
  "materiais_perdidos_mes": 2,
  "total_multas_por_cobrar": 4500.00
}
```

### Estatísticas da biblioteca (Coordenador, Bibliotecário, Assistente)
- **GET** `/api/dashboard/biblioteca` (usa `cod_biblioteca` do token)
- Resposta:
```json
{
  "emprestimos_ativos": 23,
  "emprestimos_vencidos": 4,
  "devolucoes_hoje": 5,
  "materiais_disponiveis": 340,
  "materiais_emprestados": 23,
  "multas_por_cobrar": 1200.00,
  "eventos_este_mes": 2,
  "doacoes_este_mes": 1,
  "transferencias_pendentes": 1,
  "emprestimos_semana": [12, 8, 15, 9, 11, 3, 0],
  "top_materiais": [
    { "titulo": "O Leão e o Ratinho", "total_emprestimos": 18 }
  ]
}
```

---

## 5. Módulo Leitores

### Listar leitores
- **GET** `/api/leitores?biblioteca=BIBMPM0001&status=Activo&tipo=Adulto&historico=Pontual&search=Ana&page=1&limit=20`
- Administrador pode passar qualquer `biblioteca`. Os outros roles só vêem a sua.
- Resposta inclui tipo resolvido (Adulto/Criança/Professor), empréstimo activo flag

### Perfil completo do leitor
- **GET** `/api/leitores/:num_cartao`
- Resposta inclui: dados base + subtipo (adulto/criança/professor com campos específicos) + empréstimo activo (se existir) + histórico de empréstimos (últimos 10) + suspensões activas + multas em aberto

### Cadastrar leitor
- **POST** `/api/leitores`
- Body varia conforme tipo:
```json
{
  "tipo": "Adulto",
  "nome_completo": "João Sitoe",
  "data_nasc": "1985-03-20",
  "genero": "Masculino",
  "nivel_escolar": "Secundário Completo",
  "localizacao_leitor": "Bairro da Maxaquene, Maputo",
  "contacto": "+258 82 555 1234",
  "distancia_biblioteca": 3.5,
  "profissao": "Agricultor",
  "nivel_literacia": "Funcional",
  "interesses": ["Agricultura", "Saúde"]
}
```
- Para tipo `"Crianca"`: inclui `nome_responsavel`, `telefone_responsavel`, `escola_frequenta`, `classe`
- Para tipo `"Professor"`: inclui campos de adulto + `escola_instituto`, `nivel_ensino`, `num_alunos`, `disciplinas: []`
- Backend gera `num_cartao` automaticamente no formato `XXX202XYYY`

### Editar leitor
- **PATCH** `/api/leitores/:num_cartao`
- Apenas campos editáveis (não altera num_cartao, cod_biblioteca, status gerado por triggers)

### Alterar status manualmente
- **PATCH** `/api/leitores/:num_cartao/status`
- Só Coordenador/Administrador
- Body: `{ status_leitor: "Activo", observacoes: "Suspensão levantada por decisão do coordenador" }`

### Eliminar leitor
- **DELETE** `/api/leitores/:num_cartao`
- Só Administrador
- Backend verifica: sem empréstimo activo, sem multas por pagar

---

## 6. Módulo Empréstimos

### Listar empréstimos
- **GET** `/api/emprestimos?biblioteca=BIBMPM0001&estado=activo&page=1&limit=20`
- `estado`: `activo` | `vencido` | `devolvido` | `todos`
- Resposta inclui dados do leitor e material já resolvidos (JOIN)

### Validar leitor antes de criar empréstimo
- **GET** `/api/emprestimos/validar-leitor/:num_cartao`
- Frontend chama isto ao seleccionar o leitor no formulário
- Resposta:
```json
{
  "pode_emprestar": false,
  "motivo": "Leitor tem empréstimo activo",
  "emprestimo_activo": { "id_emprestimo": 42, "titulo": "A Escola da Floresta", "prazo_devolucao": "2025-06-10" }
}
```

### Preview do prazo antes de confirmar
- **POST** `/api/emprestimos/calcular-prazo`
- Body: `{ num_cartao, data_retirada }`
- Resposta: `{ prazo_devolucao: "2025-06-27", dias_prazo: 24, detalhes: { base: 14, geografico: 3, professor: 7, pontualidade: 0 } }`

### Criar empréstimo
- **POST** `/api/emprestimos`
- Body:
```json
{
  "num_cartao": "BEI20250001",
  "cod_material": "MAT20250012",
  "estado_material_saida": "Bom",
  "observacoes": ""
}
```
- Backend calcula e insere `prazo_devolucao` conforme RN02
- Backend valida RN01 (empréstimo activo), RN04.1 (faixa etária), status do leitor

### Registar devolução
- **PATCH** `/api/emprestimos/:id_emprestimo/devolver`
- Body:
```json
{
  "estado_material_retorno": "Degradado",
  "observacoes_devolucao": "Capa com rasgão na lombada"
}
```
- Triggers calculam multa, aplicam suspensão, actualizam estado do material, actualizam histórico de pontualidade
- Resposta inclui resumo: dias de atraso, multa calculada, suspensão gerada (se houver)

### Marcar multa como paga
- **PATCH** `/api/emprestimos/:id_emprestimo/pagar-multa`
- Body: `{ data_pagamento_multa: "2025-06-15" }`

---

## 7. Módulo Materiais

### Listar materiais (catálogo)
- **GET** `/api/materiais?biblioteca=BIBMPM0001&tipo=Livro&estado=Bom&disponivel=true&search=historia&page=1&limit=20`
- `tipo`: `Livro` | `Ebook` | `Periodico`
- `disponivel`: filtra materiais não emprestados e não `Indisponivel`

### Detalhe do material
- **GET** `/api/materiais/:cod_material`
- Resposta inclui subtipo (livro/ebook/periódico), categoria, histórico de empréstimos (últimos 5), transferências associadas, doação de origem (se aplicável)

### Criar material
- **POST** `/api/materiais`
- Body base + subtipo:
```json
{
  "titulo": "Fauna de Moçambique",
  "autor": "Machava, R., Tembe, J.",
  "editora": "INLD",
  "ano_publicacao": 2020,
  "idioma": "Português",
  "num_paginas": 230,
  "origem_material": "Comprado",
  "data_aquisicao": "2025-01-10",
  "valor_aquisicao": 850.00,
  "localizacao_estante": "B3-EST1-012",
  "cod_categoria": 3,
  "tipo": "Livro"
}
```
- Backend gera `cod_material` no formato `MAT20XXYYYY`

### Editar material
- **PATCH** `/api/materiais/:cod_material`

### Eliminar material
- **DELETE** `/api/materiais/:cod_material`
- Backend verifica: sem empréstimo activo, sem transferência pendente/aprovada

---

## 8. Módulo Transferências

### Listar transferências
- **GET** `/api/transferencias?biblioteca=BIBMPM0001&direcao=enviadas&estado=Pendente`
- `direcao`: `enviadas` | `recebidas` | `todas`

### Solicitar transferência (Coordenador)
- **POST** `/api/transferencias`
- Body: `{ cod_material, cod_biblioteca_destino, motivo (opcional) }`
- Backend valida: sem empréstimo activo no material, sem transferência já pendente/aprovada

### Aprovar / Rejeitar (Coordenador do destino)
- **PATCH** `/api/transferencias/:id_transferencia/aprovar`
- **PATCH** `/api/transferencias/:id_transferencia/rejeitar`
- Body para rejeitar: `{ motivo: "Material já existe em quantidade suficiente" }`

### Concluir transferência
- **PATCH** `/api/transferencias/:id_transferencia/concluir`
- Backend actualiza `MATERIAL_BIBLIOGRAFICO.cod_biblioteca` para destino

---

## 9. Módulo Eventos

### Listar eventos
- **GET** `/api/eventos?biblioteca=BIBMPM0001&status=Planeado&page=1&limit=20`

### Criar evento
- **POST** `/api/eventos`
- Body inclui dados do evento + horários:
```json
{
  "titulo_evento": "Clube de Leitura Infantil",
  "descricao_evento": "Sessão mensal de leitura partilhada",
  "local_evento": "Sala Principal",
  "publico_alvo": "Todos",
  "data_evento": "2025-07-05",
  "capacidade": 30,
  "recorrente": "N",
  "horarios": [
    { "dia_semana": "Sábado", "data_ocorrencia": "2025-07-05", "hora_inicio": "09:00", "hora_fim": "11:00" }
  ],
  "recursos": [
    { "nome_recurso": "Cadeiras", "quantidade": 30 }
  ]
}
```
- Backend valida RN07: hora_inicio e hora_fim dentro do horário da biblioteca

### Gerir participantes
- **POST** `/api/eventos/:id_evento/participantes` — inscrever leitor
- **DELETE** `/api/eventos/:id_evento/participantes/:num_cartao` — remover

### Atualizar status
- **PATCH** `/api/eventos/:id_evento/status`
- Body: `{ status_evento: "Cancelado" }`

---

## 10. Módulo Doações

### Listar doações
- **GET** `/api/doacoes?biblioteca=BIBMPM0001&page=1&limit=20`

### Criar doação
- **POST** `/api/doacoes`
- Body:
```json
{
  "id_doador": 5,
  "data_doacao": "2025-06-01",
  "itens": [
    { "cod_biblioteca": "BIBMPM0001", "quantidade": 10, "valor_estimado": 5000.00, "observacoes": "Livros infantis variados" }
  ]
}
```
- Para doação anónima: `id_doador: 0` (RN10)
- Trigger emite certificado automaticamente se valor ≥ 1.000 MT e doador Individual (RN08)

### Emitir certificado manualmente
- **POST** `/api/doacoes/:id_doacao/certificado`
- Body: `{ tipo_certificado: "Honorifico", observacoes: "..." }`

### Listar/criar doadores
- **GET** `/api/doadores?search=empresa`
- **POST** `/api/doadores` — criar novo doador

---

## 11. Módulo Programas de Alfabetização

### Listar programas
- **GET** `/api/programas?biblioteca=BIBMPM0001&estado=Activo`

### Criar programa
- **POST** `/api/programas`
- Body inclui dados do programa + níveis de progressão + materiais + funcionários

### Ver progresso
- **GET** `/api/programas/:cod_programa/participantes`
- Resposta: lista de participantes com nível actual, estado, datas

### Gerir participantes
- **POST** `/api/programas/:cod_programa/participantes` — inscrever leitor
- **PATCH** `/api/programas/:cod_programa/participantes/:num_cartao` — actualizar nível/estado

---

## 12. Módulo Funcionários

### Listar funcionários
- **GET** `/api/funcionarios?biblioteca=BIBMPM0001`
- Coordenador vê só da sua biblioteca. Administrador pode filtrar ou ver todos.

### Detalhe do funcionário
- **GET** `/api/funcionarios/:cod_funcionario`
- Inclui habilidades, horários, biblioteca

### Criar funcionário
- **POST** `/api/funcionarios`
- Backend gera `cod_funcionario` no formato `FUC20XXYYYY`
- Backend gera `email` no formato `nome.apelido@sabercomunitario.mz` (não editável depois)
- Body inclui dados base + `id_funcao` + habilidades + horários

### Editar funcionário
- **PATCH** `/api/funcionarios/:cod_funcionario`
- Campos editáveis por Coordenador: dados pessoais, habilidades, horários
- `email` e `nivel_acesso` nunca são editáveis por esta rota

### Alterar nível de acesso (só Administrador)
- **PATCH** `/api/funcionarios/:cod_funcionario/acesso`
- Body: `{ id_funcao: 2 }` (referencia `FUNCAO_FUNCIONARIO`)
- Backend regista em log de auditoria

### Eliminar funcionário (só Administrador)
- **DELETE** `/api/funcionarios/:cod_funcionario`
- Backend verifica: sem empréstimos em curso a seu cargo, sem eventos a seu cargo com status Planeado

---

## 13. Módulo Bibliotecas

### Listar bibliotecas da rede (só Administrador)
- **GET** `/api/bibliotecas`
- Inclui responsável actual e contagem de materiais/leitores por biblioteca

### Detalhe da biblioteca
- **GET** `/api/bibliotecas/:cod_biblioteca`
- Inclui horários, responsáveis (histórico), estatísticas básicas

### Criar biblioteca (só Administrador)
- **POST** `/api/bibliotecas`
- Backend gera `cod_biblioteca` no formato `BIBXXXYYYY`

### Editar biblioteca
- **PATCH** `/api/bibliotecas/:cod_biblioteca`
- Administrador edita tudo. Coordenador só edita infraestrutura e serviços da sua.

---

## 14. Módulo Suspensões e Multas

### Ver suspensões activas de um leitor
- **GET** `/api/leitores/:num_cartao/suspensoes`

### Reduzir suspensão (Coordenador ou Administrador — RN03.2)
- **PATCH** `/api/suspensoes/:id_suspensao/reduzir`
- Body: `{ nova_data_fim: "2025-06-20", observacoes: "Justificativa obrigatória aqui" }`
- Regista em log de auditoria

---

## 15. Comportamentos de UX que o Backend deve suportar

| Comportamento | Endpoint necessário |
|---|---|
| Ao digitar num cartão no form de empréstimo, mostrar dados do leitor e avisar se bloqueado | `GET /api/leitores/:num_cartao` (resposta rápida) |
| Ao seleccionar material no form de empréstimo, mostrar se disponível | `GET /api/materiais/:cod_material` (inclui flag `disponivel`) |
| Ao confirmar empréstimo, mostrar prazo calculado antes do submit | `POST /api/emprestimos/calcular-prazo` |
| Ao registar devolução, mostrar preview da multa antes de confirmar | `POST /api/emprestimos/preview-devolucao` — body: `{ id_emprestimo, estado_material_retorno }` |
| Ao alterar nível de acesso de um funcionário, mostrar o que ele vai poder fazer | Sem endpoint — o frontend mapeia localmente a partir da matriz de permissões |
| Dashboard actualiza em tempo real (ou próximo disso) | Backend pode suportar polling a cada 60s ou SSE opcional |

---

## 16. Respostas de Erro Padronizadas

O frontend espera este formato em todos os erros:

```json
{
  "erro": true,
  "codigo": "LEITOR_BLOQUEADO",
  "mensagem": "Este leitor está bloqueado e não pode efectuar empréstimos.",
  "detalhes": {}
}
```

Códigos importantes que o frontend vai tratar visualmente:

| Código | Situação |
|---|---|
| `EMPRESTIMO_ACTIVO` | Leitor já tem empréstimo activo (RN01) |
| `LEITOR_SUSPENSO` | Leitor suspenso (RN03.2) |
| `LEITOR_BLOQUEADO` | Leitor bloqueado (RN03.3) |
| `MATERIAL_INDISPONIVEL` | Material não pode ser emprestado |
| `MATERIAL_EM_TRANSFERENCIA` | Material tem transferência pendente/aprovada (RN06) |
| `FAIXA_ETARIA_INVALIDA` | Criança tentando pegar material não-infantil (RN04.1) |
| `SEM_PERMISSAO` | Nível de acesso insuficiente |
| `HORARIO_INVALIDO` | Evento fora do horário da biblioteca (RN07) |
| `AVISO_NIVEL_LEITURA` | Material acima do nível do leitor (RN04.2) — não bloqueia, só avisa |

---

## 17. Avatares — Funcionários e Leitores

A tabela `FUNCIONARIO` **não tem** coluna `foto_path`. Avatares de funcionários são **sempre** gerados com as iniciais do nome (2 letras), fundo `var(--theme-accent-light)`, cor `var(--theme-accent-text)`.

A tabela `LEITOR` tem `foto_path` (VARCHAR2 300, nullable) deixa preparado para receber,  mas **não é exibido na interface** por hora — leitores também usam avatar com iniciais que é o fallback.

Materiais não têm imagem.

**Regra absoluta: nenhuma entidade mostra foto na UI por hora. Todos os avatares são iniciais.**

---
