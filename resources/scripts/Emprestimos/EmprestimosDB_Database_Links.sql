-- ============================================================
-- EmprestimosDB_Database_Links.sql
-- Pré-requisito: usr_emprestimosdb precisa de CREATE PUBLIC DATABASE LINK
--   (concedido em EmprestimosDB_Roles.sql via sysdba)
-- Executar como: usr_emprestimosdb
-- ============================================================

DROP PUBLIC DATABASE LINK nacionaldb;
DROP PUBLIC DATABASE LINK materiaisdb;
DROP PUBLIC DATABASE LINK eventosdb;

CREATE PUBLIC DATABASE LINK nacionaldb
  CONNECT TO app_emprestimosdb IDENTIFIED BY "YC20220156"
  USING 'NACIONALDB';

CREATE PUBLIC DATABASE LINK materiaisdb
  CONNECT TO app_emprestimosdb IDENTIFIED BY "YC20220156"
  USING 'MATERIAISDB';

CREATE PUBLIC DATABASE LINK eventosdb
  CONNECT TO app_emprestimosdb IDENTIFIED BY "YC20220156"
  USING 'EVENTOSDB';
