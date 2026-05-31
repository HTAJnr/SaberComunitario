# Regras de Negócio — Sistema de Gestão de Bibliotecas Comunitárias
**Versão 4.0** — Actualizado para BD Distribuída com Auditoria e Permissões Granulares

> **v4 — Alterações face à v3:**
> - `RN08 — Certificados de Doação`: actualizado para reflectir biblioteca beneficiada ao nível de `DOACAO` e campos obrigatórios de item (nome + tipo)
> - `RN12 — Registo de Auditoria`: nova regra — todas as operações críticas auditadas em `AUDITORIA_OPERACOES` via middleware de backend
> - `RN13 — Estado de Biblioteca`: nova regra — campo `ESTADO` controla activação/desactivação de bibliotecas na rede
> - `RN14 — Permissões Granulares por Cargo`: nova regra — cargos têm matriz de permissões por módulo/acção em `PERMISSAO_CARGO`

---

## RN01 — Limite de Empréstimo por Leitor

**Descrição:** Cada leitor, independentemente da categoria, só pode ter **1 material em empréstimo activo** em simultâneo.

**Contagem:** Empréstimo activo = `data_devolucao IS NULL`.

**Validação:** Antes de registar novo empréstimo, verificar se o leitor já possui empréstimo activo. Se sim, rejeitar.

**Condição de bloqueio adicional:** Leitores com `status_leitor != 'Activo'` não podem efectuar empréstimos independentemente do limite.

**Implementação:** Trigger `trg_valida_limite_emprestimos` — `BEFORE INSERT ON EMPRESTIMO`.

---

## RN02 — Prazos de Devolução

**Descrição:** O prazo de devolução é calculado com base na distância do leitor à biblioteca, em privilégios docentes, e no histórico de pontualidade.

**Fórmula:**
```
prazo_devolucao = data_retirada
               + 14 dias (base)
               + FLOOR(distancia_biblioteca / 10) dias (ajuste geográfico)
               + 7 dias (se Professor)
               - ajuste_pontualidade (se histórico negativo)
```

**Ajuste por histórico de pontualidade (`historico_pontualidade`):**

| Valor | Ajuste ao prazo |
|---|---|
| `'Pontual'` | Nenhum (0 dias) |
| `'Irregular'` | −3 dias |
| `'Mau'` | −5 dias |

> O prazo mínimo resultante nunca pode ser inferior a 7 dias, independentemente dos ajustes.

**Exemplos:**
- Adulto a 35 km, `'Pontual'` → 14 + 3 + 0 = **17 dias**
- Professor a 35 km, `'Pontual'` → 14 + 3 + 7 = **24 dias**
- Adulto a 35 km, `'Mau'` → 14 + 3 − 5 = **12 dias**
- Professor a 35 km, `'Mau'` → 14 + 3 + 7 − 5 = **19 dias**

**Fonte dos dados:**
- `LEITOR.distancia_biblioteca` (NUMBER 6,2 — km)
- `LEITOR.historico_pontualidade` (VARCHAR2 10)

**Implementação:** Cálculo no backend ao criar empréstimo. O prazo calculado é passado directamente no INSERT — não é trigger.

---

## RN03 — Multas, Suspensões e Bloqueios por Atraso

**Descrição:** Sistema progressivo de penalizações activado automaticamente no momento da devolução ou por monitorização diária de empréstimos vencidos.

---

### 3.1 — Multas por Atraso

Calculadas com base nos dias de atraso (`data_devolucao − prazo_devolucao` quando positivo, ou `SYSDATE − prazo_devolucao` para empréstimos ainda não devolvidos).

| Categoria | Taxa diária | Excepção |
|---|---|---|
| Adulto | 15 MT/dia | — |
| Criança | 5 MT/dia | — |
| Professor | 0 MT (1ª infracção — só advertência) | A partir da 2.ª: 10 MT/dia |

**Contagem de infracções de Professor:**
```sql
SELECT COUNT(*) FROM EMPRESTIMO e
JOIN PROFESSOR p ON e.num_cartao = p.num_cartao
WHERE e.data_devolucao > e.prazo_devolucao
  AND e.data_devolucao IS NOT NULL;
```

> Isento a 1 suspensão, porém, muda o `historico_pontualidade` do professor para `'Irregular'`

---

### 3.2 — Suspensão Automática por Atraso

**Regra:** Cada atraso gera uma suspensão automática com duração proporcional ao número de dias em falta, aplicada após a devolução do material.

