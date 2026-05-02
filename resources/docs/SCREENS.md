# SCREENS.md — Saber Comunitário

## Mapa Completo de Telas, Campos e Permissões

---

## Estrutura de Permissões

Cada funcionário tem um `nivel_acesso` vindo de `FUNCAO_FUNCIONARIO.nivel_acesso`:  
`'Administrador'` | `'Coordenador'` | `'Bibliotecario'` | `'Assistente'`

**Matriz de acesso por módulo:**

| Módulo                            | Admin | Coord | Biblio | Assist |
| --------------------------------- | ----- | ----- | ------ | ------ |
| Dashboard (rede)                  | ✓     | —     | —      | —      |
| Dashboard (biblioteca)            | ✓     | ✓     | ✓      | ✓      |
| Leitores — ver lista              | ✓     | ✓     | ✓      | ✓      |
| Leitores — cadastrar              | ✓     | ✓     | ✓      | ✓      |
| Leitores — editar                 | ✓     | ✓     | ✓      | —      |
| Leitores — eliminar               | ✓     | —     | —      | —      |
| Leitores — alterar status         | ✓     | ✓     | —      | —      |
| Empréstimos — ver                 | ✓     | ✓     | ✓      | ✓      |
| Empréstimos — criar               | ✓     | ✓     | ✓      | ✓      |
| Empréstimos — devolver            | ✓     | ✓     | ✓      | ✓      |
| Empréstimos — eliminar            | ✓     | —     | —      | —      |
| Multas — marcar paga              | ✓     | ✓     | ✓      | —      |
| Materiais — ver                   | ✓     | ✓     | ✓      | ✓      |
| Materiais — adicionar             | ✓     | ✓     | ✓      | —      |
| Materiais — editar                | ✓     | ✓     | ✓      | —      |
| Materiais — eliminar              | ✓     | ✓     | —      | —      |
| Transferências — ver              | ✓     | ✓     | —      | —      |
| Transferências — solicitar        | ✓     | ✓     | —      | —      |
| Transferências — aprovar/rejeitar | ✓     | ✓     | —      | —      |
| Eventos — ver                     | ✓     | ✓     | ✓      | ✓      |
| Eventos — criar/editar            | ✓     | ✓     | ✓      | —      |
| Eventos — cancelar                | ✓     | ✓     | —      | —      |
| Eventos — gerir participantes     | ✓     | ✓     | ✓      | ✓      |
| Doações — ver                     | ✓     | ✓     | ✓      | —      |
| Doações — registar                | ✓     | ✓     | —      | —      |
| Certificados — emitir             | ✓     | ✓     | —      | —      |
| Programas — ver                   | ✓     | ✓     | ✓      | ✓      |
| Programas — criar/editar          | ✓     | ✓     | —      | —      |
| Programas — gerir participantes   | ✓     | ✓     | ✓      | —      |
| Funcionários — ver                | ✓     | ✓     | —      | —      |
| Funcionários — cadastrar/editar   | ✓     | ✓     | —      | —      |
| Funcionários — eliminar           | ✓     | —     | —      | —      |
| Permissões — ver/gerir            | ✓     | —     | —      | —      |
| Bibliotecas (rede)                | ✓     | —     | —      | —      |
| Biblioteca (própria)              | ✓     | ✓     | —      | —      |
| Suspensões — reduzir              | ✓     | ✓     | —      | —      |

---

## TELA 00 — Login

**Já feito**

**Rota:** `/login`  
**Acesso:** Público (não autenticado)

**Elementos:**

- Logo centrado (grande, 80px)
- Nome da app + subtítulo
- Campo: `email` (VARCHAR2 100)
- Campo: `senha` (input type=password)
- Botão "Entrar"
- Sem registo público — só Admin cria contas

**Comportamento pós-login:**

1. Backend devolve: `{ cod_funcionario, nome_funcionario, nivel_acesso, cod_biblioteca, provincia, nome_biblioteca }`
2. Determinar região com base em `provincia` → aplicar CSS class `theme-sul` / `theme-centro` / `theme-norte`
3. Redirecionar para `/dashboard`

---

## TELA 01 — Dashboard

**Já feito**

**Rota:** `/dashboard`  
**Acesso:** Todos os roles

### Vista Coordenador / Bibliotecário / Assistente

**Topbar:** "Dashboard" + "Bib. [nome] — [provincia]"

**Secção 1 — Stat cards (grid 4 colunas):**

