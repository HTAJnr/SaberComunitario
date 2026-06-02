-- ============================================================
-- BibNacional_Grants.sql
-- Grants directos a app_NACIONALDB e visitor users.
-- Executar como usr_NACIONALDB:
--   sqlplus usr_NACIONALDB/"HTAJnr#020403" @/root/TP/BibNacional_Grants.sql
-- Nota: roles removidos — Oracle 10g nao activa roles em todos
-- os contextos de sessao; grants directos sao obrigatorios.
-- ============================================================


-- ============================================================
-- SECÇÃO 1: GRANTS AOS ROLES LOCAIS
-- Roles funcionam em sessao directa (nao via dblink).
-- Grants directos na Secção 2 sao a autoridade efectiva;
-- estes grants documentam o modelo de controlo de acesso por role.
-- ============================================================

GRANT SELECT ON FUNCAO_FUNCIONARIO     TO role_NACIONALDB_read;
GRANT SELECT ON FUNCIONARIO            TO role_NACIONALDB_read;
GRANT SELECT ON FUNCIONARIO_HABILIDADE TO role_NACIONALDB_read;
GRANT SELECT ON HORARIO_FUNCIONARIO    TO role_NACIONALDB_read;
GRANT SELECT ON LEITOR                 TO role_NACIONALDB_read;
GRANT SELECT ON ADULTO                 TO role_NACIONALDB_read;
GRANT SELECT ON ADULTO_INTERESSE       TO role_NACIONALDB_read;
GRANT SELECT ON PROFESSOR              TO role_NACIONALDB_read;
GRANT SELECT ON PROFESSOR_DISCIPLINA   TO role_NACIONALDB_read;
GRANT SELECT ON CRIANCA                TO role_NACIONALDB_read;
GRANT SELECT ON DOADOR                 TO role_NACIONALDB_read;
GRANT SELECT ON DOACAO                 TO role_NACIONALDB_read;
GRANT SELECT ON ITEM_DOACAO            TO role_NACIONALDB_read;
GRANT SELECT ON CERTIFICADO_DOACAO     TO role_NACIONALDB_read;
GRANT SELECT ON AUDITORIA_OPERACOES    TO role_NACIONALDB_read;
GRANT SELECT ON PERMISSAO_CARGO        TO role_NACIONALDB_read;
GRANT SELECT ON biblioteca_snap        TO role_NACIONALDB_read;
GRANT SELECT ON snap_material_basico   TO role_NACIONALDB_read;
GRANT SELECT ON snap_emp_activos       TO role_NACIONALDB_read;
GRANT SELECT ON snap_eventos           TO role_NACIONALDB_read;
GRANT SELECT ON snap_transferencias    TO role_NACIONALDB_read;

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
GRANT INSERT                 ON AUDITORIA_OPERACOES    TO role_NACIONALDB_write;
GRANT INSERT, UPDATE, DELETE ON FUNCAO_FUNCIONARIO     TO role_NACIONALDB_write;
GRANT INSERT, UPDATE, DELETE ON PERMISSAO_CARGO        TO role_NACIONALDB_write;


-- ============================================================
-- SECÇÃO 2: GRANTS DIRECTOS AOS VISITOR USERS
-- Obrigatorios para acesso via dblink + DML exclusivo por no.
-- ── Dashboard: visitor users precisam das views de metricas e
--    snapshots quando o backend corre noutro no.
-- ============================================================

-- ── AUDITORIA CROSS-NODE ─────────────────────────────────────
-- O middleware registar() insere em AUDITORIA_OPERACOES + usa SEQ_AUDITORIA
-- independentemente do no logado. Os visitor users precisam de acesso directo
-- (roles nao transitam por dblink — ORA-02289 sem estes grants).
GRANT INSERT ON AUDITORIA_OPERACOES TO app_emprestimosdb;
GRANT INSERT ON AUDITORIA_OPERACOES TO app_eventosdb;
GRANT INSERT ON AUDITORIA_OPERACOES TO app_materiaisdb;
GRANT SELECT ON SEQ_AUDITORIA       TO app_emprestimosdb;
GRANT SELECT ON SEQ_AUDITORIA       TO app_eventosdb;
GRANT SELECT ON SEQ_AUDITORIA       TO app_materiaisdb;

-- ── Yannis (app_emprestimosdb) ──────────────────────────────

