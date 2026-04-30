---
created: 2025-09-27 10:54
tags:
  - ISCTEM
---
## RN01 - Limites de Empréstimo por Categoria de Leitor

**Descrição:** O sistema impõe limites diferenciados de materiais que podem ser emprestados simultaneamente, baseado na categoria do leitor.

**Especificação:**

- **Adulto:** Máximo 3 materiais em simultâneo
- **Criança:** Máximo 2 materiais em simultâneo
- **Professor:** Máximo 5 materiais em simultâneo

**Contagem:** Considera-se empréstimo ativo quando a data de devolução ainda não foi registada (campo `data_devolucao` nulo).

**Validação:** Antes de registar novo empréstimo, o sistema verifica se o limite da categoria será excedido.

**Implementação:** Trigger `valida_limite_emprestimos` (Fase 3).

---

## RN02 - Prazos de Devolução Flexíveis

**Descrição:** O sistema calcula prazos de devolução considerando distância geográfica do leitor e privilégios académicos.

**Cálculo do Prazo:**

1. **Base:** 14 dias a partir da data de retirada
    
2. **Ajuste Geográfico:** Adiciona-se 1 dia por cada 10 quilómetros de distância entre a localização do leitor e a biblioteca
    
    - Distância calculada a partir dos campos `Leitor.localizacao_leitor` e `Biblioteca.localizacao`
3. **Privilégio Docente:** Professores recebem 7 dias adicionais além do prazo calculado
    

**Fórmula Final:**

```
prazo_devolucao = data_retirada + 14 dias + PISO(distancia_km / 10) dias + (7 dias se Professor)
```

**Exemplo:** Adulto a 35km da biblioteca = 14 + 3 = 17 dias  
**Exemplo:** Professor a 35km da biblioteca = 14 + 3 + 7 = 24 dias

**Implementação:** Cálculo na aplicação (Fase 4) ao criar empréstimo.

---

## RN03 - Multas por Atraso

**Descrição:** O sistema aplica multas diferenciadas por categoria de leitor quando a devolução excede o prazo estabelecido.

**Taxas Diárias:**

- **Adulto:** 15MT por dia de atraso
- **Criança:** 5MT por dia de atraso
- **Professor:**
    - 1ª infração: Apenas advertência (multa = 0MT), registada em observações
    - 2ª infração em diante: 10MT por dia de atraso

**Cálculo de numero de infrações:**

```sql
data_devolucao > prazo_devolucao -- Atrasados 
AND data_devolucao < :data_atual; -- Anteriores a agora
```

**Consequências Automáticas:**

1. **Atraso > 30 dias:**
    
    - Suspensão automática de novos empréstimos
    - Bloqueio mantido até regularização (devolução + pagamento multa)
2. **Atraso > 60 dias:**
    
    - Material considerado perdido automaticamente
    - Estado do material alterado para `Indisponível`
    - Cobrança especial aplicada (ver RN05)

**Implementação:** Trigger `calcula_multa_atraso` (Fase 3).

---

## RN04 - Restrições por Faixa Etária

**Descrição:** O sistema restringe empréstimos de materiais baseado na adequação etária para proteger crianças.

**Regra Específica:**

- **Crianças** apenas podem emprestar materiais classificados como:
    - Faixa etária: `Infantil`
    - Faixa etária: `Todas as Idades`
- **Adultos e Professores:** Sem restrições de faixa etária
    

**Validação:** Sistema verifica a categoria temática do material solicitado antes de aprovar empréstimo para leitores da subclasse Criança.

**Implementação:** Trigger `valida_emprestimo_categoria` (Fase 3).

---

## RN05 - Material Danificado ou Perdido

**Descrição:** O sistema aplica penalizações quando materiais são devolvidos com danos ou não são devolvidos.

**Cenários e Penalizações:**

### Caso 1: Material Degradado

- **Situação:** `estado_material_retorno = 'Degradado'`
- **Penalização:** Multa adicional de 20% do valor estimado do material
- **Ação no Sistema:** Estado de conservação do material atualizado para `Degradado`

