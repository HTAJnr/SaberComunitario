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
-- ============================================================

-- Objectos e views locais
DROP PUBLIC SYNONYM funcao_funcionario;
DROP PUBLIC SYNONYM funcionario;
DROP PUBLIC SYNONYM funcionario_habilidade;
DROP PUBLIC SYNONYM horario_funcionario;
DROP PUBLIC SYNONYM leitor;
DROP PUBLIC SYNONYM adulto;
DROP PUBLIC SYNONYM adulto_interesse;
DROP PUBLIC SYNONYM professor;
DROP PUBLIC SYNONYM professor_disciplina;
DROP PUBLIC SYNONYM crianca;
DROP PUBLIC SYNONYM doador;
DROP PUBLIC SYNONYM doacao;
DROP PUBLIC SYNONYM item_doacao;
DROP PUBLIC SYNONYM certificado_doacao;
DROP PUBLIC SYNONYM auditoria_operacoes;
DROP PUBLIC SYNONYM vw_doacoes_detalhadas;
DROP PUBLIC SYNONYM vw_doadores_ranking;
DROP PUBLIC SYNONYM vw_certificados_emitidos;
DROP PUBLIC SYNONYM vw_funcionarios_ativos;
DROP PUBLIC SYNONYM vw_acesso_funcionario;
DROP PUBLIC SYNONYM vw_horarios_funcionario_semana;
DROP PUBLIC SYNONYM vw_replica_funcionarios;
DROP PUBLIC SYNONYM vw_func_activos_operacional;
DROP PUBLIC SYNONYM vw_func_activos_confidencial;
DROP PUBLIC SYNONYM vw_func_inactivos_operacional;
DROP PUBLIC SYNONYM vw_func_inactivos_confidencial;
DROP PUBLIC SYNONYM vw_leitores_completos;
DROP PUBLIC SYNONYM vw_leitor_publico;
DROP PUBLIC SYNONYM vw_leitor_privado;
DROP PUBLIC SYNONYM vw_frag_leitor_activos;
DROP PUBLIC SYNONYM vw_frag_leitor_suspensos;
DROP PUBLIC SYNONYM vw_frag_leitor_inactivos;
DROP PUBLIC SYNONYM vw_global_leitores_emprestimos;
DROP PUBLIC SYNONYM vw_global_catalogo;
DROP PUBLIC SYNONYM vw_global_eventos_participacao;
DROP PUBLIC SYNONYM vw_auditoria;
DROP PUBLIC SYNONYM vw_metricas_sistema;
DROP PUBLIC SYNONYM vw_metricas_por_biblioteca;
DROP PUBLIC SYNONYM total_doacoes_doador;
DROP PUBLIC SYNONYM registrar_doacao_completa;
DROP PUBLIC SYNONYM reemitir_certificado;
DROP PUBLIC SYNONYM proc_gerir_acesso_bd;
DROP PUBLIC SYNONYM prc_registar_auditoria;
DROP PUBLIC SYNONYM prc_apagar_leitor;
DROP PUBLIC SYNONYM prc_emitir_honorifico;
DROP PUBLIC SYNONYM prc_atualizar_doacao_segura;
DROP PUBLIC SYNONYM prc_demo_2pc;
DROP PUBLIC SYNONYM prc_refresh_snapshots;

-- EmpréstimosDB (Yannis)
DROP PUBLIC SYNONYM emprestimo;
DROP PUBLIC SYNONYM suspensao;
DROP PUBLIC SYNONYM seq_emprestimo;
DROP PUBLIC SYNONYM programa_alfabetizacao;
DROP PUBLIC SYNONYM nivel_progressao;
DROP PUBLIC SYNONYM programa_material;
DROP PUBLIC SYNONYM programa_funcionario;
DROP PUBLIC SYNONYM participacao_programa;
DROP PUBLIC SYNONYM seq_nivel;
DROP PUBLIC SYNONYM vw_emprestimos_ativos;
DROP PUBLIC SYNONYM vw_historico_emprestimos;
DROP PUBLIC SYNONYM processar_devolucao;
DROP PUBLIC SYNONYM repl_funcionarios;

-- MateriaisDB (Yasin)
DROP PUBLIC SYNONYM material_bibliografico;
DROP PUBLIC SYNONYM categoria;
DROP PUBLIC SYNONYM livro_fisico;
DROP PUBLIC SYNONYM ebook;
DROP PUBLIC SYNONYM periodico;
DROP PUBLIC SYNONYM transferencia;
DROP PUBLIC SYNONYM seq_transferencia;
DROP PUBLIC SYNONYM vw_materiais_completos;
DROP PUBLIC SYNONYM vw_transferencias_detalhadas;

-- EventosBibliotecasDB (Gerson)
DROP PUBLIC SYNONYM evento;
DROP PUBLIC SYNONYM participacao_evento;
DROP PUBLIC SYNONYM avaliacao_evento;
DROP PUBLIC SYNONYM horario_evento;
DROP PUBLIC SYNONYM horario_biblioteca;
DROP PUBLIC SYNONYM evento_recurso;
DROP PUBLIC SYNONYM seq_evento;
DROP PUBLIC SYNONYM seq_avaliacao;
DROP PUBLIC SYNONYM vw_eventos_proximos;
DROP PUBLIC SYNONYM vw_eventos_completos;
DROP PUBLIC SYNONYM insere_participacao_evento;

-- MV local (snapshot de BIBLIOTECA)
DROP PUBLIC SYNONYM biblioteca;


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
