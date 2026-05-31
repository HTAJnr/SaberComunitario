-- ============================================================
-- EmprestimosDB_Grants.sql
-- Executar como usr_emprestimosdb
-- ============================================================


-- ============================================================
-- SECÇÃO 1: UTILIZADOR LOCAL — app_emprestimosdb
-- ============================================================
GRANT SELECT ON EMPRESTIMO              TO app_emprestimosdb;
GRANT SELECT ON SUSPENSAO               TO app_emprestimosdb;
GRANT SELECT ON REPL_FUNCIONARIOS        TO app_emprestimosdb;
GRANT SELECT ON REPL_FUNCAO_FUNCIONARIO  TO app_emprestimosdb;
GRANT SELECT ON vw_historico_emprestimos TO app_emprestimosdb;
GRANT SELECT ON PROGRAMA_ALFABETIZACAO  TO app_emprestimosdb;
GRANT SELECT ON NIVEL_PROGRESSAO        TO app_emprestimosdb;
GRANT SELECT ON PROGRAMA_MATERIAL       TO app_emprestimosdb;
GRANT SELECT ON PROGRAMA_FUNCIONARIO    TO app_emprestimosdb;
GRANT SELECT ON PARTICIPACAO_PROGRAMA   TO app_emprestimosdb;
GRANT SELECT ON AUDITORIA_EMPRESTIMOS   TO app_emprestimosdb;
GRANT SELECT ON vw_emprestimos_activos  TO app_emprestimosdb;
GRANT SELECT ON vw_emprestimos_ativos   TO app_emprestimosdb;
GRANT SELECT ON vw_suspensoes_activas   TO app_emprestimosdb;
GRANT SELECT ON frag_emp_activos_op     TO app_emprestimosdb;
GRANT SELECT ON frag_emp_activos_det    TO app_emprestimosdb;
GRANT SELECT ON frag_emp_historico_op   TO app_emprestimosdb;
GRANT SELECT ON frag_emp_historico_det  TO app_emprestimosdb;
GRANT SELECT ON VW_AUDITORIA            TO app_emprestimosdb;
-- Snapshots locais — criados em EmprestimosDB_Snapshots.sql (depois deste script).
-- Usa nome qualificado para evitar ORA-01775 (loop de sinónimos).
-- Bloco tolerante a ORA-00942 caso os snapshots ainda nao existam.
BEGIN
  EXECUTE IMMEDIATE 'GRANT SELECT ON usr_emprestimosdb.snap_leitor     TO app_emprestimosdb';
  EXECUTE IMMEDIATE 'GRANT SELECT ON usr_emprestimosdb.snap_material   TO app_emprestimosdb';
  EXECUTE IMMEDIATE 'GRANT SELECT ON usr_emprestimosdb.snap_adulto     TO app_emprestimosdb';
  EXECUTE IMMEDIATE 'GRANT SELECT ON usr_emprestimosdb.snap_crianca    TO app_emprestimosdb';
  EXECUTE IMMEDIATE 'GRANT SELECT ON usr_emprestimosdb.snap_professor  TO app_emprestimosdb';
  EXECUTE IMMEDIATE 'GRANT SELECT ON usr_emprestimosdb.snap_categoria  TO app_emprestimosdb';
  EXECUTE IMMEDIATE 'GRANT SELECT ON usr_emprestimosdb.biblioteca_snap TO app_emprestimosdb';
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('AVISO: snapshots ainda nao criados — re-correr apos EmprestimosDB_Snapshots.sql. ORA: ' || SQLERRM);
END;
/


-- ============================================================
-- SECÇÃO 2: ROLES PARA VISITOR USERS
-- NOTA: roles nao transitam por dblink — grants directos
-- na Secção 3 sao obrigatorios para acesso cross-node.
-- ============================================================

-- role_emp_visitante — acesso minimo para verificacao de emprestimos
-- Destinatarios: todos os nos visitantes
-- (role criado em EmprestimosDB_Roles.sql como SYSDBA)
GRANT SELECT ON EMPRESTIMO             TO role_emp_visitante;
GRANT SELECT ON vw_emprestimos_activos TO role_emp_visitante;
GRANT SELECT ON frag_emp_activos_op    TO role_emp_visitante;

-- role_emp_programas — acesso completo para gestao de programas e auditoria
-- Destinatarios: app_nacionaldb, app_eventosdb
GRANT SELECT ON EMPRESTIMO              TO role_emp_programas;
GRANT SELECT ON SUSPENSAO               TO role_emp_programas;
GRANT SELECT ON PROGRAMA_ALFABETIZACAO  TO role_emp_programas;
GRANT SELECT ON PARTICIPACAO_PROGRAMA   TO role_emp_programas;
GRANT SELECT ON NIVEL_PROGRESSAO        TO role_emp_programas;
GRANT SELECT ON PROGRAMA_MATERIAL       TO role_emp_programas;
GRANT SELECT ON PROGRAMA_FUNCIONARIO    TO role_emp_programas;
GRANT SELECT ON REPL_FUNCIONARIOS       TO role_emp_programas;
GRANT SELECT ON vw_emprestimos_activos  TO role_emp_programas;
GRANT SELECT ON vw_emprestimos_ativos   TO role_emp_programas;
GRANT SELECT ON vw_historico_emprestimos TO role_emp_programas;
GRANT SELECT ON vw_suspensoes_activas   TO role_emp_programas;
GRANT SELECT ON frag_emp_activos_op     TO role_emp_programas;
GRANT SELECT ON VW_AUDITORIA            TO role_emp_programas;

-- (atribuicao de roles feita em EmprestimosDB_Roles.sql como SYSDBA)


