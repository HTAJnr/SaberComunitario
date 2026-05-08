# Gerson — Nó EventosBibliotecasDB
### Sistema de Gestão de Bibliotecas Comunitárias Distribuído
**Ambiente:** Oracle 10g XE, CentOS 6.8, SQL*Plus
**Referências obrigatórias:** DD v3, Regras de Negócio v3 (RN07), Guia BD2 Tema 8

---

## O teu nó no sistema

O EventosBibliotecasDB gere a infraestrutura física do sistema — as bibliotecas onde tudo acontece — e a programação cultural — os eventos que essas bibliotecas realizam.

Este nó é o ponto de entrada para o registo de qualquer biblioteca nova no sistema. Sem uma biblioteca registada aqui, não podem existir materiais, leitores nem funcionários associados a ela nos outros nós. É também o nó que fornece ao BibliotecaNacionalDB a informação de horários e programação para análise nacional, e ao MateriaisDB a lista de bibliotecas para o planeamento de eventos temáticos.

---

## Fase 1 — Estrutura local do nó

### 1.1 — Tabelas do teu domínio

As tabelas que pertencem ao EventosBibliotecasDB são as seguintes, todas definidas no DD v3:
- `BIBLIOTECA`
- `HORARIO_BIBLIOTECA`
- `BIBLIOTECA_RESPONSAVEL`
- `FUNCIONARIO`
- `FUNCAO_FUNCIONARIO`
- `HORARIO_FUNCIONARIO`
- `FUNCIONARIO_HABILIDADE`
- `EVENTO`
- `HORARIO_EV_BIB`
- `PARTICIPACAO_EVENTO`
- `AVALIACAO_EVENTO`
- `EVENTO_RECURSO`

**O que fazer:**
Cria todas estas tabelas no teu schema (`usr_eventosdb`), usando a tablespace de dados e a tablespace de índices criadas na Fase Comum. Consulta o DD v3 para os tipos, tamanhos e constraints exactos. Presta atenção especial às constraints de CHECK: `EVENTO` tem valores controlados em `status_evento`; `AVALIACAO_EVENTO` tem um CHECK em `nota`; `FUNCAO_FUNCIONARIO` tem CHECKs tanto em `nome_funcao` como em `nivel_acesso` — consulta o DD v3 para os valores exactos.

Depois de criar cada tabela, verifica no dicionário de dados do Oracle que foi criada na tablespace correcta. Regista esse output no relatório.

Cria índices nas colunas mais consultadas. Pensa: quais são as pesquisas mais frequentes em eventos e bibliotecas? Por biblioteca? Por status do evento? Por funcionário? Justifica cada índice no relatório.

**O que registar no relatório:**
- Output da query ao dicionário de dados confirmando cada tabela na tablespace correcta
- Lista de índices criados com justificação de cada um

---

### 1.2 — A decisão de fragmentação e porquê

**O problema:**
O sistema tem múltiplas bibliotecas em diferentes localidades. Cada biblioteca realiza os seus próprios eventos — os eventos da Biblioteca de Nampula não têm relevância operacional diária para a Biblioteca de Maputo. Guardar todos os eventos num único bloco indistinto significa que qualquer consulta local percorre dados irrelevantes. Para além disso, faz sentido que os dados de uma entidade estejam no mesmo lugar que os dados das entidades de que dependem.

**A fragmentação que implementas:**
Fragmentação derivada de `EVENTO` com base na relação com `BIBLIOTECA`. Cada fragmento de `EVENTO` é o conjunto de eventos cuja biblioteca pertence a um dado grupo. A fragmentação de `EVENTO` *deriva* da fragmentação de `BIBLIOTECA` — não é decidida directamente por um atributo de `EVENTO`, mas pela relação deste com `BIBLIOTECA`.

Em termos formais, usa-se a semi-junção: cada fragmento de `EVENTO` é o resultado de juntar `EVENTO` com o fragmento correspondente de `BIBLIOTECA`.

Implementa os fragmentos como vistas, agrupando as bibliotecas por região ou por critério que faça sentido com os teus dados de teste.

**As 3 regras que tens de demonstrar (Guia BD2 Tema 8):**
- **Completude:** todos os eventos aparecem em pelo menos um fragmento
- **Reconstrução:** a união de todos os fragmentos devolve exactamente a tabela `EVENTO` completa
- **Disjuntividade:** cada evento aparece num único fragmento (cada evento pertence a uma única biblioteca)