-- Doacoes — DML cross-node (modulo acessivel de qualquer no)
GRANT SELECT, INSERT, UPDATE, DELETE ON DOACAO            TO app_emprestimosdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON ITEM_DOACAO       TO app_emprestimosdb;
GRANT SELECT, INSERT                 ON DOADOR            TO app_emprestimosdb;
GRANT SELECT, INSERT                 ON CERTIFICADO_DOACAO TO app_emprestimosdb;
GRANT SELECT                         ON SEQ_DOACAO        TO app_emprestimosdb;
GRANT SELECT                         ON SEQ_ITEMDOADO     TO app_emprestimosdb;
GRANT SELECT                         ON SEQ_DOADOR        TO app_emprestimosdb;
GRANT SELECT                         ON SEQ_CERTIFICADO   TO app_emprestimosdb;
-- Permissoes — so leitura (escrita exclusiva do NacionalDB per enunciado)
GRANT SELECT                         ON PERMISSAO_CARGO   TO app_emprestimosdb;
GRANT SELECT                         ON SEQ_PERMISSAO     TO app_emprestimosdb;

-- Leitores — DML cross-node (criar/editar de qualquer no)
GRANT SELECT, INSERT ON LEITOR                  TO app_emprestimosdb;
GRANT SELECT ON vw_leitor_publico               TO app_emprestimosdb;
GRANT SELECT ON vw_leitores_completos           TO app_emprestimosdb;
-- RN03: trigger de devolucao actualiza status_leitor (UPDATE ja existia)
GRANT UPDATE ON LEITOR                          TO app_emprestimosdb;
-- Subtipos de leitor — DML para criar/editar de qualquer no
GRANT SELECT, INSERT, UPDATE ON ADULTO          TO app_emprestimosdb;
GRANT SELECT, INSERT, DELETE ON ADULTO_INTERESSE TO app_emprestimosdb;
GRANT SELECT, INSERT, UPDATE ON PROFESSOR       TO app_emprestimosdb;
GRANT SELECT, INSERT, DELETE ON PROFESSOR_DISCIPLINA TO app_emprestimosdb;
GRANT SELECT, INSERT, UPDATE ON CRIANCA         TO app_emprestimosdb;

-- Funcionarios — DML cross-node (criar/editar/desactivar de qualquer no)
-- DELETE de funcionario e soft-delete (UPDATE DATA_DEMISSAO) — coberto pelo UPDATE
GRANT SELECT ON FUNCAO_FUNCIONARIO              TO app_emprestimosdb;
GRANT SELECT, INSERT, UPDATE ON FUNCIONARIO     TO app_emprestimosdb;
GRANT SELECT, INSERT, DELETE ON FUNCIONARIO_HABILIDADE TO app_emprestimosdb;
GRANT SELECT, INSERT, DELETE ON HORARIO_FUNCIONARIO    TO app_emprestimosdb;
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

-- Doacoes — DML cross-node
GRANT SELECT, INSERT, UPDATE, DELETE ON DOACAO            TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON ITEM_DOACAO       TO app_materiaisdb;
GRANT SELECT, INSERT                 ON DOADOR            TO app_materiaisdb;
GRANT SELECT, INSERT                 ON CERTIFICADO_DOACAO TO app_materiaisdb;
GRANT SELECT                         ON SEQ_DOACAO        TO app_materiaisdb;
GRANT SELECT                         ON SEQ_ITEMDOADO     TO app_materiaisdb;
GRANT SELECT                         ON SEQ_DOADOR        TO app_materiaisdb;
GRANT SELECT                         ON SEQ_CERTIFICADO   TO app_materiaisdb;
-- Permissoes — so leitura
GRANT SELECT                         ON PERMISSAO_CARGO   TO app_materiaisdb;
GRANT SELECT                         ON SEQ_PERMISSAO     TO app_materiaisdb;

-- Leitores — DML cross-node (criar/editar de qualquer no)
GRANT SELECT, INSERT, UPDATE ON LEITOR          TO app_materiaisdb;
GRANT SELECT ON vw_leitor_publico               TO app_materiaisdb;
GRANT SELECT ON vw_leitores_completos           TO app_materiaisdb;
-- Subtipos de leitor — DML para criar/editar de qualquer no
GRANT SELECT, INSERT, UPDATE ON ADULTO          TO app_materiaisdb;
GRANT SELECT, INSERT, DELETE ON ADULTO_INTERESSE TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE ON PROFESSOR       TO app_materiaisdb;
GRANT SELECT, INSERT, DELETE ON PROFESSOR_DISCIPLINA TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE ON CRIANCA         TO app_materiaisdb;