| Card                     | Dado                                                                                | Alerta          |
| ------------------------ | ----------------------------------------------------------------------------------- | --------------- |
| Empréstimos activos      | COUNT EMPRESTIMO WHERE data_devolucao IS NULL                                       | —               |
| Em atraso                | COUNT onde SYSDATE > prazo_devolucao e não devolvido                                | vermelho se > 0 |
| Materiais disponíveis    | COUNT MATERIAL_BIBLIOGRAFICO WHERE estado != 'Indisponivel' e sem empréstimo activo | —               |
| Transferências pendentes | COUNT TRANSFERENCIA WHERE estado = 'Pendente'                                       | laranja se > 0  |

Assistente vê apenas os 2 primeiros cards.

**Secção 2 — Linha dupla:**

- Painel esquerdo: "Devoluções previstas hoje" — lista até 5 empréstimos com `prazo_devolucao = HOJE`, colunas: avatar iniciais leitor, nome, título material, badge (Pontual / Hoje / +N dias)
- Painel direito: "Empréstimos por dia" — gráfico de barras simples, últimos 7 dias

Assistente: só vê painel esquerdo (lista de devoluções).

**Secção 3 — Linha dupla (só Coord/Biblio):**

- Painel esquerdo: tabela "Leitores recentes" — últimos 5 registados: num_cartao (mono), nome, badge tipo, badge status
- Painel direito: lista "Transferências" — últimas 3: direcção (↗ enviada / ↙ recebida), título material, biblioteca, badge estado

### Vista Administrador

**Topbar:** "Dashboard — Rede Nacional"

**Secção 1 — Stat cards (grid 4 colunas):**

- Total de bibliotecas activas na rede
- Total de empréstimos activos na rede
- Total de transferências pendentes
- Total de materiais em circulação

**Secção 2 — Tabela de bibliotecas:**
Colunas: `cod_biblioteca` (mono), nome, província, região (badge Sul/Centro/Norte), empréstimos activos, estado nó (online/offline — simulado)

**Secção 3 — Actividade recente da rede:**
Feed cronológico de eventos: nova biblioteca adicionada, transferências concluídas, etc.

---

## TELA 02 — Leitores

**Rota:** `/leitores`  
**Acesso:** Todos os roles (acções variam)

### 02-A Lista de Leitores

**Topbar:** "Leitores" + "Bib. [nome]"

**Barra de acções:**

- Input de pesquisa: por `nome_completo` ou `num_cartao`
- Filtro dropdown: Status (`Activo` / `Suspenso` / `Bloqueado` / Todos)
- Filtro dropdown: Tipo (`Adulto` / `Professor` / `Criança` / Todos)
- Filtro dropdown: Histórico (`Pontual` / `Irregular` / `Mau` / Todos)
- Botão "+ Cadastrar Leitor" → abre wizard 02-B (visível para todos os roles)

**Tabela:**

| Coluna       | Campo                    | Notas                           |
| ------------ | ------------------------ | ------------------------------- |
| Cartão       | `num_cartao`             | monospace, muted                |
| Nome         | `nome_completo`          | —                               |
| Tipo         | subtabela                | badge Adulto/Professor/Criança  |
| Pontualidade | `historico_pontualidade` | badge verde/laranja/vermelho    |
| Status       | `status_leitor`          | badge Activo/Suspenso/Bloqueado |
| Acções       | —                        | botão "..." com menu contextual |

**Menu contextual por row (botão "..."):**

- "Ver perfil" → abre drawer 02-C (todos)
- "Editar" → abre modal 02-D (Coord, Biblio, Admin)
- "Alterar status" → abre modal 02-E (Coord, Admin)
- "Ver suspensões" → abre modal 02-F (Coord, Admin)
- "Eliminar" → modal de confirmação → DELETE (só Admin)

---

### 02-B Wizard — Cadastrar Leitor

**3 steps:**

**Step 1 — Dados Base** (tabela `LEITOR`):

- `nome_completo` (text, obrigatório)
- `data_nasc` (date, obrigatório)
- `genero` (select: Masculino / Feminino, obrigatório)
- `nivel_escolar` (text: ex. "Primário Completo")
- `localizacao_leitor` (textarea)
- `contacto` (text)
- `distancia_biblioteca` (number, em km — usado no cálculo do prazo RN02)
- `cod_biblioteca` preenchido automaticamente com a biblioteca do funcionário logado