| Dias de atraso | Dias de suspensão |
|---|---|
| 1 – 7 | 7 |
| 8 – 15 | 15 |
| 16 – 30 | 30 |
| 31 – 60 | 60 |
| > 60 | **BLOQUEIO** (ver 3.3) |

**Comportamento durante suspensão:**
- `status_leitor = 'Suspenso'`
- Novos empréstimos bloqueados (RN01)
- Suspensão levanta automaticamente após decorridos os dias definidos
- Data de fim de suspensão deve ser registada (campo `data_fim_suspensao` ou calculada via trigger com base em `SYSDATE + dias_suspensao`)

**Alteração manual:** Um funcionário com nível de acesso `'Coordenador'` ou superior pode reduzir ou remover dias de suspensão, com justificativa obrigatória registada em campo de observações. A alteração fica em log de auditoria (RN12).

**Actualização do histórico de pontualidade:**

| Situação acumulada | Valor resultante |
|---|---|
| Sem atrasos registados | `'Pontual'` |
| 1 a 2 atrasos com suspensão cumprida e multa paga | `'Irregular'` |
| 3 ou mais atrasos, ou multa por pagar, ou bloqueio | `'Mau'` |

> O `historico_pontualidade` é recalculado automaticamente após cada devolução com atraso.

---

### 3.3 — Bloqueio Permanente

**Condição de activação:** Atraso superior a 60 dias sem devolução do material — o leitor é considerado desaparecido e o material perdido.

**Consequências imediatas:**
- `status_leitor = 'Bloqueado'`
- `estado_material_conservacao = 'Perdido'`
- Cobrança automática conforme RN05 (material perdido: 150% do `valor_estimado` + 50 MT taxa administrativa)
- Notificação automática ao funcionário responsável da biblioteca (`id_responsavel`)

**Natureza do bloqueio:**
- Permanente — não existe reversão automática
- Leitor bloqueado não pode criar nova conta (controlo físico via fotografia no registo)
- Empréstimos, inscrições em eventos e programas ficam bloqueados

**Saída do estado Bloqueado:** Não prevista no sistema — requer intervenção manual de `'Administrador'` com justificativa documentada + pagamento conforme RN05 (caso excecional).

---

## RN04 — Restrições por Faixa Etária e Recomendação por Literacia

### 4.1 — Restrição por Faixa Etária (Crianças)

**Descrição:** Crianças só podem emprestar materiais adequados à sua faixa etária.

| Leitor | Faixas permitidas |
|---|---|
| Criança | `'Infantil'`, `'Todas as Idades'` |
| Adulto / Professor | Sem restrição |

**Validação:** Verificar `CATEGORIA.faixa_etaria` do material antes de aprovar empréstimo para `CRIANCA`. Se faixa não permitida, rejeitar com mensagem.

**Implementação:** Trigger `trg_valida_emprestimo_categoria` — `BEFORE INSERT ON EMPRESTIMO`.

---

### 4.2 — Recomendação por Nível de Literacia (Adultos)

**Descrição:** O sistema recomenda materiais compatíveis com o `nivel_literacia` do adulto, mas não bloqueia o empréstimo. O leitor pode pedir qualquer material independentemente do seu nível.

**Correspondência de compatibilidade (informativa):**

| `ADULTO.nivel_literacia` | `CATEGORIA.nivel_leitura` compatível |
|---|---|
| `'Basico'` | `'Basico'` |
| `'Funcional'` | `'Basico'`, `'Intermedio'` |
| `'Avancado'` | Todos |

**Comportamento:** Quando o material solicitado está acima do nível do leitor, o sistema regista um aviso informativo — não rejeita. O funcionário pode usar esta informação para orientar o leitor.

**Implementação:** Lógica no backend — não é trigger. Retorna flag `aviso_nivel_leitura = TRUE` na resposta da operação de empréstimo quando há incompatibilidade.

---

## RN05 — Material Danificado, Destruído ou Perdido

**Descrição:** Penalizações aplicadas no momento da devolução conforme o estado do material devolvido. O funcionário avalia o estado no acto da devolução e regista em `estado_material_retorno`.

