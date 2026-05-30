-- ============================================================
-- BibNacional_Grants.sql
-- Permissões completas para app_NACIONALDB e visitor users
-- Executar como usr_NACIONALDB:
--   sqlplus usr_NACIONALDB/"HTAJnr#020403" @/root/TP/BibNacional_Grants.sql
-- ============================================================


-- ============================================================
-- SECÇÃO 1: POPULAR O ROLE DE LEITURA (app_NACIONALDB local)
-- O role foi criado mas nunca recebeu privilégios.
-- NOTA: mesmo com o role populado, os grants directos da
-- Secção 3 continuam a ser necessários para acesso cross-node
-- via dblink (roles nao transitam por dblink no Oracle).
-- ============================================================

-- Tabelas base — leitura
GRANT SELECT ON FUNCAO_FUNCIONARIO      TO role_NACIONALDB_read;
GRANT SELECT ON FUNCIONARIO             TO role_NACIONALDB_read;
GRANT SELECT ON FUNCIONARIO_HABILIDADE  TO role_NACIONALDB_read;
GRANT SELECT ON HORARIO_FUNCIONARIO     TO role_NACIONALDB_read;
GRANT SELECT ON LEITOR                  TO role_NACIONALDB_read;
GRANT SELECT ON ADULTO                  TO role_NACIONALDB_read;
GRANT SELECT ON ADULTO_INTERESSE        TO role_NACIONALDB_read;
GRANT SELECT ON PROFESSOR               TO role_NACIONALDB_read;
GRANT SELECT ON PROFESSOR_DISCIPLINA    TO role_NACIONALDB_read;
GRANT SELECT ON CRIANCA                 TO role_NACIONALDB_read;
GRANT SELECT ON DOADOR                  TO role_NACIONALDB_read;
GRANT SELECT ON DOACAO                  TO role_NACIONALDB_read;
GRANT SELECT ON ITEM_DOACAO             TO role_NACIONALDB_read;
GRANT SELECT ON CERTIFICADO_DOACAO      TO role_NACIONALDB_read;
GRANT SELECT ON AUDITORIA_OPERACOES     TO role_NACIONALDB_read;

-- Snapshots (MVs locais) — leitura
GRANT SELECT ON biblioteca_snap                 TO role_NACIONALDB_read;
GRANT SELECT ON snap_material_basico            TO role_NACIONALDB_read;
GRANT SELECT ON snap_emp_activos                TO role_NACIONALDB_read;
GRANT SELECT ON snap_eventos                    TO role_NACIONALDB_read;
GRANT SELECT ON snap_transferencias             TO role_NACIONALDB_read;

-- Vistas — leitura
GRANT SELECT ON vw_doacoes_detalhadas           TO role_NACIONALDB_read;
GRANT SELECT ON vw_doadores_ranking             TO role_NACIONALDB_read;
GRANT SELECT ON vw_certificados_emitidos        TO role_NACIONALDB_read;
GRANT SELECT ON vw_funcionarios_ativos          TO role_NACIONALDB_read;
GRANT SELECT ON vw_acesso_funcionario           TO role_NACIONALDB_read;
GRANT SELECT ON vw_horarios_funcionario_semana  TO role_NACIONALDB_read;
GRANT SELECT ON vw_leitores_completos           TO role_NACIONALDB_read;
GRANT SELECT ON vw_leitor_publico               TO role_NACIONALDB_read;
GRANT SELECT ON vw_leitor_privado               TO role_NACIONALDB_read;
GRANT SELECT ON vw_global_leitores_emprestimos  TO role_NACIONALDB_read;
GRANT SELECT ON vw_global_catalogo              TO role_NACIONALDB_read;
GRANT SELECT ON vw_global_eventos_participacao  TO role_NACIONALDB_read;
-- Fragmentação horizontal de LEITOR (Tarefa A3)
GRANT SELECT ON vw_frag_leitor_activos          TO role_NACIONALDB_read;
GRANT SELECT ON vw_frag_leitor_suspensos        TO role_NACIONALDB_read;
GRANT SELECT ON vw_frag_leitor_inactivos        TO role_NACIONALDB_read;
GRANT SELECT ON vw_replica_funcionarios         TO role_NACIONALDB_read;
GRANT SELECT ON vw_func_activos_operacional     TO role_NACIONALDB_read;
GRANT SELECT ON vw_func_activos_confidencial    TO role_NACIONALDB_read;
GRANT SELECT ON vw_func_inactivos_operacional   TO role_NACIONALDB_read;
GRANT SELECT ON vw_func_inactivos_confidencial  TO role_NACIONALDB_read;
GRANT SELECT ON VW_AUDITORIA                    TO role_NACIONALDB_read;
GRANT SELECT ON vw_metricas_sistema             TO role_NACIONALDB_read;
GRANT SELECT ON vw_metricas_por_biblioteca      TO role_NACIONALDB_read;

