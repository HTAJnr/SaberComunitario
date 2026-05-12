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
-- SECÇÃO 3: GRANTS DIRECTOS A app_NACIONALDB
-- Obrigatórios para acesso cross-node via database link.
-- Roles não funcionam através de dblinks — ORA-01031 se não tiver
-- grant directo. Qualquer nó que fizer SELECT/DELETE via
-- @bibliotecanacionaldb autentica como app_NACIONALDB e precisa
-- destes grants directos, independentemente das roles.
-- ============================================================

-- Vista pública de leitores — consumida por Yannis, Yasin e Gerson
-- via sinónimo leitor@<link_nacional> nos nós deles
GRANT SELECT ON vw_leitor_publico       TO app_NACIONALDB;

-- Vista de réplica de funcionários — consumida pelo Yannis
-- para sincronização da tabela repl_funcionarios no EmpréstimosDB
GRANT SELECT ON vw_replica_funcionarios TO app_NACIONALDB;

-- Vista operacional de funcionários activos — consumida por outros nós
-- para verificação de nível de acesso em tempo real
GRANT SELECT ON vw_func_activos_operacional TO app_NACIONALDB;

-- Tabelas de leitores — acesso directo necessário para o Yannis
-- (trigger RN01 verifica status_leitor antes de criar empréstimo)
GRANT SELECT ON LEITOR                  TO app_NACIONALDB;
GRANT UPDATE ON LEITOR                  TO app_NACIONALDB;

-- Tabelas de funcionários — acesso directo para verificações cross-node
GRANT SELECT ON FUNCIONARIO             TO app_NACIONALDB;
GRANT SELECT ON FUNCAO_FUNCIONARIO      TO app_NACIONALDB;

-- DELETE em PARTICIPACAO_EVENTO e AVALIACAO_EVENTO estão no nó do Gerson
-- (EventosBibliotecasDB) — não aqui. O que está aqui e o Gerson precisa
-- de apagar são os dados de leitores. Confirma com o Gerson os grants
-- no nó dele para app_NACIONALDB.

-- Procedures — execução pelo backend e por outros nós
GRANT EXECUTE ON registrar_doacao_completa  TO app_NACIONALDB;
GRANT EXECUTE ON reemitir_certificado       TO app_NACIONALDB;
GRANT EXECUTE ON proc_gerir_acesso_bd       TO app_NACIONALDB;
GRANT EXECUTE ON prc_registar_auditoria     TO app_NACIONALDB;
GRANT EXECUTE ON prc_apagar_leitor          TO app_NACIONALDB;
GRANT EXECUTE ON prc_remover_funcionario    TO app_NACIONALDB;
GRANT EXECUTE ON prc_sincronizar_funcionarios TO app_NACIONALDB;
GRANT EXECUTE ON prc_modificar_nivel_acesso TO app_NACIONALDB;
GRANT EXECUTE ON prc_demo_2pc              TO app_NACIONALDB;
GRANT EXECUTE ON prc_emitir_honorifico     TO app_NACIONALDB;

-- Função
GRANT EXECUTE ON total_doacoes_doador       TO app_NACIONALDB;


-- ============================================================
-- SECÇÃO 4: GRANTS PARA ACESSO CROSS-NODE DOS OUTROS NÓS
-- Quando Yannis/Yasin/Gerson criam sinónimos que apontam para
-- objectos deste nó via dblink, o Oracle verifica os privilégios
-- do utilizador de conexão do link (app_NACIONALDB, app_emprestimosdb,
-- etc.). Estes grants cobrem o que cada nó precisa.
-- ============================================================

-- Para o Yannis (EmprestimosDB) consultar leitores ao processar empréstimos
GRANT SELECT ON vw_leitor_publico           TO app_NACIONALDB;
-- (já feito acima — repetido aqui para clareza documental)

-- Para a prc_sincronizar_funcionarios funcionar:
-- o app_emprestimosdb no nó do Yannis precisa de SELECT na vista de réplica
-- via o database link que o Yannis criou para cá.
-- Se o database link do Yannis conecta como app_NACIONALDB, já está coberto.
-- Se conecta com utilizador diferente, coordena com o Yannis.