**Step 2 — Tipo de Leitor:**

Radio: `Adulto` | `Professor` | `Criança`

Se **Adulto** (`ADULTO` + `ADULTO_INTERESSE`):

- `profissao` (text)
- `nivel_literacia` (select: Básico / Funcional / Avançado)
- `interesses` (chips adicionáveis — lista de strings para `ADULTO_INTERESSE`)

Se **Professor** (herda Adulto + `PROFESSOR` + `PROFESSOR_DISCIPLINA`):

- Todos os campos de Adulto acima
- `escola_instituto` (text)
- `nivel_ensino` (select: Primário / Secundário / Técnico / Universitário)
- `num_alunos` (number)
- `disciplinas` (chips adicionáveis — lista para `PROFESSOR_DISCIPLINA`)

Se **Criança** (`CRIANCA`):

- `nome_responsavel` (text, obrigatório)
- `telefone_responsavel` (text)
- `escola_frequenta` (text)
- `classe` (text: ex. "5ª Classe")

**Step 3 — Confirmação:**

- Resumo dos dados inseridos
- `num_cartao` gerado automaticamente pelo backend (formato: 3 letras biblioteca + ano + sequencial)
- Botão "Confirmar registo"

---

### 02-C Drawer — Perfil do Leitor

Drawer lateral (380px) com tabs:

**Tab "Perfil":**

- Avatar com iniciais (2 letras do nome)
- `num_cartao` (mono, grande)
- Nome completo, tipo, status (badge), pontualidade (badge)
- Dados base: contacto, localização, distância, escolaridade
- Dados específicos do subtipo (profissão/literacia/interesses OU escola/classe/responsável OU escola/disciplinas)

**Tab "Empréstimo Activo":**

- Se existe: card com título material, data retirada, prazo devolução, dias restantes (verde) ou dias em atraso (vermelho)
- Se não existe: empty state "Nenhum empréstimo activo"

**Tab "Histórico":**

- Tabela de empréstimos passados: material, data retirada, data devolução, atraso (dias), multa (MT), paga (S/N)

**Tab "Suspensões":**

- Lista de suspensões com: data início, data fim, dias, estado (Activa/Cumprida/Reduzida), origem (ID empréstimo)
- Suspensão activa destacada com fundo laranja claro

**Tab "Multas em Aberto":**

- Lista de empréstimos com `multa_valor > 0` e `multa_paga = 'N'`
- Total em MT no rodapé
- Botão "Marcar como paga" por linha (Coord, Biblio, Admin)

---

### 02-D Modal — Editar Leitor

Campos editáveis do step 1 + step 2 do wizard. Pré-preenchidos.  
`num_cartao` não é editável (apresentado como texto readonly).  
Acesso: Coord, Biblio, Admin.

---

### 02-E Modal — Alterar Status

Apresenta status actual e dropdown para novo status:  
`Activo` | `Suspenso` | `Bloqueado`

Campo obrigatório: `observacoes` (justificativa textual)  
Aviso a vermelho se tentar activar um leitor com suspensão ainda activa.  
Acesso: Coord, Admin.

---

### 02-F Modal — Suspensões (gestão)

Lista de suspensões do leitor. Por cada suspensão `Activa`:

- Botão "Reduzir dias" → input number (novo número de dias, mínimo 1) + campo `observacoes` obrigatório
- Botão "Remover suspensão" → confirmação + `observacoes` obrigatório
  Acesso: Coord, Admin.

---

## TELA 03 — Empréstimos

**Rota:** `/emprestimos`  
**Acesso:** Todos os roles

### 03-A Lista de Empréstimos

**Tabs:** `Activos` | `Vencidos` | `Devolvidos` | `Todos`

**Filtros:** pesquisa por nome leitor ou título material; filtro por data

**Tabela:**

| Coluna   | Campo             | Notas                                                |
| -------- | ----------------- | ---------------------------------------------------- |
| ID       | `id_emprestimo`   | mono, muted                                          |
| Leitor   | `nome_completo`   | —                                                    |
| Material | `titulo`          | —                                                    |
| Retirada | `data_retirada`   | dd/mm/aaaa                                           |
| Prazo    | `prazo_devolucao` | badge verde/laranja/vermelho conforme dias restantes |
| Estado   | calculado         | badge Activo / Vencido / Devolvido                   |
| Multa    | `multa_valor`     | só mostra se > 0                                     |
| Acções   | —                 | botão "..."                                          |

