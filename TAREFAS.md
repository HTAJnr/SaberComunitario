# Hélder — Nó BibliotecaNacionalDB
### Sistema de Gestão de Bibliotecas Comunitárias Distribuído
**Ambiente:** Oracle 10g XE, CentOS 6.8, SQL*Plus
**Referências obrigatórias:** DD v3, Regras de Negócio v3 (RN08, RN10), Guia BD2 — Todos os temas

---

## O teu nó no sistema

O BibliotecaNacionalDB é o nó coordenador do sistema distribuído. É o único que tem visibilidade total sobre todos os outros nós via database links, pode apagar registos de leitores e funcionários, pode modificar níveis de acesso, agrega dados de todos os nós em vistas globais, e coordena transacções que escrevem em mais de um nó.

É também o nó que gere doações, doadores, certificados e programas de alfabetização — o domínio financeiro e educacional do sistema.

Este é o nó com maior responsabilidade técnica. O professor vai questioná-lo com mais detalhe na defesa, porque é aqui que se demonstram os conceitos mais avançados do Guia BD2: replicação, auditoria, transparência de localização, Two-Phase Commit, e Data Pump.

---

## Fase 1 — Estrutura local do nó

### 1.1 — Tabelas do teu domínio

As tabelas que pertencem ao BibliotecaNacionalDB são as seguintes, todas definidas no DD v3:
- `DOADOR`
- `DOACAO`
- `ITEM_DOACAO`
- `CERTIFICADO_DOACAO`
- `PROGRAMA_ALFABETIZACAO`
- `NIVEL_PROGRESSAO`
- `PROGRAMA_MATERIAL`
- `PROGRAMA_FUNCIONARIO`
- `PARTICIPACAO_PROGRAMA`

**O que fazer:**
Cria todas estas tabelas no teu schema (`usr_nacionaldb`), usando a tablespace de dados e a tablespace de índices criadas na Fase Comum. Consulta o DD v3 para os tipos, tamanhos e constraints exactos de cada campo.

Depois de criar as tabelas, insere imediatamente o registo especial do doador anónimo com `id_doador = 0`, conforme definido na RN10. Este registo tem de existir antes de qualquer operação com doações — é um dado inicial obrigatório do sistema.

Verifica no dicionário de dados que todas as tabelas foram criadas na tablespace correcta e que o registo do doador anónimo foi inserido correctamente. Regista esses outputs no relatório.

Cria índices nas colunas mais consultadas — pesquisa de doações por doador, pesquisa de certificados por número, pesquisa de programas por biblioteca. Justifica cada índice.

**O que registar no relatório:**
- Output da query ao dicionário de dados confirmando cada tabela na tablespace correcta
- Confirmação de que o registo do doador anónimo foi inserido: mostra o SELECT que o devolve
- Lista de índices criados com justificação de cada um

---

### 1.2 — A decisão de replicação e porquê

**O problema:**
Outros nós precisam de verificar dados de funcionários que vivem no EventosBibliotecasDB. O EmpréstimosDB, por exemplo, pode precisar de confirmar se um funcionário tem nível de acesso suficiente para aprovar certas operações. Fazer essa consulta sempre via database link em tempo real funciona — mas tem um custo de latência de rede em cada operação.

Para dados que mudam raramente, como os dados de funcionários, há uma alternativa melhor: replicação assíncrona. Copia-se um subconjunto dos dados para o nó que os precisa e actualiza-se periodicamente.

**O que implementar:**
Cria uma vista no teu nó que agrega os dados públicos de funcionários a partir do EventosBibliotecasDB via database link. Esta vista é a fonte da replicação — representa o que vai ser copiado.

Cria uma procedure de sincronização que copia os dados dessa vista para uma tabela receptora no EmpréstimosDB. A procedure apaga os dados anteriores da réplica e insere os actuais. Para isso funcionar, o Yannis tem de criar a tabela receptora no nó dele — coordena com ele.

Não replicas todos os atributos de funcionário — só os que outros nós precisam operacionalmente: identificação, nível de acesso, função, e a que biblioteca pertence. O resto é informação privada que fica no EventosBibliotecasDB.

**O que registar no relatório:**
- A vista criada e a explicação dos atributos incluídos e excluídos
- O resultado de executar a procedure de sincronização — número de linhas copiadas
- Explicação da diferença entre replicação síncrona e assíncrona
- Justificação de porquê escolheste replicação assíncrona para este caso concreto

**Pergunta de validação (responde por escrito antes de avançar):**
> A replicação assíncrona pode criar inconsistências temporárias. Dá um cenário concreto no vosso sistema em que essa inconsistência poderia ser um problema real. Como o sistema deveria lidar com ela?

