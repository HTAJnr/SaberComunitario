-- Utilizador principal
BEGIN EXECUTE IMMEDIATE 'DROP USER usr_NACIONALDB CASCADE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -1918 THEN RAISE; END IF; END;
/
CREATE USER usr_NACIONALDB IDENTIFIED BY HTAJnr#020403
  DEFAULT TABLESPACE tbs_NACIONALDB
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON tbs_NACIONALDB
  QUOTA UNLIMITED ON tbs_NACIONALDB_idx;

-- Utilizador de aplicacao (backend Node.js - usa este no .env, nunca o usr_)
BEGIN EXECUTE IMMEDIATE 'DROP USER app_NACIONALDB CASCADE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -1918 THEN RAISE; END IF; END;
/
CREATE USER app_NACIONALDB IDENTIFIED BY HTAJnr#22041
  DEFAULT TABLESPACE tbs_NACIONALDB
  TEMPORARY TABLESPACE TEMP;

-- ============================================================
-- Visitor users - utilizadores que os outros nos usam
-- quando os database links deles se ligam a este Oracle.
-- Criados aqui (SYSDBA) porque CREATE USER exige DBA.
-- Os grants ficam em BibNacional_Grants.sql Seccao 3.
-- ============================================================

-- Visitor do Yannis (EmprestimosDB) - password igual ao app_emprestimosdb dele
BEGIN EXECUTE IMMEDIATE 'DROP USER app_emprestimosdb CASCADE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -1918 THEN RAISE; END IF; END;
/
CREATE USER app_emprestimosdb IDENTIFIED BY "YC20220156"
  DEFAULT TABLESPACE tbs_NACIONALDB
  TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO app_emprestimosdb;

-- Visitor do Yasin (MateriaisDB) - password igual ao app_materiaisdb dele
BEGIN EXECUTE IMMEDIATE 'DROP USER app_materiaisdb CASCADE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -1918 THEN RAISE; END IF; END;
/
CREATE USER app_materiaisdb IDENTIFIED BY "YM20240260"
  DEFAULT TABLESPACE tbs_NACIONALDB
  TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO app_materiaisdb;

-- Visitor do Gerson (EventosBibliotecasDB) - password igual ao app_eventosdb dele
BEGIN EXECUTE IMMEDIATE 'DROP USER app_eventosdb CASCADE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -1918 THEN RAISE; END IF; END;
/
CREATE USER app_eventosdb IDENTIFIED BY "appev1234"
  DEFAULT TABLESPACE tbs_NACIONALDB
  TEMPORARY TABLESPACE TEMP;
GRANT CREATE SESSION TO app_eventosdb;
