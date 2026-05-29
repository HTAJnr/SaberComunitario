-- ============================================================
-- EventosDB_Main.sql - Script de instalacao completo
-- No EventosBibliotecasDB - Gerson
--
-- INSTRUCOES:
-- Executa como SYSDBA:
--    sqlplus sys/bd2.isctem as sysdba @/root/TP/EventosDB_Main.sql
-- ============================================================

-- ============================================================
-- FASE 0 — DROP DE TUDO (SYSDBA)
-- ============================================================

-- Sinonimos publicos
DROP PUBLIC SYNONYM BIBLIOTECA;
DROP PUBLIC SYNONYM HORARIO_BIBLIOTECA;
DROP PUBLIC SYNONYM BIBLIOTECA_RESPONSAVEL;
DROP PUBLIC SYNONYM EVENTO;
DROP PUBLIC SYNONYM HORARIO_EVENTO;
DROP PUBLIC SYNONYM HORARIO_EV_BIB;
DROP PUBLIC SYNONYM PARTICIPACAO_EVENTO;
DROP PUBLIC SYNONYM AVALIACAO_EVENTO;
DROP PUBLIC SYNONYM EVENTO_RECURSO;
DROP PUBLIC SYNONYM AUDITORIA_EVENTOS;
DROP PUBLIC SYNONYM V_PROGRAMACAO_EVENTOS;
DROP PUBLIC SYNONYM V_HORARIOS_BIBLIOTECAS;
DROP PUBLIC SYNONYM V_BIBLIOTECAS_ACTIVAS;
DROP PUBLIC SYNONYM V_EVENTO_GLOBAL;
DROP PUBLIC SYNONYM FRAG_EVENTO_SUL;
DROP PUBLIC SYNONYM FRAG_EVENTO_CENTRO;
DROP PUBLIC SYNONYM FRAG_EVENTO_NORTE;
DROP PUBLIC SYNONYM VW_FRAG_EVENTO_FUTURO;
DROP PUBLIC SYNONYM VW_FRAG_EVENTO_PASSADO;
DROP PUBLIC SYNONYM VW_FRAG_PARTICIPACAO_FUTURO;
DROP PUBLIC SYNONYM VW_FRAG_PARTICIPACAO_PASSADO;
DROP PUBLIC SYNONYM REPL_FUNCIONARIOS;

-- Visitor users
DROP USER app_nacionaldb    CASCADE;
DROP USER app_emprestimosdb CASCADE;
DROP USER app_materiaisdb   CASCADE;

-- Passa para usr_eventosdb
CONNECT usr_eventosdb/eventos1234

-- Snapshots
DROP MATERIALIZED VIEW repl_funcionarios;

-- Views
DROP VIEW vw_frag_evento_futuro;
DROP VIEW vw_frag_evento_passado;
DROP VIEW vw_frag_participacao_futuro;
DROP VIEW vw_frag_participacao_passado;
DROP VIEW v_programacao_eventos;
DROP VIEW v_horarios_bibliotecas;
DROP VIEW v_bibliotecas_activas;
DROP VIEW frag_evento_sul;
DROP VIEW frag_evento_centro;
DROP VIEW frag_evento_norte;
DROP VIEW v_evento_global;

-- Triggers
DROP TRIGGER trg_valida_horario_evento;
DROP TRIGGER trg_protege_delete_evento;

-- Sequencias
DROP SEQUENCE SEQ_AUDITORIA_EVT;
DROP SEQUENCE SEQ_EVENTO;
DROP SEQUENCE SEQ_HORARIO_EVENTO;

-- Database links (apenas Nacional e Materiais)
DROP DATABASE LINK link_nacionaldb;
DROP DATABASE LINK link_materiaisdb;

-- Tabelas (filhas primeiro, pai por ultimo)
DROP TABLE AUDITORIA_EVENTOS;
DROP TABLE EVENTO_RECURSO;
DROP TABLE AVALIACAO_EVENTO;
DROP TABLE PARTICIPACAO_EVENTO;
DROP TABLE HORARIO_EVENTO;
DROP TABLE HORARIO_BIBLIOTECA;
DROP TABLE BIBLIOTECA_RESPONSAVEL;
DROP TABLE EVENTO;
DROP TABLE BIBLIOTECA;

-- Limpar recyclebin
PURGE RECYCLEBIN;

-- ============================================================
-- VERIFICACAO POS-DROP (tudo deve ser 0)
-- ============================================================
PROMPT ============================================
PROMPT Verificacao pos-DROP
PROMPT ============================================

