
-- ============================================================
-- Campos completos para autenticacao offline (inclui SENHA e EMAIL)
DROP TABLE repl_funcionarios;
DROP MATERIALIZED VIEW repl_funcionarios;

CREATE MATERIALIZED VIEW repl_funcionarios
    BUILD IMMEDIATE
    REFRESH COMPLETE
    START WITH SYSDATE
    NEXT SYSDATE + 1/24
AS
SELECT f.cod_funcionario, f.nome_funcionario, f.email, f.contacto,
       f.id_funcao, f.cod_biblioteca, fn.nivel_acesso, fn.nome_funcao, f.senha,
       f.data_demissao
FROM funcionario@link_nacionaldb f,
     funcao_funcionario@link_nacionaldb fn
WHERE f.id_funcao = fn.id_funcao
AND f.data_demissao IS NULL;

-- ============================================================
-- repl_funcao_funcionario — para JOIN offline na query de login
-- ============================================================
DROP MATERIALIZED VIEW repl_funcao_funcionario;

CREATE MATERIALIZED VIEW repl_funcao_funcionario
    BUILD IMMEDIATE
    REFRESH COMPLETE
    START WITH SYSDATE
    NEXT SYSDATE + 1/24
AS
SELECT id_funcao, nome_funcao, nivel_acesso
FROM funcao_funcionario@link_nacionaldb;

-- ============================================================
DROP TABLE snap_leitor;
DROP MATERIALIZED VIEW snap_leitor;

CREATE MATERIALIZED VIEW snap_leitor
    BUILD IMMEDIATE
    REFRESH COMPLETE
    START WITH SYSDATE
    NEXT SYSDATE + 1/24
AS
SELECT num_cartao, nome_completo, cod_biblioteca,
       status_leitor, historico_pontualidade, distancia_biblioteca
FROM leitor@link_nacionaldb;

-- ============================================================
-- Recompilar objectos dependentes das MVs
-- ============================================================
ALTER VIEW vw_bibliotecas_operacionais COMPILE;
ALTER VIEW vw_eventos_completos COMPILE;
ALTER VIEW vw_participacoes_eventos COMPILE;
