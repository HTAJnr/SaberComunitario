-- ============================================================
-- EventosDB_Main.sql — Script de instalacao completo (v5)
-- No EventosBibliotecasDB — Sistema de Gestao de Bibliotecas Comunitarias Distribuido
--
-- Executar como SYSDBA:
--   sqlplus sys/bd2.isctem as sysdba @/root/TP/EventosDB_Main.sql
--
-- PRE-REQUISITO (1 vez, antes do primeiro install):
--   ALTER SYSTEM SET audit_trail = 'DB' SCOPE = SPFILE;
--   SHUTDOWN IMMEDIATE; STARTUP;
-- ============================================================


-- ============================================================
-- FASE 0A — LIMPEZA DE SINONIMOS PUBLICOS (SYSDBA)
-- ============================================================

DROP PUBLIC SYNONYM BIBLIOTECA;
DROP PUBLIC SYNONYM HORARIO_BIBLIOTECA;
DROP PUBLIC SYNONYM BIBLIOTECA_RESPONSAVEL;
DROP PUBLIC SYNONYM EVENTO;
DROP PUBLIC SYNONYM HORARIO_EVENTO;
DROP PUBLIC SYNONYM PARTICIPACAO_EVENTO;
DROP PUBLIC SYNONYM AVALIACAO_EVENTO;
DROP PUBLIC SYNONYM EVENTO_RECURSO;
DROP PUBLIC SYNONYM AUDITORIA_EVENTOS;
DROP PUBLIC SYNONYM REPL_FUNCIONARIOS;
DROP PUBLIC SYNONYM SNAP_LEITOR;
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
DROP PUBLIC SYNONYM VW_EVENTOS_PROXIMOS;
DROP PUBLIC SYNONYM VW_EVENTOS_COMPLETOS;


-- ============================================================
-- FASE 0B — LIMPEZA DO SCHEMA (como usr_eventosdb)
-- ============================================================
CONNECT usr_eventosdb/eventos1234

-- Materialized Views (snapshots)
DROP MATERIALIZED VIEW repl_funcionarios;
DROP MATERIALIZED VIEW snap_leitor;

-- Triggers
DROP TRIGGER trg_valida_horario_evento;
DROP TRIGGER trg_protege_delete_evento;
DROP TRIGGER trg_avaliacao_id;
DROP TRIGGER trg_recurso_id;

-- Procedures
DROP PROCEDURE insere_participacao_evento;

-- Vistas (dependentes primeiro)
DROP VIEW vw_frag_participacao_passado;
DROP VIEW vw_frag_participacao_futuro;
DROP VIEW vw_frag_evento_passado;
DROP VIEW vw_frag_evento_futuro;
DROP VIEW vw_eventos_completos;
DROP VIEW vw_eventos_proximos;
DROP VIEW v_evento_global;
DROP VIEW frag_evento_norte;
DROP VIEW frag_evento_centro;
DROP VIEW frag_evento_sul;
DROP VIEW v_programacao_eventos;
DROP VIEW v_horarios_bibliotecas;
DROP VIEW v_bibliotecas_activas;

-- Tabela placeholder do snapshot (se existir de instalacao anterior)
DROP TABLE repl_funcionarios;
DROP TABLE snap_leitor;

-- Tabelas de dados (filhas primeiro)
DROP TABLE AUDITORIA_EVENTOS   CASCADE CONSTRAINTS PURGE;
DROP TABLE AVALIACAO_EVENTO    CASCADE CONSTRAINTS PURGE;
DROP TABLE PARTICIPACAO_EVENTO CASCADE CONSTRAINTS PURGE;
DROP TABLE EVENTO_RECURSO      CASCADE CONSTRAINTS PURGE;
DROP TABLE HORARIO_EVENTO      CASCADE CONSTRAINTS PURGE;
DROP TABLE EVENTO              CASCADE CONSTRAINTS PURGE;
DROP TABLE BIBLIOTECA_RESPONSAVEL CASCADE CONSTRAINTS PURGE;
DROP TABLE HORARIO_BIBLIOTECA  CASCADE CONSTRAINTS PURGE;
DROP TABLE BIBLIOTECA          CASCADE CONSTRAINTS PURGE;

-- Sequencias
DROP SEQUENCE SEQ_AUDITORIA_EVT;
DROP SEQUENCE SEQ_EVENTO;
DROP SEQUENCE SEQ_HORARIO_EVENTO;
DROP SEQUENCE SEQ_AVALIACAO;
DROP SEQUENCE SEQ_RECURSO;