-- Funcionarios — DML cross-node (criar/editar/desactivar de qualquer no)
GRANT SELECT ON FUNCAO_FUNCIONARIO              TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE ON FUNCIONARIO     TO app_materiaisdb;
GRANT SELECT, INSERT, DELETE ON FUNCIONARIO_HABILIDADE TO app_materiaisdb;
GRANT SELECT, INSERT, DELETE ON HORARIO_FUNCIONARIO    TO app_materiaisdb;
GRANT SELECT ON vw_replica_funcionarios         TO app_materiaisdb;

-- Dashboard e snapshots
GRANT SELECT ON vw_metricas_sistema             TO app_materiaisdb;
GRANT SELECT ON vw_metricas_por_biblioteca      TO app_materiaisdb;
GRANT SELECT ON snap_material_basico            TO app_materiaisdb;
GRANT SELECT ON snap_emp_activos                TO app_materiaisdb;
GRANT SELECT ON snap_eventos                    TO app_materiaisdb;
GRANT SELECT ON snap_transferencias             TO app_materiaisdb;

-- ── Gerson (app_eventosdb) ──────────────────────────────────

-- Doacoes — DML cross-node
GRANT SELECT, INSERT, UPDATE, DELETE ON DOACAO            TO app_eventosdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON ITEM_DOACAO       TO app_eventosdb;
GRANT SELECT, INSERT                 ON DOADOR            TO app_eventosdb;
GRANT SELECT, INSERT                 ON CERTIFICADO_DOACAO TO app_eventosdb;
GRANT SELECT                         ON SEQ_DOACAO        TO app_eventosdb;
GRANT SELECT                         ON SEQ_ITEMDOADO     TO app_eventosdb;
GRANT SELECT                         ON SEQ_DOADOR        TO app_eventosdb;
GRANT SELECT                         ON SEQ_CERTIFICADO   TO app_eventosdb;
-- Permissoes — so leitura
GRANT SELECT                         ON PERMISSAO_CARGO   TO app_eventosdb;
GRANT SELECT                         ON SEQ_PERMISSAO     TO app_eventosdb;

-- Leitores — DML cross-node (criar/editar de qualquer no)
GRANT SELECT, INSERT, UPDATE ON LEITOR          TO app_eventosdb;
GRANT SELECT ON vw_leitor_publico               TO app_eventosdb;
GRANT SELECT ON vw_leitores_completos           TO app_eventosdb;
-- Subtipos de leitor — DML para criar/editar de qualquer no
GRANT SELECT, INSERT, UPDATE ON ADULTO          TO app_eventosdb;
GRANT SELECT, INSERT, DELETE ON ADULTO_INTERESSE TO app_eventosdb;
GRANT SELECT, INSERT, UPDATE ON PROFESSOR       TO app_eventosdb;
GRANT SELECT, INSERT, DELETE ON PROFESSOR_DISCIPLINA TO app_eventosdb;
GRANT SELECT, INSERT, UPDATE ON CRIANCA         TO app_eventosdb;

-- Funcionarios — DML cross-node (criar/editar/desactivar de qualquer no)
GRANT SELECT ON FUNCAO_FUNCIONARIO              TO app_eventosdb;
GRANT SELECT, INSERT, UPDATE ON FUNCIONARIO     TO app_eventosdb;
GRANT SELECT, INSERT, DELETE ON FUNCIONARIO_HABILIDADE TO app_eventosdb;
GRANT SELECT, INSERT, DELETE ON HORARIO_FUNCIONARIO    TO app_eventosdb;
GRANT SELECT ON vw_func_activos_operacional     TO app_eventosdb;
GRANT SELECT ON vw_replica_funcionarios         TO app_eventosdb;

-- Dashboard e snapshots
GRANT SELECT ON vw_metricas_sistema             TO app_eventosdb;
GRANT SELECT ON vw_metricas_por_biblioteca      TO app_eventosdb;
GRANT SELECT ON snap_material_basico            TO app_eventosdb;
GRANT SELECT ON snap_emp_activos                TO app_eventosdb;
GRANT SELECT ON snap_eventos                    TO app_eventosdb;
GRANT SELECT ON snap_transferencias             TO app_eventosdb;