---

## Fase 2 — Lógica do nó

### 2.1 — RN08: Geração de certificados de doação

**Contexto (lê a RN08 completa):**
Existem três tipos de certificados: Original (emitido automaticamente para doações individuais com valor igual ou superior a 1.000 MT), Anual (para doadores institucionais, gerado manualmente no fim do ano), e Honorífico (para contribuições excepcionais, emitido manualmente por um Coordenador ou superior).

O número do certificado segue o formato `CERT-[ANO]-[SEQUENCIAL]`. Tens de criar uma sequência Oracle para gerar o número sequencial.

**O que implementar:**
Dois mecanismos distintos — um automático e um manual.

Para a emissão automática: um trigger que actua após cada INSERT em `DOACAO`. O trigger verifica o tipo do doador e o valor da doação. Se as condições da RN08 estiverem satisfeitas, gera o número do certificado usando a sequência e insere o registo em `CERTIFICADO_DOACAO`. Atenção ao caso de doações anónimas — consulta a RN10 para perceber como tratar esse caso no trigger.

Para a emissão manual de honoríficos: uma procedure que recebe o ID da doação, o código do funcionário que está a emitir, e uma justificativa. A procedure tem de verificar se o funcionário tem nível de acesso `'Coordenador'` ou `'Administrador'` — consulta essa informação no EventosBibliotecasDB via database link. Se não tiver, rejeita com mensagem. Se tiver, gera o certificado e regista a justificativa.

**O que registar no relatório:**
- Descrição do que o trigger faz, caso a caso, referenciando a RN08
- Descrição da lógica da procedure de emissão manual e das verificações que faz
- Confirmação de que a sequência Oracle foi criada

---

### 2.2 — RN10: Protecção do doador anónimo

**Contexto (lê a RN10):**
O registo com `id_doador = 0` nunca pode ser eliminado. Todas as doações sem identificação de doador referenciam este registo especial permanente.

**O que implementar:**
Um trigger que actua antes de qualquer DELETE em `DOADOR`. Se o registo a apagar tiver `id_doador = 0`, rejeita a operação com mensagem de erro.

**O que registar no relatório:**
- Descrição do trigger e porquê este registo tem protecção especial

---

### 2.3 — Auditoria do sistema

**Contexto:**
O enunciado especifica que todos os nós devem manter logs de auditoria, e que só o BibliotecaNacionalDB pode apagar leitores, remover funcionários e modificar níveis de acesso. A auditoria garante rastreabilidade — quem fez o quê e quando — e é obrigatória nas operações mais sensíveis do sistema.

**O que implementar — duas camadas:**

**Camada 1 — Auditoria Oracle nativa:**
O Oracle 10g tem suporte nativo a auditoria através do parâmetro `AUDIT_TRAIL`. Activa a auditoria no teu nó (requer ligação como SYSDBA e possivelmente reinício da instância — consulta o Guia BD2 para o procedimento correcto em Oracle 10g XE). Depois de activa, configura auditorias específicas para as operações mais críticas: logins no nó central, operações de DELETE e UPDATE nas tabelas sensíveis. Verifica no dicionário de dados que as auditorias estão configuradas.

**Camada 2 — Tabela de auditoria manual para operações distribuídas:**
A auditoria Oracle nativa regista operações locais. Mas operações que atravessam nós — como apagar um leitor que está no EmpréstimosDB a partir do NacionalDB — precisam de um log próprio que registe a operação distribuída. Cria uma tabela de auditoria manual no teu nó e uma procedure que insere registos nessa tabela.

Esta procedure de auditoria tem uma característica especial: tem de usar `PRAGMA AUTONOMOUS_TRANSACTION`. Pesquisa o que isto significa no contexto do Oracle PL/SQL e explica no relatório porquê é necessário para um sistema de auditoria — o que acontece ao log se a transacção principal fizer ROLLBACK?

**O que registar no relatório:**
- Confirmação de que a auditoria Oracle nativa está activa e configurada — output do dicionário de dados
- Descrição da tabela de auditoria manual criada
- Explicação de `PRAGMA AUTONOMOUS_TRANSACTION` e porquê é necessário aqui

---

### 2.4 — Controlo de acesso global

**Contexto:**
O enunciado é explícito: só o BibliotecaNacionalDB pode apagar registos de leitores e remover funcionários. Isso não pode ser apenas uma política escrita — tem de ser implementado como restrição real no sistema.