### Caso 2: Material Perdido

- **Situação:** `estado_material_retorno = 'Perdido'` OU atraso superior a 60 dias
- **Penalização:**
    - 150% do valor estimado do material (valor de reposição)
    - Multa acumulada por atraso (se aplicável)
    - Taxa administrativa adicional de 50MT
- **Ação no Sistema:** Estado de conservação do material atualizado para `Indisponível`

### Caso 3: Material em Bom Estado

- **Situação:** `estado_material_retorno = 'Bom'`
- **Penalização:** Nenhuma (apenas multa por atraso, se existir)
- **Ação no Sistema:** Estado de conservação mantido inalterado

**Rastreabilidade:** O sistema compara `estado_material_saida` (na retirada) com `estado_material_retorno` (na devolução) para identificar danos ocorridos durante o período de empréstimo específico.

**Implementação:** Trigger `atualiza_estado_material` (Fase 3).

---

## RN06 - Transferências Inter-Bibliotecas

**Descrição:** O sistema permite movimentação de materiais entre bibliotecas da rede com controlo por coordenadores e rastreamento de estados.

**Estados da Transferência:**

1. **Pendente:** Solicitação criada pelo coordenador da biblioteca origem
2. **Aprovada:** Coordenador da biblioteca destino autorizou a transferência
3. **Rejeitada:** Coordenador da biblioteca destino recusou (motivo obrigatório)
4. **Concluída:** Transporte físico realizado, localização do material atualizada

**Fluxo Obrigatório:**

1. Funcionário com função `Coordenador` na Biblioteca A cria transferência
    
    - Estado inicial: `Pendente`
    - Campo `id_funcionario_solicitante` preenchido
    - Campo `data_solicitacao` registado
2. Funcionário com função `Coordenador` na Biblioteca B analisa solicitação
    
    - **Se aprovar:** Estado altera para `Aprovada`, campos `id_funcionario_aprovador` e `data_aprovacao_destino` preenchidos
    - **Se rejeitar:** Estado altera para `Rejeitada`, campo `motivo` obrigatório
3. Após transporte físico (apenas se aprovada):
    
    - Estado altera para `Concluída`
    - Campo `data_conclusao` registado
    - Campo `Material_Bibliografico.id_biblioteca` atualizado para biblioteca destino

**Restrições de Segurança:**

- Material com empréstimo ativo (devolução pendente) não pode ser transferido
- Material com transferência nos estados `Pendente` ou `Aprovada` não pode ser emprestado
- Biblioteca origem deve ser diferente da biblioteca destino
- Apenas funcionários com função `Coordenador` podem solicitar ou aprovar transferências

**Implementação:** Triggers `protege_material_transferencia` e `valida_transferencia_origem_destino` (Fase 3).

---

## RN07 - Eventos Recorrentes

**Descrição:** O sistema suporta eventos únicos e recorrentes com gestão diferenciada de horários e participações.

**Tipos de Evento:**

### Evento Único (`recorrente = 'N'`)

- Data de realização específica e única
- Horário registado uma única vez na entidade `Horario_Ev_Bib`
- Participações vinculadas àquela ocorrência específica

### Evento Recorrente (`recorrente = 'S'`)

- Permite múltiplas datas de realização (ex: hora do conto toda segunda-feira)
- Múltiplas entradas em `Horario_Ev_Bib` com datas distintas
- Cada ocorrência (data diferente) gera novas inscrições independentes em `Participacao_Evento`

**Validação de Horário:**

Eventos (únicos ou recorrentes) só podem ocorrer dentro do horário de funcionamento da biblioteca organizadora:

- Horário do evento deve estar entre `Horario_Ev_Bib.hora_abertura` e `Horario_Ev_Bib.hora_fecho` da biblioteca
- Sistema verifica compatibilidade antes de registar horário do evento

**Implementação:** Trigger `valida_horario_evento` (Fase 3).

---

## RN08 - Certificados de Doação

**Descrição:** O sistema emite certificados de agradecimento automaticamente ou manualmente conforme valor e tipo de doador, mantendo reconhecimento formal das contribuições.

