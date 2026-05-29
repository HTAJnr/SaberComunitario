-- ============================================================
-- EventosDB_Auditoria.sql — Auditoria Oracle nativa
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: SYS AS SYSDBA
-- Executar DEPOIS de: todos os objectos criados
--
-- PRE-REQUISITO: audit_trail = 'DB' activo e BD reiniciada:
--   ALTER SYSTEM SET audit_trail = 'DB' SCOPE = SPFILE;
--   SHUTDOWN IMMEDIATE;
--   STARTUP;
-- ============================================================

-- Sessoes dos utilizadores principais e visitor users
AUDIT CREATE SESSION BY usr_eventosdb;
AUDIT CREATE SESSION BY app_eventosdb;
AUDIT CREATE SESSION BY app_nacionaldb;
AUDIT CREATE SESSION BY app_emprestimosdb;
AUDIT CREATE SESSION BY app_materiaisdb;

-- Tabelas criticas
AUDIT INSERT, UPDATE, DELETE ON usr_eventosdb.BIBLIOTECA
    BY SESSION WHENEVER SUCCESSFUL;
AUDIT INSERT, UPDATE, DELETE ON usr_eventosdb.EVENTO
    BY SESSION WHENEVER SUCCESSFUL;
AUDIT INSERT, DELETE ON usr_eventosdb.PARTICIPACAO_EVENTO
    BY SESSION WHENEVER SUCCESSFUL;

-- Tentativas falhadas de apagar bibliotecas (integridade referencial)
AUDIT DELETE ON usr_eventosdb.BIBLIOTECA
    BY SESSION WHENEVER NOT SUCCESSFUL;