-- ============================================================
-- SECÇÃO 3: GRANTS DIRECTOS AOS VISITOR USERS
-- Obrigatorios para acesso via dblink + DML exclusivo por no.
-- ============================================================

-- ── Yasin (app_materiaisdb) ─────────────────────────────────
-- RN06: verifica emprestimo activo antes de transferencia
GRANT SELECT ON EMPRESTIMO             TO app_materiaisdb;
GRANT SELECT ON vw_emprestimos_activos TO app_materiaisdb;
GRANT SELECT ON frag_emp_activos_op    TO app_materiaisdb;
-- DML: endpoints de emprestimos/programas (mesmo backend nos 4 nos)
GRANT SELECT ON SUSPENSAO                TO app_materiaisdb;
GRANT UPDATE ON SUSPENSAO                TO app_materiaisdb;
GRANT INSERT ON EMPRESTIMO               TO app_materiaisdb;
GRANT UPDATE ON EMPRESTIMO               TO app_materiaisdb;
GRANT SELECT ON PARTICIPACAO_PROGRAMA    TO app_materiaisdb;
GRANT INSERT, UPDATE ON PARTICIPACAO_PROGRAMA TO app_materiaisdb;

-- ── Helder (app_nacionaldb) ─────────────────────────────────
-- Emprestimos e suspensoes para vistas globais
GRANT SELECT ON EMPRESTIMO               TO app_nacionaldb;
GRANT SELECT ON SUSPENSAO                TO app_nacionaldb;
-- Programas de alfabetizacao para MV mv_relatorio_programas
GRANT SELECT ON PROGRAMA_ALFABETIZACAO   TO app_nacionaldb;
GRANT SELECT ON PARTICIPACAO_PROGRAMA    TO app_nacionaldb;
GRANT SELECT ON NIVEL_PROGRESSAO         TO app_nacionaldb;
GRANT SELECT ON PROGRAMA_MATERIAL        TO app_nacionaldb;
GRANT SELECT ON PROGRAMA_FUNCIONARIO     TO app_nacionaldb;
-- prc_apagar_leitor: apaga participacoes do leitor eliminado
GRANT DELETE ON PARTICIPACAO_PROGRAMA    TO app_nacionaldb;
-- prc_remover_funcionario: apaga relacao funcionario-programa
GRANT DELETE ON PROGRAMA_FUNCIONARIO     TO app_nacionaldb;
-- prc_sincronizar_funcionarios e prc_modificar_nivel_acesso
GRANT SELECT, INSERT, UPDATE, DELETE ON REPL_FUNCIONARIOS TO app_nacionaldb;
-- Vistas de servico
GRANT SELECT ON vw_emprestimos_activos   TO app_nacionaldb;
GRANT SELECT ON vw_emprestimos_ativos    TO app_nacionaldb;
GRANT SELECT ON vw_historico_emprestimos TO app_nacionaldb;
GRANT SELECT ON vw_suspensoes_activas    TO app_nacionaldb;
GRANT SELECT ON vw_relatorio_programas   TO app_nacionaldb;
GRANT SELECT ON frag_emp_activos_op      TO app_nacionaldb;
GRANT SELECT ON VW_AUDITORIA             TO app_nacionaldb;
-- GET /validar-leitor: auto-liberta suspensoes expiradas
GRANT UPDATE ON SUSPENSAO                TO app_nacionaldb;
-- POST /emprestimos: criar emprestimo
GRANT INSERT ON EMPRESTIMO               TO app_nacionaldb;
-- PATCH /emprestimos/:id/devolver: registar devolucao + multa (multa = colunas no EMPRESTIMO)
GRANT UPDATE ON EMPRESTIMO               TO app_nacionaldb;
-- PATCH /programas/:cod/participantes: actualizar participante
GRANT INSERT, UPDATE ON PARTICIPACAO_PROGRAMA TO app_nacionaldb;

-- ── Gerson (app_eventosdb) ──────────────────────────────────
-- Backend correndo no EventosDB precisa de acesso a emprestimos
-- e programas para o mesmo conjunto de endpoints dos outros nos.
GRANT SELECT ON EMPRESTIMO               TO app_eventosdb;
GRANT SELECT ON SUSPENSAO                TO app_eventosdb;
GRANT SELECT ON vw_emprestimos_ativos    TO app_eventosdb;
GRANT SELECT ON vw_emprestimos_activos   TO app_eventosdb;
GRANT SELECT ON vw_historico_emprestimos TO app_eventosdb;
GRANT SELECT ON vw_suspensoes_activas    TO app_eventosdb;
GRANT SELECT ON frag_emp_activos_op      TO app_eventosdb;
GRANT SELECT ON PROGRAMA_ALFABETIZACAO   TO app_eventosdb;
GRANT SELECT ON PARTICIPACAO_PROGRAMA    TO app_eventosdb;
GRANT SELECT ON NIVEL_PROGRESSAO         TO app_eventosdb;
GRANT SELECT ON PROGRAMA_MATERIAL        TO app_eventosdb;
GRANT SELECT ON PROGRAMA_FUNCIONARIO     TO app_eventosdb;
GRANT SELECT ON REPL_FUNCIONARIOS        TO app_eventosdb;
GRANT SELECT ON VW_AUDITORIA             TO app_eventosdb;
-- DML: mesmos endpoints de emprestimos/programas que app_nacionaldb
GRANT UPDATE ON SUSPENSAO                TO app_eventosdb;
GRANT INSERT ON EMPRESTIMO               TO app_eventosdb;
GRANT UPDATE ON EMPRESTIMO               TO app_eventosdb;
GRANT INSERT, UPDATE ON PARTICIPACAO_PROGRAMA TO app_eventosdb;
