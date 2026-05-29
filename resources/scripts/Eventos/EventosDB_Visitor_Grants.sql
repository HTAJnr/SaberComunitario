-- ============================================================
-- GRANTS PARA VISITOR USERS - EventosBibliotecasDB (v4)
-- Executar como usr_eventosdb
-- ============================================================

-- -- Para o Helder (app_nacionaldb) -------------------------
-- Leitura de dados base
GRANT SELECT ON BIBLIOTECA              TO app_nacionaldb;
GRANT SELECT ON EVENTO                  TO app_nacionaldb;
GRANT SELECT ON PARTICIPACAO_EVENTO     TO app_nacionaldb;
GRANT SELECT ON AVALIACAO_EVENTO        TO app_nacionaldb;
GRANT SELECT ON HORARIO_BIBLIOTECA      TO app_nacionaldb;

-- Vistas de servico
GRANT SELECT ON v_programacao_eventos   TO app_nacionaldb;
GRANT SELECT ON v_horarios_bibliotecas  TO app_nacionaldb;
GRANT SELECT ON v_bibliotecas_activas   TO app_nacionaldb;

-- prc_apagar_leitor: limpa participacoes e avaliacoes do leitor eliminado
GRANT DELETE ON PARTICIPACAO_EVENTO     TO app_nacionaldb;
GRANT DELETE ON AVALIACAO_EVENTO        TO app_nacionaldb;

-- Reclamacoes do EventosDB enviadas ao BibliotecaNacionalDB (enunciado p.3)
GRANT INSERT ON AUDITORIA_EVENTOS       TO app_nacionaldb;

-- -- Para o Yasin (app_materiaisdb) -------------------------
-- Leitura de bibliotecas para associar materiais
GRANT SELECT ON BIBLIOTECA              TO app_materiaisdb;
GRANT SELECT ON v_bibliotecas_activas   TO app_materiaisdb;

-- Horarios para planeamento de eventos tematicos (enunciado p.3)
GRANT SELECT ON HORARIO_BIBLIOTECA      TO app_materiaisdb;
GRANT SELECT ON v_horarios_bibliotecas  TO app_materiaisdb;

-- Eventos para coordenar transferencias de materiais (enunciado p.3)
GRANT SELECT ON EVENTO                  TO app_materiaisdb;
GRANT SELECT ON v_programacao_eventos   TO app_materiaisdb;

-- -- Para o Yannis (app_emprestimosdb) ----------------------
-- Acesso minimo (link removido mas visitor user mantido)
GRANT SELECT ON BIBLIOTECA              TO app_emprestimosdb;
GRANT SELECT ON v_bibliotecas_activas   TO app_emprestimosdb;

-- ============================================================
-- Verificar todos os grants por visitor user
-- ============================================================
SELECT GRANTEE, TABLE_NAME, PRIVILEGE
FROM USER_TAB_PRIVS
WHERE GRANTEE IN ('APP_NACIONALDB','APP_MATERIAISDB','APP_EMPRESTIMOSDB')
ORDER BY GRANTEE, TABLE_NAME;