SELECT
    (SELECT COUNT(*) FROM USER_TABLES
     WHERE TABLE_NAME IN (
        'BIBLIOTECA','HORARIO_BIBLIOTECA','BIBLIOTECA_RESPONSAVEL',
        'EVENTO','HORARIO_EVENTO','PARTICIPACAO_EVENTO',
        'AVALIACAO_EVENTO','EVENTO_RECURSO','AUDITORIA_EVENTOS'
     )) AS TABELAS,
    (SELECT COUNT(*) FROM USER_VIEWS
     WHERE VIEW_NAME IN (
        'FRAG_EVENTO_SUL','FRAG_EVENTO_CENTRO','FRAG_EVENTO_NORTE',
        'V_EVENTO_GLOBAL','V_PROGRAMACAO_EVENTOS',
        'V_HORARIOS_BIBLIOTECAS','V_BIBLIOTECAS_ACTIVAS',
        'VW_FRAG_EVENTO_FUTURO','VW_FRAG_EVENTO_PASSADO',
        'VW_FRAG_PARTICIPACAO_FUTURO','VW_FRAG_PARTICIPACAO_PASSADO'
     )) AS VISTAS,
    (SELECT COUNT(*) FROM USER_OBJECTS
     WHERE OBJECT_TYPE = 'TRIGGER'
     AND OBJECT_NAME IN (
        'TRG_VALIDA_HORARIO_EVENTO','TRG_PROTEGE_DELETE_EVENTO'
     )) AS TRIGGERS,
    (SELECT COUNT(*) FROM USER_OBJECTS
     WHERE OBJECT_TYPE = 'SEQUENCE'
     AND OBJECT_NAME IN (
        'SEQ_AUDITORIA_EVT','SEQ_EVENTO','SEQ_HORARIO_EVENTO'
     )) AS SEQUENCIAS,
    (SELECT COUNT(*) FROM USER_DB_LINKS
     WHERE DB_LINK IN (
        'LINK_MATERIAISDB','LINK_NACIONALDB'
     )) AS DB_LINKS,
    (SELECT COUNT(*) FROM USER_MVIEWS) AS SNAPSHOTS
FROM DUAL;

PROMPT Se tudo 0, continuar. Caso contrario parar e fazer DROP manual.
PROMPT ============================================

-- ============================================================
-- FASE 1 — RECRIAR (usr_eventosdb)
-- ============================================================

-- 1. Database Links (apenas Nacional e Materiais)
@/root/TP/EventosDB_Database_Links.sql

-- 2. Tabelas e constraints
@/root/TP/EventosDB_Create.sql

-- 3. Sequencias
@/root/TP/EventosDB_Sequences.sql

-- 4. Indices
@/root/TP/EventosDB_Indexes.sql

-- 5. Vistas de fragmento e servico
@/root/TP/EventosDB_Views.sql

-- 6. Vistas de fragmentacao adicional (A1 e A2)
@/root/TP/EventosDB_Fragmentacao_Extra.sql

-- 7. Funcoes
@/root/TP/EventosDB_Functions.sql

-- 8. Procedures
@/root/TP/EventosDB_Procedures.sql

-- 9. Triggers
@/root/TP/EventosDB_Triggers.sql

-- 10. Grants para app_eventosdb
@/root/TP/EventosDB_Grants.sql

-- 11. Dados iniciais de bibliotecas
@/root/TP/EventosDB_Intro.sql

-- 12. Snapshot de FUNCIONARIO (so executar apos grant do Helder)
-- @/root/TP/EventosDB_Snapshots.sql

-- ============================================================
-- FASE 2 — VISITOR USERS, SINONIMOS E GRANTS (SYSDBA)
-- ============================================================
CONNECT sys/bd2.isctem as sysdba

-- 13. Visitor users
@/root/TP/EventosDB_Visitor_Users.sql

-- 14. Sinonimos publicos
@/root/TP/EventosDB_Synonyms.sql

-- 15. Grants para visitor users
CONNECT usr_eventosdb/eventos1234
@/root/TP/EventosDB_Visitor_Grants.sql

-- ============================================================
-- VERIFICACAO FINAL
-- ============================================================
CONNECT sys/bd2.isctem as sysdba

PROMPT ============================================
PROMPT Verificacao final pos-INSTALACAO
PROMPT ============================================

SELECT
    (SELECT COUNT(*) FROM DBA_TABLES
     WHERE OWNER = 'USR_EVENTOSDB') AS TABELAS,
    (SELECT COUNT(*) FROM DBA_VIEWS
     WHERE OWNER = 'USR_EVENTOSDB') AS VISTAS,
    (SELECT COUNT(*) FROM DBA_OBJECTS
     WHERE OWNER = 'USR_EVENTOSDB'
     AND OBJECT_TYPE = 'TRIGGER') AS TRIGGERS,
    (SELECT COUNT(*) FROM DBA_OBJECTS
     WHERE OWNER = 'USR_EVENTOSDB'
     AND OBJECT_TYPE = 'SEQUENCE') AS SEQUENCIAS,
    (SELECT COUNT(*) FROM DBA_INDEXES
     WHERE OWNER = 'USR_EVENTOSDB'
     AND TABLESPACE_NAME = 'TBS_EVENTOSDB_IDX') AS INDICES,
    (SELECT COUNT(*) FROM DBA_DB_LINKS
     WHERE OWNER = 'USR_EVENTOSDB') AS DB_LINKS,
    (SELECT COUNT(*) FROM DBA_SYNONYMS
     WHERE TABLE_OWNER = 'USR_EVENTOSDB') AS SINONIMOS,
    (SELECT COUNT(*) FROM DBA_USERS
     WHERE USERNAME IN (
        'APP_NACIONALDB','APP_EMPRESTIMOSDB','APP_MATERIAISDB'
     )) AS VISITOR_USERS,
    (SELECT COUNT(*) FROM DBA_MVIEWS
     WHERE OWNER = 'USR_EVENTOSDB') AS SNAPSHOTS
FROM DUAL;

PROMPT ============================================
PROMPT Instalacao do No EventosBibliotecasDB concluida
PROMPT ============================================