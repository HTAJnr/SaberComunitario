# Yannis — Nó EmpréstimosDB
### Sistema de Gestão de Bibliotecas Comunitárias Distribuído
**Ambiente:** Oracle 10g XE, CentOS 6.8, SQL*Plus
**Referências obrigatórias:** DD v3, Regras de Negócio v3 (RN01, RN02, RN03, RN04, RN11), Guia BD2 Temas 8 e 9

---

## O teu nó no sistema

O EmpréstimosDB é o nó transaccionalmente mais crítico do sistema. É aqui que acontece o registo de todos os empréstimos e devoluções, a aplicação de multas, suspensões e bloqueios, a gestão de leitores e as suas restrições, e a verificação de elegibilidade antes de qualquer empréstimo ser criado.

Todos os outros nós dependem de dados deste nó. O MateriaisDB precisa de saber se um material tem empréstimo activo para permitir transferências. O EventosBibliotecasDB precisa do status do leitor para registar participações. O BibliotecaNacionalDB agrega os dados de leitores nas suas vistas globais. Se a lógica deste nó estiver errada, o sistema inteiro produz resultados inválidos.

---

## Fase 1 — Estrutura local do nó

### 1.1 — Tabelas do teu domínio

As tabelas que pertencem ao EmpréstimosDB são as seguintes, todas definidas no DD v3:
- `LEITOR`
- `ADULTO`
- `ADULTO_INTERESSE`
- `PROFESSOR`
- `PROFESSOR_DISCIPLINA`
- `CRIANCA`
- `EMPRESTIMO`
- `SUSPENSAO`

**O que fazer:**
Cria todas estas tabelas no teu schema (`usr_emprestimosdb`), usando a tablespace de dados e a tablespace de índices criadas na Fase Comum. Consulta o DD v3 para os tipos, tamanhos, constraints e regras de integridade referencial de cada campo. Presta atenção especial às constraints de CHECK — há vários campos com valores controlados que o DD v3 especifica explicitamente, como `status_leitor`, `historico_pontualidade`, e os campos de estado do empréstimo e da suspensão.

Nota importante sobre `LEITOR.contacto`: a ausência de constraint UNIQUE neste campo é intencional — consulta a RN11 para perceber porquê antes de tentares adicionar essa constraint.

Cria índices nas colunas mais consultadas. Pensa em quais são as queries mais frequentes neste nó: verificar se um leitor tem empréstimo activo, filtrar por status do leitor, encontrar empréstimos de um material específico. Justifica cada índice no relatório.

**O que registar no relatório:**
- Output da query ao dicionário de dados confirmando cada tabela na tablespace correcta
- Lista de índices criados com justificação de cada um
- Explicação de porquê `contacto` não tem UNIQUE, referenciando a RN11

---

### 1.2 — A decisão de fragmentação e porquê

**O problema:**
A tabela `LEITOR` tem campos que são necessários em vários nós. O MateriaisDB precisa de verificar `status_leitor` e `historico_pontualidade` antes de confirmar se pode haver transferência. O EventosBibliotecasDB precisa do `status_leitor` para registar participações. Mas campos como `foto_path`, `data_nasc` e `nivel_escolar` são dados privados sem utilidade fora do EmpréstimosDB.

Dar acesso total à tabela `LEITOR` a outros nós expõe dados pessoais desnecessariamente e viola o princípio de autonomia. A solução é fragmentação vertical.

**A fragmentação que implementas:**
Fragmentação vertical de `LEITOR` — separar os atributos em dois grupos lógicos: dados públicos, necessários noutros nós para verificação de restrições operacionais; e dados privados, exclusivos do EmpréstimosDB. Antes de criar as vistas, decide quais atributos pertencem a cada grupo. O critério é operacional: o que outros nós precisam de saber para funcionar versus o que é informação pessoal que não sai deste nó.

**As 3 regras que tens de demonstrar (Guia BD2 Tema 8):**
- **Completude:** todos os atributos de `LEITOR` aparecem em pelo menos um fragmento
- **Reconstrução:** a junção dos dois fragmentos pelo `num_cartao` reconstrói a tabela completa
- **Disjuntividade:** cada atributo aparece num único fragmento — excepto `num_cartao`, que é a chave primária e está em ambos por definição

**Vista de serviço para outros nós:**
Cria uma vista que expõe apenas os atributos do fragmento público. É esta vista que o MateriaisDB e o EventosBibliotecasDB vão consultar via database link. Concede acesso aos utilizadores de leitura dos nós que a precisam.

**O que registar no relatório:**
- As vistas de fragmento com a descrição dos atributos em cada grupo e o critério de divisão
- Uma query que demonstra a Reconstrução: contagem em `LEITOR` deve ser igual à contagem na vista que junta os dois fragmentos
- Explicação das 3 regras aplicadas ao teu caso concreto

**Pergunta de validação (responde por escrito antes de avançar):**
> A chave primária `num_cartao` aparece nos dois fragmentos. Isso não viola a disjuntividade? Explica porquê a excepção da chave primária existe na fragmentação vertical e porquê é necessária para garantir a Reconstrução.

