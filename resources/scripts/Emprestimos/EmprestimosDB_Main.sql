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

-- 4. Auditoria nativa (SYSDBA)
@/root/TP/EmprestimosDB_Auditoria_SYSDBA.sql

-- Passa para o schema owner — o resto corre como usr_emprestimosdb
CONNECT usr_emprestimosdb/YC20220156

-- 5. Database Links
CREATE DATABASE LINK nacionaldb
  CONNECT TO app_emprestimosdb IDENTIFIED BY "HTAJnr#22041"
  USING 'NACIONALDB';

CREATE DATABASE LINK materiaisdb
  CONNECT TO app_emprestimosdb IDENTIFIED BY "YM20240260"
  USING 'MATERIAISDB';

CREATE DATABASE LINK eventosdb
  CONNECT TO app_emprestimosdb IDENTIFIED BY "appev1234"
  USING 'EVENTOSDB';

-- 6. Snapshots (depende dos database links)
@/root/TP/EmprestimosDB_Snapshots.sql

-- 7. Sinonimos (depende dos database links e snapshots)
@/root/TP/EmprestimosDB_Synonyms.sql

-- 8. Estruturas base (tabelas + constraints)
@/root/TP/EmprestimosDB_Create.sql

-- 9. Sequencias
@/root/TP/EmprestimosDB_Sequences.sql

-- 10. Views (inclui fragmentacao mista)
@/root/TP/EmprestimosDB_Views.sql

-- 11. Auditoria manual (tabela + procedure + VW_AUDITORIA)
@/root/TP/EmprestimosDB_Auditoria_Owner.sql

-- 12. Funcoes
@/root/TP/EmprestimosDB_Functions.sql

-- 13. Procedimentos
@/root/TP/EmprestimosDB_Procedures.sql

-- 14. Triggers
@/root/TP/EmprestimosDB_Triggers.sql

-- 15. Indices
@/root/TP/EmprestimosDB_Indexes.sql

-- 16. Grants e permissoes
@/root/TP/EmprestimosDB_Grants.sql

-- 17. Dados iniciais
@/root/TP/EmprestimosDB_Intro.sql