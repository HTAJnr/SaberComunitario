-- ============================================================
-- GRANTS - EventosBibliotecasDB (v5)
-- Executar como usr_eventosdb
-- ============================================================


-- ============================================================
-- SECÇÃO 1: GRANTS AOS ROLES LOCAIS
-- ============================================================

GRANT SELECT ON BIBLIOTECA         TO role_eventosdb_read;
GRANT SELECT ON HORARIO_BIBLIOTECA TO role_eventosdb_read;
GRANT SELECT ON EVENTO             TO role_eventosdb_read;
GRANT SELECT ON HORARIO_EVENTO     TO role_eventosdb_read;
GRANT SELECT ON PARTICIPACAO_EVENTO TO role_eventosdb_read;
GRANT SELECT ON AVALIACAO_EVENTO   TO role_eventosdb_read;
GRANT SELECT ON AUDITORIA_EVENTOS  TO role_eventosdb_read;

GRANT INSERT, UPDATE        ON EVENTO             TO role_eventosdb_write;
GRANT INSERT, UPDATE        ON HORARIO_EVENTO     TO role_eventosdb_write;
GRANT INSERT, DELETE        ON PARTICIPACAO_EVENTO TO role_eventosdb_write;
GRANT INSERT, DELETE        ON AVALIACAO_EVENTO   TO role_eventosdb_write;
GRANT INSERT                ON AUDITORIA_EVENTOS  TO role_eventosdb_write;


-- ============================================================
-- SECÇÃO 2: UTILIZADOR LOCAL — app_eventosdb
-- ============================================================

-- Tabelas
GRANT SELECT ON BIBLIOTECA                  TO app_eventosdb;
GRANT SELECT ON HORARIO_BIBLIOTECA          TO app_eventosdb;
GRANT SELECT ON BIBLIOTECA_RESPONSAVEL      TO app_eventosdb;
GRANT SELECT, INSERT, UPDATE ON EVENTO      TO app_eventosdb;
GRANT SELECT, INSERT ON HORARIO_EVENTO      TO app_eventosdb;
GRANT SELECT ON EVENTO_RECURSO              TO app_eventosdb;
GRANT SELECT, INSERT, DELETE ON PARTICIPACAO_EVENTO TO app_eventosdb;
GRANT SELECT, INSERT, DELETE ON AVALIACAO_EVENTO    TO app_eventosdb;
GRANT SELECT, INSERT ON AUDITORIA_EVENTOS   TO app_eventosdb;

-- Vistas de servico
GRANT SELECT ON v_programacao_eventos       TO app_eventosdb;
GRANT SELECT ON v_horarios_bibliotecas      TO app_eventosdb;
GRANT SELECT ON v_bibliotecas_activas       TO app_eventosdb;
GRANT SELECT ON v_evento_global             TO app_eventosdb;

-- Vistas acedidas via dblink por outros nos
GRANT SELECT ON vw_eventos_proximos          TO app_eventosdb;
GRANT SELECT ON vw_eventos_completos         TO app_eventosdb;
GRANT SELECT ON vw_bibliotecas_operacionais  TO app_eventosdb;
GRANT SELECT ON vw_horarios_biblioteca_semana TO app_eventosdb;
GRANT SELECT ON vw_participacoes_eventos     TO app_eventosdb;

-- Vistas de fragmento
GRANT SELECT ON frag_evento_sul             TO app_eventosdb;
GRANT SELECT ON frag_evento_centro          TO app_eventosdb;
GRANT SELECT ON frag_evento_norte           TO app_eventosdb;
GRANT SELECT ON vw_frag_evento_futuro       TO app_eventosdb;
GRANT SELECT ON vw_frag_evento_passado      TO app_eventosdb;
GRANT SELECT ON vw_frag_participacao_futuro  TO app_eventosdb;
GRANT SELECT ON vw_frag_participacao_passado TO app_eventosdb;

-- Sequencias
GRANT SELECT ON SEQ_EVENTO                  TO app_eventosdb;
GRANT SELECT ON SEQ_AVALIACAO               TO app_eventosdb;
GRANT SELECT ON SEQ_AUDITORIA_EVT           TO app_eventosdb;
GRANT SELECT ON SEQ_HORARIO_EVENTO          TO app_eventosdb;

-- Procedimentos
GRANT EXECUTE ON INSERE_PARTICIPACAO_EVENTO TO app_eventosdb;
-- Snapshots locais — criados em EventosDB_Snapshots.sql (depois deste script).
-- Usa nome qualificado para evitar ORA-01775 (loop de sinónimos).
-- Bloco tolerante a ORA-00942 caso os snapshots ainda nao existam.
BEGIN
  EXECUTE IMMEDIATE 'GRANT SELECT ON usr_eventosdb.snap_leitor             TO app_eventosdb';
  EXECUTE IMMEDIATE 'GRANT SELECT ON usr_eventosdb.repl_funcionarios       TO app_eventosdb';
  EXECUTE IMMEDIATE 'GRANT SELECT ON usr_eventosdb.repl_funcao_funcionario TO app_eventosdb';
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('AVISO: snapshots ainda nao criados — re-correr apos EventosDB_Snapshots.sql. ORA: ' || SQLERRM);
END;
/