| Cenário | Condição | Penalização adicional | Estado resultante em MATERIAL_BIBLIOGRAFICO |
|---|---|---|---|
| Bom | `estado_material_retorno = 'Bom'` | Nenhuma (só multa por atraso, se existir) | Estado inalterado |
| Degradado | `estado_material_retorno = 'Degradado'` | +20% do `valor_estimado` | `estado_material_conservacao = 'Degradado'` |
| Destruído | `estado_material_retorno = 'Destruido'` | +150% do `valor_estimado` + 50 MT taxa administrativa | `estado_material_conservacao = 'Indisponivel'`, `motivo_indisponibilidade = 'Destruído'` |
| Perdido | `estado_material_retorno = 'Perdido'` OU atraso > 60 dias | +150% do `valor_estimado` + 50 MT taxa administrativa | `estado_material_conservacao = 'Indisponivel'`, `motivo_indisponibilidade = 'Perdido em empréstimo'` |

**Distinção entre Degradado e Destruído:**
- `'Degradado'` — dano parcial: capa arrancada, página ilegível, escrita sobre o texto. Material ainda utilizável e **pode continuar a ser emprestado**.
- `'Destruído'` — dano total ou estrutural: todas as folhas separadas, livro desmontado, inutilizável. Material **não pode ser emprestado** — sai de circulação com o mesmo tratamento económico de um material perdido.
- A distinção é feita pelo funcionário no acto da devolução. Se houver dúvida entre Degradado e Destruído, aplica-se o critério: **pode ainda ser lido na íntegra?** Se sim → Degradado. Se não → Destruído.

**Disponibilidade para empréstimo por estado de conservação:**

| `estado_material_conservacao` | Pode ser emprestado? |
|---|---|
| `'Bom'` | Sim |
| `'Degradado'` | Sim |
| `'Indisponivel'` | Não — filtrado em todas as queries de catálogo |

**Rastreabilidade:** Comparar `estado_material_saida` com `estado_material_retorno` para identificar danos ocorridos durante o empréstimo específico.

**Novo exemplar:** Se a biblioteca adquirir outro exemplar do mesmo título, entra como novo registo em `MATERIAL_BIBLIOGRAFICO` com `cod_material` próprio. O exemplar `'Indisponivel'` permanece na BD como registo histórico — nunca é eliminado nem reutilizado.

**Implementação:** Trigger `trg_atualiza_estado_material` — `BEFORE UPDATE ON EMPRESTIMO`.

---

## RN06 — Transferências Inter-Bibliotecas

**Descrição:** Movimentação de materiais entre bibliotecas com fluxo de aprovação obrigatório.

**Estados e fluxo:**
```
Pendente → Aprovada → Concluida
         ↘ Rejeitada
```

| Estado | Quem activa | Campos preenchidos |
|---|---|---|
| `Pendente` | Coordenador da origem | `id_funcionario_solicitante`, `data_solicitacao` |
| `Aprovada` | Coordenador do destino | `id_funcionario_aprovador`, `data_aprovacao_destino` |
| `Rejeitada` | Coordenador do destino | `motivo` (obrigatório) |
| `Concluida` | Sistema após transporte | `data_conclusao` + `MATERIAL_BIBLIOGRAFICO.id_biblioteca` actualizado |

**Restrições:**
- Material com empréstimo activo não pode ser transferido
- Material com transferência `'Pendente'` ou `'Aprovada'` não pode ser emprestado
- `id_biblioteca_origem <> id_biblioteca_destino` (CHECK na tabela)
- Só `'Coordenador'` pode solicitar ou aprovar transferências

**Implementação:** Triggers `trg_protege_material_transferencia` e `trg_valida_transferencia`.

---

## RN07 — Eventos Recorrentes

**Descrição:** Suporte a eventos únicos e recorrentes com gestão diferenciada.

| Tipo | `recorrente` | Horário | Participações |
|---|---|---|---|
| Único | `'N'` | Uma entrada em `HORARIO_EV_BIB` | Vinculadas à ocorrência única |
| Recorrente | `'S'` | Múltiplas entradas com datas distintas | Novas inscrições por ocorrência |

**Validação de horário:** O evento só pode ocorrer dentro do horário de funcionamento da biblioteca — `hora_inicio >= hora_abertura` e `hora_fim <= hora_fecho`.

**Implementação:** Trigger `trg_valida_horario_evento` — `BEFORE INSERT ON HORARIO_EV_BIB`.

---

## RN08 — Certificados de Doação e Registo de Doações *(actualizado em v4)*

**Descrição:** Emissão automática ou manual de certificados conforme valor e tipo de doador. Uma doação destina-se sempre a uma única biblioteca beneficiada; os itens doados têm nome e tipo obrigatórios.