**Vista de serviço para outros nós:**
Cria uma vista de programação que o BibliotecaNacionalDB pode consultar — com informação de eventos, horários e bibliotecas. Cria também uma vista com o horário de funcionamento de cada biblioteca, que outros nós podem precisar de consultar. Concede os acessos correctos.

**O que registar no relatório:**
- As vistas de fragmento criadas com a explicação do critério de divisão
- Uma query que demonstra a Reconstrução: contagem em `EVENTO` deve ser igual à contagem na vista global
- Explicação das 3 regras aplicadas ao teu caso
- Explicação do que é uma fragmentação derivada e em que é diferente de uma fragmentação horizontal directa

**Pergunta de validação (responde por escrito antes de avançar):**
> A fragmentação derivada usa uma semi-junção com `BIBLIOTECA`. O que é uma semi-junção e em que é diferente de uma junção normal? Neste caso concreto, fragmentar `EVENTO` directamente por `id_biblioteca` daria o mesmo resultado que a fragmentação derivada? Se sim, porquê usar a semi-junção em vez de fragmentação directa?

---

## Fase 2 — Lógica do nó

### 2.1 — RN07: Validação do horário de evento

**Contexto (lê a RN07 completa):**
Um evento só pode ser marcado dentro do horário de funcionamento da biblioteca onde vai ocorrer. Não faz sentido agendar um evento para as 22h numa biblioteca que fecha às 18h. Esta verificação acontece antes de qualquer INSERT em `HORARIO_EV_BIB`.

**O que implementar:**
Um trigger que actua antes de cada INSERT em `HORARIO_EV_BIB`. O trigger tem de:
1. Identificar em que biblioteca o evento vai ocorrer, consultando a tabela `EVENTO`
2. Determinar o dia da semana da ocorrência a partir da data e hora de início
3. Consultar o horário de funcionamento da biblioteca para esse dia em `HORARIO_BIBLIOTECA`
4. Verificar que a hora de início da ocorrência não é anterior à hora de abertura
5. Verificar que a hora de fim não é posterior à hora de fecho
6. Se qualquer condição falhar, rejeitar o INSERT com mensagem clara indicando o problema

Atenção ao formato do dia da semana — o valor que usas para comparar com os registos em `HORARIO_BIBLIOTECA` tem de estar no mesmo formato que foi usado para inserir esses dados. Garante consistência.

**O que registar no relatório:**
- Descrição da lógica do trigger, passo a passo
- Explicação do risco de inconsistência no formato do dia da semana e como o resolveste

---

### 2.2 — Protecção de DELETE em EVENTO

**Contexto:**
O enunciado especifica que só eventos com status `'Cancelado'` podem ser apagados. Um evento planeado ou realizado tem registos de participação e avaliações associados — apagá-lo destruiria histórico que pertence ao sistema.

**O que implementar:**
Um trigger que actua antes de qualquer DELETE em `EVENTO`. Se o evento não tiver status `'Cancelado'`, rejeita a operação com mensagem clara indicando o status actual do evento.

**O que registar no relatório:**
- Descrição do que o trigger faz e porquê esta restrição existe do ponto de vista da integridade dos dados

---

### 2.3 — Testes obrigatórios da Fase 2

Para cada cenário, prepara os dados necessários, executa e regista o output real do SQL*Plus no relatório. Não inventes resultados.

**Preparação necessária:**
Antes de testar os triggers, insere pelo menos uma biblioteca com horário de funcionamento definido em `HORARIO_BIBLIOTECA` (por exemplo: segunda a sexta, das 08h às 18h) e um evento associado a essa biblioteca.

**Cenário 1 — RN07: Evento dentro do horário (deve passar)**
Tenta inserir uma ocorrência em `HORARIO_EV_BIB` com hora de início e hora de fim dentro do horário de funcionamento da biblioteca. O sistema deve aceitar o INSERT.

**Cenário 2 — RN07: Evento a começar antes da abertura (deve falhar)**
Tenta inserir uma ocorrência com hora de início antes da hora de abertura da biblioteca. O sistema deve rejeitar com mensagem de erro.

**Cenário 3 — RN07: Evento a terminar após o fecho (deve falhar)**
Tenta inserir uma ocorrência com hora de início válida mas hora de fim depois do fecho da biblioteca. O sistema deve rejeitar com mensagem de erro.