-- Sequências — leitura
GRANT SELECT ON SEQ_FUNCAO       TO role_NACIONALDB_read;
GRANT SELECT ON SEQ_FUNCIONARIO  TO role_NACIONALDB_read;
GRANT SELECT ON SEQ_HORARIO_FUNC TO role_NACIONALDB_read;
GRANT SELECT ON SEQ_DOADOR       TO role_NACIONALDB_read;
GRANT SELECT ON SEQ_DOACAO       TO role_NACIONALDB_read;
GRANT SELECT ON SEQ_ITEMDOADO    TO role_NACIONALDB_read;
GRANT SELECT ON SEQ_CERTIFICADO  TO role_NACIONALDB_read;
GRANT SELECT ON SEQ_AUDITORIA    TO role_NACIONALDB_read;


-- ============================================================
-- SECÇÃO 2: POPULAR O ROLE DE ESCRITA (app_NACIONALDB local)
-- ============================================================

GRANT INSERT, UPDATE, DELETE ON FUNCIONARIO            TO role_NACIONALDB_write;
GRANT INSERT, UPDATE, DELETE ON FUNCIONARIO_HABILIDADE TO role_NACIONALDB_write;
GRANT INSERT, UPDATE, DELETE ON HORARIO_FUNCIONARIO    TO role_NACIONALDB_write;
GRANT INSERT, UPDATE, DELETE ON LEITOR                 TO role_NACIONALDB_write;
GRANT INSERT, UPDATE, DELETE ON ADULTO                 TO role_NACIONALDB_write;
GRANT INSERT, UPDATE, DELETE ON ADULTO_INTERESSE       TO role_NACIONALDB_write;
GRANT INSERT, UPDATE, DELETE ON PROFESSOR              TO role_NACIONALDB_write;
GRANT INSERT, UPDATE, DELETE ON PROFESSOR_DISCIPLINA   TO role_NACIONALDB_write;
GRANT INSERT, UPDATE, DELETE ON CRIANCA                TO role_NACIONALDB_write;
GRANT INSERT, UPDATE, DELETE ON DOADOR                 TO role_NACIONALDB_write;
GRANT INSERT, UPDATE, DELETE ON DOACAO                 TO role_NACIONALDB_write;
GRANT INSERT, UPDATE, DELETE ON ITEM_DOACAO            TO role_NACIONALDB_write;
GRANT INSERT, UPDATE, DELETE ON CERTIFICADO_DOACAO     TO role_NACIONALDB_write;
-- AUDITORIA: só INSERT — ninguém apaga registos de auditoria
GRANT INSERT ON AUDITORIA_OPERACOES                    TO role_NACIONALDB_write;
-- Gestão de permissões (módulo Admin)
GRANT INSERT, UPDATE, DELETE ON FUNCAO_FUNCIONARIO     TO role_NACIONALDB_write;

-- Sequências — NEXTVAL
GRANT SELECT ON SEQ_FUNCAO       TO role_NACIONALDB_write;
GRANT SELECT ON SEQ_FUNCIONARIO  TO role_NACIONALDB_write;
GRANT SELECT ON SEQ_HORARIO_FUNC TO role_NACIONALDB_write;
GRANT SELECT ON SEQ_DOADOR       TO role_NACIONALDB_write;
GRANT SELECT ON SEQ_DOACAO       TO role_NACIONALDB_write;
GRANT SELECT ON SEQ_ITEMDOADO    TO role_NACIONALDB_write;
GRANT SELECT ON SEQ_CERTIFICADO  TO role_NACIONALDB_write;
GRANT SELECT ON SEQ_AUDITORIA    TO role_NACIONALDB_write;

