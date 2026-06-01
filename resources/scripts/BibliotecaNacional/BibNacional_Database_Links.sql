-- ============================================================
-- BibNacional_DatabaseLinks.sql — Drop e recriação dos database links
-- Pré-requisito: usr_NACIONALDB precisa de CREATE PUBLIC DATABASE LINK
--   (concedido em BibNacional_Roles.sql via sysdba)
-- Executar como usr_NACIONALDB
-- Ignora ORA-02024 (link inexistente) em primeira instalação.
-- ============================================================
DECLARE
  PROCEDURE drop_link(p_link IN VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE 'DROP PUBLIC DATABASE LINK ' || p_link;
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -2024 THEN RAISE; END IF;
  END;
BEGIN
  drop_link('materiaisdb');
  drop_link('emprestimosdb');
  drop_link('eventosdb');
END;
/

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
