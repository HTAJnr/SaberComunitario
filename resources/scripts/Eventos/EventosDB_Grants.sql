-- ============================================================
-- GRANTS - EventosBibliotecasDB (v4)
-- Executar como usr_eventosdb
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
GRANT SELECT ON AUDITORIA_EVENTOS           TO app_eventosdb;

-- Vistas de servico
GRANT SELECT ON v_programacao_eventos       TO app_eventosdb;
GRANT SELECT ON v_horarios_bibliotecas      TO app_eventosdb;
GRANT SELECT ON v_bibliotecas_activas       TO app_eventosdb;
GRANT SELECT ON v_evento_global             TO app_eventosdb;

-- Vistas de fragmento originais
GRANT SELECT ON frag_evento_sul             TO app_eventosdb;
GRANT SELECT ON frag_evento_centro          TO app_eventosdb;
GRANT SELECT ON frag_evento_norte           TO app_eventosdb;

-- Vistas de fragmentacao horizontal (Tarefa A1)
GRANT SELECT ON vw_frag_evento_futuro       TO app_eventosdb;
GRANT SELECT ON vw_frag_evento_passado      TO app_eventosdb;

-- Vistas de fragmentacao derivada (Tarefa A2)
GRANT SELECT ON vw_frag_participacao_futuro  TO app_eventosdb;
GRANT SELECT ON vw_frag_participacao_passado TO app_eventosdb;

-- Sequencias
GRANT SELECT ON SEQ_EVENTO                  TO app_eventosdb;
GRANT SELECT ON SEQ_AUDITORIA_EVT           TO app_eventosdb;
GRANT SELECT ON SEQ_HORARIO_EVENTO          TO app_eventosdb;

-- Verificar
SELECT TABLE_NAME, PRIVILEGE, GRANTEE
FROM USER_TAB_PRIVS
WHERE GRANTEE = 'APP_EVENTOSDB'
ORDER BY TABLE_NAME;