-- NOTA: GRANT role_NACIONALDB_write TO app_NACIONALDB está em BibNacional_Roles.sql


-- ============================================================
-- SECÇÃO 3: ROLES PARA VISITOR USERS
-- Simplificam a gestao local; grants directos (Secção 4)
-- sao obrigatorios para acesso via dblink.
-- ============================================================

-- role_nac_visitante — acesso base para todos os nos visitantes
-- Inclui: leitores, funcionarios, metricas e snapshots
-- (roles criados em BibNacional_Roles.sql como SYSDBA)
GRANT SELECT ON LEITOR                      TO role_nac_visitante;
GRANT SELECT ON ADULTO                      TO role_nac_visitante;
GRANT SELECT ON FUNCIONARIO                 TO role_nac_visitante;
GRANT SELECT ON FUNCAO_FUNCIONARIO          TO role_nac_visitante;
GRANT SELECT ON vw_leitor_publico           TO role_nac_visitante;
GRANT SELECT ON vw_replica_funcionarios     TO role_nac_visitante;
GRANT SELECT ON vw_metricas_sistema         TO role_nac_visitante;
GRANT SELECT ON vw_metricas_por_biblioteca  TO role_nac_visitante;
GRANT SELECT ON snap_material_basico        TO role_nac_visitante;
GRANT SELECT ON snap_emp_activos            TO role_nac_visitante;
GRANT SELECT ON snap_eventos                TO role_nac_visitante;
GRANT SELECT ON snap_transferencias         TO role_nac_visitante;

-- role_nac_leitor_tipo — tipos de leitor para validacoes de emprestimo/evento
-- Destinatarios: app_emprestimosdb, app_eventosdb
GRANT SELECT ON CRIANCA                     TO role_nac_leitor_tipo;
GRANT SELECT ON PROFESSOR                   TO role_nac_leitor_tipo;
GRANT SELECT ON vw_func_activos_operacional TO role_nac_leitor_tipo;

-- (atribuicao de roles feita em BibNacional_Roles.sql como SYSDBA)


-- ============================================================
-- SECÇÃO 4: GRANTS DIRECTOS AOS VISITOR USERS
-- Obrigatorios para acesso via dblink + DML exclusivo por no.
-- ── Dashboard: visitor users precisam das views de metricas e
--    snapshots quando o backend corre noutro no.
-- ============================================================

-- ── Yannis (app_emprestimosdb) ──────────────────────────────

-- RN01: trigger verifica status_leitor antes de criar emprestimo
GRANT SELECT ON LEITOR                          TO app_emprestimosdb;
GRANT SELECT ON vw_leitor_publico               TO app_emprestimosdb;

-- RN03: trigger de devolucao actualiza status_leitor
GRANT UPDATE ON LEITOR                          TO app_emprestimosdb;

-- RN01/RN04.1: verificar tipo de leitor
GRANT SELECT ON ADULTO                          TO app_emprestimosdb;
GRANT SELECT ON PROFESSOR                       TO app_emprestimosdb;
GRANT SELECT ON CRIANCA                         TO app_emprestimosdb;

-- Verificacao de nivel de acesso cross-node
GRANT SELECT ON FUNCAO_FUNCIONARIO              TO app_emprestimosdb;
GRANT SELECT ON FUNCIONARIO                     TO app_emprestimosdb;
GRANT SELECT ON vw_func_activos_operacional     TO app_emprestimosdb;
GRANT SELECT ON vw_replica_funcionarios         TO app_emprestimosdb;

