-- ============================================================
-- EmprestimosProg_Auditoria_SYSDBA.sql
-- Executar como SYSDBA
-- ============================================================
AUDIT CREATE SESSION BY usr_emprestimosdb;
AUDIT CREATE SESSION BY app_emprestimosdb;

AUDIT INSERT, UPDATE, DELETE ON usr_emprestimosdb.EMPRESTIMO
    BY SESSION WHENEVER SUCCESSFUL;
AUDIT INSERT, UPDATE, DELETE ON usr_emprestimosdb.SUSPENSAO
    BY SESSION WHENEVER SUCCESSFUL;
AUDIT DELETE ON usr_emprestimosdb.EMPRESTIMO
    BY SESSION WHENEVER NOT SUCCESSFUL;

