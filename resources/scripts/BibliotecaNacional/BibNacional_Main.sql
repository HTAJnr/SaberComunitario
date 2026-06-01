-- ============================================================
-- BibNacional_Main.sql — Script de instalação completo
-- BibliotecaNacionalDB — Sistema de Gestão de Bibliotecas Comunitárias Distribuído
--
-- Executar como SYSDBA:
--   sqlplus sys/"bd2.isctem" as sysdba @/root/TP/BibNacional_Main.sql
--
-- PRÉ-REQUISITO (1 vez, antes do primeiro install):
--   ALTER SYSTEM SET audit_trail = 'DB' SCOPE = SPFILE;
--   SHUTDOWN IMMEDIATE; STARTUP;
-- ============================================================


-- ============================================================
-- FASE 0A — LIMPEZA DE SINÓNIMOS PÚBLICOS (SYSDBA)
-- Ignora ORA-01432 (sinónimo inexistente) em primeira instalação.
-- ============================================================
DECLARE
  PROCEDURE drop_syn(p_syn IN VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE 'DROP PUBLIC SYNONYM ' || p_syn;
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -1432 THEN RAISE; END IF;
  END;
BEGIN
  -- Objectos e views locais
  drop_syn('funcao_funcionario');
  drop_syn('funcionario');
  drop_syn('funcionario_habilidade');
  drop_syn('horario_funcionario');
  drop_syn('leitor');
  drop_syn('adulto');
  drop_syn('adulto_interesse');
  drop_syn('professor');
  drop_syn('professor_disciplina');
  drop_syn('crianca');
  drop_syn('doador');
  drop_syn('doacao');
  drop_syn('item_doacao');
  drop_syn('certificado_doacao');
  drop_syn('auditoria_operacoes');
  drop_syn('vw_doacoes_detalhadas');
  drop_syn('vw_doadores_ranking');
  drop_syn('vw_certificados_emitidos');
  drop_syn('vw_funcionarios_ativos');
  drop_syn('vw_acesso_funcionario');
  drop_syn('vw_horarios_funcionario_semana');
  drop_syn('vw_replica_funcionarios');
  drop_syn('vw_func_activos_operacional');
  drop_syn('vw_func_activos_confidencial');
  drop_syn('vw_func_inactivos_operacional');
  drop_syn('vw_func_inactivos_confidencial');
  drop_syn('vw_leitores_completos');
  drop_syn('vw_leitor_publico');
  drop_syn('vw_leitor_privado');
  drop_syn('vw_frag_leitor_activos');
  drop_syn('vw_frag_leitor_suspensos');
  drop_syn('vw_frag_leitor_inactivos');
  drop_syn('vw_global_leitores_emprestimos');
  drop_syn('vw_global_catalogo');
  drop_syn('vw_global_eventos_participacao');
  drop_syn('vw_auditoria');
  drop_syn('vw_metricas_sistema');
  drop_syn('vw_metricas_por_biblioteca');
  drop_syn('total_doacoes_doador');
  drop_syn('registrar_doacao_completa');
  drop_syn('reemitir_certificado');
  drop_syn('proc_gerir_acesso_bd');
  drop_syn('prc_registar_auditoria');
  drop_syn('prc_apagar_leitor');
  drop_syn('prc_emitir_honorifico');
  drop_syn('prc_atualizar_doacao_segura');
  drop_syn('prc_demo_2pc');
  drop_syn('prc_refresh_snapshots');
  -- EmprestimosDB (Yannis)
  drop_syn('emprestimo');
  drop_syn('suspensao');
  drop_syn('seq_emprestimo');
  drop_syn('programa_alfabetizacao');
  drop_syn('nivel_progressao');
  drop_syn('programa_material');
  drop_syn('programa_funcionario');
  drop_syn('participacao_programa');
  drop_syn('seq_nivel');
  drop_syn('vw_emprestimos_ativos');
  drop_syn('vw_historico_emprestimos');
  drop_syn('processar_devolucao');
  drop_syn('repl_funcionarios');
  -- MateriaisDB (Yasin)
  drop_syn('material_bibliografico');
  drop_syn('categoria');
  drop_syn('livro_fisico');
  drop_syn('ebook');
  drop_syn('periodico');
  drop_syn('transferencia');
  drop_syn('seq_transferencia');
  drop_syn('vw_materiais_completos');
  drop_syn('vw_transferencias_detalhadas');
  -- EventosBibliotecasDB (Gerson)
  drop_syn('evento');
  drop_syn('participacao_evento');
  drop_syn('avaliacao_evento');
  drop_syn('horario_evento');
  drop_syn('horario_biblioteca');
  drop_syn('evento_recurso');
  drop_syn('seq_evento');
  drop_syn('seq_avaliacao');
  drop_syn('vw_eventos_proximos');
  drop_syn('vw_eventos_completos');
  drop_syn('insere_participacao_evento');
  -- MV local (snapshot de BIBLIOTECA)
  drop_syn('biblioteca');
END;
/


-- ============================================================
-- FASE 0B — LIMPEZA DE UTILIZADORES (SYSDBA)
-- Mata sessoes activas antes de DROP para evitar ORA-01940.
-- Ignora ORA-01918 (utilizador inexistente) em re-installs.
-- ============================================================
DECLARE
  PROCEDURE kill_sessions(p_user IN VARCHAR2) IS
  BEGIN
    FOR s IN (SELECT sid, serial# FROM v$session
              WHERE username = UPPER(p_user)
                AND sid != SYS_CONTEXT('USERENV','SID')) LOOP
      BEGIN
        EXECUTE IMMEDIATE 'ALTER SYSTEM KILL SESSION ''' || s.sid || ',' || s.serial# || ''' IMMEDIATE';
      EXCEPTION WHEN OTHERS THEN NULL;
      END;
    END LOOP;
  END;
  PROCEDURE drop_user_safe(p_user IN VARCHAR2) IS
  BEGIN
    IF UPPER(p_user) = USER THEN RETURN; END IF;
    kill_sessions(p_user);
    EXECUTE IMMEDIATE 'DROP USER ' || p_user || ' CASCADE';
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -1918 THEN RAISE; END IF;
  END;
BEGIN
  drop_user_safe('usr_NACIONALDB');
  drop_user_safe('app_NACIONALDB');
  drop_user_safe('app_emprestimosdb');
  drop_user_safe('app_materiaisdb');
  drop_user_safe('app_eventosdb');
END;
/


-- ============================================================
-- FASE 1 — INFRAESTRUTURA (SYSDBA)
-- ============================================================

-- 1. Tablespaces
@/root/TP/BibNacional_Tablespaces.sql

-- 2. Utilizadores e visitor users
@/root/TP/BibNacional_Users.sql

-- 3. Roles e privilégios
@/root/TP/BibNacional_Roles.sql


-- ============================================================
-- FASE 2 — OBJECTOS DO SCHEMA (usr_NACIONALDB)
-- ============================================================
CONNECT usr_NACIONALDB/"HTAJnr#020403"

-- 4. Database Links
@/root/TP/BibNacional_Database_Links.sql

-- 5. Snapshots locais (replicação — depende dos database links)
@/root/TP/BibNacional_Snapshots.sql

-- 6. Sinónimos (depende dos database links e snapshots)
@/root/TP/BibNacional_Synonyms.sql

-- 7. Tabelas e constraints
@/root/TP/BibNacional_Create.sql

-- 8. Sequências
@/root/TP/BibNacional_Sequences.sql

-- 9. Vistas
@/root/TP/BibNacional_Views.sql

-- 10. Funções
@/root/TP/BibNacional_Functions.sql

-- 11. Procedimentos
@/root/TP/BibNacional_Procedures.sql

-- 12. Triggers
@/root/TP/BibNacional_Triggers.sql

-- 13. Índices
@/root/TP/BibNacional_Indexes.sql

-- 14. Grants e permissões
@/root/TP/BibNacional_Grants.sql

-- 15. Dados iniciais
@/root/TP/BibNacional_Intro.sql


-- ============================================================
-- FASE 3 — AUDITORIA (SYSDBA)
-- ============================================================
CONNECT sys/"bd2.isctem" as sysdba

-- 16. Auditoria Oracle nativa
@/root/TP/BibNacional_Audit.sql
