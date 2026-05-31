-- ============================================================
-- EventosDB_AuditView.sql
-- Vista VW_AUDITORIA local ao EventosDB, necessária para a
-- rota GET /api/auditoria do backend.
-- Padrão idêntico ao EmprestimosDB e MateriaisDB.
-- Executar como: usr_eventosdb
-- ============================================================

CREATE OR REPLACE VIEW VW_AUDITORIA AS
SELECT
    id_auditoria,
    data_operacao,
    operacao,
    resultado,
    motivo_falha,
    nos_afetados,
    observacoes,
    'EVENTOS' AS no_origem
FROM AUDITORIA_EVENTOS;

GRANT SELECT ON VW_AUDITORIA TO app_eventosdb;