**Menu contextual:**

- "Ver detalhe" → drawer 03-B (todos)
- "Registar devolução" → modal 03-C (todos — só para activos)
- "Marcar multa paga" → confirmação (Coord, Biblio, Admin — só se multa_paga = 'N')
- "Eliminar" → modal confirmação (só Admin — só empréstimos não iniciados)

**Botão "+ Novo Empréstimo"** → wizard 03-D (todos os roles)

---

### 03-B Drawer — Detalhe do Empréstimo

- Dados do empréstimo: leitor (com link para perfil), material, funcionário que registou
- Datas: retirada, prazo, devolução (se devolvido)
- Estado do material na saída e no retorno
- Multa: valor, paga (S/N), data pagamento
- Suspensão gerada (se existir): link para suspensão

---

### 03-C Modal — Registar Devolução

**Apresenta:**

- Card leitor: nome, num_cartao
- Card material: título, cod_material, estado na saída
- Dias de atraso calculados (se > 0, destacado a vermelho)

**Campos:**

- `estado_material_retorno` (select obrigatório: Bom / Degradado / Destruído / Perdido)
- `observacoes_devolucao` (textarea, opcional)

**Preview dinâmico de multa** (actualiza ao mudar o estado):

- Multa por atraso: N dias × taxa (15 MT adulto, 5 MT criança, 0/10 MT professor)
- Penalização por estado: +20% valor_estimado se Degradado; +150% + 50 MT se Destruído/Perdido
- Total em MT

**Aviso especial** se `estado = 'Destruido'` ou `'Perdido'`: "Material será marcado como Indisponível no catálogo."  
**Aviso especial** se atraso > 60 dias: "Leitor será bloqueado automaticamente (RN03.3)."

Botão "Confirmar Devolução".

---

### 03-D Wizard — Novo Empréstimo

**Step 1 — Seleccionar Leitor:**

- Pesquisa por `num_cartao` ou `nome_completo`
- Card com dados do leitor ao seleccionar:
  - Nome, tipo, status (badge)
  - Pontualidade, distância (para info do prazo)
  - **Bloqueio imediato** se `status_leitor != 'Activo'`: mensagem de erro, não pode avançar
  - **Aviso** se já tem empréstimo activo (RN01): não pode avançar

**Step 2 — Seleccionar Material:**

- Pesquisa por `titulo`, `autor`, `cod_material`
- Só mostra materiais com `estado_material_conservacao != 'Indisponivel'` e sem empréstimo activo e sem transferência pendente/aprovada
- Card com dados do material ao seleccionar:
  - Título, autor, tipo (Livro/Ebook/Periódico), estado conservação (badge)
  - `localizacao_estante` (onde ir buscar fisicamente)
  - **Aviso de nível de leitura** se material acima do nível do leitor adulto (RN04.2) — não bloqueia

**Step 3 — Confirmar:**

- `estado_material_saida` (select: Bom / Degradado) — estado verificado no momento
- Prazo calculado automaticamente e apresentado:
  ```
  14 dias (base)
  + X dias (distância: floor(distancia/10))
  + 7 dias (professor)    ← só se for professor
  − N dias (pontualidade) ← 0/−3/−5 conforme histórico
  = PRAZO: DD/MM/AAAA (mínimo 7 dias garantido)
  ```
- Botão "Confirmar Empréstimo"

---

## TELA 04 — Materiais

**Rota:** `/materiais`  
**Acesso:** Todos os roles (acções variam)

### 04-A Lista de Materiais

**Filtros:** pesquisa por título/autor/ISBN; tipo (Livro/Ebook/Periódico); estado; disponibilidade; categoria

**Tabela:**

| Coluna     | Campo                         | Notas                            |
| ---------- | ----------------------------- | -------------------------------- |
| Código     | `cod_material`                | mono, muted                      |
| Título     | `titulo`                      | —                                |
| Autor      | `autor`                       | —                                |
| Tipo       | subtabela                     | badge Livro/Ebook/Periódico      |
| Categoria  | `area_tematica`               | muted                            |
| Estado     | `estado_material_conservacao` | badge Bom/Degradado/Indisponível |
| Disponível | calculado                     | badge Sim/Não                    |
| Acções     | —                             | botão "..."                      |

**Menu contextual:**

