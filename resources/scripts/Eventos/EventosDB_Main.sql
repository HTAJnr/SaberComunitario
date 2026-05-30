-- ============================================================
-- EventosDB_Main.sql — Script de instalação completo
-- EventosBibliotecasDB — Sistema de Gestão de Bibliotecas Comunitárias Distribuído
--
-- Executar como SYSDBA:
--   sqlplus sys/"bd2.isctem" as sysdba @/root/TP/EventosDB_Main.sql
--
-- PRÉ-REQUISITO (1 vez, antes do primeiro install):
--   ALTER SYSTEM SET audit_trail = 'DB' SCOPE = SPFILE;
--   SHUTDOWN IMMEDIATE; STARTUP;
-- ============================================================


-- ============================================================
-- FASE 0A — LIMPEZA DE SINÓNIMOS PÚBLICOS (SYSDBA)
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
DROP PUBLIC SYNONYM FUNCIONARIO;
DROP PUBLIC SYNONYM FUNCAO_FUNCIONARIO;
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
-- FASE 0B — LIMPEZA DE UTILIZADORES (SYSDBA)
-- ============================================================
DROP USER usr_eventosdb CASCADE;
DROP USER app_eventosdb CASCADE;
DROP USER app_nacionaldb CASCADE;
DROP USER app_materiaisdb CASCADE;
DROP USER app_emprestimosdb CASCADE;


-- ============================================================
-- FASE 1 — INFRAESTRUTURA (SYSDBA)
-- ============================================================

-- 1. Tablespaces
@/root/TP/EventosDB_Tablespaces.sql

-- 2. Utilizadores e visitor users
@/root/TP/EventosDB_Users.sql

-- 3. Roles e privilégios
@/root/TP/EventosDB_Roles.sql


-- ============================================================
-- FASE 2 — OBJECTOS DO SCHEMA (usr_eventosdb)
-- ============================================================
CONNECT usr_eventosdb/"eventos1234"

-- 4. Database Links
@/root/TP/EventosDB_Database_Links.sql

-- 5. Tabelas e constraints
@/root/TP/EventosDB_Create.sql

-- 6. Sequências
@/root/TP/EventosDB_Sequences.sql

-- Placeholders para repl_funcionarios e snap_leitor:
-- vw_eventos_completos faz LEFT JOIN nestes nomes.
-- O snapshot real (Fase 3) substitui estas tabelas com DROP TABLE antes do CREATE MV.
CREATE TABLE repl_funcionarios (
    cod_funcionario  VARCHAR2(12),
    nome_funcionario VARCHAR2(100),
    cod_biblioteca   VARCHAR2(10),
    id_funcao        NUMBER,
    nivel_acesso     VARCHAR2(15),
    nome_funcao      VARCHAR2(15),
    email            VARCHAR2(100),
    contacto         VARCHAR2(20)
) TABLESPACE tbs_eventosdb;

CREATE TABLE snap_leitor (
    num_cartao               VARCHAR2(12),
    nome_completo            VARCHAR2(100),
    cod_biblioteca           VARCHAR2(10),
    status_leitor            VARCHAR2(12),
    historico_pontualidade   VARCHAR2(10),
    distancia_biblioteca     NUMBER(6,2)
) TABLESPACE tbs_eventosdb;

-- 7. Vistas
@/root/TP/EventosDB_Views.sql

-- 8. Funções
@/root/TP/EventosDB_Functions.sql

-- 9. Procedimentos
@/root/TP/EventosDB_Procedures.sql

-- 10. Triggers
@/root/TP/EventosDB_Triggers.sql

-- 11. Índices
@/root/TP/EventosDB_Indexes.sql

-- 12. Grants e permissões
@/root/TP/EventosDB_Grants.sql

-- 13. Dados iniciais
@/root/TP/EventosDB_Intro.sql


-- ============================================================
-- FASE 3 — SNAPSHOTS (usr_eventosdb)
-- Executar MANUALMENTE após o Helder confirmar:
--   GRANT SELECT ON vw_replica_funcionarios TO app_eventosdb
--   GRANT SELECT ON vw_leitor_publico       TO app_eventosdb
-- O EventosDB_Snapshots.sql já faz DROP TABLE antes do CREATE MV,
-- substituindo os placeholders criados na Fase 2.
-- ============================================================
-- @/root/TP/EventosDB_Snapshots.sql


-- ============================================================
-- FASE 4 — SINÓNIMOS E AUDITORIA (SYSDBA)
-- ============================================================
CONNECT sys/"bd2.isctem" as sysdba

-- 14. Sinónimos públicos
@/root/TP/EventosDB_Synonyms.sql

-- 15. Auditoria Oracle nativa
@/root/TP/EventosDB_Auditoria.sql
