-- ============================================================
-- EmprestimosDB_Grants.sql
-- Executar como usr_emprestimosdb
-- ============================================================


-- ============================================================
-- SECÇÃO 1: GRANTS AOS ROLES LOCAIS
-- ============================================================

GRANT SELECT ON EMPRESTIMO             TO role_emprestimosdb_read;
GRANT SELECT ON SUSPENSAO              TO role_emprestimosdb_read;
GRANT SELECT ON PROGRAMA_ALFABETIZACAO TO role_emprestimosdb_read;
GRANT SELECT ON PARTICIPACAO_PROGRAMA  TO role_emprestimosdb_read;
GRANT SELECT ON NIVEL_PROGRESSAO       TO role_emprestimosdb_read;
GRANT SELECT ON PROGRAMA_MATERIAL      TO role_emprestimosdb_read;
GRANT SELECT ON PROGRAMA_FUNCIONARIO   TO role_emprestimosdb_read;
BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON usr_emprestimosdb.repl_funcionarios TO role_emprestimosdb_read'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
GRANT SELECT ON AUDITORIA_EMPRESTIMOS  TO role_emprestimosdb_read;

GRANT INSERT, UPDATE ON EMPRESTIMO            TO role_emprestimosdb_write;
GRANT INSERT, UPDATE ON SUSPENSAO             TO role_emprestimosdb_write;
GRANT INSERT, UPDATE ON PARTICIPACAO_PROGRAMA TO role_emprestimosdb_write;
GRANT INSERT         ON AUDITORIA_EMPRESTIMOS TO role_emprestimosdb_write;


-- ============================================================
-- SECÇÃO 2: UTILIZADOR LOCAL — app_emprestimosdb
-- ============================================================
GRANT SELECT ON EMPRESTIMO              TO app_emprestimosdb;
GRANT SELECT ON SUSPENSAO               TO app_emprestimosdb;
BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON usr_emprestimosdb.repl_funcionarios TO app_emprestimosdb'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON usr_emprestimosdb.repl_funcao_funcionario TO app_emprestimosdb'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
GRANT SELECT ON vw_historico_emprestimos TO app_emprestimosdb;
GRANT SELECT ON PROGRAMA_ALFABETIZACAO  TO app_emprestimosdb;
GRANT SELECT ON NIVEL_PROGRESSAO        TO app_emprestimosdb;
GRANT SELECT ON PROGRAMA_MATERIAL       TO app_emprestimosdb;
GRANT SELECT ON PROGRAMA_FUNCIONARIO    TO app_emprestimosdb;
GRANT SELECT ON PARTICIPACAO_PROGRAMA   TO app_emprestimosdb;
GRANT SELECT, INSERT ON AUDITORIA_EMPRESTIMOS TO app_emprestimosdb;
GRANT SELECT ON SEQ_AUDITORIA_EMP             TO app_emprestimosdb;
GRANT SELECT ON vw_emprestimos_activos  TO app_emprestimosdb;
GRANT SELECT ON vw_emprestimos_ativos   TO app_emprestimosdb;
GRANT SELECT ON vw_suspensoes_activas   TO app_emprestimosdb;
GRANT SELECT ON frag_emp_activos_op     TO app_emprestimosdb;
GRANT SELECT ON frag_emp_activos_det    TO app_emprestimosdb;
GRANT SELECT ON frag_emp_historico_op   TO app_emprestimosdb;
GRANT SELECT ON frag_emp_historico_det  TO app_emprestimosdb;
GRANT SELECT ON VW_AUDITORIA            TO app_emprestimosdb;
-- DML directo: Oracle 10g nao activa roles em todos os contextos de sessao
GRANT INSERT, UPDATE ON EMPRESTIMO              TO app_emprestimosdb;
GRANT INSERT, UPDATE ON SUSPENSAO               TO app_emprestimosdb;
GRANT INSERT, UPDATE ON PARTICIPACAO_PROGRAMA   TO app_emprestimosdb;
GRANT DELETE ON PARTICIPACAO_PROGRAMA           TO app_emprestimosdb;
GRANT DELETE ON PROGRAMA_FUNCIONARIO            TO app_emprestimosdb;
GRANT SELECT ON SEQ_EMPRESTIMO                  TO app_emprestimosdb;
GRANT EXECUTE ON processar_devolucao            TO app_emprestimosdb;
-- Criar/editar programas (backend transparente — todos os nos correm o mesmo codigo)
GRANT INSERT, UPDATE ON PROGRAMA_ALFABETIZACAO  TO app_emprestimosdb;
GRANT INSERT ON NIVEL_PROGRESSAO                TO app_emprestimosdb;
GRANT SELECT ON SEQ_NIVEL                       TO app_emprestimosdb;
GRANT INSERT ON PROGRAMA_MATERIAL               TO app_emprestimosdb;
GRANT INSERT ON PROGRAMA_FUNCIONARIO            TO app_emprestimosdb;
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
-- SECÇÃO 2: GRANTS DIRECTOS AOS VISITOR USERS
-- Obrigatorios para acesso via dblink + DML exclusivo por no.
-- ============================================================

