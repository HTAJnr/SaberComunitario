-- ============================================================
-- MateriaisDB_AuditoriaNativa.sql — Auditoria Oracle nativa
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: SYS AS SYSDBA
-- Executar DEPOIS de: MateriaisDB_Create.sql
--
-- PRE-REQUISITO: audit_trail = 'DB' activo e BD reiniciada:
--   ALTER SYSTEM SET audit_trail = 'DB' SCOPE = SPFILE;
--   SHUTDOWN IMMEDIATE;
--   STARTUP;
-- ============================================================

AUDIT CREATE SESSION BY usr_materiaisdb;
AUDIT CREATE SESSION BY app_materiaisdb;

AUDIT INSERT, UPDATE, DELETE ON usr_materiaisdb.MATERIAL_BIBLIOGRAFICO
    BY SESSION WHENEVER SUCCESSFUL;
AUDIT INSERT, UPDATE, DELETE ON usr_materiaisdb.TRANSFERENCIA
    BY SESSION WHENEVER SUCCESSFUL;
AUDIT DELETE ON usr_materiaisdb.MATERIAL_BIBLIOGRAFICO
    BY SESSION WHENEVER NOT SUCCESSFUL;
AUDIT INSERT, DELETE ON usr_materiaisdb.LIVRO_FISICO  BY SESSION;
AUDIT INSERT, DELETE ON usr_materiaisdb.EBOOK         BY SESSION;
AUDIT INSERT, DELETE ON usr_materiaisdb.PERIODICO     BY SESSION;
