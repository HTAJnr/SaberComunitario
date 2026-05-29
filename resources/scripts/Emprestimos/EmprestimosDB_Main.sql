-- ============================================================
-- EmprestimosDB_Main.sql — Script de instalacao completo
-- Executar como SYSDBA:
--   sqlplus / as sysdba @/root/TP/EmprestimosDB_Main.sql
-- ============================================================

-- 1. Tablespaces
@/root/TP/EmprestimosDB_Tablespaces.sql

-- 2. Utilizadores
@/root/TP/EmprestimosDB_Users.sql

-- 3. Roles, privilegios e visitor users
@/root/TP/EmprestimosDB_Roles.sql

-- Passa para o schema owner — o resto corre como usr_emprestimosdb
CONNECT usr_emprestimosdb/YC20220156

-- 4. Database Links
@/root/TP/EmprestimosDB_Database_Links.sql

-- 5. Snapshots (depende dos database links)
@/root/TP/EmprestimosDB_Snapshots.sql

-- 6. Sinonimos (depende dos database links e snapshots)
@/root/TP/EmprestimosDB_Synonyms.sql

-- 7. Estruturas base (tabelas + constraints, inclui AUDITORIA_EMPRESTIMOS)
@/root/TP/EmprestimosDB_Create.sql

-- 8. Sequencias (inclui SEQ_AUDITORIA_EMP)
@/root/TP/EmprestimosDB_Sequences.sql

-- 9. Views (inclui fragmentacao mista e VW_AUDITORIA)
@/root/TP/EmprestimosDB_Views.sql

-- 10. Funcoes
@/root/TP/EmprestimosDB_Functions.sql

-- 11. Procedimentos (inclui prc_registar_auditoria)
@/root/TP/EmprestimosDB_Procedures.sql

-- 12. Triggers
@/root/TP/EmprestimosDB_Triggers.sql

-- 13. Indices (inclui indices de AUDITORIA_EMPRESTIMOS)
@/root/TP/EmprestimosDB_Indexes.sql

-- 14. Grants e permissoes
@/root/TP/EmprestimosDB_Grants.sql

-- 15. Dados iniciais
@/root/TP/EmprestimosDB_Intro.sql

-- 16. Auditoria Oracle nativa (requer SYSDBA — volta a ligar como sys)
CONNECT sys as sysdba
@/root/TP/EmprestimosDB_Auditoria.sql