### 8.1 — Biblioteca Beneficiada

**Regra:** O campo `DOACAO.cod_biblioteca` identifica a biblioteca que recebe a totalidade da doação. Uma doação não pode ser dividida entre bibliotecas diferentes — se o doador quiser beneficiar duas bibliotecas, são registadas duas doações separadas.

**Validação:** `DOACAO.cod_biblioteca` é NOT NULL — obrigatório no INSERT. O backend valida que a biblioteca existe e está com `estado = 'Activo'` (RN13).

### 8.2 — Itens da Doação

**Regra:** Cada item deve ter `nome_item` (descrição do que foi doado) e `tipo_item` (classificação).

| Campo | Tipo | Valores permitidos |
|---|---|---|
| `nome_item` | VARCHAR2(200) | NOT NULL. Ex: `'Dom Casmurro'`, `'Tablet Samsung'`, `'500 MT'` |
| `tipo_item` | VARCHAR2(20) | `'Livro'`, `'Dinheiro'`, `'Recurso'`, `'Outro'` |

**Validação:** Backend retorna 400 se `tipo_item` não for um dos valores permitidos. CHECK constraint reforça na BD.

### 8.3 — Emissão de Certificados

| Tipo | Condição | Emissão |
|---|---|---|
| Individual | Valor total ≥ 1.000 MT + doador `'Individual'` | Automática após registo |
| Anual | Doador `'Institucional'` — agregação anual | Manual ou batch fim de ano |
| Honorífico | Contribuições excepcionais | Manual por Coordenador |

**Formato do número:** `CERT-[ANO]-[SEQUENCIAL]` (ex: `CERT-2025-0001`)

**Rastreabilidade:** Múltiplos certificados podem referenciar a mesma doação (original + reemissões). `original_numero` guarda a referência em reemissões.

**Implementação:** Trigger `trg_gera_certificado_automatico` — `AFTER INSERT ON DOACAO` (casos automáticos). Interface manual (backend) para honoríficos.

---

## RN09 — E-books em Suportes Físicos

**Descrição:** E-books em contexto moçambicano frequentemente existem em suportes físicos (CD/PEN).

| Formato | `url_acesso` | `tamanho_arquivo` | Tratamento |
|---|---|---|---|
| `'PDF'`, `'EPUB'`, `'MOBI'` | Obrigatório | Obrigatório | Digital — acesso remoto |
| `'CD'`, `'PEN'` | NULL | Nullable | Físico — empréstimo convencional |

**CHECK:** `formato NOT IN ('PDF','EPUB','MOBI') OR url_acesso IS NOT NULL`

**Implementação:** CHECK constraint na tabela `EBOOK`.

---

## RN10 — Doações Anónimas

**Descrição:** Doações sem identificação do doador referenciam registo especial permanente.

**Registo especial em `DOADOR`:**
```
id_doador    = 0
nome_doador  = 'Anonimo'
tipo_doador  = 'Individual'
contacto     = NULL
endereco     = NULL
```

**Restrição:** `id_doador = 0` nunca pode ser eliminado.

**Implementação:** INSERT manual no script de dados iniciais. Trigger `trg_protege_doador_anonimo` — `BEFORE DELETE ON DOADOR`.

---

## RN11 — Contactos Partilhados

**Descrição:** Crianças podem partilhar contacto com o responsável adulto leitor.

**Regra:** `LEITOR.contacto` não tem constraint UNIQUE — permite o mesmo número em registos distintos.

**Implementação:** Ausência intencional de UNIQUE constraint em `LEITOR.contacto`.

---

## RN12 — Registo de Auditoria *(nova em v4)*

**Descrição:** Todas as operações críticas executadas via backend devem ser registadas em `AUDITORIA_OPERACOES`. A auditoria não pode bloquear a operação principal — falhas no registo de auditoria são apenas logadas na consola do servidor.

### 12.1 — Operações Sujeitas a Auditoria

| Módulo | Operações auditadas |
|---|---|
| **Funcionários** | Criar, editar, eliminar, alterar permissões/cargo |
| **Leitores** | Criar, editar, eliminar, suspender, remover suspensão |
| **Empréstimos** | Criar empréstimo, devolver, eliminar |
| **Eventos** | Criar, editar, cancelar |
| **Doações** | Registar doação, emitir certificado |
| **Autenticação** | Login com sucesso, login com falha (motivo registado) |

