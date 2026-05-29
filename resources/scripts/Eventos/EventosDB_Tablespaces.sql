-- ============================================
-- TABLESPACES - EventosBibliotecasDB
-- Executar como SYSDBA
-- ============================================
CREATE TABLESPACE tbs_eventosdb
    DATAFILE '/usr/lib/oracle/xe/oradata/XE/tbs_eventosdb.dbf'
    SIZE 100M
    AUTOEXTEND ON NEXT 10M MAXSIZE 500M
    EXTENT MANAGEMENT LOCAL
    SEGMENT SPACE MANAGEMENT AUTO;

CREATE TABLESPACE tbs_eventosdb_idx
    DATAFILE '/usr/lib/oracle/xe/oradata/XE/tbs_eventosdb_idx.dbf'
    SIZE 50M
    AUTOEXTEND ON NEXT 5M MAXSIZE 200M
    EXTENT MANAGEMENT LOCAL
    SEGMENT SPACE MANAGEMENT AUTO;
