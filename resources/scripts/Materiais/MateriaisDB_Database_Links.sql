-- ============================================================
-- MateriaisDB_Database_Links.sql
-- Pré-requisito: usr_materiaisdb precisa de CREATE PUBLIC DATABASE LINK
--   (concedido em MateriaisDB_Roles.sql via sysdba)
-- Executar como: usr_materiaisdb
-- ============================================================

DROP PUBLIC DATABASE LINK link_emprestimosdb;
DROP PUBLIC DATABASE LINK link_eventosdb;
DROP PUBLIC DATABASE LINK link_nacionaldb;

CREATE PUBLIC DATABASE LINK link_emprestimosdb
  CONNECT TO app_materiaisdb IDENTIFIED BY "YM20240260"
  USING 'EMPRESTIMOSDB';

CREATE PUBLIC DATABASE LINK link_eventosdb
  CONNECT TO app_materiaisdb IDENTIFIED BY "YM20240260"
  USING 'EVENTOSDB';

CREATE PUBLIC DATABASE LINK link_nacionaldb
  CONNECT TO app_materiaisdb IDENTIFIED BY "YM20240260"
  USING 'NACIONALDB';
