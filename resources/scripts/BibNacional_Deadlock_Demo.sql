-- ============================================================
-- BibNacional_Deadlock_Demo.sql — Demonstração de Deadlock
-- Tarefa A2 — Guia BD2 Temas 9.16–9.19
--
-- CONCEITO:
--   Deadlock = duas transacções mutuamente bloqueadas.
--   T1 detém lock em A e quer B. T2 detém lock em B e quer A.
--   Ciclo no grafo de esperas (wait-for graph) → sem saída.
--   Oracle detecta o ciclo automaticamente e escolhe uma "vítima"
--   para ROLLBACK automático (a outra recebe ORA-00060).
--
-- CRITÉRIO DE ESCOLHA DA VÍTIMA:
--   Oracle escolhe minimizar o custo do rollback — normalmente
--   a transacção que fez menos trabalho (menos undo gerado).
--   O critério NÃO é aleatório nem baseado em prioridade do utilizador.
--
-- NOTA SOBRE V$LOCK / V$SESSION:
--   Estas views de performance requerem privilégio SELECT que
--   usr_NACIONALDB não tem por defeito.
--   Para conceder (correr como SYSDBA):
--     GRANT SELECT ON V_$LOCK    TO usr_NACIONALDB;
--     GRANT SELECT ON V_$SESSION TO usr_NACIONALDB;
--   (Note: o nome base para GRANT usa underscore: V_$LOCK, V_$SESSION)
--   Em alternativa, as queries de verificação podem correr directamente
--   numa sessão SYSDBA enquanto o deadlock está activo.
--
-- COMO EXECUTAR:
--   Abrir 3 janelas de SQL*Plus.
--   Seguir os passos numerados na ordem indicada.
-- ============================================================


-- ============================================================
-- PRÉ-REQUISITO: garantir que existem linhas nas tabelas
-- (correr numa sessão qualquer como usr_NACIONALDB)
-- ============================================================
-- Verificar dados existentes:
SELECT id_doador, nome_doador FROM DOADOR WHERE ROWNUM <= 3;
SELECT id_doacao, id_doador   FROM DOACAO  WHERE ROWNUM <= 3;


-- ============================================================
-- PASSO 1 — SESSÃO 1 (SQL*Plus #1)
-- T1 bloqueia a linha 1 de DOADOR
-- NÃO fazer COMMIT — o lock deve ficar activo
-- ============================================================
-- (Executar na Sessão 1)
UPDATE DOADOR SET contacto = contacto WHERE id_doador = 1;
-- Resultado esperado: "1 row updated." — lock exclusivo em DOADOR id=1


-- ============================================================
-- PASSO 2 — SESSÃO 2 (SQL*Plus #2)
-- T2 bloqueia a linha 1 de DOACAO
-- NÃO fazer COMMIT — o lock deve ficar activo
-- ============================================================
-- (Executar na Sessão 2)
UPDATE DOACAO SET data_doacao = SYSDATE WHERE id_doacao = 1;
-- Resultado esperado: "1 row updated." — lock exclusivo em DOACAO id=1


-- ============================================================
-- PASSO 3 — SESSÃO 3 (SQL*Plus #3, sysdba ou com grants)
-- Verificar os locks activos enquanto T1 e T2 ainda não se cruzaram
-- ============================================================
-- (Executar na Sessão 3 — requer SELECT em V_$LOCK e V_$SESSION)
SELECT s.SID,
       s.SERIAL#,
       s.USERNAME,
       l.TYPE,
       l.LMODE,     -- modo detido: 3=ROW SHARE, 6=EXCLUSIVE
       l.REQUEST,   -- modo pedido: 0=nenhum, 6=EXCLUSIVE
       l.BLOCK      -- 1 se esta sessão está a bloquear outra
  FROM V$SESSION s
  JOIN V$LOCK l ON s.SID = l.SID
 WHERE l.TYPE = 'TM'   -- table locks (nível de tabela)
    OR l.TYPE = 'TX'   -- transaction locks (nível de linha)
 ORDER BY s.SID;
-- Output esperado: duas sessões, cada uma com LMODE=6, REQUEST=0, BLOCK=1


-- ============================================================
-- PASSO 4 — SESSÃO 1 — T1 pede lock que T2 já detém (ESPERA)
-- ============================================================
-- (Executar na Sessão 1 — vai BLOQUEAR e esperar)
UPDATE DOACAO SET data_doacao = SYSDATE WHERE id_doacao = 1;
-- T1 fica à espera: T2 tem lock exclusivo em DOACAO id=1.
-- O cursor não volta — a sessão está suspensa.


-- ============================================================
-- PASSO 5 — SESSÃO 2 — T2 pede lock que T1 já detém (DEADLOCK)
-- ============================================================
-- (Executar na Sessão 2 — Oracle detecta o ciclo imediatamente)
UPDATE DOADOR SET contacto = contacto WHERE id_doador = 1;
-- Output esperado:
--   ORA-00060: deadlock detected while waiting for resource
--
-- O que acontece:
--   Oracle detectou o ciclo: T1 → T2 → T1 = deadlock.
--   Escolheu T2 como vítima (a última a criar o ciclo = menos undo).
--   T2 recebe ORA-00060, o seu último UPDATE é revertido (só o UPDATE,
--   não toda a transacção — T2 ainda tem o lock em DOACAO id=1).
--   T1 desbloqueou e o seu UPDATE em DOACAO é concedido e completa.


-- ============================================================
-- PASSO 6 — LIMPEZA (executar em ambas as sessões)
-- ============================================================
-- (Sessão 1 — commit da transacção que sobreviveu)
COMMIT;
-- (Sessão 2 — rollback da transacção vítima)
ROLLBACK;


-- ============================================================
-- PREVENÇÃO — MÉTODO 1: Ordem consistente de bloqueio
-- Implementada em prc_atualizar_doacao_segura (BibNacional_Procedures.sql).
-- EXEC prc_atualizar_doacao_segura(1, 1);

-- ============================================================
-- PREVENÇÃO — MÉTODO 2: Bloqueio antecipado (LOCK TABLE)
-- Bloquear tudo no início da transacção, antes de qualquer DML.
-- Mais conservador — reduz concorrência mas elimina deadlocks.
-- ============================================================
/*
BEGIN
    LOCK TABLE DOADOR IN EXCLUSIVE MODE;
    LOCK TABLE DOACAO IN EXCLUSIVE MODE;
    -- agora fazer todos os UPDATEs sem risco de deadlock
    UPDATE DOADOR SET contacto = contacto WHERE id_doador = 1;
    UPDATE DOACAO SET data_doacao = SYSDATE WHERE id_doacao = 1;
    COMMIT;
END;
/
*/

-- ============================================================
-- NOTA SOBRE DEADLOCK DISTRIBUÍDO (sistemas multi-nó)
-- Em sistemas com múltiplos nós Oracle, os locks estão espalhados.
-- O grafo de esperas está fragmentado — cada nó só vê a sua parte.
-- O Oracle resolve via o coordenador 2PC, que agrega os grafos
-- parciais de cada participante. A detecção é mais lenta (pode
-- demorar minutos) porque exige comunicação entre nós.
-- ============================================================