-- ── Transparencia: sequencias e vistas de doacoes cross-node ──
-- SEQ_FUNCIONARIO e SEQ_HORARIO_FUNC: necessarias para CREATE FUNCIONARIO de qualquer no
-- (roles nao transitam por dblink — ORA-02289 sem grants directos)
GRANT SELECT ON SEQ_FUNCIONARIO          TO app_emprestimosdb;
GRANT SELECT ON SEQ_FUNCIONARIO          TO app_eventosdb;
GRANT SELECT ON SEQ_FUNCIONARIO          TO app_materiaisdb;

-- reemitir_certificado: procedure chamada de qualquer no (modulo doacoes cross-node)
GRANT EXECUTE ON reemitir_certificado    TO app_emprestimosdb;
GRANT EXECUTE ON reemitir_certificado    TO app_eventosdb;
GRANT EXECUTE ON reemitir_certificado    TO app_materiaisdb;
GRANT SELECT ON SEQ_HORARIO_FUNC         TO app_emprestimosdb;
GRANT SELECT ON SEQ_HORARIO_FUNC         TO app_eventosdb;
GRANT SELECT ON SEQ_HORARIO_FUNC         TO app_materiaisdb;

-- vw_doacoes_detalhadas e vw_certificados_emitidos: vistas de NacionalDB
-- precisam de ser acessiveis de qualquer no para o modulo de doacoes/certificados
GRANT SELECT ON vw_doacoes_detalhadas    TO app_emprestimosdb;
GRANT SELECT ON vw_doacoes_detalhadas    TO app_eventosdb;
GRANT SELECT ON vw_doacoes_detalhadas    TO app_materiaisdb;
GRANT SELECT ON vw_certificados_emitidos TO app_emprestimosdb;
GRANT SELECT ON vw_certificados_emitidos TO app_eventosdb;
GRANT SELECT ON vw_certificados_emitidos TO app_materiaisdb;

-- ── Backend local (app_NACIONALDB) ──────────────────────────
-- O Node.js usa este user para DML e execucao de procedures.
GRANT EXECUTE ON registrar_doacao_completa      TO app_NACIONALDB;
GRANT EXECUTE ON reemitir_certificado           TO app_NACIONALDB;
GRANT EXECUTE ON prc_registar_auditoria         TO app_NACIONALDB;
GRANT EXECUTE ON prc_apagar_leitor              TO app_NACIONALDB;
GRANT EXECUTE ON prc_remover_funcionario        TO app_NACIONALDB;
GRANT EXECUTE ON prc_modificar_nivel_acesso     TO app_NACIONALDB;
GRANT EXECUTE ON prc_demo_2pc                   TO app_NACIONALDB;
GRANT EXECUTE ON prc_emitir_honorifico          TO app_NACIONALDB;
GRANT EXECUTE ON total_doacoes_doador           TO app_NACIONALDB;
GRANT EXECUTE ON prc_atualizar_doacao_segura    TO app_NACIONALDB;
GRANT EXECUTE ON prc_refresh_snapshots          TO app_NACIONALDB;
-- Sequencias: grants directos (roles nao sao activados em todos os
-- contextos de sessao no Oracle 10g — ORA-02289 sem estes grants)
GRANT SELECT ON SEQ_FUNCIONARIO          TO app_NACIONALDB;
GRANT SELECT ON SEQ_HORARIO_FUNC         TO app_NACIONALDB;
GRANT SELECT ON SEQ_DOADOR               TO app_NACIONALDB;
GRANT SELECT ON SEQ_DOACAO               TO app_NACIONALDB;
GRANT SELECT ON SEQ_ITEMDOADO            TO app_NACIONALDB;
GRANT SELECT ON SEQ_CERTIFICADO          TO app_NACIONALDB;
GRANT SELECT ON SEQ_AUDITORIA            TO app_NACIONALDB;
GRANT SELECT ON SEQ_FUNCAO               TO app_NACIONALDB;
GRANT SELECT ON SEQ_PERMISSAO            TO app_NACIONALDB;
GRANT SELECT, INSERT, UPDATE, DELETE ON PERMISSAO_CARGO TO app_NACIONALDB;