**Cenário 4 — RN07: Evento num dia sem horário definido (deve falhar)**
Tenta inserir uma ocorrência num dia da semana para o qual a biblioteca não tem horário definido em `HORARIO_BIBLIOTECA`. O sistema deve rejeitar com mensagem clara.

**Cenário 5 — DELETE de evento não cancelado (deve falhar)**
Com um evento em status `'Planeado'`, tenta apagá-lo. O sistema deve rejeitar com mensagem indicando o status actual.

**Cenário 6 — DELETE de evento cancelado (deve passar)**
Actualiza o status do mesmo evento para `'Cancelado'`. Tenta apagá-lo. O sistema deve aceitar.

**Cenário 7 — Reconstrução do fragmento**
Faz uma contagem directamente em `EVENTO` e outra na vista global que reconstrói os fragmentos. Os dois valores têm de ser iguais. Regista ambos os outputs lado a lado.

**Pergunta de validação:**
> O trigger de validação de horário usa o dia da semana para consultar `HORARIO_BIBLIOTECA`. Se a VM estiver configurada com um locale diferente do que usaste para inserir os dados, o que pode correr mal? Como garantiste consistência no formato do dia da semana entre os dados inseridos e a lógica do trigger?

---

## Fase 3 — Distribuição e Backup

### 3.1 — Exposição de dados para outros nós

Verifica que as vistas correctas estão acessíveis com os GRANTs correctos. Pensa em quem precisa de quê:
- O BibliotecaNacionalDB precisa da programação de eventos e dos horários das bibliotecas para análise nacional
- O MateriaisDB precisa de saber quais bibliotecas existem (os materiais têm `id_biblioteca`)
- O EmpréstimosDB precisa de saber quais bibliotecas existem (os leitores têm `cod_biblioteca`)

Para cada caso, confirma que a vista existe e o GRANT foi feito. Pede ao colega do BibliotecaNacionalDB para confirmar que consegue aceder às tuas vistas via database link. Regista o output no teu relatório.

**O que registar:**
- Lista de vistas expostas, a quem, e para quê
- Output do teste de acesso remoto confirmado com um colega

---

### 3.2 — Backup e Recovery do EventosBibliotecasDB

**Contexto:**
O EventosBibliotecasDB contém o registo de todas as bibliotecas do sistema. Se este nó perder dados, os outros nós ficam com referências a bibliotecas que deixaram de existir na vista central. O recovery tem de repor o estado exacto antes da falha.

**O que fazer:**
Faz um backup a quente do datafile da tua tablespace, com a base de dados aberta. Consulta o Guia BD2 e os materiais das aulas para os comandos correctos.

Simula uma falha apagando o datafile. Regista o erro ao tentar aceder às tabelas. Faz o recovery usando o ficheiro de backup e os archived logs. Confirma que os dados voltaram.

**O que registar:**
- Passos do backup com outputs reais de cada comando
- Output do erro após simular a falha
- Passos do recovery com outputs
- Output final confirmando que os dados voltaram

**Pergunta de validação:**
> O backup que fizeste é um backup físico a nível de datafile. Existe outro tipo de backup em Oracle — o Data Pump (`expdp`). Qual é a diferença entre um backup físico e um backup lógico com Data Pump? Em que situação usarias cada um? Para o teu cenário de recovery, qual é mais rápido e porquê?

---

## Checklist final — EventosBibliotecasDB

- [ ] Todas as tabelas criadas na tablespace correcta com todas as constraints do DD v3
- [ ] Índices criados na tablespace de índices com justificação documentada
- [ ] Vistas de fragmento derivado de EVENTO criadas com demonstração das 3 regras
- [ ] Vista de programação de eventos para o BibliotecaNacionalDB criada com GRANTs correctos
- [ ] Vista de horário das bibliotecas criada com GRANTs correctos
- [ ] Vista de bibliotecas activas criada com GRANTs para os outros nós
- [ ] Trigger de validação de horário de evento criado e testado (4 cenários)
- [ ] Trigger de protecção de DELETE em EVENTO criado e testado
- [ ] Todos os 7 cenários de teste executados com outputs reais registados
- [ ] Acesso remoto confirmado com o colega do BibliotecaNacionalDB
- [ ] Backup a quente executado e documentado
- [ ] Recovery simulado e documentado
- [ ] Todas as perguntas de validação respondidas por escrito no relatório
