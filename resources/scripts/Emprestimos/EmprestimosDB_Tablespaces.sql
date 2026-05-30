-- ============================================================
-- EmprestimosProgramas_Tablespaces.sql
-- ============================================================
DROP TABLESPACE tbs_emprestimosdb
  INCLUDING CONTENTS AND DATAFILES
  CASCADE CONSTRAINTS;

CREATE TABLESPACE tbs_emprestimosdb
  DATAFILE '/usr/lib/oracle/xe/oradata/XE/tbs_emprestimosdb.dbf'
  SIZE 100M
  AUTOEXTEND ON NEXT 10M MAXSIZE 500M
  EXTENT MANAGEMENT LOCAL
  SEGMENT SPACE MANAGEMENT AUTO;

DROP TABLESPACE tbs_emprestimosdb_idx
  INCLUDING CONTENTS AND DATAFILES
  CASCADE CONSTRAINTS;

CREATE TABLESPACE tbs_emprestimosdb_idx
  DATAFILE '/usr/lib/oracle/xe/oradata/XE/tbs_emprestimosdb_idx.dbf'
  SIZE 50M
  AUTOEXTEND ON NEXT 5M MAXSIZE 200M
  EXTENT MANAGEMENT LOCAL
  SEGMENT SPACE MANAGEMENT AUTO;