-- Database Links
DROP DATABASE LINK link_nacionaldb;
DROP DATABASE LINK link_materiaisdb;
DROP DATABASE LINK link_emprestimosdb;


-- ============================================================
-- FASE 1 — INFRAESTRUTURA (SYSDBA)
-- ============================================================
CONNECT sys/bd2.isctem as sysdba

-- 1. Tablespaces (inclui DROP ... INCLUDING CONTENTS AND DATAFILES)
@/root/TP/EventosDB_Tablespaces.sql

-- 2. Utilizadores (inclui DROP USER CASCADE)
@/root/TP/EventosDB_Users.sql

-- 3. Roles e privilegios DDL
@/root/TP/EventosDB_Roles.sql


-- ============================================================
-- FASE 2 — OBJECTOS DO SCHEMA (usr_eventosdb)
-- ============================================================
CONNECT usr_eventosdb/eventos1234

-- 4. Database Links
@/root/TP/EventosDB_Database_Links.sql

-- 5. Tabelas e constraints
@/root/TP/EventosDB_Create.sql

-- 6. Sequencias
@/root/TP/EventosDB_Sequences.sql

-- ------------------------------------------------------------
-- PLACEHOLDER: repl_funcionarios e snap_leitor
-- A vw_eventos_completos faz LEFT JOIN em repl_funcionarios.
-- O snapshot real so e criado na Fase 3 (requer Helder online).
-- Esta tabela local garante que a view compila sem erros agora.
-- Quando o snapshot for criado (Fase 3), o script faz DROP TABLE
-- antes do CREATE MATERIALIZED VIEW — o nome mantem-se e a view
-- continua a funcionar sem qualquer alteracao.
-- ------------------------------------------------------------
CREATE TABLE repl_funcionarios (
    cod_funcionario  VARCHAR2(12),
    nome_funcionario VARCHAR2(100),
    cod_biblioteca   VARCHAR2(10),
    id_funcao        NUMBER,
    nivel_acesso     VARCHAR2(15),
    nome_funcao      VARCHAR2(15)
) TABLESPACE tbs_eventosdb;

CREATE TABLE snap_leitor (
    num_cartao               VARCHAR2(12),
    nome_completo            VARCHAR2(100),
    cod_biblioteca           VARCHAR2(10),
    status_leitor            VARCHAR2(12),
    historico_pontualidade   VARCHAR2(10),
    distancia_biblioteca     NUMBER(6,2)
) TABLESPACE tbs_eventosdb;

-- 7. Vistas (fragmentacao + servico + backend)
@/root/TP/EventosDB_Views.sql

-- 8. Funcoes
@/root/TP/EventosDB_Functions.sql

-- 9. Procedures
@/root/TP/EventosDB_Procedures.sql

-- 10. Triggers
@/root/TP/EventosDB_Triggers.sql

-- 11. Indices
@/root/TP/EventosDB_Indexes.sql

-- 12. Grants (app_eventosdb + visitor users)
@/root/TP/EventosDB_Grants.sql

-- 13. Dados iniciais
@/root/TP/EventosDB_Intro.sql


-- ============================================================
-- FASE 3 — SNAPSHOTS (usr_eventosdb)
-- Executar MANUALMENTE quando o Helder confirmar:
--   1. GRANT SELECT ON vw_replica_funcionarios TO app_eventosdb
--   2. GRANT SELECT ON vw_leitor_publico       TO app_eventosdb
--   3. Testar: SELECT SYSDATE FROM DUAL@link_nacionaldb;
--
-- O EventosDB_Snapshots.sql ja tem DROP TABLE repl_funcionarios
-- e DROP TABLE snap_leitor antes dos CREATE MATERIALIZED VIEW,
-- para substituir os placeholders criados na Fase 2.
-- ============================================================

-- @/root/TP/EventosDB_Snapshots.sql


-- ============================================================
-- FASE 4 — SINONIMOS E AUDITORIA (SYSDBA)
-- ============================================================
CONNECT sys/bd2.isctem as sysdba

-- 14. Sinonimos publicos
@/root/TP/EventosDB_Synonyms.sql

-- 15. Auditoria Oracle nativa
@/root/TP/EventosDB_Auditoria.sql