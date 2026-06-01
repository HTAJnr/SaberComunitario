-- ============================================================
-- MateriaisDB_Grants.sql — GRANTs para todos os utilizadores
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: usr_materiaisdb
-- Executar DEPOIS de: MateriaisDB_Procedures.sql, MateriaisDB_Views.sql
-- ============================================================


-- ============================================================
-- SECÇÃO 1: GRANTS AOS ROLES LOCAIS
-- ============================================================

GRANT SELECT ON CATEGORIA              TO role_materiaisdb_read;
GRANT SELECT ON MATERIAL_BIBLIOGRAFICO TO role_materiaisdb_read;
GRANT SELECT ON LIVRO_FISICO           TO role_materiaisdb_read;
GRANT SELECT ON EBOOK                  TO role_materiaisdb_read;
GRANT SELECT ON PERIODICO              TO role_materiaisdb_read;
GRANT SELECT ON TRANSFERENCIA          TO role_materiaisdb_read;
GRANT SELECT ON AUDITORIA_MATERIAIS    TO role_materiaisdb_read;
GRANT SELECT ON VW_MAT_DISPONIVEL      TO role_materiaisdb_read;
GRANT SELECT ON VW_MAT_CATALOGO_PUBLICO TO role_materiaisdb_read;

GRANT INSERT, UPDATE, DELETE ON MATERIAL_BIBLIOGRAFICO TO role_materiaisdb_write;
GRANT INSERT, UPDATE, DELETE ON LIVRO_FISICO           TO role_materiaisdb_write;
GRANT INSERT, UPDATE, DELETE ON EBOOK                  TO role_materiaisdb_write;
GRANT INSERT, UPDATE, DELETE ON PERIODICO              TO role_materiaisdb_write;
GRANT INSERT, UPDATE, DELETE ON TRANSFERENCIA          TO role_materiaisdb_write;
GRANT INSERT, UPDATE, DELETE ON CATEGORIA              TO role_materiaisdb_write;
GRANT INSERT                 ON AUDITORIA_MATERIAIS    TO role_materiaisdb_write;


-- ============================================================
-- SECÇÃO 2: UTILIZADOR LOCAL — app_materiaisdb
-- ============================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON CATEGORIA               TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON MATERIAL_BIBLIOGRAFICO  TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON LIVRO_FISICO            TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON EBOOK                   TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON PERIODICO               TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON TRANSFERENCIA           TO app_materiaisdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON AUDITORIA_MATERIAIS     TO app_materiaisdb;
GRANT SELECT  ON VW_MAT_DISPONIVEL        TO app_materiaisdb;
GRANT SELECT  ON VW_MAT_GLOBAL            TO app_materiaisdb;
GRANT SELECT  ON VW_MAT_CATALOGO_PUBLICO  TO app_materiaisdb;
GRANT SELECT  ON VW_AUDITORIA             TO app_materiaisdb;
GRANT EXECUTE ON atualizar_estado_material TO app_materiaisdb;
GRANT EXECUTE ON registar_auditoria_mat    TO app_materiaisdb;
GRANT SELECT  ON SEQ_AUDITORIA_MAT         TO app_materiaisdb;
-- Signal A: visitor users têm estas sequences — home user também precisa
GRANT SELECT  ON SEQ_MATERIAL              TO app_materiaisdb;
GRANT SELECT  ON SEQ_CATEGORIA             TO app_materiaisdb;
-- Autenticacao local (app_materiaisdb autentica contra snapshots locais)
GRANT SELECT  ON REPL_FUNCIONARIOS         TO app_materiaisdb;
GRANT SELECT  ON REPL_FUNCAO_FUNCIONARIO   TO app_materiaisdb;
GRANT SELECT  ON BIBLIOTECA_SNAP           TO app_materiaisdb;
-- snap_leitor_publico: criado em MateriaisDB_Snapshots.sql — tolerante a ORA-00942
BEGIN
  EXECUTE IMMEDIATE 'GRANT SELECT ON usr_materiaisdb.snap_leitor_publico TO app_materiaisdb';
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('AVISO: snap_leitor_publico ainda nao existe — re-correr apos Snapshots. ORA: ' || SQLERRM);
END;
/


-- ============================================================
-- SECÇÃO 2: GRANTS DIRECTOS AOS VISITOR USERS
-- Obrigatorios para acesso via dblink (roles nao transitam
-- por dblink no Oracle — ORA-01031 sem grant directo).
-- Tambem cobre DML e EXECUTE que os roles nao incluem.
-- ============================================================