-- Dashboard e snapshots
GRANT SELECT ON vw_metricas_sistema             TO app_emprestimosdb;
GRANT SELECT ON vw_metricas_por_biblioteca      TO app_emprestimosdb;
GRANT SELECT ON snap_material_basico            TO app_emprestimosdb;
GRANT SELECT ON snap_emp_activos                TO app_emprestimosdb;
GRANT SELECT ON snap_eventos                    TO app_emprestimosdb;
GRANT SELECT ON snap_transferencias             TO app_emprestimosdb;

-- ── Yasin (app_materiaisdb) ─────────────────────────────────

-- RN09: e-books exigem leitor adulto
GRANT SELECT ON LEITOR                          TO app_materiaisdb;
GRANT SELECT ON ADULTO                          TO app_materiaisdb;
GRANT SELECT ON vw_leitor_publico               TO app_materiaisdb;

-- Replicacao de funcionarios
GRANT SELECT ON vw_replica_funcionarios         TO app_materiaisdb;
GRANT SELECT ON FUNCIONARIO                     TO app_materiaisdb;
GRANT SELECT ON FUNCAO_FUNCIONARIO              TO app_materiaisdb;

-- Dashboard e snapshots
GRANT SELECT ON vw_metricas_sistema             TO app_materiaisdb;
GRANT SELECT ON vw_metricas_por_biblioteca      TO app_materiaisdb;
GRANT SELECT ON snap_material_basico            TO app_materiaisdb;
GRANT SELECT ON snap_emp_activos                TO app_materiaisdb;
GRANT SELECT ON snap_eventos                    TO app_materiaisdb;
GRANT SELECT ON snap_transferencias             TO app_materiaisdb;

-- ── Gerson (app_eventosdb) ──────────────────────────────────

-- Verificacao de leitores antes de inscrever em eventos
GRANT SELECT ON LEITOR                          TO app_eventosdb;
GRANT SELECT ON vw_leitor_publico               TO app_eventosdb;
GRANT SELECT ON ADULTO                          TO app_eventosdb;
GRANT SELECT ON CRIANCA                         TO app_eventosdb;
GRANT SELECT ON PROFESSOR                       TO app_eventosdb;

-- Verificacao de funcionarios (responsavel de evento/biblioteca)
GRANT SELECT ON FUNCIONARIO                     TO app_eventosdb;
GRANT SELECT ON FUNCAO_FUNCIONARIO              TO app_eventosdb;
GRANT SELECT ON vw_func_activos_operacional     TO app_eventosdb;
GRANT SELECT ON vw_replica_funcionarios         TO app_eventosdb;

-- Dashboard e snapshots
GRANT SELECT ON vw_metricas_sistema             TO app_eventosdb;
GRANT SELECT ON vw_metricas_por_biblioteca      TO app_eventosdb;
GRANT SELECT ON snap_material_basico            TO app_eventosdb;
GRANT SELECT ON snap_emp_activos                TO app_eventosdb;
GRANT SELECT ON snap_eventos                    TO app_eventosdb;
GRANT SELECT ON snap_transferencias             TO app_eventosdb;

-- ── Backend local (app_NACIONALDB) ──────────────────────────
-- O Node.js usa este user para DML e execucao de procedures.
GRANT EXECUTE ON registrar_doacao_completa      TO app_NACIONALDB;
GRANT EXECUTE ON reemitir_certificado           TO app_NACIONALDB;
GRANT EXECUTE ON proc_gerir_acesso_bd           TO app_NACIONALDB;
GRANT EXECUTE ON prc_registar_auditoria         TO app_NACIONALDB;
GRANT EXECUTE ON prc_apagar_leitor              TO app_NACIONALDB;
GRANT EXECUTE ON prc_remover_funcionario        TO app_NACIONALDB;
GRANT EXECUTE ON prc_modificar_nivel_acesso     TO app_NACIONALDB;
GRANT EXECUTE ON prc_demo_2pc                   TO app_NACIONALDB;
GRANT EXECUTE ON prc_emitir_honorifico          TO app_NACIONALDB;
GRANT EXECUTE ON total_doacoes_doador           TO app_NACIONALDB;
GRANT EXECUTE ON prc_atualizar_doacao_segura    TO app_NACIONALDB;