### 12.2 — Campos Obrigatórios no Registo de Auditoria

| Campo | Preenchimento |
|---|---|
| `cod_funcionario` | Funcionário que executou a operação (`req.session.cod_funcionario`) |
| `operacao` | Código da operação. Ex: `'CRIAR_LEITOR'`, `'LOGIN_FALHA'` |
| `objeto_afetado` | Identificador do registo afectado. Ex: `num_cartao`, `cod_funcionario` |
| `resultado` | `'SUCESSO'` ou `'FALHA'` |
| `motivo_falha` | Preenchido apenas em `resultado = 'FALHA'`. Ex: mensagem de erro Oracle |
| `nos_afetados` | Nós da rede afectados pela operação. Ex: `'NACIONAL'`, `'EmprestimosDB'` |

### 12.3 — Implementação

**Middleware:** `backend/middleware/auditoria.js` — função `registar(conn, { cod_func, operacao, objeto, resultado, motivo, nos })` chamada dentro do mesmo `conn` antes do `commit`.

**Autonomia:** O INSERT em `AUDITORIA_OPERACOES` usa `PRAGMA AUTONOMOUS_TRANSACTION` na BD — garante persistência mesmo em caso de ROLLBACK da transacção principal.

**Falha silenciosa:** Se `registar()` lançar excepção, o erro é capturado com `console.warn` e a operação principal prossegue normalmente — a auditoria nunca bloqueia o negócio.

### 12.4 — Restrições de Acesso

- Apenas `'Administrador'` pode ler os registos de auditoria via interface
- Nenhum utilizador pode alterar ou eliminar registos de `AUDITORIA_OPERACOES`
- O registo de auditoria de login inclui tentativas falhadas com o motivo da falha

---

## RN13 — Estado de Biblioteca *(nova em v4)*

**Descrição:** O campo `BIBLIOTECA.estado` controla a activação/desactivação de uma biblioteca na rede distribuída.

### 13.1 — Valores e Semântica

| Estado | Significado | Efeitos no sistema |
|---|---|---|
| `'Activo'` | Biblioteca operacional | Aceita novos leitores, empréstimos, eventos, doações e transferências |
| `'Inactivo'` | Biblioteca desactivada | Bloqueada para novas operações (ver 13.2) |

### 13.2 — Restrições para Biblioteca Inactiva

Uma biblioteca com `estado = 'Inactivo'` não pode:
- Ser seleccionada como destino em novas transferências
- Receber novas doações (`DOACAO.cod_biblioteca`)
- Ter novos leitores registados
- Ter novos eventos criados

Registos históricos (empréstimos, transferências, doações, eventos) existentes numa biblioteca inactiva são preservados — apenas operações **novas** são bloqueadas.

### 13.3 — Quem pode alterar o estado

- Apenas funcionários com `nivel_acesso = 'Administrador'` podem activar ou desactivar uma biblioteca
- A alteração fica registada em `AUDITORIA_OPERACOES` com `operacao = 'ALTERAR_ESTADO_BIBLIOTECA'` (RN12)

### 13.4 — Implementação

- CHECK constraint `chk_bib_estado` na tabela `BIBLIOTECA`: `CHECK (estado IN ('Activo','Inactivo'))`
- DEFAULT `'Activo'` — todas as bibliotecas criadas ficam activas por omissão
- O backend valida `estado = 'Activo'` antes de aceitar operações que requerem biblioteca activa

---

## RN14 — Permissões Granulares por Cargo *(nova em v4)*

**Descrição:** Para além do `nivel_acesso` herdado de `FUNCAO_FUNCIONARIO`, é possível definir uma matriz de permissões por cargo a nível de módulo e acção, armazenada em `PERMISSAO_CARGO`.

### 14.1 — Estrutura da Matriz

Cada linha de `PERMISSAO_CARGO` define se um cargo tem (ou não tem) permissão para executar uma `accao` num `modulo`:

