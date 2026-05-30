-- ============================================================
-- EmprestimosDB_Main.sql — Script de instalação completo
-- EmprestimosDB — Sistema de Gestão de Bibliotecas Comunitárias Distribuído
--
-- Executar como SYSDBA:
--   sqlplus sys/"bd2.isctem" as sysdba @/root/TP/EmprestimosDB_Main.sql
--
-- PRÉ-REQUISITO (1 vez, antes do primeiro install):
--   ALTER SYSTEM SET audit_trail = 'DB' SCOPE = SPFILE;
--   SHUTDOWN IMMEDIATE; STARTUP;
-- ============================================================


-- ============================================================
-- FASE 0A — LIMPEZA DE SINÓNIMOS PÚBLICOS (SYSDBA)
-- ============================================================

-- BibliotecaNacionalDB (Helder)
DROP PUBLIC SYNONYM leitor;
DROP PUBLIC SYNONYM adulto;
DROP PUBLIC SYNONYM adulto_interesse;
DROP PUBLIC SYNONYM professor;
DROP PUBLIC SYNONYM professor_disciplina;
DROP PUBLIC SYNONYM crianca;

-- Snapshots locais
DROP PUBLIC SYNONYM funcao_funcionario;
DROP PUBLIC SYNONYM funcionario;
DROP PUBLIC SYNONYM biblioteca;

-- MateriaisDB (Yasin)
DROP PUBLIC SYNONYM material_bibliografico;
DROP PUBLIC SYNONYM categoria;
DROP PUBLIC SYNONYM transferencia;

-- Objectos e views locais
DROP PUBLIC SYNONYM emprestimo;
DROP PUBLIC SYNONYM suspensao;
DROP PUBLIC SYNONYM repl_funcionarios;
DROP PUBLIC SYNONYM programa_alfabetizacao;
DROP PUBLIC SYNONYM nivel_progressao;
DROP PUBLIC SYNONYM programa_material;
DROP PUBLIC SYNONYM programa_funcionario;
DROP PUBLIC SYNONYM participacao_programa;
DROP PUBLIC SYNONYM vw_emprestimos_activos;
DROP PUBLIC SYNONYM vw_suspensoes_activas;
DROP PUBLIC SYNONYM frag_emp_activos_op;
DROP PUBLIC SYNONYM vw_auditoria;
DROP PUBLIC SYNONYM vw_relatorio_programas;


-- ============================================================
-- FASE 0B — LIMPEZA DE UTILIZADORES (SYSDBA)
-- ============================================================
DROP USER usr_emprestimosdb CASCADE;
DROP USER app_emprestimosdb CASCADE;
DROP USER app_nacionaldb CASCADE;
DROP USER app_materiaisdb CASCADE;


-- ============================================================
-- FASE 1 — INFRAESTRUTURA (SYSDBA)
-- ============================================================

-- 1. Tablespaces
@/root/TP/EmprestimosDB_Tablespaces.sql

-- 2. Utilizadores e visitor users
@/root/TP/EmprestimosDB_Users.sql

-- 3. Roles e privilégios
@/root/TP/EmprestimosDB_Roles.sql


-- ============================================================
-- FASE 2 — OBJECTOS DO SCHEMA (usr_emprestimosdb)
-- ============================================================
CONNECT usr_emprestimosdb/"YC20220156"

-- 4. Database Links
@/root/TP/EmprestimosDB_Database_Links.sql

-- 5. Snapshots (depende dos database links)
@/root/TP/EmprestimosDB_Snapshots.sql

-- 6. Sinónimos (depende dos database links e snapshots)
@/root/TP/EmprestimosDB_Synonyms.sql

-- 7. Tabelas e constraints
@/root/TP/EmprestimosDB_Create.sql

-- 8. Sequências
@/root/TP/EmprestimosDB_Sequences.sql

-- 9. Vistas
@/root/TP/EmprestimosDB_Views.sql

-- 10. Funções
@/root/TP/EmprestimosDB_Functions.sql

-- 11. Procedimentos
@/root/TP/EmprestimosDB_Procedures.sql

-- 12. Triggers
@/root/TP/EmprestimosDB_Triggers.sql

-- 13. Índices
@/root/TP/EmprestimosDB_Indexes.sql

-- 14. Grants e permissões
@/root/TP/EmprestimosDB_Grants.sql

-- 15. Dados iniciais
@/root/TP/EmprestimosDB_Intro.sql


-- ============================================================
-- FASE 3 — AUDITORIA (SYSDBA)
-- ============================================================
CONNECT sys/"bd2.isctem" as sysdba

-- 16. Auditoria Oracle nativa
@/root/TP/EmprestimosDB_Auditoria.sql