**O que implementar:**
Uma procedure controlada para apagar leitores. Em vez de qualquer nó poder fazer `DELETE FROM LEITOR` directamente, a deleção só acontece através desta procedure, que: verifica se o funcionário que está a pedir a operação tem nível `'Administrador'` (consultando o EventosBibliotecasDB via database link); verifica se o leitor não tem empréstimos activos (consultando o EmpréstimosDB via database link); executa o DELETE no EmpréstimosDB via database link; e regista a operação na tabela de auditoria manual — tanto em caso de sucesso como em caso de falha.

**O que registar no relatório:**
- Descrição completa da lógica da procedure e de cada verificação que faz
- Explicação de porquê centralizar esta operação no NacionalDB e não deixar cada nó gerir as suas próprias deleções

---

### 2.5 — Vistas globais — transparência de localização

**Contexto:**
Um dos objectivos de uma BD distribuída é a transparência de localização — o utilizador executa uma query como se os dados estivessem todos num só lugar, sem saber que estão distribuídos por 4 nós. Estas vistas materializam esse princípio.

**O que implementar:**
Pelo menos 3 vistas que agregam dados de múltiplos nós via database links:

Uma vista que mostra leitores com o seu estado de empréstimo actual — combina dados do EmpréstimosDB.

Uma vista que mostra o catálogo completo com disponibilidade e localização — combina dados do MateriaisDB e do EventosBibliotecasDB.

Uma vista que mostra a programação de eventos com dados de participação — combina dados do EventosBibliotecasDB.

Para cada vista, testa com um SELECT real e regista o output. O utilizador que faz esse SELECT não sabe de onde vieram os dados — é isso que demonstras.

**O que registar no relatório:**
- As vistas criadas com a descrição de quais nós são consultados em cada uma
- Output de um SELECT em cada vista com dados reais dos outros nós
- Explicação de como estas vistas implementam a transparência de localização

**Pergunta de validação:**
> A transparência de localização é uma das propriedades desejáveis de uma BD distribuída. Quais são as outras propriedades de transparência que o Guia BD2 menciona? O vosso sistema implementa alguma delas além da transparência de localização?

---

### 2.6 — Demonstração do Two-Phase Commit

**Contexto (Guia BD2 Tema 8):**
O Two-Phase Commit (2PC) é o protocolo que garante atomicidade em transacções distribuídas — se uma operação precisa de escrever em dois nós ao mesmo tempo, ou ambos confirmam ou nenhum confirma. O Oracle implementa isso automaticamente quando uma única transacção faz operações em database links antes do COMMIT.

**O que demonstrar:**
Cria uma procedure que, numa única transacção, regista uma doação no teu nó (local) e actualiza um campo no MateriaisDB (remoto via database link). Como as duas operações estão na mesma transacção e o COMMIT final coordena os dois nós, o Oracle usa 2PC automaticamente.

Documenta a execução: mostra que os dados aparecem em ambos os nós após o COMMIT. Depois, no relatório, explica as duas fases do protocolo — fase de preparação (PREPARE) e fase de confirmação (COMMIT) — e o que o Oracle faz se um dos nós ficar offline entre as duas fases. Pesquisa a vista `DBA_2PC_PENDING` e explica para que serve.

**O que registar no relatório:**
- Descrição da procedure criada e de porquê constitui uma transacção distribuída
- Confirmação de que os dados aparecem nos dois nós após a execução
- Explicação das duas fases do 2PC e do comportamento em caso de falha entre fases

---

### 2.7 — Testes obrigatórios da Fase 2

Para cada cenário, prepara os dados, executa e regista o output real do SQL*Plus. Não inventes resultados.

**Cenário 1 — RN10: Tentativa de apagar o doador anónimo**
Tenta apagar o registo com `id_doador = 0`. O sistema deve rejeitar com mensagem de erro.

**Cenário 2 — RN08: Doação individual com valor >= 1.000 MT gera certificado**
Insere uma doação para um doador do tipo `'Individual'` com valor igual ou superior a 1.000 MT. Confirma que um certificado foi gerado automaticamente em `CERTIFICADO_DOACAO` com o número no formato correcto.

**Cenário 3 — RN08: Doação individual com valor < 1.000 MT não gera certificado**
Insere uma doação para um doador `'Individual'` com valor inferior a 1.000 MT. Confirma que nenhum certificado foi gerado.

**Cenário 4 — RN08: Certificado honorífico por funcionário sem permissão**
Chama a procedure de emissão de honorífico passando o código de um funcionário com nível `'Bibliotecario'`. O sistema deve rejeitar com mensagem de erro.

