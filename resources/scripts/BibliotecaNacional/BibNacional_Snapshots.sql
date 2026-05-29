-- ============================================================
-- BibNacional_Snapshots.sql
-- Materialized Views (snapshots) do nó BibliotecaNacionalDB.
-- Guia BD2 Tema 8.19 — parâmetros START WITH / NEXT
--
-- MV 1 — biblioteca_snap
--   Master: EventosDB (Gerson). Replica a tabela BIBLIOTECA.
--   Requer: nó do Gerson online no momento da criação.
--   Requer: app_nacionaldb com SELECT ON BIBLIOTECA no EventosDB.
--
-- MV 2 — mv_relatorio_programas
--   Master: EmprestimosDB (Yannis). Agrega programas + participantes.
--   Requer: nó do Yannis online no momento da criação.
--   Requer: app_nacionaldb com SELECT ON PROGRAMA_ALFABETIZACAO,
--           PARTICIPACAO_PROGRAMA, NIVEL_PROGRESSAO no EmprestimosDB.
--

-- ============================================================

-- ============================================================
-- MV 1: biblioteca_snap
-- ============================================================

DROP MATERIALIZED VIEW biblioteca_snap;

CREATE MATERIALIZED VIEW biblioteca_snap
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT * FROM biblioteca@eventosdb;

-- ============================================================
-- MV 2: mv_relatorio_programas
-- Agrega programas de alfabetização do EmprestimosDB com
-- contagem de participantes, concluídos e nível máximo atingido.
-- Usado para relatório de progresso cross-node no BibliotecaNacionalDB.
-- ============================================================

DROP MATERIALIZED VIEW mv_relatorio_programas;

CREATE MATERIALIZED VIEW mv_relatorio_programas
  REFRESH COMPLETE ON DEMAND
AS
SELECT p.cod_programa,
       p.nome_programa,
       p.cod_biblioteca,
       p.estado_programa,
       COUNT(pp.num_cartao)                                                         AS total_participantes,
       SUM(CASE WHEN pp.estado_participacao = 'Concluido' THEN 1 ELSE 0 END)        AS concluidos,
       SUM(CASE WHEN pp.estado_participacao = 'Activo'    THEN 1 ELSE 0 END)        AS em_curso,
       SUM(CASE WHEN pp.estado_participacao = 'Desistiu'  THEN 1 ELSE 0 END)        AS desistencias,
       MAX(np.ordem)                                                                AS nivel_maximo_atingido
  FROM PROGRAMA_ALFABETIZACAO@emprestimosdb p
  LEFT JOIN PARTICIPACAO_PROGRAMA@emprestimosdb pp
         ON pp.cod_programa = p.cod_programa
  LEFT JOIN NIVEL_PROGRESSAO@emprestimosdb np
         ON np.id_nivel    = pp.id_nivel_atual
 GROUP BY p.cod_programa, p.nome_programa, p.cod_biblioteca, p.estado_programa;