| `modulo` | `accao` | Exemplos de operações cobertas |
|---|---|---|
| `leitores` | `ver`, `criar`, `editar`, `eliminar`, `alterar_status` | Gestão de leitores |
| `emprestimos` | `ver`, `criar`, `devolver`, `eliminar` | Empréstimos e devoluções |
| `materiais` | `ver`, `criar`, `editar`, `eliminar` | Catálogo de materiais |
| `transferencias` | `ver`, `solicitar`, `aprovar` | Transferências inter-bibliotecas |
| `eventos` | `ver`, `criar`, `editar`, `cancelar`, `gerir_participantes` | Gestão de eventos |
| `doacoes` | `ver`, `registar`, `emitir_certificado` | Doações e certificados |
| `programas` | `ver`, `criar`, `editar`, `gerir_participantes` | Programas de alfabetização |
| `funcionarios` | `ver`, `criar`, `editar`, `eliminar` | Gestão de funcionários |
| `permissoes` | `ver`, `gerir` | Cargos e permissões |
| `bibliotecas` | `ver`, `editar`, `alterar_estado` | Gestão de bibliotecas |
| `auditoria` | `ver` | Registos de auditoria |

### 14.2 — Semântica do Campo `permitido`

| Valor | Significado |
|---|---|
| `1` | Permissão concedida para este par (módulo, acção) |
| `0` | Permissão explicitamente revogada (útil para auditoria e overrides) |
| *(ausência de linha)* | Sem permissão — equivalente a `0` |

### 14.3 — Precedência

O `nivel_acesso` de `FUNCAO_FUNCIONARIO` define o nível base. A tabela `PERMISSAO_CARGO` permite refinamento por cargo:
- Um `'Coordenador'` pode ter `transferencias.aprovar = 0` se a biblioteca não realiza transferências
- Um `'Bibliotecario'` pode ter `doacoes.registar = 1` se o cargo específico incluir essa responsabilidade

O backend verifica ambas as fontes: `nivel_acesso` (via middleware `exigirNivel`) e `PERMISSAO_CARGO` (via query adicional para operações que suportam controlo granular).

### 14.4 — Gestão

- Apenas `'Administrador'` pode criar/editar cargos e gerir a matriz de permissões
- A operação `PUT /api/permissoes/cargos/:id/matriz` substitui toda a matriz do cargo atomicamente
- Cada alteração à matriz fica registada em `AUDITORIA_OPERACOES` com `operacao = 'MODIFICAR_MATRIZ_PERMISSOES'` (RN12)

### 14.5 — Implementação

- Tabela: `PERMISSAO_CARGO` com UNIQUE em `(id_funcao, modulo, accao)` — evita duplicados
- Sequência: `SEQ_PERMISSAO`
- Backend: endpoints em `backend/routes/permissoes.js`
  - `GET /api/permissoes/cargos` — lista cargos
  - `POST /api/permissoes/cargos` — criar cargo
  - `PATCH /api/permissoes/cargos/:id` — editar cargo
  - `DELETE /api/permissoes/cargos/:id` — eliminar (só se sem funcionários associados)
  - `GET /api/permissoes/cargos/:id/matriz` — ler matriz
  - `PUT /api/permissoes/cargos/:id/matriz` — substituir matriz

---

## Resumo de Triggers

| Trigger | Evento | Tabela | Regra |
|---|---|---|---|
| `trg_valida_limite_emprestimos` | BEFORE INSERT | EMPRESTIMO | RN01 |
| `trg_valida_status_leitor` | BEFORE INSERT | EMPRESTIMO | RN01 / RN03 |
| `trg_calcula_multa_atraso` | BEFORE UPDATE | EMPRESTIMO | RN03.1 |
| `trg_aplica_suspensao` | BEFORE UPDATE | EMPRESTIMO | RN03.2 |
| `trg_aplica_bloqueio` | BEFORE UPDATE / job diário | EMPRESTIMO / LEITOR | RN03.3 |
| `trg_atualiza_historico_pontualidade` | AFTER UPDATE | EMPRESTIMO | RN03.2 |
| `trg_valida_emprestimo_categoria` | BEFORE INSERT | EMPRESTIMO | RN04.1 |
| `trg_atualiza_estado_material` | BEFORE UPDATE | EMPRESTIMO | RN05 — cobre Degradado, Destruído e Perdido |
| `trg_protege_material_transferencia` | BEFORE INSERT | TRANSFERENCIA | RN06 |
| `trg_valida_transferencia` | BEFORE INSERT/UPDATE | TRANSFERENCIA | RN06 |
| `trg_valida_horario_evento` | BEFORE INSERT | HORARIO_EV_BIB | RN07 |
| `trg_gera_certificado_automatico` | AFTER INSERT | DOACAO | RN08.3 |
| `trg_protege_doador_anonimo` | BEFORE DELETE | DOADOR | RN10 |
