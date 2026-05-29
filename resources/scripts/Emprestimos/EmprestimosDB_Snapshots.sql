-- ============================================================
-- EmprestimosProg_Snapshots.sql
-- Executar como usr_emprestimosdb
-- Pré-requisito: Gerson dar GRANT SELECT ON BIBLIOTECA TO app_emprestimosdb
-- ============================================================

DROP MATERIALIZED VIEW biblioteca_snap;

CREATE MATERIALIZED VIEW biblioteca_snap
  BUILD IMMEDIATE
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT * FROM biblioteca@eventosdb;