---

## Fase 2 — Lógica do nó

### 2.1 — RN01: Limite de empréstimo e verificação de status

**Contexto (lê a RN01 completa):**
Cada leitor só pode ter 1 empréstimo activo em simultâneo. Leitores com status diferente de `'Activo'` não podem emprestar, independentemente do limite. Estas verificações têm de acontecer antes de qualquer INSERT em `EMPRESTIMO`.

**O que implementar:**
Um trigger que actua antes de cada INSERT em `EMPRESTIMO`. O trigger verifica em sequência: se o status do leitor permite empréstimos; se ele já tem um empréstimo activo; se o material está disponível no MateriaisDB (via database link); e se o material não tem transferência pendente ou aprovada (RN06). Se qualquer condição falhar, o INSERT é rejeitado com mensagem clara que identifica o motivo.

**O que registar no relatório:**
- Descrição das verificações que o trigger faz, em que ordem, e porquê essa ordem
- Explicação de porquê este trigger consulta outro nó via database link

---

### 2.2 — RN04.1: Restrição por faixa etária para crianças

**Contexto (lê a RN04):**
Crianças só podem emprestar materiais com faixa etária `'Infantil'` ou `'Todas as Idades'`. Esta verificação acontece antes do INSERT, depois de confirmar que o leitor é uma criança.

**O que implementar:**
Lógica (no mesmo trigger ou separada) que verifica se o leitor é uma criança consultando a tabela `CRIANCA`. Se for, consulta a categoria do material no MateriaisDB via database link para obter a `faixa_etaria`. Se a faixa não for permitida, rejeita com mensagem.

**O que registar no relatório:**
- Descrição da lógica de verificação
- Porquê a informação de categoria tem de ser buscada no MateriaisDB e não está disponível localmente

---

### 2.3 — RN02: Cálculo do prazo de devolução

**Contexto (lê a RN02 completa, incluindo a fórmula e os exemplos):**
O prazo é calculado com base na distância do leitor à biblioteca, se é professor, e no histórico de pontualidade. O prazo mínimo nunca pode ser inferior a 7 dias. O cálculo é feito antes do INSERT, não por trigger.

**O que implementar:**
Uma **function** que recebe o `num_cartao` do leitor e a data de retirada, e devolve a data de prazo calculada segundo a fórmula exacta da RN02. A function tem de cobrir todos os casos: ajuste de distância, bónus de professor, penalização por mau histórico, e o piso mínimo de 7 dias.

Testa a function com os exemplos concretos que estão na RN02 — eles indicam os valores esperados para diferentes combinações. Se o resultado não bater certo com os exemplos, há um erro na lógica.

**O que registar no relatório:**
- Descrição da lógica da function, passo a passo, referenciando a fórmula da RN02
- Porquê foi implementada como function e não como trigger
- Confirmação de que os exemplos da RN02 produzem os valores correctos

---

### 2.4 — RN03: Multas, suspensões e bloqueios na devolução

**Contexto (lê a RN03 completa — é a regra mais complexa do sistema):**
Quando um empréstimo é devolvido com atraso, o sistema aplica uma sequência de penalizações: calcula a multa com base nos dias de atraso e na categoria do leitor; aplica uma suspensão com duração proporcional ao atraso; ou um bloqueio permanente se o atraso superar 60 dias; e recalcula o histórico de pontualidade do leitor.

**O que implementar:**
Um trigger que actua antes de o campo `data_devolucao` ser preenchido num UPDATE em `EMPRESTIMO`. O trigger só deve activar quando a devolução está a ser registada — quando `data_devolucao` passa de NULL para um valor.

A lógica segue esta sequência, conforme a RN03:
1. Calcular os dias de atraso. Se não há atraso, não faz nada.
2. Se há atraso, calcular a multa conforme a categoria do leitor — adulto, criança, ou professor com as regras específicas para primeira infracção.
3. Determinar a suspensão ou bloqueio conforme a tabela de dias da RN03.
4. Actualizar o status do leitor e criar o registo em `SUSPENSAO` se aplicável.
5. Se for bloqueio, comunicar ao MateriaisDB para marcar o material como perdido.
6. Recalcular e actualizar `historico_pontualidade` conforme as regras da RN03.

Consulta a RN03 para os valores exactos de cada caso — taxas de multa por categoria, tabela de dias de suspensão por intervalo de atraso, condições de bloqueio, regras de actualização do histórico.

**O que registar no relatório:**
- Descrição da lógica completa do trigger, caso a caso, referenciando a RN03
- Explicação de como o trigger distingue uma devolução de outros tipos de UPDATE em `EMPRESTIMO`

---

### 2.5 — Testes obrigatórios da Fase 2

Para cada cenário, prepara os dados, executa e regista o output real do SQL*Plus. Não inventes resultados.

**Cenário 1 — RN01: Segundo empréstimo bloqueado**
Cria um leitor activo com um empréstimo activo. Tenta criar um segundo empréstimo para ele. O sistema deve rejeitar com mensagem de erro.

