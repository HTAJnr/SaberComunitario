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
-- PRE-REQUISITO (1 vez, antes do primeiro install):
--   ALTER SYSTEM SET audit_trail = 'DB' SCOPE = SPFILE;
--   SHUTDOWN IMMEDIATE; STARTUP;
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
-- 5. Sinonimos publicos (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Synonyms.sql


-- ------------------------------------------------------------
-- 6. Tabelas e constraints (usr_materiaisdb)
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
-- 9. Funcoes (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Functions.sql


-- ------------------------------------------------------------
-- 10. Procedures (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Procedures.sql


-- ------------------------------------------------------------
-- 11. Triggers (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Triggers.sql


-- ------------------------------------------------------------
-- 12. Indices (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Indexes.sql


-- ------------------------------------------------------------
-- 13. GRANTs (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Grants.sql


-- ------------------------------------------------------------
-- 14. Dados iniciais (usr_materiaisdb)
-- ------------------------------------------------------------
@/root/No_MateriaisDB/MateriaisDB_Intro.sql


-- ------------------------------------------------------------
-- 15. Snapshots (so executar apos grants dos outros nos)
-- ------------------------------------------------------------
-- @/root/No_MateriaisDB/MateriaisDB_Snapshots.sql


-- ------------------------------------------------------------
-- 16. Auditoria Oracle nativa (requer SYSDBA)
-- ------------------------------------------------------------
CONNECT sys/bd2.isctem as sysdba
@/root/No_MateriaisDB/MateriaisDB_Auditoria.sql


-- ============================================================
-- FIM DA INSTALACAO
-- ============================================================