-- ── Yannis (app_emprestimosdb) ──────────────────────────────
-- RN05: verifica disponibilidade e actualiza estado via procedure
GRANT SELECT  ON CATEGORIA                  TO app_emprestimosdb;
GRANT SELECT  ON MATERIAL_BIBLIOGRAFICO     TO app_emprestimosdb;
GRANT SELECT  ON VW_MAT_DISPONIVEL          TO app_emprestimosdb;
GRANT SELECT  ON VW_MAT_CATALOGO_PUBLICO        TO app_emprestimosdb;
GRANT SELECT  ON vw_materiais_completos         TO app_emprestimosdb;
GRANT SELECT  ON vw_transferencias_detalhadas   TO app_emprestimosdb;
-- NAO tem UPDATE directo — usa procedure
GRANT EXECUTE ON atualizar_estado_material  TO app_emprestimosdb;
-- Transparencia: criar/editar materiais e solicitar transferencias de qualquer no
GRANT SELECT, INSERT, UPDATE, DELETE ON MATERIAL_BIBLIOGRAFICO TO app_emprestimosdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON LIVRO_FISICO           TO app_emprestimosdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON EBOOK                  TO app_emprestimosdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON PERIODICO              TO app_emprestimosdb;
GRANT SELECT, INSERT, UPDATE ON TRANSFERENCIA                  TO app_emprestimosdb;
GRANT SELECT ON SEQ_MATERIAL                                   TO app_emprestimosdb;
GRANT SELECT ON SEQ_CATEGORIA                                  TO app_emprestimosdb;
GRANT SELECT ON SEQ_TRANSFERENCIA                              TO app_emprestimosdb;

-- ── Helder (app_nacionaldb) ─────────────────────────────────
-- Supervisao: visao global do catalogo + actualizacao para demo 2PC
GRANT SELECT ON CATEGORIA                    TO app_nacionaldb;
GRANT SELECT ON MATERIAL_BIBLIOGRAFICO       TO app_nacionaldb;
GRANT SELECT ON LIVRO_FISICO                 TO app_nacionaldb;
GRANT SELECT ON EBOOK                        TO app_nacionaldb;
GRANT SELECT ON PERIODICO                    TO app_nacionaldb;
GRANT SELECT ON TRANSFERENCIA                TO app_nacionaldb;
GRANT SELECT ON VW_MAT_DISPONIVEL            TO app_nacionaldb;
GRANT SELECT ON VW_MAT_CATALOGO_PUBLICO      TO app_nacionaldb;
GRANT SELECT ON vw_materiais_completos       TO app_nacionaldb;
GRANT SELECT ON vw_transferencias_detalhadas TO app_nacionaldb;
GRANT SELECT ON SEQ_TRANSFERENCIA            TO app_nacionaldb;
-- DML directo para demo 2PC
GRANT UPDATE ON MATERIAL_BIBLIOGRAFICO       TO app_nacionaldb;
GRANT EXECUTE ON atualizar_estado_material   TO app_nacionaldb;
-- Transparencia: criar/editar materiais e transferencias de qualquer no
GRANT INSERT, DELETE ON MATERIAL_BIBLIOGRAFICO TO app_nacionaldb;
GRANT SELECT, INSERT, UPDATE, DELETE ON LIVRO_FISICO  TO app_nacionaldb;
GRANT SELECT, INSERT, UPDATE, DELETE ON EBOOK         TO app_nacionaldb;
GRANT SELECT, INSERT, UPDATE, DELETE ON PERIODICO     TO app_nacionaldb;
GRANT INSERT, UPDATE ON TRANSFERENCIA                 TO app_nacionaldb;
GRANT SELECT ON SEQ_MATERIAL                          TO app_nacionaldb;
GRANT SELECT ON SEQ_CATEGORIA                         TO app_nacionaldb;

-- ── Gerson (app_eventosdb) ──────────────────────────────────
-- Planeamento de eventos: catalogo publico e disponibilidade
GRANT SELECT ON CATEGORIA               TO app_eventosdb;
GRANT SELECT ON VW_MAT_CATALOGO_PUBLICO TO app_eventosdb;
GRANT SELECT ON VW_MAT_DISPONIVEL               TO app_eventosdb;
GRANT SELECT ON vw_materiais_completos          TO app_eventosdb;
GRANT SELECT ON vw_transferencias_detalhadas    TO app_eventosdb;
-- Transparencia: criar/editar materiais e solicitar transferencias de qualquer no
GRANT SELECT, INSERT, UPDATE, DELETE ON MATERIAL_BIBLIOGRAFICO TO app_eventosdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON LIVRO_FISICO           TO app_eventosdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON EBOOK                  TO app_eventosdb;
GRANT SELECT, INSERT, UPDATE, DELETE ON PERIODICO              TO app_eventosdb;
GRANT SELECT, INSERT, UPDATE ON TRANSFERENCIA                  TO app_eventosdb;
GRANT EXECUTE ON atualizar_estado_material                     TO app_eventosdb;
GRANT SELECT ON SEQ_MATERIAL                                   TO app_eventosdb;
GRANT SELECT ON SEQ_CATEGORIA                                  TO app_eventosdb;
GRANT SELECT ON SEQ_TRANSFERENCIA                              TO app_eventosdb;
