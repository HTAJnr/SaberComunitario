-- ============================================================
-- EmprestimosProg_Grants.sql
-- Executar como usr_emprestimosdb
-- ============================================================

-- -- app_emprestimosdb (utilizador local da aplicacao) -------
GRANT SELECT ON EMPRESTIMO              TO app_emprestimosdb;
GRANT SELECT ON SUSPENSAO               TO app_emprestimosdb;
GRANT SELECT ON REPL_FUNCIONARIOS       TO app_emprestimosdb;
GRANT SELECT ON PROGRAMA_ALFABETIZACAO  TO app_emprestimosdb;
GRANT SELECT ON NIVEL_PROGRESSAO        TO app_emprestimosdb;
GRANT SELECT ON PROGRAMA_MATERIAL       TO app_emprestimosdb;
GRANT SELECT ON PROGRAMA_FUNCIONARIO    TO app_emprestimosdb;
GRANT SELECT ON PARTICIPACAO_PROGRAMA   TO app_emprestimosdb;
GRANT SELECT ON AUDITORIA_EMPRESTIMOS   TO app_emprestimosdb;
GRANT SELECT ON vw_emprestimos_activos  TO app_emprestimosdb;
GRANT SELECT ON vw_suspensoes_activas   TO app_emprestimosdb;
GRANT SELECT ON frag_emp_activos_op     TO app_emprestimosdb;
GRANT SELECT ON frag_emp_activos_det    TO app_emprestimosdb;
GRANT SELECT ON frag_emp_historico_op   TO app_emprestimosdb;
GRANT SELECT ON frag_emp_historico_det  TO app_emprestimosdb;
GRANT SELECT ON VW_AUDITORIA            TO app_emprestimosdb;

-- -- app_nacionaldb (visitor user do Helder) -----------------
-- Emprestimos e suspensoes para vistas globais
GRANT SELECT ON EMPRESTIMO              TO app_nacionaldb;
GRANT SELECT ON SUSPENSAO               TO app_nacionaldb;
-- Programas de alfabetizacao para MV mv_relatorio_programas
GRANT SELECT ON PROGRAMA_ALFABETIZACAO  TO app_nacionaldb;
GRANT SELECT ON PARTICIPACAO_PROGRAMA   TO app_nacionaldb;
GRANT SELECT ON NIVEL_PROGRESSAO        TO app_nacionaldb;
GRANT SELECT ON PROGRAMA_MATERIAL       TO app_nacionaldb;
GRANT SELECT ON PROGRAMA_FUNCIONARIO    TO app_nacionaldb;
-- prc_apagar_leitor: apaga participacoes do leitor eliminado
GRANT DELETE ON PARTICIPACAO_PROGRAMA   TO app_nacionaldb;
-- prc_remover_funcionario: apaga relacao funcionario-programa
GRANT DELETE ON PROGRAMA_FUNCIONARIO    TO app_nacionaldb;
-- prc_sincronizar_funcionarios e prc_modificar_nivel_acesso
GRANT SELECT, INSERT, UPDATE, DELETE ON REPL_FUNCIONARIOS TO app_nacionaldb;
-- Vistas de servico
GRANT SELECT ON vw_emprestimos_activos  TO app_nacionaldb;
GRANT SELECT ON vw_suspensoes_activas   TO app_nacionaldb;
GRANT SELECT ON frag_emp_activos_op     TO app_nacionaldb;
GRANT SELECT ON VW_AUDITORIA            TO app_nacionaldb;

-- -- app_materiaisdb (visitor user do Yasin) -----------------
-- RN06: verifica emprestimo activo antes de transferencia
GRANT SELECT ON EMPRESTIMO              TO app_materiaisdb;
GRANT SELECT ON vw_emprestimos_activos  TO app_materiaisdb;
GRANT SELECT ON frag_emp_activos_op     TO app_materiaisdb;

-- Fragmentos expostos externamente (fragmentacao mista)
GRANT SELECT ON frag_emp_activos_op TO app_materiaisdb;
GRANT SELECT ON frag_emp_activos_op TO app_nacionaldb;
