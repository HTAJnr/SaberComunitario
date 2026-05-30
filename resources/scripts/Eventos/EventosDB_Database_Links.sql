-- ============================================================
-- EventosDB_Database_Links.sql
-- Pré-requisito: usr_eventosdb precisa de CREATE PUBLIC DATABASE LINK
--   (concedido em EventosDB_Roles.sql via sysdba)
-- Executar como: usr_eventosdb
-- ============================================================

DROP PUBLIC DATABASE LINK link_nacionaldb;
DROP PUBLIC DATABASE LINK link_materiaisdb;
DROP PUBLIC DATABASE LINK link_emprestimosdb;

CREATE PUBLIC DATABASE LINK link_nacionaldb
  CONNECT TO app_eventosdb IDENTIFIED BY "appev1234"
  USING 'NACIONALDB';

CREATE PUBLIC DATABASE LINK link_materiaisdb
  CONNECT TO app_eventosdb IDENTIFIED BY "appev1234"
  USING 'MATERIAISDB';

CREATE PUBLIC DATABASE LINK link_emprestimosdb
  CONNECT TO app_eventosdb IDENTIFIED BY "appev1234"
  USING 'EMPRESTIMOSDB';
