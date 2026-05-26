-- ============================================================
-- BibNacional_Grants.sql
-- Permissões completas para app_NACIONALDB
-- Executar como usr_NACIONALDB:
--   sqlplus usr_NACIONALDB/"HTAJnr#020403" @/root/TP/BibNacional_Grants.sql
-- ============================================================


-- ============================================================
-- SECÇÃO 1: POPULAR O ROLE DE LEITURA
-- O role foi criado mas nunca recebeu privilégios.
-- Atribuir SELECT em todas as tabelas e vistas ao role,
-- depois o role já está atribuído ao app_NACIONALDB via Roles.sql.
-- NOTA: mesmo com o role populado, os grants directos abaixo
-- continuam a ser necessários para acesso cross-node via dblink.
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

-- Sequências — leitura (necessário para NEXTVAL/CURRVAL no backend)
GRANT SELECT ON SEQ_FUNCAO       TO role_NACIONALDB_read;
GRANT SELECT ON SEQ_FUNCIONARIO  TO role_NACIONALDB_read;
GRANT SELECT ON SEQ_HORARIO_FUNC TO role_NACIONALDB_read;
GRANT SELECT ON SEQ_DOADOR       TO role_NACIONALDB_read;
GRANT SELECT ON SEQ_DOACAO       TO role_NACIONALDB_read;
GRANT SELECT ON SEQ_ITEMDOADO    TO role_NACIONALDB_read;
GRANT SELECT ON SEQ_CERTIFICADO  TO role_NACIONALDB_read;
GRANT SELECT ON SEQ_AUDITORIA    TO role_NACIONALDB_read;


-- ============================================================
-- SECÇÃO 2: POPULAR O ROLE DE ESCRITA
-- Operações DML para o backend e para outros nós que escrevem
-- neste nó (ex: prc_apagar_leitor chama DELETE cross-node desde
-- o EventosBibliotecasDB de volta para cá — não se aplica aqui,
-- mas o backend local precisa de INSERT/UPDATE/DELETE).
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
-- Gestão de permissões (módulo Admin): atribui/altera funções de funcionários
GRANT INSERT, UPDATE, DELETE ON FUNCAO_FUNCIONARIO     TO role_NACIONALDB_write;

-- Sequências — NEXTVAL (escrita)
GRANT SELECT ON SEQ_FUNCAO       TO role_NACIONALDB_write;
GRANT SELECT ON SEQ_FUNCIONARIO  TO role_NACIONALDB_write;
GRANT SELECT ON SEQ_HORARIO_FUNC TO role_NACIONALDB_write;
GRANT SELECT ON SEQ_DOADOR       TO role_NACIONALDB_write;
GRANT SELECT ON SEQ_DOACAO       TO role_NACIONALDB_write;
GRANT SELECT ON SEQ_ITEMDOADO    TO role_NACIONALDB_write;
GRANT SELECT ON SEQ_CERTIFICADO  TO role_NACIONALDB_write;
GRANT SELECT ON SEQ_AUDITORIA    TO role_NACIONALDB_write;

-- NOTA: GRANT role_NACIONALDB_write TO app_NACIONALDB está em BibNacional_Roles.sql
-- (corre como SYSDBA — usr_NACIONALDB não tem ADMIN OPTION para atribuir roles).


-- ============================================================
-- SECÇÃO 3: GRANTS DIRECTOS AOS VISITOR USERS
-- Roles não funcionam através de dblinks — ORA-01031 sem grant directo.
-- Os visitor users são criados em BibNacional_Users.sql com a mesma
-- password do app_ de cada nó, para não ser necessário trocar passwords.
-- Cada visitor user recebe apenas o mínimo que o nó visitante precisa.
-- ============================================================

-- ── Yannis (app_emprestimosdb) ──────────────────────────────
-- RN01: verifica status_leitor antes de criar empréstimo
GRANT SELECT ON vw_leitor_publico               TO app_emprestimosdb;
GRANT SELECT ON LEITOR                           TO app_emprestimosdb;
GRANT UPDATE ON LEITOR                          TO app_emprestimosdb;

-- Verificação de nível de acesso cross-node
GRANT SELECT ON FUNCIONARIO                     TO app_emprestimosdb;
GRANT SELECT ON vw_func_activos_operacional     TO app_emprestimosdb;
GRANT SELECT ON vw_replica_funcionarios         TO app_emprestimosdb;

-- Programas: procedure valida funcionário antes de inserir em PROGRAMA_FUNCIONARIO
GRANT SELECT ON FUNCAO_FUNCIONARIO  TO app_emprestimosdb;

-- RN04.1: trigger verifica se leitor é criança
GRANT SELECT ON ADULTO      TO app_emprestimosdb;
GRANT SELECT ON PROFESSOR   TO app_emprestimosdb;
GRANT SELECT ON CRIANCA     TO app_emprestimosdb;

-- ── Yasin (app_materiaisdb) ─────────────────────────────────
-- Verificações de leitores (ex: RN09 e-books requer leitor adulto)
GRANT SELECT ON vw_leitor_publico               TO app_materiaisdb;
GRANT SELECT ON LEITOR                          TO app_materiaisdb;

-- RN09: verificar tipo de leitor (adulto) antes de e-book
GRANT SELECT ON ADULTO      TO app_materiaisdb;

-- ── Gerson (app_eventosdb) ──────────────────────────────────
-- Verificação de leitores antes de inscrever em eventos
GRANT SELECT ON vw_leitor_publico               TO app_eventosdb;
GRANT SELECT ON LEITOR                          TO app_eventosdb;

-- Verificação de tipo de leitor antes de inscrever em evento
GRANT SELECT ON ADULTO      TO app_eventosdb;
GRANT SELECT ON CRIANCA     TO app_eventosdb;
GRANT SELECT ON PROFESSOR   TO app_eventosdb;

-- Funcionario
GRANT SELECT ON FUNCIONARIO                     TO app_eventosdb;
GRANT SELECT ON vw_func_activos_operacional     TO app_eventosdb;

-- prc_registar_auditoria: chamada cross-node quando operações falham (todos os nós visitantes)
GRANT EXECUTE ON prc_registar_auditoria  TO app_emprestimosdb;
GRANT EXECUTE ON prc_registar_auditoria  TO app_materiaisdb;
GRANT EXECUTE ON prc_registar_auditoria  TO app_eventosdb;




-- ── Backend local (app_NACIONALDB) ──────────────────────────
-- O Node.js usa este user para DML e execução de procedures.
-- Procedures só são chamadas pelo backend local — não por outros nós.
GRANT EXECUTE ON registrar_doacao_completa      TO app_NACIONALDB;
GRANT EXECUTE ON reemitir_certificado           TO app_NACIONALDB;
GRANT EXECUTE ON proc_gerir_acesso_bd           TO app_NACIONALDB;
GRANT EXECUTE ON prc_registar_auditoria         TO app_NACIONALDB;
GRANT EXECUTE ON prc_apagar_leitor              TO app_NACIONALDB;
GRANT EXECUTE ON prc_remover_funcionario        TO app_NACIONALDB;
GRANT EXECUTE ON prc_sincronizar_funcionarios   TO app_NACIONALDB;
GRANT EXECUTE ON prc_modificar_nivel_acesso     TO app_NACIONALDB;
GRANT EXECUTE ON prc_demo_2pc                   TO app_NACIONALDB;
GRANT EXECUTE ON prc_emitir_honorifico              TO app_NACIONALDB;
GRANT EXECUTE ON total_doacoes_doador               TO app_NACIONALDB;
GRANT EXECUTE ON prc_atualizar_doacao_segura        TO app_NACIONALDB;