-- ============================================================
-- SECÇÃO 2: GRANTS DIRECTOS AOS VISITOR USERS
-- Obrigatorios para acesso via dblink + DML exclusivo por no.
-- ============================================================

-- ── Yannis (app_emprestimosdb) ──────────────────────────────
GRANT SELECT ON BIBLIOTECA               TO app_emprestimosdb;
GRANT SELECT ON EVENTO                   TO app_emprestimosdb;
GRANT SELECT ON PARTICIPACAO_EVENTO      TO app_emprestimosdb;
GRANT SELECT ON HORARIO_BIBLIOTECA       TO app_emprestimosdb;
GRANT SELECT ON vw_eventos_proximos      TO app_emprestimosdb;
GRANT SELECT ON vw_eventos_completos     TO app_emprestimosdb;
GRANT SELECT ON v_bibliotecas_activas    TO app_emprestimosdb;
GRANT SELECT ON v_programacao_eventos    TO app_emprestimosdb;
GRANT SELECT ON v_horarios_bibliotecas   TO app_emprestimosdb;
-- Transparencia: DML e sequencias para criar/editar eventos de qualquer no
GRANT INSERT, UPDATE ON EVENTO           TO app_emprestimosdb;
GRANT SELECT, INSERT ON HORARIO_EVENTO   TO app_emprestimosdb;
GRANT SELECT ON SEQ_EVENTO               TO app_emprestimosdb;
GRANT SELECT ON SEQ_HORARIO_EVENTO       TO app_emprestimosdb;

-- ── Yasin (app_materiaisdb) ─────────────────────────────────
GRANT SELECT ON BIBLIOTECA               TO app_materiaisdb;
GRANT SELECT ON EVENTO                   TO app_materiaisdb;
GRANT SELECT ON PARTICIPACAO_EVENTO      TO app_materiaisdb;
GRANT SELECT ON HORARIO_BIBLIOTECA       TO app_materiaisdb;
GRANT SELECT ON v_bibliotecas_activas    TO app_materiaisdb;
GRANT SELECT ON v_horarios_bibliotecas   TO app_materiaisdb;
GRANT SELECT ON v_programacao_eventos    TO app_materiaisdb;
GRANT SELECT ON vw_eventos_proximos      TO app_materiaisdb;
GRANT SELECT ON vw_eventos_completos     TO app_materiaisdb;
-- Transparencia: DML e sequencias para criar/editar eventos de qualquer no
GRANT INSERT, UPDATE ON EVENTO           TO app_materiaisdb;
GRANT SELECT, INSERT ON HORARIO_EVENTO   TO app_materiaisdb;
GRANT SELECT ON SEQ_EVENTO               TO app_materiaisdb;
GRANT SELECT ON SEQ_HORARIO_EVENTO       TO app_materiaisdb;

-- ── Helder (app_nacionaldb) ─────────────────────────────────
-- Supervisao e gestao cross-node
GRANT SELECT ON BIBLIOTECA               TO app_nacionaldb;
GRANT SELECT ON BIBLIOTECA_RESPONSAVEL   TO app_nacionaldb;
GRANT SELECT ON EVENTO                   TO app_nacionaldb;
GRANT SELECT ON PARTICIPACAO_EVENTO      TO app_nacionaldb;
GRANT SELECT ON AVALIACAO_EVENTO         TO app_nacionaldb;
GRANT SELECT ON HORARIO_EVENTO           TO app_nacionaldb;
GRANT SELECT ON HORARIO_BIBLIOTECA       TO app_nacionaldb;
GRANT SELECT ON v_programacao_eventos    TO app_nacionaldb;
GRANT SELECT ON v_horarios_bibliotecas   TO app_nacionaldb;
GRANT SELECT ON v_bibliotecas_activas    TO app_nacionaldb;
GRANT SELECT ON vw_eventos_proximos      TO app_nacionaldb;
GRANT SELECT ON vw_eventos_completos     TO app_nacionaldb;
GRANT SELECT ON vw_bibliotecas_operacionais   TO app_nacionaldb;
GRANT SELECT ON vw_horarios_biblioteca_semana TO app_nacionaldb;
GRANT SELECT ON vw_participacoes_eventos      TO app_nacionaldb;
-- DML para prc_apagar_leitor e gestao de participacoes
GRANT DELETE ON PARTICIPACAO_EVENTO      TO app_nacionaldb;
GRANT DELETE ON AVALIACAO_EVENTO         TO app_nacionaldb;
GRANT INSERT ON AUDITORIA_EVENTOS        TO app_nacionaldb;
-- NacionalDB usa seq_avaliacao directamente para INSERT em AVALIACAO_EVENTO
GRANT SELECT ON SEQ_AVALIACAO            TO app_nacionaldb;
-- Procedimento de participacao chamado via dblink
GRANT EXECUTE ON INSERE_PARTICIPACAO_EVENTO TO app_nacionaldb;
-- Transparencia: criar/editar eventos e horarios de qualquer no
GRANT INSERT, UPDATE ON EVENTO           TO app_nacionaldb;
GRANT INSERT ON HORARIO_EVENTO           TO app_nacionaldb;
GRANT SELECT ON SEQ_EVENTO               TO app_nacionaldb;
GRANT SELECT ON SEQ_HORARIO_EVENTO       TO app_nacionaldb;