**Cenário 2 — RN01: Leitor suspenso não pode emprestar**
Coloca um leitor em status `'Suspenso'`. Tenta criar um empréstimo para ele. O sistema deve rejeitar antes de verificar qualquer outra condição.

**Cenário 3 — RN02: Verificar os exemplos da regra**
Cria leitores com as características dos exemplos que estão na RN02. Chama a function para cada um e confirma que os resultados coincidem com os valores esperados na regra.

**Cenário 4 — RN03: Devolução com atraso de 5 dias**
Cria um empréstimo e simula a devolução com 5 dias de atraso. Verifica: que a multa foi calculada correctamente para a categoria do leitor; que foi criado um registo em `SUSPENSAO` com os dias correctos da tabela da RN03; que o status do leitor passou para `'Suspenso'`.

**Cenário 5 — RN03: Devolução com mais de 60 dias de atraso**
Simula uma devolução com atraso superior a 60 dias. Verifica que o status passou para `'Bloqueado'` e confirma com o Yasin que o material foi marcado como perdido no MateriaisDB.

**Cenário 6 — RN04.1: Criança tenta emprestar material inadequado**
Cria um leitor do tipo `CRIANCA`. Tenta criar um empréstimo para um material com faixa etária diferente de `'Infantil'` ou `'Todas as Idades'` — coordena com o Yasin para ter esse material disponível. O sistema deve rejeitar.

**Cenário 7 — Teste de concorrência (Guia BD2 Tema 9)**
Abre duas sessões SQL*Plus em simultâneo. Na sessão 1, começa a inserir um empréstimo para um material específico mas não faz COMMIT. Na sessão 2, tenta inserir um empréstimo para o mesmo material. Observa e regista o que acontece em cada sessão. Faz COMMIT na sessão 1 e regista o que acontece na sessão 2.

No relatório, explica o comportamento observado usando os conceitos de bloqueio exclusivo e serialização do Guia BD2 Tema 9.

**Pergunta de validação:**
> O trigger de devolução comunica com o MateriaisDB remotamente quando há bloqueio. Isso é uma transacção distribuída. O que é o protocolo Two-Phase Commit (2PC) e como o Oracle garante que esta operação é atómica — ou os dois nós confirmam ou nenhum confirma?

---

## Fase 3 — Distribuição e Backup

### 3.1 — Exposição de dados para outros nós

Verifica que as vistas correctas estão acessíveis com os GRANTs correctos. Pensa em quem precisa de quê:
- O MateriaisDB precisa de saber se um material tem empréstimo activo (para RN06)
- O EventosBibliotecasDB precisa do status do leitor para registar participações
- O BibliotecaNacionalDB precisa de dados de leitores e empréstimos para as vistas globais

Para cada caso, confirma que a vista existe e o GRANT foi feito. Testa o acesso remoto com um colega e regista o output no relatório.

---

### 3.2 — Backup e Recovery do EmpréstimosDB

**Contexto:**
O EmpréstimosDB contém o histórico de todos os empréstimos e o estado actual de todos os leitores. Perder esses dados significa perder o registo de quem tem o quê emprestado e quem está suspenso. O recovery tem de ser preciso — não podes perder transacções já confirmadas.

**O que fazer:**
Faz um backup a quente do datafile da tua tablespace, com a base de dados aberta. Consulta o Guia BD2 e os materiais das aulas para os comandos correctos.

Simula uma falha apagando o datafile. Regista o erro ao tentar aceder às tabelas. Faz o recovery usando o ficheiro de backup e os archived logs. Confirma que os dados voltaram.

**O que registar:**
- Passos do backup com outputs reais de cada comando
- Output do erro após simular a falha
- Passos do recovery com outputs
- Output final confirmando que os dados voltaram

**Pergunta de validação:**
> O teu nó tem a lógica transaccionalmente mais pesada — multas, suspensões, actualizações de status, tudo dentro de triggers. Se o sistema falhar a meio de um trigger, o que garante que a BD não fica em estado inconsistente? Fala sobre atomicidade e o papel do Undo no Oracle.

---

## Checklist final — EmpréstimosDB

- [ ] Todas as tabelas criadas na tablespace correcta com todas as constraints do DD v3
- [ ] Índices criados na tablespace de índices com justificação documentada
- [ ] Vistas de fragmento vertical de LEITOR criadas com demonstração das 3 regras
- [ ] Vista de dados públicos de leitores com GRANTs correctos para os outros nós
- [ ] Vista de empréstimos activos por material com GRANTs correctos
- [ ] Function de cálculo do prazo de devolução criada e testada com os exemplos da RN02
- [ ] Trigger de validação antes do INSERT em EMPRESTIMO criado e testado (RN01 e RN04.1)
- [ ] Trigger de processamento da devolução criado e testado (RN03 completa)
- [ ] Todos os 7 cenários de teste executados com outputs reais registados
- [ ] Teste de concorrência executado e explicado no relatório com conceitos do Tema 9
- [ ] Acesso remoto testado e confirmado com um colega
- [ ] Backup a quente executado e documentado
- [ ] Recovery simulado e documentado
- [ ] Todas as perguntas de validação respondidas por escrito no relatório
