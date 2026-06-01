-- ============================================================
-- MateriaisDB_Snapshots.sql — Snapshots (Materialized Views)
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: usr_materiaisdb
-- Executar DEPOIS de: MateriaisDB_Database_Links.sql
--
-- NOTA: Os nos remotos devem estar online durante a criacao
-- BUILD IMMEDIATE popula o snapshot imediatamente
-- REFRESH COMPLETE a cada hora (NEXT SYSDATE + 1/24)
-- ============================================================


-- ============================================================
-- SNAPSHOT 1 — repl_funcionarios
-- Replica funcionarios do BibliotecaNacionalDB (Helder)
-- Permite verificar dados de funcionarios sem depender
-- da disponibilidade do no do Helder
-- ============================================================
DROP TABLE repl_funcionarios;
DROP MATERIALIZED VIEW repl_funcionarios;

-- Campos completos para autenticacao offline (inclui SENHA e EMAIL)
CREATE MATERIALIZED VIEW repl_funcionarios
  BUILD DEFERRED
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT f.cod_funcionario, f.nome_funcionario, f.email, f.contacto,
       f.id_funcao, f.cod_biblioteca, fn.nivel_acesso, fn.nome_funcao, f.senha,
       f.genero, f.data_nasc, f.endereco, f.formacao, f.experiencia,
       f.data_contratacao, f.data_demissao
FROM usr_nacionaldb.funcionario@link_nacionaldb f,
     usr_nacionaldb.funcao_funcionario@link_nacionaldb fn
WHERE f.id_funcao = fn.id_funcao AND f.data_demissao IS NULL;


-- ============================================================
-- SNAPSHOT 4 — repl_funcao_funcionario
-- Replica funcoes do BibliotecaNacionalDB
-- Necessario para: JOIN FUNCAO_FUNCIONARIO na query de login offline
-- ============================================================
DROP TABLE repl_funcao_funcionario;
DROP MATERIALIZED VIEW repl_funcao_funcionario;

CREATE MATERIALIZED VIEW repl_funcao_funcionario
  BUILD DEFERRED
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT id_funcao, nome_funcao, nivel_acesso, descricao
FROM usr_nacionaldb.funcao_funcionario@link_nacionaldb;

-- ============================================================
-- SNAPSHOT 2 — biblioteca_snap
-- Replica bibliotecas do EventosBibliotecasDB (Gerson)
-- Permite verificar dados de bibliotecas sem depender
-- da disponibilidade do no do Gerson
-- ============================================================
DROP TABLE biblioteca_snap;
DROP MATERIALIZED VIEW biblioteca_snap;

CREATE MATERIALIZED VIEW biblioteca_snap
  BUILD DEFERRED
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT * FROM usr_eventosdb.biblioteca@link_eventosdb;


-- ============================================================
-- SNAPSHOT 3 — snap_leitor_publico
-- Replica leitores publicos do BibliotecaNacionalDB (Helder)
-- Permite verificar dados de leitores sem depender
-- da disponibilidade do no do Helder
-- ============================================================
DROP TABLE snap_leitor_publico;
DROP MATERIALIZED VIEW snap_leitor_publico;

CREATE MATERIALIZED VIEW snap_leitor_publico
  BUILD DEFERRED
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT num_cartao, nome_completo, cod_biblioteca,
       status_leitor, historico_pontualidade, distancia_biblioteca
FROM usr_nacionaldb.leitor@link_nacionaldb;

-- Grants imediatos — tolerante a MV inexistente (NacionalDB offline durante install)
BEGIN
  BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON repl_funcionarios TO app_materiaisdb';       EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON repl_funcao_funcionario TO app_materiaisdb'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/

-- Recompilar trigger dependente das MVs (se ja existir)
BEGIN
  BEGIN EXECUTE IMMEDIATE 'ALTER TRIGGER trg_valida_transferencia COMPILE'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/

-- ============================================================
-- Recriar sinonimos publicos cross-node dependentes de BibliotecaNacionalDB
-- (agora que o no NacionalDB esta activo)
-- ============================================================
CONNECT sys/"bd2.isctem" AS SYSDBA
@@MateriaisDB_Synonyms.sql
CONNECT usr_materiaisdb/"YM20240260"