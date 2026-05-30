-- ============================================================
-- EmprestimosDB_Database_Links.sql
-- Executar como: usr_emprestimosdb
-- ============================================================

DROP DATABASE LINK nacionaldb;
CREATE DATABASE LINK nacionaldb
  CONNECT TO app_emprestimosdb IDENTIFIED BY "YC20220156"
  USING 'NACIONALDB';

DROP DATABASE LINK materiaisdb;
CREATE DATABASE LINK materiaisdb
  CONNECT TO app_emprestimosdb IDENTIFIED BY "YC20220156"
  USING 'MATERIAISDB';

DROP DATABASE LINK eventosdb;
CREATE DATABASE LINK eventosdb
  CONNECT TO app_emprestimosdb IDENTIFIED BY "YC20220156"
  USING 'EVENTOSDB';