-- ── Yasin (app_materiaisdb) ─────────────────────────────────
-- Emprestimos e suspensoes
GRANT SELECT ON EMPRESTIMO               TO app_materiaisdb;
GRANT INSERT, UPDATE ON EMPRESTIMO       TO app_materiaisdb;
GRANT SELECT ON SUSPENSAO                TO app_materiaisdb;
GRANT UPDATE ON SUSPENSAO                TO app_materiaisdb;
-- Vistas de emprestimos (paridade com app_eventosdb)
GRANT SELECT ON vw_emprestimos_activos   TO app_materiaisdb;
GRANT SELECT ON vw_emprestimos_ativos    TO app_materiaisdb;
GRANT SELECT ON vw_historico_emprestimos TO app_materiaisdb;
GRANT SELECT ON vw_suspensoes_activas    TO app_materiaisdb;
GRANT SELECT ON frag_emp_activos_op      TO app_materiaisdb;
-- Programas — SELECT em falta (INSERT/UPDATE adicionados mais abaixo)
GRANT SELECT ON PROGRAMA_ALFABETIZACAO   TO app_materiaisdb;
GRANT SELECT ON PARTICIPACAO_PROGRAMA    TO app_materiaisdb;
GRANT INSERT, UPDATE, DELETE ON PARTICIPACAO_PROGRAMA TO app_materiaisdb;
GRANT SELECT ON NIVEL_PROGRESSAO         TO app_materiaisdb;
GRANT SELECT ON PROGRAMA_MATERIAL        TO app_materiaisdb;
GRANT SELECT ON PROGRAMA_FUNCIONARIO     TO app_materiaisdb;
-- Auditoria
GRANT SELECT ON VW_AUDITORIA             TO app_materiaisdb;

-- ── Helder (app_nacionaldb) ─────────────────────────────────
-- Emprestimos e suspensoes para vistas globais
GRANT SELECT ON EMPRESTIMO               TO app_nacionaldb;
GRANT SELECT ON SUSPENSAO                TO app_nacionaldb;
-- Procedure chamada via dblink (PATCH /emprestimos/:id/devolver)
GRANT EXECUTE ON processar_devolucao     TO app_nacionaldb;
-- Sequencia necessaria para INSERT EMPRESTIMO via synonym (SEQ.NEXTVAL inline)
GRANT SELECT ON SEQ_EMPRESTIMO           TO app_nacionaldb;
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
-- Criar/editar programas de qualquer no (transparencia)
GRANT INSERT, UPDATE ON PROGRAMA_ALFABETIZACAO TO app_nacionaldb;
GRANT INSERT ON NIVEL_PROGRESSAO               TO app_nacionaldb;
GRANT SELECT ON SEQ_NIVEL                      TO app_nacionaldb;
GRANT INSERT ON PROGRAMA_MATERIAL              TO app_nacionaldb;
GRANT INSERT ON PROGRAMA_FUNCIONARIO           TO app_nacionaldb;
-- prc_sincronizar_funcionarios e prc_modificar_nivel_acesso
BEGIN EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON usr_emprestimosdb.repl_funcionarios TO app_nacionaldb'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
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
-- Transparencia: mesmos grants que app_nacionaldb e app_materiaisdb.
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
BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON usr_emprestimosdb.repl_funcionarios TO app_eventosdb'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
GRANT SELECT ON VW_AUDITORIA             TO app_eventosdb;
-- DML: emprestimos, suspensoes, participacoes, programas
GRANT INSERT, UPDATE ON EMPRESTIMO               TO app_eventosdb;
GRANT UPDATE ON SUSPENSAO                        TO app_eventosdb;
GRANT INSERT, UPDATE, DELETE ON PARTICIPACAO_PROGRAMA TO app_eventosdb;
-- Transparencia: sequencia + procedure necessarias para qualquer no logado
GRANT SELECT  ON SEQ_EMPRESTIMO              TO app_eventosdb;
GRANT EXECUTE ON processar_devolucao         TO app_eventosdb;
-- Criar/editar programas de qualquer no (transparencia)
GRANT INSERT, UPDATE ON PROGRAMA_ALFABETIZACAO TO app_eventosdb;
GRANT INSERT ON NIVEL_PROGRESSAO               TO app_eventosdb;
GRANT SELECT ON SEQ_NIVEL                      TO app_eventosdb;
GRANT INSERT ON PROGRAMA_MATERIAL              TO app_eventosdb;
GRANT INSERT ON PROGRAMA_FUNCIONARIO           TO app_eventosdb;

-- ── Yasin (app_materiaisdb) — sequencia + procedure (restantes grants ja na seccao acima)
GRANT SELECT  ON SEQ_EMPRESTIMO              TO app_materiaisdb;
GRANT EXECUTE ON processar_devolucao         TO app_materiaisdb;
GRANT SELECT ON SEQ_NIVEL                    TO app_materiaisdb;
-- Criar/editar programas de qualquer no (transparencia)
GRANT INSERT, UPDATE ON PROGRAMA_ALFABETIZACAO TO app_materiaisdb;
GRANT INSERT ON NIVEL_PROGRESSAO               TO app_materiaisdb;
GRANT INSERT ON PROGRAMA_MATERIAL              TO app_materiaisdb;
GRANT INSERT ON PROGRAMA_FUNCIONARIO           TO app_materiaisdb;
