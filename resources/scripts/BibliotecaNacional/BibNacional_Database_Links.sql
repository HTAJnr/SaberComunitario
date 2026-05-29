-- ============================================================
-- BibNacional_DatabaseLinks.sql — Drop e recriação dos database links
-- Executar como usr_NACIONALDB:
--   sqlplus usr_NACIONALDB/HTAJnr#020403 @/root/TP/BibNacional_Database_Links.sql
--
-- ============================================================

DROP DATABASE LINK materiaisdb;
DROP DATABASE LINK emprestimosdb;
DROP DATABASE LINK eventosdb;

-- Cada link conecta como app_nacionaldb — visitor user criado por cada
-- colega no Oracle deles com a mesma password do app_ deles.
CREATE DATABASE LINK materiaisdb
  CONNECT TO app_nacionaldb IDENTIFIED BY "HTAJnr#22041"
  USING 'MATERIAISDB';

CREATE DATABASE LINK emprestimosdb
  CONNECT TO app_nacionaldb IDENTIFIED BY "HTAJnr#22041"
  USING 'EMPRESTIMOSDB';

CREATE DATABASE LINK eventosdb
  CONNECT TO app_nacionaldb IDENTIFIED BY "HTAJnr#22041"
  USING 'EVENTOSDB';