- "Ver detalhe" → drawer 04-B (todos)
- "Editar" → modal 04-C (Coord, Biblio, Admin)
- "Eliminar" → confirmação (Coord, Admin — só se sem empréstimo activo e sem transferência activa)

**Botão "+ Adicionar Material"** → wizard 04-D (Coord, Biblio, Admin)

---

### 04-B Drawer — Detalhe do Material

**Tab "Informação":**

- Todos os campos de `MATERIAL_BIBLIOGRAFICO`
- Campos específicos do subtipo (Ebook: formato, URL, tamanho; Periódico: edição, periodicidade, ISSN; Livro: sem campos extra)
- Categoria: área temática, faixa etária, nível leitura
- Origem: Comprado/Doado/Transferido — se Doado, link para doação; se Transferido, link para transferência

**Tab "Histórico de Empréstimos":**

- Tabela: leitor, data retirada, data devolução, atraso, multa, estado retorno

**Tab "Transferências":**

- Lista de transferências deste material com origem, destino, data, estado

---

### 04-C Modal — Editar Material

Campos editáveis: `titulo`, `autor`, `editora`, `ano_publicacao`, `ISBN`, `idioma`, `num_paginas`, `localizacao_estante`, `cod_categoria`, `estado_material_conservacao` (com `motivo_indisponibilidade` se Indisponível).  
Campos de subtipo editáveis conforme tipo.

---

### 04-D Wizard — Adicionar Material

**Step 1 — Dados Base:**

- `titulo` (obrigatório)
- `autor`
- `editora`
- `ano_publicacao`
- `ISBN`
- `idioma`
- `num_paginas`
- `cod_categoria` (select com área temática + faixa etária + nível leitura)
- `localizacao_estante`
- `valor_aquisicao`
- `data_aquisicao`

**Step 2 — Tipo:**

Radio: `Livro Físico` | `Ebook` | `Periódico`

Se **Ebook:**

- `formato` (select: PDF / EPUB / MOBI / CD / PEN)
- `url_acesso` (obrigatório se formato digital)
- `tamanho_arquivo`

Se **Periódico:**

- `edicao`
- `periodicidade` (select: Mensal / Trimestral / Anual)
- `data_publicacao`
- `ISSN`

**Step 3 — Origem:**

Radio: `Comprado` | `Doado` | `Transferido`

Se **Doado:** seleccionar doação existente (`id_doacao`) e item (`id_itemDoado`)  
Se **Transferido:** referência à transferência  
Se **Comprado:** sem campos adicionais

---

## TELA 05 — Transferências

**Rota:** `/transferencias`  
**Acesso:** Admin, Coord

### 05-A Lista de Transferências

**Tabs:** `Enviadas` | `Recebidas` | `Todas`

**Tabela:**

| Coluna      | Campo                  | Notas                                       |
| ----------- | ---------------------- | ------------------------------------------- |
| ID          | `id_transferencia`     | mono                                        |
| Material    | `titulo`               | —                                           |
| Origem      | `nome_biblioteca`      | biblioteca de origem                        |
| Destino     | `nome_biblioteca`      | biblioteca de destino                       |
| Solicitante | `nome_funcionario`     | —                                           |
| Data        | `data_solicitacao`     | —                                           |
| Estado      | `estado_transferencia` | badge Pendente/Aprovada/Rejeitada/Concluída |
| Acções      | —                      | —                                           |

**Acções por row:**

- "Ver detalhe" → drawer com todos os campos, histórico de datas, aprovador, motivo (se rejeitada)
- "Aprovar" → confirmação simples (Coord do destino, Admin) — só estado Pendente
- "Rejeitar" → modal com campo `motivo` obrigatório (Coord do destino, Admin) — só estado Pendente
- "Marcar concluída" → confirmação (Admin, Coord) — só estado Aprovada

**Botão "+ Solicitar Transferência"** → modal 05-B

---

### 05-B Modal — Solicitar Transferência

- Pesquisa e selecção de material (da biblioteca do utilizador logado)
  - Valida: sem empréstimo activo, sem transferência pendente/aprovada
- Selecção de biblioteca destino (dropdown com todas as bibliotecas excepto a própria)
- Campo `motivo` (texto — justificativa da transferência)
- Botão "Solicitar"

---

## TELA 06 — Eventos

**Rota:** `/eventos`  
**Acesso:** Todos os roles (acções variam)

### 06-A Lista de Eventos

**Toggle vista:** Lista | Calendário (simples, mostra dias com eventos marcados)

**Tabela/Cards:**