**Tipos de Certificado:**

### Individual (Automático)

- **Condição:** Doação com valor total igual ou superior a 1000MT
- **Tipo de Doador:** Individual
- **Emissão:** Automática após registo da doação
- **Formato:** Número único no formato `CERT-[ANO]-[SEQUENCIAL]` (ex: CERT-2025-0001)

### Anual (Manual/Batch)

- **Condição:** Agregação de todas as doações de um doador institucional no ano
- **Tipo de Doador:** Institucional
- **Emissão:** Processo manual ou automático no fim do ano fiscal
- **Conteúdo:** Soma total das contribuições do período

### Honorífico (Manual)

- **Condição:** Contribuições excepcionais ou continuadas
- **Emissão:** Manual por coordenador
- **Finalidade:** Reconhecimento especial de benfeitores com impacto significativo

**Rastreabilidade:**

- Cada certificado possui número único no sistema
- Sistema mantém histórico completo de emissões
- Permite reemissão (ex: certificado perdido) sem perder referência à doação original
- Múltiplos certificados podem referenciar a mesma doação (original + reemissões)

**Implementação:** Trigger `gera_certificado_automatico` (Fase 3) para casos automáticos; interface manual (Fase 4) para honoríficos.

---

## RN09 - E-books em Suportes Físicos

**Descrição:** O sistema reconhece que e-books em contexto moçambicano de baixa literacia frequentemente existem em suportes físicos (CD/pen), não como ficheiros digitais remotos.

**Categorização de E-books:**

### E-books Físicos (`formato IN ('CD', 'PEN')`)

- **Tratamento:** Idêntico a livros físicos
- **Empréstimo:** Segue todas as regras convencionais (prazos, multas, limites)
- **Campos Específicos:**
    - `url_acesso`: NULL (não há acesso digital remoto)
    - `tamanho_arquivo`: NULL ou tamanho do ficheiro no suporte
- **Localização:** Rastreada via biblioteca associada, como material tangível

### E-books Digitais (`formato IN ('PDF', 'EPUB', 'MOBI')`)

- **Contexto:** Raros em zonas de baixa literacia, previsão para crescimento futuro
- **Tratamento:** Potencial acesso remoto via URL
- **Campos Específicos:**
    - `url_acesso`: Obrigatório (link para acesso)
    - `tamanho_arquivo`: Tamanho do ficheiro digital
- **Empréstimo:** Pode significar "licença de acesso temporário"

**Justificativa:** A especialização `Ebook` mantém-se na hierarquia `Material_Bibliografico` para escalabilidade futura, mesmo que implementação atual seja predominantemente física.

**Implementação:** Regra aplicada em lógica de negócio da aplicação (Fase 4).

---

## RN10 - Doações Anónimas

**Descrição:** O sistema aceita doações sem identificação do doador mantendo integridade referencial através de registo padrão.

**Solução Técnica:**

O sistema mantém permanentemente um registo especial na entidade `DOADOR`:

- `id_doador = 0`
- `nome_doador = 'Anónimo'`
- `tipo_doador = 'Individual'`
- `contacto = NULL`
- `endereco = NULL`

**Utilização:**

Quando doação não possui identificação do contribuinte, o campo `Doacao.id_doador` referencia o registo padrão (id = 0).

**Vantagens:**

- Elimina necessidade de valores NULL em chave estrangeira
- Mantém integridade referencial em todas as doações
- Permite rastreamento estatístico de doações anónimas como categoria
- Preserva simplicidade do modelo sem casos especiais

**Restrição:** O registo `id_doador = 0` não pode ser eliminado do sistema.

---
## **RN11 - Contactos Partilhados**

**Descrição:** O sistema permite que leitores da mesma família, isto é, crianças com pais leitores compartilhem o mesmo contacto, reconhecendo que crianças podem não possuir um numero próprio.

**Cenários Válidos:**

- Crianças cujo `telefone_responsavel` corresponde ao `contacto` de outro leitor adulto

**Restrição:** O atributo `LEITOR.contacto` **não possui** constraint UNIQUE.
