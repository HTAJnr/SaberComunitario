
-- Apagar tabelas placeholder se existirem (criadas pelo Main para compilacao offline)
DROP TABLE repl_funcionarios;
DROP TABLE snap_leitor;

-- ============================================================
CREATE MATERIALIZED VIEW repl_funcionarios
    REFRESH COMPLETE
    START WITH SYSDATE
    NEXT SYSDATE + 1/24
AS
SELECT f.cod_funcionario, f.nome_funcionario,
       f.cod_biblioteca, fn.nivel_acesso
FROM funcionario@link_nacionaldb f,
     funcao_funcionario@link_nacionaldb fn
WHERE f.id_funcao = fn.id_funcao
AND f.data_demissao IS NULL;

-- ============================================================
CREATE MATERIALIZED VIEW snap_leitor
    BUILD IMMEDIATE
    REFRESH COMPLETE
    START WITH SYSDATE
    NEXT SYSDATE + 1/24
AS
SELECT num_cartao, nome_completo, cod_biblioteca,
       status_leitor, historico_pontualidade, distancia_biblioteca
FROM leitor@link_nacionaldb;

-- Verificar
SELECT MVIEW_NAME, REFRESH_MODE, LAST_REFRESH_DATE
FROM USER_MVIEWS;

SELECT COUNT(*) AS funcionarios_replicados FROM repl_funcionarios;
SELECT COUNT(*) AS leitores_replicados     FROM snap_leitor;