-- Tabelas: grants directos (roles nao sao activados em todos os contextos
-- de sessao no Oracle 10g — DML falha silenciosamente sem estes grants)
GRANT SELECT                         ON FUNCAO_FUNCIONARIO      TO app_NACIONALDB;
GRANT SELECT, INSERT, UPDATE, DELETE ON FUNCIONARIO             TO app_NACIONALDB;
GRANT SELECT, INSERT, UPDATE, DELETE ON FUNCIONARIO_HABILIDADE  TO app_NACIONALDB;
GRANT SELECT, INSERT, UPDATE, DELETE ON HORARIO_FUNCIONARIO     TO app_NACIONALDB;
GRANT INSERT                         ON AUDITORIA_OPERACOES     TO app_NACIONALDB;
GRANT SELECT, INSERT, UPDATE, DELETE ON LEITOR                  TO app_NACIONALDB;
GRANT SELECT, INSERT, UPDATE, DELETE ON ADULTO                  TO app_NACIONALDB;
GRANT SELECT, INSERT, UPDATE, DELETE ON ADULTO_INTERESSE        TO app_NACIONALDB;
GRANT SELECT, INSERT, UPDATE, DELETE ON PROFESSOR               TO app_NACIONALDB;
GRANT SELECT, INSERT, UPDATE, DELETE ON PROFESSOR_DISCIPLINA    TO app_NACIONALDB;
GRANT SELECT, INSERT, UPDATE, DELETE ON CRIANCA                 TO app_NACIONALDB;
GRANT SELECT, INSERT, UPDATE, DELETE ON DOADOR                  TO app_NACIONALDB;
GRANT SELECT, INSERT, UPDATE, DELETE ON DOACAO                  TO app_NACIONALDB;
GRANT SELECT, INSERT, UPDATE, DELETE ON ITEM_DOACAO             TO app_NACIONALDB;
GRANT SELECT, INSERT                 ON CERTIFICADO_DOACAO      TO app_NACIONALDB;

-- Snapshots (MVs locais): grants directos
GRANT SELECT ON biblioteca_snap      TO app_NACIONALDB;
GRANT SELECT ON snap_material_basico TO app_NACIONALDB;
GRANT SELECT ON snap_emp_activos     TO app_NACIONALDB;
GRANT SELECT ON snap_eventos         TO app_NACIONALDB;
GRANT SELECT ON snap_transferencias  TO app_NACIONALDB;

-- Vistas: grants directos
GRANT SELECT ON vw_doacoes_detalhadas           TO app_NACIONALDB;
GRANT SELECT ON vw_doadores_ranking             TO app_NACIONALDB;
GRANT SELECT ON vw_certificados_emitidos        TO app_NACIONALDB;
GRANT SELECT ON vw_funcionarios_ativos          TO app_NACIONALDB;
GRANT SELECT ON vw_acesso_funcionario           TO app_NACIONALDB;
GRANT SELECT ON vw_horarios_funcionario_semana  TO app_NACIONALDB;
GRANT SELECT ON vw_leitores_completos           TO app_NACIONALDB;
GRANT SELECT ON vw_leitor_publico               TO app_NACIONALDB;
GRANT SELECT ON vw_leitor_privado               TO app_NACIONALDB;
GRANT SELECT ON vw_frag_leitor_activos          TO app_NACIONALDB;
GRANT SELECT ON vw_frag_leitor_suspensos        TO app_NACIONALDB;
GRANT SELECT ON vw_frag_leitor_inactivos        TO app_NACIONALDB;
GRANT SELECT ON vw_replica_funcionarios         TO app_NACIONALDB;
GRANT SELECT ON vw_func_activos_operacional     TO app_NACIONALDB;
GRANT SELECT ON vw_func_activos_confidencial    TO app_NACIONALDB;
GRANT SELECT ON vw_func_inactivos_operacional   TO app_NACIONALDB;
GRANT SELECT ON vw_func_inactivos_confidencial  TO app_NACIONALDB;
GRANT SELECT ON vw_global_leitores_emprestimos  TO app_NACIONALDB;
GRANT SELECT ON vw_global_catalogo              TO app_NACIONALDB;
GRANT SELECT ON vw_global_eventos_participacao  TO app_NACIONALDB;
GRANT SELECT ON VW_AUDITORIA                    TO app_NACIONALDB;
GRANT SELECT ON vw_metricas_sistema             TO app_NACIONALDB;
GRANT SELECT ON vw_metricas_por_biblioteca      TO app_NACIONALDB;
