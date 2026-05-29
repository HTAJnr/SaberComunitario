-- ============================================================
-- MateriaisDB_Database_Links.sql
-- Executar como: usr_materiaisdb
-- ============================================================

-- Apagar links antigos
DROP DATABASE LINK link_emprestimosdb;
DROP DATABASE LINK link_eventosdb;
DROP DATABASE LINK link_nacionaldb;

-- Recriar com app_materiaisdb (visitor user criado por cada colega)
-- Cada colega criou app_materiaisdb no servidor deles com a password deles
CREATE DATABASE LINK link_emprestimosdb
  CONNECT TO app_materiaisdb IDENTIFIED BY "YM20240260"
  USING 'EMPRESTIMOSDB';

CREATE DATABASE LINK link_eventosdb
  CONNECT TO app_materiaisdb IDENTIFIED BY "YM20240260"
  USING 'EVENTOSDB';

CREATE DATABASE LINK link_nacionaldb
  CONNECT TO app_materiaisdb IDENTIFIED BY "YM20240260"
  USING 'NACIONALDB';