| Campo           | Notas                              |
| --------------- | ---------------------------------- |
| `titulo_evento` | —                                  |
| `data_evento`   | dd/mm/aaaa                         |
| `local_evento`  | —                                  |
| `publico_alvo`  | badge                              |
| `capacidade`    | X / Y inscritos                    |
| `status_evento` | badge Planeado/Realizado/Cancelado |
| `recorrente`    | ícone se S                         |

**Acções:**

- "Ver detalhe" → drawer 06-B (todos)
- "Editar" → modal (Coord, Biblio, Admin) — só Planeado
- "Cancelar" → confirmação (Coord, Admin) — só Planeado
- "Marcar realizado" → confirmação (Coord, Biblio, Admin)

**Botão "+ Novo Evento"** → modal 06-C (Coord, Biblio, Admin)

---

### 06-B Drawer — Detalhe do Evento

**Tab "Info":** todos os campos, funcionário responsável, recursos (`EVENTO_RECURSO`)

**Tab "Horários":** lista de `HORARIO_EVENTO` — dia, data ocorrência, hora início, hora fim

**Tab "Participantes":**

- Lista de `PARTICIPACAO_EVENTO`: leitor (nome, cartão), data inscrição, presença confirmada (S/N)
- Botão "+ Inscrever Leitor" → pesquisa por nome/cartão (todos os roles)
- Botão "Remover" por linha (Coord, Biblio, Admin, Assist)
- Botão toggle "Confirmar presença" (Coord, Biblio)

**Tab "Avaliações":**

- Lista de `AVALIACAO_EVENTO`: leitor, nota (estrelas 1–5), comentário, data

---

### 06-C Modal — Criar Evento

- `titulo_evento` (obrigatório)
- `descricao_evento` (textarea)
- `local_evento` (obrigatório)
- `publico_alvo` (select: Iniciantes / Intermédios / Avançados / Todos)
- `data_evento`
- `capacidade`
- `recorrente` (radio: Único / Recorrente)
- `cod_funcionario_responsavel` (select — só Coord/Admin; Biblio é atribuído automaticamente)
- **Horários** (secção dinâmica — `HORARIO_EVENTO`):
  - Botão "+ Adicionar horário"
  - Por cada horário: dia da semana, data ocorrência, hora início, hora fim
  - Validação contra horário da biblioteca (RN07)
- **Recursos** (secção dinâmica — `EVENTO_RECURSO`):
  - Botão "+ Adicionar recurso"
  - Por cada recurso: nome, quantidade

---

## TELA 07 — Doações

**Rota:** `/doacoes`  
**Acesso:** Admin, Coord, Biblio (só ver)

### 07-A Lista de Doações

**Tabela:**

| Campo       | Notas                          |
| ----------- | ------------------------------ |
| ID          | `id_doacao` mono               |
| Doador      | `nome_doador` (ou "Anónimo")   |
| Tipo doador | badge Individual/Institucional |
| Data        | `data_doacao`                  |
| Itens       | COUNT de `ITEM_DOACAO`         |
| Valor total | SUM `valor_estimado` em MT     |
| Certificado | Emitido / Pendente / N/A       |

**Acções:**

- "Ver detalhe" → drawer 07-B
- "Emitir certificado" → modal 07-C (Coord, Admin)

**Botão "+ Registar Doação"** → wizard 07-D (Coord, Admin)

---

### 07-B Drawer — Detalhe da Doação

- Dados do doador (com link para histórico do doador)
- Lista de itens: `ITEM_DOACAO` — quantidade, valor estimado, observações, biblioteca destino
- Certificados emitidos: número, tipo, data, reemissão (se aplicável)

---

### 07-C Modal — Emitir Certificado

- `tipo_certificado` (select: Original / Reemissão / Honorífico)
- `observacoes` (textarea)
- Se Reemissão: campo `original_numero` (número do certificado original)
- Número gerado automaticamente: `CERT-{ANO}-{SEQUENCIAL}`
- Botão "Emitir"

---

### 07-D Wizard — Registar Doação

**Step 1 — Doador:**

- Toggle: "Doador identificado" | "Anónimo"
- Se identificado: pesquisar doador existente ou criar novo
  - `nome_doador`, `tipo_doador` (Individual/Institucional), `contacto`, `endereco`, `observacoes`
- Se anónimo: usa `id_doador = 0` automaticamente

**Step 2 — Itens:**

