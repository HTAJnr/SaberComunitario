-- ============================================================
-- MateriaisDB_Tablespaces.sql
-- Executar como SYSDBA
-- Ignora ORA-00959 (tablespace inexistente) em primeira instalação.
-- ============================================================
DECLARE
  PROCEDURE drop_ts(p_ts IN VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLESPACE ' || p_ts
        || ' INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS';
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -959 THEN RAISE; END IF;
  END;
BEGIN
  drop_ts('tbs_MATERIAISDB');
  drop_ts('tbs_MATERIAISDB_idx');
END;
/

CREATE TABLESPACE tbs_MATERIAISDB
  DATAFILE '/usr/lib/oracle/xe/oradata/XE/tbs_MATERIAISDB.dbf'
  SIZE 100M
  AUTOEXTEND ON NEXT 10M MAXSIZE 500M
  EXTENT MANAGEMENT LOCAL
  SEGMENT SPACE MANAGEMENT AUTO;

CREATE TABLESPACE tbs_MATERIAISDB_idx
  DATAFILE '/usr/lib/oracle/xe/oradata/XE/tbs_MATERIAISDB_idx.dbf'
  SIZE 50M
  AUTOEXTEND ON NEXT 5M MAXSIZE 200M
  EXTENT MANAGEMENT LOCAL
  SEGMENT SPACE MANAGEMENT AUTO;
