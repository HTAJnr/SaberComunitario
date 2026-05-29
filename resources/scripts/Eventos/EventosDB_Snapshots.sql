-- ============================================================
-- SNAPSHOTS (MATERIALIZED VIEWS) - EventosBibliotecasDB (v4)
-- Executar como usr_eventosdb
-- Pré-requisito: Hélder deve ter dado
--   GRANT SELECT ON vw_replica_funcionarios TO app_eventosdb
-- ============================================================

-- Snapshot de FUNCIONARIO do BibliotecaNacionalDB
-- Actualiza a cada hora (SYSDATE + 1/24)
-- Se o Hélder estiver offline, os dados locais continuam disponíveis

CREATE MATERIALIZED VIEW repl_funcionarios
    REFRESH COMPLETE
    START WITH SYSDATE
    NEXT SYSDATE + 1/24
AS
SELECT cod_funcionario, nome_funcionario,
       cod_biblioteca, nivel_acesso
FROM vw_replica_funcionarios@link_nacionaldb;