- Botão "+ Adicionar item"
- Por cada item: `quantidade`, `valor_estimado` (MT), `observacoes`, `cod_biblioteca` (destino)
- Total estimado calculado dinamicamente

**Step 3 — Confirmar:**

- Resumo
- Nota: se doador Individual e total ≥ 1.000 MT → certificado emitido automaticamente

---

## TELA 08 — Programas de Alfabetização

**Rota:** `/programas`  
**Acesso:** Todos os roles (acções variam)

### 08-A Lista de Programas

**Tabela:**

| Campo         | Notas                           |
| ------------- | ------------------------------- |
| Código        | `cod_programa` mono             |
| Nome          | `nome_programa`                 |
| Público-alvo  | badge                           |
| Duração       | `duracao_semanas` semanas       |
| Participantes | COUNT activos                   |
| Estado        | badge Activo/Concluído/Suspenso |

**Acções:**

- "Ver detalhe" → drawer 08-B (todos)
- "Editar" → modal (Coord, Admin)
- "Encerrar / Suspender" (Coord, Admin)

**Botão "+ Novo Programa"** → modal 08-C (Coord, Admin)

---

### 08-B Drawer — Detalhe do Programa

**Tab "Info":** todos os campos do programa, metodologia, resultados esperados

**Tab "Níveis":** lista de `NIVEL_PROGRESSAO` em ordem — nome, descrição

**Tab "Participantes":**

- Tabela: leitor (nome, cartão), data inscrição, nível actual, estado (Activo/Concluído/Desistiu)
- Botão "+ Inscrever Leitor" (Coord, Biblio, Admin)
- Botão "Actualizar nível" por linha (Coord, Admin)
- Botão "Marcar como concluído/desistiu" (Coord, Admin)

**Tab "Materiais":** lista de `PROGRAMA_MATERIAL` — título, autor, estado

**Tab "Funcionários":** lista de `PROGRAMA_FUNCIONARIO` — nome, papel (Responsável/Instrutor/Auxiliar)

---

### 08-C Modal — Criar Programa

- `nome_programa` (obrigatório)
- `descricao` (textarea)
- `publico_alvo` (select)
- `duracao_semanas` (number)
- `metodologia` (textarea)
- `resultados_esperados` (textarea)
- **Níveis de progressão** (dinâmico): botão "+ Adicionar nível" — por cada nível: `nome_nivel`, `descricao`, `ordem`
- **Materiais** (dinâmico): pesquisa e adição de materiais bibliográficos
- **Funcionários** (dinâmico): pesquisa e adição com `papel`

---

## TELA 09 — Funcionários

**Rota:** `/funcionarios`  
**Acesso:** Admin, Coord

### 09-A Lista de Funcionários

**Tabela:**

| Campo           | Notas                                     |
| --------------- | ----------------------------------------- |
| Avatar          | foto ou iniciais                          |
| Código          | `cod_funcionario` mono                    |
| Nome            | `nome_funcionario`                        |
| Função          | `nome_funcao`                             |
| Nível de Acesso | badge por cor                             |
| Biblioteca      | `nome_biblioteca`                         |
| Estado          | Activo (data_demissao IS NULL) / Inactivo |

**Acções:**

- "Ver perfil" → drawer 09-B
- "Editar" → modal 09-C (Coord para sua bib, Admin global)
- "Gerir permissões" → modal 09-D (só Admin)
- "Eliminar / Desactivar" → confirmação (só Admin)

**Botão "+ Cadastrar Funcionário"** → wizard 09-E

---

### 09-B Drawer — Perfil do Funcionário

- Avatar (foto se existir, iniciais como fallback)
- `cod_funcionario` (mono), nome, função, nível acesso (badge)
- Dados pessoais: género, data nasc, contacto, endereço
- Dados profissionais: formação, experiência, data contratação
- Habilidades: chips de `FUNCIONARIO_HABILIDADE`
- Horário: tabela de `HORARIO_FUNCIONARIO` por dia
- Bibliotecas que já foi responsável: `BIBLIOTECA_RESPONSAVEL`

---

### 09-C Modal — Editar Funcionário

Campos editáveis: todos excepto `cod_funcionario`, `email` (readonly) e `senha`.  
Habilidades: chips adicionáveis/removíveis.  
Horário: linhas adicionáveis por dia.

---

### 09-D Modal — Gerir Permissões

**Só Administrador.**

Apresenta:

