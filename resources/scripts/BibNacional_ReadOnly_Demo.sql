-- ============================================================
-- BibNacional_ReadOnly_Demo.sql — SET TRANSACTION READ ONLY
-- Tarefa A4 — Guia BD2 Tema 9.11
--
-- CONCEITO:
--   SET TRANSACTION READ ONLY instrui o Oracle a usar um snapshot
--   consistente do estado da base de dados no momento em que a
--   instrução é executada. Todos os SELECTs subsequentes dentro
--   da mesma transacção vêem os dados nesse instante — mesmo que
--   outras transacções confirmem alterações entretanto.
--
-- PORQUÊ É IMPORTANTE EM RELATÓRIOS CROSS-NODE:
--   Sem READ ONLY, cada SELECT é uma instrução independente.
--   Entre o SELECT de LEITOR e o SELECT de EMPRESTIMO@emprestimosdb,
--   outra sessão pode inserir um empréstimo, devolver um livro, ou
--   suspender um leitor. O relatório combinaria dados de instantes
--   diferentes — inconsistência lógica, mesmo sem erros de SQL.
--
-- IMPLEMENTAÇÃO INTERNA (Tema 9.9):
--   Oracle usa segmentos de rollback (undo segments) para manter
--   as imagens anteriores dos dados. READ ONLY "congela" o SCN
--   (System Change Number) e lê sempre a versão anterior ao SCN
--   registado no início da transacção.
--
-- LIMITAÇÃO — ORA-01555 (snapshot too old):
--   Se a transacção READ ONLY demorar muito, os segmentos de rollback
--   podem ser reutilizados antes do fim. Oracle não consegue reconstruir
--   a imagem anterior e gera ORA-01555: snapshot too old.
--   Solução: aumentar UNDO_RETENTION ou usar LOBs com RetentionPolicy.
--
-- LIMITAÇÃO — SEM DML:
--   Dentro de SET TRANSACTION READ ONLY, qualquer INSERT/UPDATE/DELETE
--   falha com ORA-01456: may not perform a DML operation inside a
--   READ ONLY transaction.
--   Se for necessário escrever com base nos dados lidos, guardar em
--   variáveis e escrever numa transacção separada (COMMIT + novo BEGIN).
--
-- EXECUTAR como usr_NACIONALDB (ou app_NACIONALDB):
--   sqlplus usr_NACIONALDB/"HTAJnr#020403" @/root/TP/BibNacional_ReadOnly_Demo.sql
-- ============================================================


-- ── Terminar qualquer transacção anterior ────────────────────
COMMIT;

-- ── Iniciar transacção read-only ─────────────────────────────
SET TRANSACTION READ ONLY;

-- ── SELECT 1: Leitores activos com empréstimos em curso ──────
-- Nós: local (LEITOR) + EmprestimosDB (EMPRESTIMO via @emprestimosdb)
-- Estes dados vêem o estado da BD no momento exacto do SET TRANSACTION.
SELECT l.num_cartao,
       l.nome_completo,
       l.status_leitor,
       l.cod_biblioteca,
       e.id_emprestimo,
       e.data_retirada,
       e.prazo_devolucao
  FROM LEITOR l
  LEFT JOIN emprestimo@emprestimosdb e
         ON e.num_cartao = l.num_cartao
        AND e.data_devolucao IS NULL
 WHERE l.status_leitor = 'Activo'
 ORDER BY l.nome_completo;

-- ── SELECT 2: Materiais disponíveis no catálogo ──────────────
-- Nó: MateriaisDB (MATERIAL_BIBLIOGRAFICO via @materiaisdb)
-- Mesmo snapshot — se outro nó marcar um material como Indisponivel
-- entre o SELECT 1 e este, o relatório não vê essa alteração.
SELECT cod_material,
       titulo,
       autor,
       cod_biblioteca,
       estado_material_conservacao
  FROM material_bibliografico@materiaisdb
 WHERE estado_material_conservacao != 'Indisponivel'
 ORDER BY titulo;

-- ── SELECT 3: Resumo de leitores por biblioteca ──────────────
-- biblioteca_snap é a MV LOCAL do BibliotecaNacionalDB que replica
-- a tabela BIBLIOTECA do EventosBibliotecasDB (nó do Gerson).
-- Usar a MV local protege contra a indisponibilidade do nó remoto
-- e mantém o relatório dentro do mesmo snapshot read-only.
SELECT b.cod_biblioteca,
       b.nome_biblioteca,
       COUNT(l.num_cartao)                                    AS total_leitores,
       SUM(CASE WHEN l.status_leitor = 'Activo' THEN 1 ELSE 0 END)   AS activos,
       SUM(CASE WHEN l.status_leitor = 'Suspenso' THEN 1 ELSE 0 END) AS suspensos
  FROM biblioteca_snap b
  LEFT JOIN LEITOR l ON l.cod_biblioteca = b.cod_biblioteca
 GROUP BY b.cod_biblioteca, b.nome_biblioteca
 ORDER BY b.cod_biblioteca;

-- ── Terminar a transacção read-only ──────────────────────────
-- Liberta o snapshot de consistência e os segmentos de rollback.
-- Um COMMIT (ou ROLLBACK) é obrigatório para terminar — READ ONLY
-- não termina sozinha.
COMMIT;


-- ============================================================
-- DEMONSTRAÇÃO DO ERRO COM DML DENTRO DE READ ONLY
-- (Descomentar para ver ORA-01456 em acção — esperado)
-- ============================================================
/*
SET TRANSACTION READ ONLY;

INSERT INTO AUDITORIA_OPERACOES (
    id_auditoria, data_operacao, operacao, cod_funcionario, objeto_afetado, resultado
) VALUES (
    SEQ_AUDITORIA.NEXTVAL, SYSDATE, 'TESTE', 'USR001', 'TESTE', 'FALHOU'
);
-- ORA-01456: may not perform a DML operation inside a READ ONLY transaction

ROLLBACK;
*/
