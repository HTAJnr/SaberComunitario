-- ============================================================
-- EmprestimosDB_Database_Links.sql
-- Executar como: usr_emprestimosdb
-- ============================================================

CREATE DATABASE LINK nacionaldb
  CONNECT TO app_emprestimosdb IDENTIFIED BY "HTAJnr#22041"
  USING 'NACIONALDB';

CREATE DATABASE LINK materiaisdb
  CONNECT TO app_emprestimosdb IDENTIFIED BY "YM20240260"
  USING 'MATERIAISDB';

CREATE DATABASE LINK eventosdb
  CONNECT TO app_emprestimosdb IDENTIFIED BY "appev1234"
  USING 'EVENTOSDB';
