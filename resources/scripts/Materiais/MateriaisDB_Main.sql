-- ============================================================
-- MateriaisDB_Main.sql — Script de instalacao completo
-- No MateriaisDB — Sistema de Gestao de Bibliotecas Comunitarias Distribuido
--
-- Executar como SYSDBA:
--   sqlplus sys/bd2.isctem as sysdba @/root/No_MateriaisDB/MateriaisDB_Main.sql
--
-- IMPORTANTE: Definir charset antes de executar:
--   export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
--
-- PRE-REQUISITO — Auditoria Oracle nativa (1 vez):
--   1. ALTER SYSTEM SET audit_trail = 'DB' SCOPE = SPFILE;
--   2. SHUTDOWN IMMEDIATE;
--   3. STARTUP;
--   4. sqlplus sys/bd2.isctem as sysdba @/root/No_MateriaisDB/MateriaisDB_AuditoriaNativa.sql
-- ============================================================


-- ------------------------------------------------------------
-- 1. Tablespaces (SYS)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Tablespaces.sql


-- ------------------------------------------------------------
-- 2. Utilizadores e Visitor Users (SYS)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Users.sql


-- ------------------------------------------------------------
-- 3. Roles e permissoes (SYS)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Roles.sql


-- ------------------------------------------------------------
-- Passa para o schema owner
-- ------------------------------------------------------------
CONNECT usr_materiaisdb/YM20240260


-- ------------------------------------------------------------
-- 4. Database Links (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Database_Links.sql


-- ------------------------------------------------------------
-- 5. Sinonimos publicos — remotos e locais (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Synonyms.sql


-- ------------------------------------------------------------
-- 6. Tabelas, constraints e indices (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Create.sql


-- ------------------------------------------------------------
-- 7. Sequencias (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Sequences.sql


-- ------------------------------------------------------------
-- 8. Vistas (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Views.sql


-- ------------------------------------------------------------
-- 9. Procedures (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Procedures.sql


-- ------------------------------------------------------------
-- 10. Triggers (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Triggers.sql


-- ------------------------------------------------------------
-- 11. GRANTs (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Grants.sql


-- ------------------------------------------------------------
-- 12. Dados iniciais (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Intro.sql


-- ------------------------------------------------------------
-- Scripts de manutencao (NAO fazem parte da instalacao)
--
-- Auditoria nativa (1 vez, apos activar audit_trail=DB):
--   sqlplus sys/bd2.isctem as sysdba @/root/No_MateriaisDB/MateriaisDB_AuditoriaNativa.sql
--
-- Snapshots (quando nos remotos estiverem disponiveis):
--   sqlplus usr_materiaisdb/YM20240260 @/root/No_MateriaisDB/MateriaisDB_Snapshots.sql
--
-- Backup:
--   sqlplus sys/bd2.isctem as sysdba @/root/No_MateriaisDB/MateriaisDB_Backup.sql
--
-- Recovery:
--   sqlplus sys/bd2.isctem as sysdba @/root/No_MateriaisDB/MateriaisDB_Recovery.sql
--
-- Limpeza completa:
--   sqlplus usr_materiaisdb/YM20240260 @/root/No_MateriaisDB/MateriaisDB_Drop.sql
-- ------------------------------------------------------------


-- ------------------------------------------------------------
-- FIM DA INSTALACAO
-- ============================================================
