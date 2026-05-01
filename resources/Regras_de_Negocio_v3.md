# Regras de Negócio — Sistema de Gestão de Bibliotecas Comunitárias
**Versão 2.0** — Actualizado para BD Distribuída

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

> Isento a 1 suspensão, porém, muda o `historico_pontualidade` do professor para `'Irregular'

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

**Alteração manual:** Um funcionário com nível de acesso `'Coordenador'` ou superior pode reduzir ou remover dias de suspensão, com justificativa obrigatória registada em campo de observações. A alteração fica em log de auditoria.

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

## RN08 — Certificados de Doação

**Descrição:** Emissão automática ou manual de certificados conforme valor e tipo de doador.

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
| `trg_gera_certificado_automatico` | AFTER INSERT | DOACAO | RN08 |
| `trg_protege_doador_anonimo` | BEFORE DELETE | DOADOR | RN10 |
