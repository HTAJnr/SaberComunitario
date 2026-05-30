-- ============================================================
-- BibNacional_DatabaseLinks.sql — Drop e recriação dos database links
-- Pré-requisito: usr_NACIONALDB precisa de CREATE PUBLIC DATABASE LINK
--   (concedido em BibNacional_Roles.sql via sysdba)
-- Executar como usr_NACIONALDB:
--   sqlplus usr_NACIONALDB/HTAJnr#020403 @/root/TP/BibNacional_Database_Links.sql
--
-- Links são PUBLIC para que app_NACIONALDB (user da aplicação) os resolva.
-- Os PUBLIC synonyms (BibNacional_Synonyms.sql) dependem disto.
-- ============================================================

DROP PUBLIC DATABASE LINK materiaisdb;
DROP PUBLIC DATABASE LINK emprestimosdb;
DROP PUBLIC DATABASE LINK eventosdb;

-- Cada link conecta como app_nacionaldb — visitor user criado por cada
-- colega no Oracle deles com a mesma password do app_ deles.
CREATE PUBLIC DATABASE LINK materiaisdb
  CONNECT TO app_nacionaldb IDENTIFIED BY "HTAJnr#22041"
  USING 'MATERIAISDB';

CREATE PUBLIC DATABASE LINK emprestimosdb
  CONNECT TO app_nacionaldb IDENTIFIED BY "HTAJnr#22041"
  USING 'EMPRESTIMOSDB';

CREATE PUBLIC DATABASE LINK eventosdb
  CONNECT TO app_nacionaldb IDENTIFIED BY "HTAJnr#22041"
  USING 'EVENTOSDB';
