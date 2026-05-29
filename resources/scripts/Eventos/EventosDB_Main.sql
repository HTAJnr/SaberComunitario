-- ============================================================
-- EventosDB_Main.sql — Script de instalacao completo
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
-- FASE 0 — LIMPEZA (SYSDBA)
-- ============================================================

-- Sinonimos publicos
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

-- ============================================================
-- FASE 1 — INFRAESTRUTURA (SYSDBA)
-- ============================================================

-- 1. Tablespaces
@/root/TP/EventosDB_Tablespaces.sql

-- 2. Utilizadores e roles (inclui visitor users)
@/root/TP/EventosDB_Users.sql
@/root/TP/EventosDB_Roles.sql

-- ============================================================
-- FASE 2 — OBJECTOS DO SCHEMA (usr_eventosdb)
-- ============================================================
CONNECT usr_eventosdb/eventos1234

-- 3. Database Links
@/root/TP/EventosDB_Database_Links.sql

-- 4. Snapshots (so executar apos grant do Helder)
-- @/root/TP/EventosDB_Snapshots.sql

-- 5. Tabelas e constraints
@/root/TP/EventosDB_Create.sql

-- 6. Sequencias
@/root/TP/EventosDB_Sequences.sql

-- 7. Vistas (fragmentacao + servico)
@/root/TP/EventosDB_Views.sql

-- 8. Funcoes
@/root/TP/EventosDB_Functions.sql

-- 9. Procedures
@/root/TP/EventosDB_Procedures.sql

-- 10. Triggers
@/root/TP/EventosDB_Triggers.sql

-- 11. Indices
@/root/TP/EventosDB_Indexes.sql

-- 12. Grants (inclui grants para visitor users)
@/root/TP/EventosDB_Grants.sql

-- 13. Dados iniciais
@/root/TP/EventosDB_Intro.sql

-- ============================================================
-- FASE 3 — SINONIMOS E AUDITORIA (SYSDBA)
-- ============================================================
CONNECT sys/bd2.isctem as sysdba

-- 14. Sinonimos publicos (requer SYSDBA)
@/root/TP/EventosDB_Synonyms.sql

-- 15. Auditoria Oracle nativa
@/root/TP/EventosDB_Auditoria.sql
