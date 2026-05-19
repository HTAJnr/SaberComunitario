# Relatório Técnico — BibliotecaNacionalDB
**Nó:** Helder Tamele Alfredo (BibliotecaNacionalDB)  
**Projecto:** Saber Comunitário — Sistema de Gestão de Bibliotecas Comunitárias Distribuído  
**Data:** 2026-05-19

---

## Índice

1. [Visão Geral do Nó](#visao-geral)
2. [Fase Comum — Database Links e Conectividade](#fase-comum)
3. [Fase 1 — Estrutura Local e Fragmentação](#fase-1)
4. [Fase 2 — Distribuição Avançada](#fase-2)
5. [Visitor Users — Segurança Cross-Node](#visitor-users)
6. [Tarefa A1 — Snapshot e Materialized Views](#tarefa-a1)
7. [Tarefa A2 — Deadlock: Detecção e Prevenção](#tarefa-a2)
8. [Tarefa A3 — Fragmentação Horizontal de LEITOR](#tarefa-a3)
9. [Tarefa A4 — SET TRANSACTION READ ONLY](#tarefa-a4)
10. [Mecanismos de Replicação — Tabela Comparativa](#replicacao)
11. [Respostas às Perguntas de Validação](#perguntas-validacao)

---

## 1. Visão Geral do Nó {#visao-geral}

O **BibliotecaNacionalDB** é o nó central de autenticação e gestão de leitores, funcionários e doações do sistema distribuído. É o único nó que tem informação de identidade dos leitores — os outros nós consultam este nó para verificar o status de um leitor antes de criar empréstimos (EmprestimosDB), disponibilizar e-books (MateriaisDB), ou inscrever em eventos (EventosBibliotecasDB).

**Tabelas locais:**
- `FUNCIONARIO`, `FUNCAO_FUNCIONARIO`, `FUNCIONARIO_HABILIDADE`, `HORARIO_FUNCIONARIO`
- `LEITOR`, `ADULTO`, `ADULTO_INTERESSE`, `PROFESSOR`, `PROFESSOR_DISCIPLINA`, `CRIANCA`
- `DOADOR`, `DOACAO`, `ITEM_DOACAO`, `CERTIFICADO_DOACAO`
- `AUDITORIA_OPERACOES`

**Utilizadores Oracle:**
- `usr_NACIONALDB` — schema owner, corre os scripts DDL
- `app_NACIONALDB` — utilizado pelo backend Node.js (DML + EXECUTE)
- `app_emprestimosdb`, `app_materiaisdb`, `app_eventosdb` — visitor users para cross-node

---

## 2. Fase Comum — Database Links e Conectividade {#fase-comum}

### 2.1 Database Links

Os database links permitem ao `usr_NACIONALDB` aceder a tabelas remotas com sintaxe `tabela@link`, como se fossem locais. O Oracle trata a transparência de localização automaticamente.

```sql
CREATE DATABASE LINK emprestimosdb
  CONNECT TO app_nacionaldb IDENTIFIED BY "..."
  USING 'EMPRESTIMOSDB';
```

Os links ligam-se como `app_nacionaldb` — o visitor user que cada colega cria no Oracle **deles** com os privilégios mínimos para o que este nó precisa.

**Variantes:**
- **Rede local (LAN):** `emprestimosdb`, `materiaisdb`, `eventosdb` — aponta para os tnsnames locais
- **Rede remota (ZeroTier):** `zemprestimosdb`, `zmateriaisdb`, `zeventosdb` — comentados, activados conforme necessário

### 2.2 Sinónimos

Os sinónimos encapsulam os database links — o código usa `BIBLIOTECA` em vez de `biblioteca@eventosdb`. Isto significa que se o link mudar (ex: para ZeroTier), só o sinónimo muda, não todas as queries e procedures.

**Excepção crítica:** o sinónimo `BIBLIOTECA` aponta para `biblioteca_snap` (a MV local), não directamente para `@eventosdb`. Isto garante que o login funciona mesmo quando o nó do Gerson está offline.

---

## 3. Fase 1 — Estrutura Local e Fragmentação {#fase-1}

### 3.1 Tabelas e Constraints

O schema foi desenhado com hierarquia de tabelas: `LEITOR` é a tabela pai de `ADULTO`, `PROFESSOR`, `CRIANCA` (herança por subtipagem). `DOACAO` referencia `DOADOR`. Todas as relações têm constraints de FK com ON DELETE CASCADE ou RESTRICT conforme a semântica.

### 3.2 Fragmentação Vertical de LEITOR (§1.3)

Divide a tabela LEITOR por **colunas** (atributos), usando o operador de projecção (π).

| Fragmento | Colunas | Propósito |
|---|---|---|
| `vw_leitor_publico` | num_cartao, nome_completo, cod_biblioteca, status_leitor, historico_pontualidade, distancia_biblioteca | Exposto a outros nós via DB link para verificações |
| `vw_leitor_privado` | num_cartao, data_nasc, genero, nivel_escolar, localizacao_leitor, contacto, foto_path | Dados pessoais — exclusivos deste nó |

**Regras da fragmentação vertical:**
- **Completude:** cada atributo aparece em pelo menos um fragmento ✓
- **Reconstrução:** `JOIN pelo num_cartao` reconstrói LEITOR completo ✓
- **Disjuntividade:** cada atributo aparece num único fragmento, excepto `num_cartao` — a chave primária aparece em **ambos** porque é necessária para a Reconstrução ✓

---

## 4. Fase 2 — Distribuição Avançada {#fase-2}

### 4.1 Fragmentação Mista de FUNCIONARIO (§2.2)

Combina fragmentação **horizontal** (activos vs inactivos) com **vertical** (operacional vs confidencial), criando 4 fragmentos:

| Fragmento | Tipo H | Tipo V | Colunas-chave |
|---|---|---|---|
| `vw_func_activos_operacional` | data_demissao IS NULL | Operacional | cod_funcionario, nome, cod_biblioteca, nivel_acesso |
| `vw_func_activos_confidencial` | data_demissao IS NULL | Confidencial | data_nasc, endereco, senha, formacao |
| `vw_func_inactivos_operacional` | data_demissao IS NOT NULL | Operacional | cod_funcionario, nome, cod_biblioteca, nivel_acesso |
| `vw_func_inactivos_confidencial` | data_demissao IS NOT NULL | Confidencial | data_nasc, endereco, senha, formacao |

O fragmento operacional de activos é o único exposto a outros nós (via `vw_replica_funcionarios` e grants directos). Os dados confidenciais nunca saem deste nó.

### 4.2 Replicação Síncrona — prc_modificar_nivel_acesso (§2.3)

Quando o nível de acesso de um funcionário muda, a alteração tem de ser atómica em todos os nós que têm réplicas desse dado. A procedure usa transacção distribuída com **Two-Phase Commit (2PC)**:

1. **Fase PREPARE:** Oracle contacta todos os participantes e pede confirmação de que podem fazer COMMIT. Se algum responder "não" (ou não responder), a transacção é abortada globalmente.
2. **Fase COMMIT:** Todos os participantes confirmam e fazem COMMIT simultaneamente.

O Oracle gere o 2PC automaticamente quando um `COMMIT` é executado numa sessão que tem statements DML em nós remotos via DB link. O `prc_demo_2pc` demonstra este mecanismo explicitamente.

**Porquê síncrono aqui?** Uma mudança de nível de acesso tem impacto de segurança imediato. Se EmprestimosDB ficasse com uma réplica desactualizada, um funcionário demitido poderia continuar a autorizar empréstimos no outro nó. A consistência imediata é obrigatória.

### 4.3 Replicação Assíncrona — prc_sincronizar_funcionarios (§2.4)

Copia periodicamente os dados operacionais de funcionários activos para o EmprestimosDB. É assíncrona porque:
- Os dados operacionais (nome, função) mudam raramente
- Uma latência de minutos a horas é aceitável
- Evita a sobrecarga de 2PC em operações de leitura frequente no nó do Yannis

A procedure usa `MERGE INTO funcionario_replica@emprestimosdb USING (SELECT ...) ON (...) WHEN MATCHED THEN UPDATE WHEN NOT MATCHED THEN INSERT`.

### 4.4 Vistas Globais — Transparência de Localização (§2.5)

As 3 vistas globais agregam dados de múltiplos nós num único SELECT:

- `vw_global_leitores_emprestimos`: LEITOR local + EMPRESTIMO@emprestimosdb
- `vw_global_catalogo`: MATERIAL_BIBLIOGRAFICO@materiaisdb + BIBLIOTECA@eventosdb
- `vw_global_eventos_participacao`: EVENTO@eventosdb + PARTICIPACAO_EVENTO@eventosdb

O utilizador faz `SELECT * FROM vw_global_catalogo` sem saber que os dados vêm de dois nós diferentes. O Oracle resolve os DB links de forma transparente.

### 4.5 SAVEPOINTs em prc_apagar_leitor

A procedure `prc_apagar_leitor` usa SAVEPOINTs para estruturar uma operação multi-etapa com rollback granular:

```sql
SAVEPOINT inicio_apagar_leitor;
-- ... DELETE tabelas filho ...
SAVEPOINT antes_leitor_principal;
-- ... DELETE LEITOR ...
-- Se falhar:
ROLLBACK TO SAVEPOINT inicio_apagar_leitor;
```

O `prc_registar_auditoria` usa `PRAGMA AUTONOMOUS_TRANSACTION` — o registo de auditoria faz COMMIT **independentemente** da transacção principal. Se a procedure principal fizer ROLLBACK, o registo de auditoria de "tentativa falhada" fica preservado. Sem `AUTONOMOUS_TRANSACTION`, o rollback da procedure apagaria também o registo de auditoria.

### 4.6 Auditoria Nativa Oracle

Os comandos `AUDIT SELECT ON LEITOR BY SESSION;` activam a auditoria nativa do Oracle na `DBA_AUDIT_TRAIL`. Complementa a tabela manual `AUDITORIA_OPERACOES`:
- **Auditoria manual:** regista o **que** aconteceu no nível de negócio (qual doação, qual leitor)
- **Auditoria nativa:** regista o **como** no nível de sistema (qual sessão Oracle, que IP, que hora exacta)

---

## 5. Visitor Users — Segurança Cross-Node {#visitor-users}

### Porquê visitor users e não roles?

Em Oracle, **roles não funcionam através de database links**. Quando o nó do Yannis faz `SELECT status_leitor FROM leitor@nacionaldb`, a sessão remota autentica como o utilizador do DB link — e esse utilizador precisa de **grants directos** (não roles) para aceder aos objectos.

### Arquitectura least-privilege

Cada nó visitante recebe apenas o mínimo necessário:

| Visitor User | Criado por | Grants recebidos | Porquê |
|---|---|---|---|
| `app_emprestimosdb` | Helder | SELECT em vw_leitor_publico, LEITOR, UPDATE em LEITOR, SELECT em FUNCIONARIO, FUNCAO_FUNCIONARIO | RN01: verificar status_leitor antes de criar empréstimo; actualizar status após multas |
| `app_materiaisdb` | Helder | SELECT em vw_leitor_publico, LEITOR | RN09: verificar se leitor é adulto para e-books |
| `app_eventosdb` | Helder | SELECT em vw_leitor_publico, LEITOR | Verificar leitor antes de inscrever em evento |

O `app_NACIONALDB` (backend local) recebe `EXECUTE` nas procedures — os outros nós não têm acesso a procedures deste nó, apenas às tabelas e vistas necessárias.

---

## 6. Tarefa A1 — Snapshot e Materialized Views {#tarefa-a1}

### O que foi implementado

Adicionado ao `BibNacional_Snapshots.sql`:
1. Comentário explicativo completo sobre a equivalência Snapshot = Materialized View
2. Explicação de REFRESH COMPLETE vs REFRESH FAST
3. Explicação de BUILD DEFERRED vs BUILD IMMEDIATE
4. Variante comentada `biblioteca_snap_auto` com `START WITH/NEXT` para demonstração conceptual
5. Query de verificação `USER_MVIEWS`

### Porquê BUILD DEFERRED

`BUILD IMMEDIATE` executa `SELECT * FROM biblioteca@eventosdb` **no momento da criação da MV**. Se o script `BibNacional_Main.sql` for executado enquanto o nó do Gerson está offline (VM desligada, rede indisponível), o script falharia na criação da MV — e todos os objectos que dependem de `biblioteca_snap` (o sinónimo `BIBLIOTECA`) também ficariam por criar.

`BUILD DEFERRED` cria apenas a estrutura vazia. O preço é que a MV fica vazia até ao primeiro `EXEC DBMS_MVIEW.REFRESH('BIBLIOTECA_SNAP', 'C')` — mas o schema instala-se correctamente independentemente do estado do nó remoto.

### Tabela comparativa dos mecanismos de replicação

| Mecanismo | Implementação | Refresh | Consistência | Caso de uso |
|---|---|---|---|---|
| Snapshot (MV) | `biblioteca_snap` | Manual (`DBMS_MVIEW.REFRESH`) | Eventual | Resiliência do login quando Gerson está offline |
| Assíncrono (procedure) | `prc_sincronizar_funcionarios` | Periódico (MERGE manual) | Eventual | Réplica de funcionários no EmpréstimosDB |
| Síncrono (2PC) | `prc_modificar_nivel_acesso` | Imediato (no COMMIT) | Imediata | Mudança crítica de nível de acesso |

---

## 7. Tarefa A2 — Deadlock: Detecção e Prevenção {#tarefa-a2}

### O que foi implementado

Criado `BibNacional_Deadlock_Demo.sql` com:
- Cenário completo de duas sessões com DOADOR/DOACAO
- Queries V$LOCK/V$SESSION com nota sobre privilégios SYSDBA
- Procedure de prevenção `prc_atualizar_doacao_segura` (ordem consistente)
- Demonstração comentada de LOCK TABLE (prevenção por bloqueio antecipado)
- Nota sobre deadlock distribuído

### Como o deadlock se forma

```
T1 detém: DOADOR id=1    T1 pede: DOACAO id=1  → espera T2
T2 detém: DOACAO id=1    T2 pede: DOADOR id=1  → espera T1
Ciclo: T1 → T2 → T1 = deadlock
```

O Oracle detecta o ciclo através do **wait-for graph** — um grafo dirigido onde cada nó é uma transacção e cada arco representa "esta transacção está à espera que aquela liberte um lock". Um ciclo no grafo = deadlock.

### Resolução

Oracle escolhe uma "vítima" com base no custo mínimo de rollback (quantidade de undo gerado). A vítima recebe `ORA-00060: deadlock detected while waiting for resource`. O seu **último statement** é revertido automaticamente — não toda a transacção. A outra transacção recebe o lock e continua.

### Prevenção — dois métodos

**Método 1 — Ordem consistente de locks:** Se todas as transacções bloqueiam SEMPRE na mesma ordem (ex: tabela pai antes do filho — DOADOR antes de DOACAO), o ciclo nunca se forma. Esta é a abordagem implementada em `prc_atualizar_doacao_segura`.

**Método 2 — Bloqueio antecipado (LOCK TABLE):** Bloquear explicitamente todas as tabelas no início da transacção. Mais conservador — reduz concorrência mas é mais previsível.

---

## 8. Tarefa A3 — Fragmentação Horizontal de LEITOR {#tarefa-a3}

### O que foi implementado

Adicionadas ao `BibNacional_Views.sql` (nova Secção 4, antes das Vistas Globais):
- `vw_frag_leitor_activos`: WHERE STATUS_LEITOR = 'Activo'
- `vw_frag_leitor_suspensos`: WHERE STATUS_LEITOR = 'Suspenso'
- `vw_frag_leitor_inactivos`: WHERE STATUS_LEITOR NOT IN ('Activo', 'Suspenso')
- Queries de validação de Completude e Disjuntividade

Adicionados ao `BibNacional_Grants.sql` (Secção 1): GRANT SELECT nas 3 vistas a `role_NACIONALDB_read`.

### Critério de divisão

`STATUS_LEITOR` é o critério natural porque separa dados com padrões de acesso radicalmente diferentes:
- **Activos:** consultados em cada empréstimo, evento e programa — muito frequente
- **Suspensos:** consultados quando tentam emprestar — menos frequente
- **Inactivos:** só em relatórios históricos — raramente

Fragmentar por este critério coloca os dados "quentes" num fragmento menor que o optimizer pode varrer mais rapidamente, sem ler os registos históricos.

### Validação das 3 regras

**Completude:** `COUNT(LEITOR) = COUNT(H1) + COUNT(H2) + COUNT(H3)` — cada tupla aparece em exactamente um fragmento.

**Reconstrução:** `H1 UNION ALL H2 UNION ALL H3 = LEITOR` — a tabela original é reconstituível.

**Disjuntividade:** um leitor com STATUS='Activo' não pode estar em H2 ou H3 (os critérios são mutuamente exclusivos por definição). As queries de validação confirmam contagem zero nos cruzamentos.

---

## 9. Tarefa A4 — SET TRANSACTION READ ONLY {#tarefa-a4}

### O que foi implementado

Criado `BibNacional_ReadOnly_Demo.sql` com:
- Bloco completo SET TRANSACTION READ ONLY com 3 SELECTs cross-node
- Demonstração do erro ORA-01456 (DML dentro de READ ONLY)
- Comentários explicativos de ORA-01555 e segmentos de rollback

### Porquê é importante em relatórios cross-node

Sem READ ONLY, cada SELECT é uma instrução separada com o seu próprio snapshot de consistência. Entre o SELECT de LEITOR e o SELECT de EMPRESTIMO@emprestimosdb, outra sessão pode:
- Criar um novo empréstimo (o leitor aparece como "sem empréstimos" no primeiro SELECT mas "com empréstimo" no segundo)
- Suspender um leitor (aparece como "Activo" no primeiro SELECT mas o empréstimo é recusado)

O relatório combinaria dados de instantes diferentes — **inconsistência de leitura** — mesmo sem nenhum erro SQL.

Com `SET TRANSACTION READ ONLY`, todos os SELECTs vêem o estado da BD no **mesmo SCN (System Change Number)** — o instante do início da transacção.

---

## 10. Mecanismos de Replicação — Tabela Comparativa {#replicacao}

| # | Mecanismo | Implementação | Quando actualiza | Consistência | Disponibilidade offline | Caso de uso |
|---|---|---|---|---|---|---|
| 1 | **Snapshot / MV** | `biblioteca_snap` (CREATE MATERIALIZED VIEW) | Manual (DBMS_MVIEW.REFRESH) ou automático com NEXT | Eventual | Sim — a MV local funciona sem o nó remoto | Cache local de BIBLIOTECA para login e relatórios |
| 2 | **Replicação assíncrona** | `prc_sincronizar_funcionarios` (MERGE via DB link) | Chamada periódica manual | Eventual | Não — requer o nó remoto online no momento da sync | Cópia de funcionários activos para EmprestimosDB |
| 3 | **Replicação síncrona (2PC)** | `prc_modificar_nivel_acesso` (transacção distribuída) | Imediata no COMMIT | Imediata / ACID | Não — se qualquer nó participante falhar, a transacção inteira reverte | Mudança de nível de acesso com impacto de segurança |

---

## 11. Respostas às Perguntas de Validação {#perguntas-validacao}

### Tarefa A1 — REFRESH COMPLETE vs REFRESH FAST

> O `biblioteca_snap` usa `REFRESH COMPLETE ON DEMAND`. O que significa `REFRESH COMPLETE` (em oposição a `REFRESH FAST`)? Para que serve `REFRESH FAST` e o que exige do nó remoto? Porquê `REFRESH COMPLETE` é a escolha correcta para o Oracle 10g XE neste cenário?

**REFRESH COMPLETE** recalcula toda a MV do zero: executa o SELECT de base (`SELECT * FROM biblioteca@eventosdb`) e substitui todo o conteúdo da MV. É mais lento em MVs grandes mas não tem requisitos no nó remoto.

**REFRESH FAST** é incremental: aplica apenas as alterações (INSERT/UPDATE/DELETE) desde o último refresh. É muito mais eficiente para MVs grandes. Mas exige que o nó remoto tenha um **MVIEW LOG** (também chamado snapshot log) criado na tabela base: `CREATE MATERIALIZED VIEW LOG ON biblioteca`. O MVIEW LOG rastreia as linhas alteradas. Sem ele, o REFRESH FAST falha com erro.

**Porquê COMPLETE é correcto aqui:**
1. Não temos controlo sobre o schema do nó do Gerson — não podemos exigir que ele crie um MVIEW LOG
2. Oracle 10g XE tem limitações de features; REFRESH FAST é mais susceptível a erros nesta versão
3. A tabela BIBLIOTECA é pequena (poucas dezenas de bibliotecas) — o custo de REFRESH COMPLETE é negligenciável
4. A MV só precisa de refresh manual quando os dados da biblioteca mudam (raramente) — a eficiência do FAST não justifica a dependência

---

### Tarefa A2 — Escolha da vítima de deadlock

> Quando o Oracle detecta um deadlock, uma das sessões recebe ORA-00060 e a sua transacção é revertida automaticamente. A outra sessão recebe o lock e continua. Quem decide qual é a vítima? O critério é justo? Num sistema distribuído com 4 nós, como é que o grafo de esperas é construído se os locks estão em nós diferentes?

**Quem decide:** O Oracle decide de forma autónoma, sem intervenção do utilizador. O critério é minimizar o custo do rollback — a transacção que gerou menos undo (fez menos trabalho) é escolhida como vítima. Normalmente é a última transacção a completar o ciclo de espera (a que "fechou" o deadlock).

**É justo?** O critério é pragmático, não necessariamente "justo" em termos de prioridade de negócio. Uma transacção importante que fez muito trabalho pode ser vítima apenas porque foi a última a criar o ciclo. Para controlar qual transacção sobrevive, o único mecanismo é prevenir o deadlock (com ordem de locks ou LOCK TABLE antecipado), não reagir a ele.

**Deadlock distribuído:** Em sistemas com múltiplos nós, os locks estão fragmentados — o nó A sabe quem está à espera localmente, mas não sabe que o nó B está à espera do nó A. O Oracle resolve através do **coordenador 2PC**:
1. Cada nó constrói o seu subgrafo de esperas local
2. Periodicamente, o coordenador agrega os subgrafos de todos os nós participantes
3. Se o grafo agregado tiver um ciclo que cruza nós, é um deadlock distribuído
4. A detecção é significativamente mais lenta (pode demorar minutos) porque requer mensagens entre nós — contrasta com o deadlock local que é detectado em milissegundos

---

### Tarefa A3 — Disjuntividade: horizontal vs vertical

> Na fragmentação vertical de LEITOR (Fase 1, secção 1.3), a chave primária `num_cartao` aparece em ambos os fragmentos. Na fragmentação horizontal que acabaste de criar, `num_cartao` aparece apenas num fragmento. Porquê a regra da disjuntividade funciona de forma diferente nos dois tipos? O que é "um dado" em cada tipo de fragmentação?

Na **fragmentação vertical**, "um dado" é um **atributo** (coluna). A disjuntividade exige que cada atributo apareça num único fragmento — excepto a chave primária, que é a excepção explícita necessária para a Reconstrução. `num_cartao` aparece em ambos os fragmentos porque o JOIN de reconstrução precisa da chave em ambos os lados. Isto não viola a disjuntividade — é a excepção prevista pela regra.

Na **fragmentação horizontal**, "um dado" é uma **tupla** (linha). A disjuntividade exige que cada tupla apareça num único fragmento. Um leitor com STATUS='Activo' só pode estar em H1 — nunca em H2 ou H3 — porque a condição `WHERE STATUS_LEITOR = 'Activo'` e `WHERE STATUS_LEITOR = 'Suspenso'` são mutuamente exclusivas. `num_cartao` aparece num único fragmento (o fragmento correspondente ao status do leitor). Não há excepção de chave aqui porque o `UNION ALL` de reconstrução não precisa de identificar tuplas comuns entre fragmentos — cada tupla está num único fragmento por definição.

---

### Tarefa A4 — ORA-01555 e segmentos de rollback

> `SET TRANSACTION READ ONLY` garante consistência entre múltiplos SELECTs. O Oracle implementa isso usando segmentos de rollback (Tema 9.9) — vê os dados como estavam no início da transacção, usando as imagens anteriores guardadas nesses segmentos. Se a transacção read-only demorar muito tempo, o que acontece se os segmentos de rollback forem reutilizados antes do fim? Que erro o Oracle gera?

O Oracle gera **ORA-01555: snapshot too old (rollback segment too small)**.

O que acontece internamente:
1. No início do SET TRANSACTION READ ONLY, o Oracle regista o SCN actual
2. Quando faz um SELECT, usa os segmentos de rollback para reconstituir a versão dos dados nesse SCN
3. Se outro processo sobrescrever o segmento de rollback que continha a imagem anterior (porque o espaço de undo foi necessário para outra transacção), o Oracle já não consegue reconstituir a imagem
4. ORA-01555 é gerado — a transacção read-only falha

**Soluções:**
- Aumentar `UNDO_RETENTION` (parâmetro do sistema) para manter imagens anteriores por mais tempo
- Aumentar o tamanho do tablespace de undo
- Para transacções read-only muito longas: usar LOBs com `RETENTION` policy
- Redesenhar o relatório para ser mais rápido ou processar por partes

---

## Scripts Criados / Modificados

| Ficheiro | Operação | Conteúdo |
|---|---|---|
| `resources/scripts/BibNacional_Snapshots.sql` | **Editado** | Adicionada variante auto-refresh comentada + USER_MVIEWS query + comentários teóricos (Tarefa A1) |
| `resources/scripts/BibNacional_Views.sql` | **Editado** | Adicionada Secção 4 com 3 vistas de fragmentação horizontal de LEITOR + queries de validação (Tarefa A3) |
| `resources/scripts/BibNacional_Grants.sql` | **Editado** | Adicionados GRANT SELECT nas 3 novas vistas a role_NACIONALDB_read (Tarefa A3) |
| `resources/scripts/BibNacional_Deadlock_Demo.sql` | **Criado** | Demonstração completa de deadlock em 2 sessões + procedure de prevenção (Tarefa A2) |
| `resources/scripts/BibNacional_ReadOnly_Demo.sql` | **Criado** | Bloco SET TRANSACTION READ ONLY com 3 SELECTs cross-node (Tarefa A4) |
| `resources/scripts/BibNacional_Testes_Completos.sql` | **Criado** | Documento de testes geral cobrindo todas as fases (Fase Comum + 1 + 2 + A1–A4) |

---

*Relatório gerado automaticamente para defesa do Trabalho Prático BD2 — ISCTEM 2026*