- Funcionário seleccionado (nome, foto/avatar, função actual)
- Dropdown: `nivel_acesso` (Administrador / Coordenador / Bibliotecário / Assistente)
- Painel de preview: o que este nível pode fazer — tabela com as acções e checkmarks (baseada na matriz de permissões do topo deste ficheiro)

Ao mudar o dropdown, o painel de preview actualiza em tempo real.

Botão "Guardar permissão".

---

### 09-E Wizard — Cadastrar Funcionário

**Step 1 — Dados Pessoais:**

- `nome_funcionario` (obrigatório)
- `genero` (select)
- `data_nasc`
- `contacto`
- `endereco`
- `email` (obrigatório, UNIQUE — será o login)
- `senha` (input password — hash SHA-256 no backend)
- Foto de perfil (upload opcional — guardada em `/uploads/funcionarios/{cod_funcionario}.jpg`)

**Step 2 — Dados Profissionais:**

- `formacao`
- `experiencia`
- `data_contratacao` (obrigatório)
- `id_funcao` (select: Administrador / Coordenador / Bibliotecário / Assistente)
- `cod_biblioteca` (select — Coord só pode atribuir à sua bib; Admin pode atribuir a qualquer)
- Habilidades: chips adicionáveis
- Horário semanal: linhas por dia (dia, hora entrada, hora saída)

**Step 3 — Confirmar:**

- Resumo
- `cod_funcionario` gerado automaticamente pelo backend

---

## TELA 10 — Permissões

**Rota:** `/permissoes`  
**Acesso:** só Admin

Tabela de todos os funcionários com `nivel_acesso` actual.  
Botão de edição rápida por linha → abre o mesmo modal 09-D.

Apresenta também a matriz de permissões completa do sistema como referência visual (tabela de acções × roles com checkmarks).

---

## TELA 11 — Biblioteca

**Rota:** `/biblioteca` (Coord — a sua própria)  
**Rota:** `/bibliotecas` (Admin — lista da rede)

### 11-A Vista Admin — Rede de Bibliotecas

**Tabela:**

| Campo       | Notas                                |
| ----------- | ------------------------------------ |
| Código      | `cod_biblioteca` mono                |
| Nome        | `nome_biblioteca`                    |
| Província   | —                                    |
| Região      | badge Sul/Centro/Norte               |
| Capacidade  | —                                    |
| Responsável | nome do responsável Principal actual |
| Estado nó   | Online/Offline (simulado)            |

**Acções:**

- "Ver detalhe" → drawer com todos os dados da biblioteca, horários, responsáveis históricos
- "Editar" → modal com campos da biblioteca
- "Adicionar à rede" → wizard com dados completos + horários + responsável inicial
- "Desactivar" → confirmação (só se sem materiais e sem empréstimos activos)

### 11-B Vista Coord — A Minha Biblioteca

Card com todos os dados da própria biblioteca.  
Secções: informação geral, horários de funcionamento, responsáveis (actual + histórico), infraestrutura, serviços.  
Botão "Editar" → modal com campos editáveis (infraestrutura, serviços, contacto, horários).  
Não pode alterar `cod_biblioteca`, `provincia`, `nome_biblioteca` (esses só Admin).

---

## Navegação e Redireccionamento por Role

| Rota              | Admin    | Coord   | Biblio     | Assist  |
| ----------------- | -------- | ------- | ---------- | ------- |
| `/dashboard`      | ✓ (rede) | ✓ (bib) | ✓ (bib)    | ✓ (bib) |
| `/leitores`       | ✓        | ✓       | ✓          | ✓       |
| `/emprestimos`    | ✓        | ✓       | ✓          | ✓       |
| `/materiais`      | ✓        | ✓       | ✓          | ✓       |
| `/transferencias` | ✓        | ✓       | 403        | 403     |
| `/eventos`        | ✓        | ✓       | ✓          | ✓       |
| `/doacoes`        | ✓        | ✓       | ✓ (só ver) | 403     |
| `/programas`      | ✓        | ✓       | ✓          | ✓       |
| `/funcionarios`   | ✓        | ✓       | 403        | 403     |
| `/permissoes`     | ✓        | 403     | 403        | 403     |
| `/biblioteca`     | ✓        | ✓       | 403        | 403     |
| `/bibliotecas`    | ✓        | 403     | 403        | 403     |

Rota 403 → redirecionar para `/dashboard` com toast de "Acesso não autorizado".