**Cenário 5 — Auditoria: tentativa falhada de apagar leitor**
Chama a procedure de apagar leitor com um funcionário que não tem nível `'Administrador'`. O sistema deve rejeitar. Verifica que a tabela de auditoria manual registou a tentativa falhada — mostra o SELECT que confirma isso.

**Cenário 6 — Vistas globais: transparência de localização**
Executa um SELECT numa das tuas vistas globais que agrega dados de outros nós. Regista o output. Explica no relatório de que nós vieram os dados mostrados, sem que o utilizador que fez o SELECT precisasse de saber isso.

**Cenário 7 — 2PC: transacção distribuída**
Executa a procedure de demonstração do 2PC. Verifica nos dois nós envolvidos que os dados foram confirmados em ambos. Regista os outputs das duas verificações.

**Pergunta de validação:**
> A procedure de auditoria usa `PRAGMA AUTONOMOUS_TRANSACTION`. Explica o que isso significa. Se a transacção principal fizer ROLLBACK, o que acontece ao registo de auditoria? Porquê esse é o comportamento correcto para um sistema de auditoria?

---

## Fase 3 — Backup, Recovery e Data Pump

### 3.1 — Backup a quente e recovery

**Contexto:**
O BibliotecaNacionalDB contém os registos de doações, certificados e programas de alfabetização — dados financeiros e educacionais. O backup tem de ser feito com a BD aberta e o recovery tem de ser preciso.

**O que fazer:**
Faz um backup a quente do datafile da tua tablespace, com a base de dados aberta. Simula uma falha apagando o datafile. Regista o erro. Faz o recovery usando o ficheiro de backup e os archived logs. Confirma que os dados voltaram.

**O que registar:**
- Passos do backup com outputs reais
- Output do erro após simular a falha
- Passos do recovery com outputs
- Output final confirmando que os dados voltaram

---

### 3.2 — Data Pump: backup lógico

**Contexto:**
O backup físico (datafile + archived logs) é o mecanismo de recovery. O Data Pump (`expdp/impdp`) tem uma utilidade diferente: exporta dados de forma lógica — por schema, por tabela, com filtros — e permite importar noutro servidor ou versão Oracle. É o backup de migração e de transferência de dados.

Como nó central, fazes o export completo do teu schema com `expdp` e documentas o processo. Depois simulas uma importação para um schema diferente com `impdp` para confirmar que o ficheiro é válido.

Consulta o Guia BD2 e os materiais das aulas para os parâmetros correctos do `expdp` e `impdp` em Oracle 10g XE no CentOS. Antes de correr o comando, cria o directório Oracle necessário tanto no sistema operativo como na BD.

**O que registar:**
- Passos da criação do directório Oracle (SO e BD)
- Output do `expdp` — tamanho do ficheiro gerado, número de objectos exportados
- Output do `impdp` para o schema de restore
- Diferença entre este backup lógico e o backup físico que fizeste em 3.1

**Pergunta de validação:**
> O Data Pump exporta o estado actual dos dados. Com backup físico em modo ARCHIVELOG consegues fazer Point-In-Time Recovery — recuperar a BD para um momento específico no passado. O Data Pump consegue isso? Porquê não? Qual é a vantagem do Data Pump que justifica a sua existência apesar desta limitação?

---

## Checklist final — BibliotecaNacionalDB

- [ ] Todas as tabelas criadas na tablespace correcta com todas as constraints do DD v3
- [ ] Registo do doador anónimo inserido e confirmado via SELECT
- [ ] Índices criados na tablespace de índices com justificação documentada
- [ ] Vista de dados públicos de funcionários criada a partir do EventosBibliotecasDB
- [ ] Procedure de sincronização de funcionários criada e executada com output registado
- [ ] Sequência Oracle para numeração de certificados criada
- [ ] Trigger de geração automática de certificados criado e testado
- [ ] Procedure de emissão de certificados honoríficos criada e testada
- [ ] Trigger de protecção do doador anónimo criado e testado
- [ ] Auditoria Oracle nativa activada e configurada — output do dicionário de dados
- [ ] Tabela de auditoria manual criada com procedure usando PRAGMA AUTONOMOUS_TRANSACTION
- [ ] Procedure de apagar leitor com controlo de acesso e auditoria criada e testada
- [ ] Pelo menos 3 vistas globais criadas e testadas com outputs reais
- [ ] Procedure de demonstração do 2PC criada e executada com verificação nos dois nós
- [ ] Todos os 7 cenários de teste executados com outputs reais registados
- [ ] Backup a quente executado e documentado
- [ ] Recovery simulado e documentado
- [ ] Data Pump export e import executados e documentados
- [ ] Todas as perguntas de validação respondidas por escrito no relatório
