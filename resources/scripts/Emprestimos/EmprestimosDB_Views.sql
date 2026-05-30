-- ============================================================
-- EmprestimosProg_Views.sql
-- Executar como: usr_emprestimosdb
-- Nota: os 4 fragmentos de EMPRESTIMO estao em Fragmentacao.sql
-- ============================================================

-- vw_emprestimos_activos
-- Lista todos os emprestimos ainda nao devolvidos (data_devolucao IS NULL).
-- Consultada pelo MateriaisDB para verificar se um material tem emprestimo
-- activo antes de autorizar uma transferencia (RN06).
-- Consultada pelo BibliotecaNacionalDB para as suas vistas globais de leitores.
CREATE OR REPLACE VIEW vw_emprestimos_activos AS
SELECT id_emprestimo,
       num_cartao,
       cod_material,
       data_retirada,
       prazo_devolucao,
       TRUNC(SYSDATE) - TRUNC(prazo_devolucao) AS dias_atraso
FROM EMPRESTIMO
WHERE data_devolucao IS NULL;

-- vw_suspensoes_activas
-- Lista todas as suspensoes em vigor (estado_suspensao = Activa).
-- Consultada pelo BibliotecaNacionalDB para verificar o estado de
-- um leitor antes de operacoes que exijam que ele esteja sem restricoes.
CREATE OR REPLACE VIEW vw_suspensoes_activas AS
SELECT id_suspensao,
       num_cartao,
       id_emprestimo,
       data_inicio,
       data_fim,
       dias_suspensao,
       estado_suspensao
FROM SUSPENSAO
WHERE estado_suspensao = 'Activa';


-- ============================================================
-- FRAGMENTACAO MISTA (horizontal + vertical) de EMPRESTIMO
-- ============================================================

DROP VIEW frag_emp_activos_op;
DROP VIEW frag_emp_activos_det;
DROP VIEW frag_emp_historico_op;
DROP VIEW frag_emp_historico_det;

-- Fragmento 1: Activos Operacional
-- Parte horizontal: so emprestimos activos (data_devolucao IS NULL)
-- Parte vertical: atributos operacionais consultados por outros nos
CREATE OR REPLACE VIEW frag_emp_activos_op AS
SELECT id_emprestimo, num_cartao, cod_material,
       data_retirada, prazo_devolucao
FROM EMPRESTIMO
WHERE data_devolucao IS NULL;

-- Fragmento 2: Activos Detalhe
-- Parte horizontal: so emprestimos activos
-- Parte vertical: atributos de detalhe operacional (uso interno)
CREATE OR REPLACE VIEW frag_emp_activos_det AS
SELECT id_emprestimo, cod_funcionario,
       estado_material_saida, observacoes_devolucao
FROM EMPRESTIMO
WHERE data_devolucao IS NULL;

-- Fragmento 3: Historico Operacional
-- Parte horizontal: so emprestimos devolvidos
-- Parte vertical: atributos operacionais para relatorios
CREATE OR REPLACE VIEW frag_emp_historico_op AS
SELECT id_emprestimo, num_cartao, cod_material,
       data_retirada, prazo_devolucao, data_devolucao
FROM EMPRESTIMO
WHERE data_devolucao IS NOT NULL;

-- Fragmento 4: Historico Detalhe
-- Parte horizontal: so emprestimos devolvidos
-- Parte vertical: atributos financeiros e de estado do material
CREATE OR REPLACE VIEW frag_emp_historico_det AS
SELECT id_emprestimo, estado_material_retorno,
       multa_valor, multa_paga, data_pagamento_multa,
       observacoes_devolucao
FROM EMPRESTIMO
WHERE data_devolucao IS NOT NULL;

-- vw_auditoria
-- Vista de servico sobre AUDITORIA_EMPRESTIMOS.
-- Usada para consultas de auditoria no backend e no no nacional.
CREATE OR REPLACE VIEW VW_AUDITORIA AS
SELECT
    id_auditoria,
    data_operacao,
    operacao,
    resultado,
    motivo_falha,
    nos_afetados,
    observacoes,
    'EMPRESTIMOS' AS no_origem
FROM AUDITORIA_EMPRESTIMOS;

-- ============================================================
-- VISTAS ADICIONADAS — ausentes no ficheiro original
-- Requerem sinonimos publicos (@nacionaldb, @materiaisdb),
-- biblioteca_snap (MV local de BIBLIOTECA@eventosdb) e REPL_FUNCIONARIOS
-- ============================================================

-- vw_emprestimos_ativos (sem 'c')
-- Usada pelo backend: GET /api/emprestimos?estado=activo|vencido
-- Expoe: ID_EMPRESTIMO, NUM_CARTAO, NOME_LEITOR, MATERIAL_TITULO,
--        DATA_RETIRADA, PRAZO_DEVOLUCAO, MULTA_ESTIMADA, DIAS_ATRASO, BIBLIOTECA_NOME
CREATE OR REPLACE VIEW vw_emprestimos_ativos AS
SELECT
    e.id_emprestimo,
    e.num_cartao,
    l.nome_completo        AS nome_leitor,
    l.cod_biblioteca,
    bs.nome_biblioteca     AS biblioteca_nome,
    e.cod_material,
    mb.titulo              AS material_titulo,
    e.data_retirada,
    e.prazo_devolucao,
    TRUNC(SYSDATE) - TRUNC(e.prazo_devolucao) AS dias_atraso,
    CASE
        WHEN TRUNC(SYSDATE) > TRUNC(e.prazo_devolucao) THEN
            CASE
                WHEN pr.num_cartao IS NOT NULL THEN
                    CASE WHEN (SELECT COUNT(*) FROM EMPRESTIMO e2
                               WHERE e2.num_cartao = e.num_cartao
                                 AND e2.data_devolucao > e2.prazo_devolucao) = 0
                         THEN 0
                         ELSE (TRUNC(SYSDATE) - TRUNC(e.prazo_devolucao)) * 10
                    END
                WHEN cr.num_cartao IS NOT NULL THEN
                    (TRUNC(SYSDATE) - TRUNC(e.prazo_devolucao)) * 5
                ELSE
                    (TRUNC(SYSDATE) - TRUNC(e.prazo_devolucao)) * 15
            END
        ELSE 0
    END AS multa_estimada
FROM EMPRESTIMO e
JOIN leitor               l  ON e.num_cartao  = l.num_cartao
JOIN material_bibliografico mb ON e.cod_material = mb.cod_material
JOIN biblioteca_snap      bs ON l.cod_biblioteca = bs.cod_biblioteca
LEFT JOIN professor        pr ON e.num_cartao  = pr.num_cartao
LEFT JOIN crianca          cr ON e.num_cartao  = cr.num_cartao
WHERE e.data_devolucao IS NULL;

-- vw_historico_emprestimos
-- Usada pelo backend: GET /api/emprestimos?estado=devolvido|todos
-- Expoe: ID_EMPRESTIMO, NUM_CARTAO, NOME_LEITOR, MATERIAL_TITULO,
--        DATA_RETIRADA, DATA_DEVOLUCAO, PRAZO_DEVOLUCAO, MULTA_VALOR, BIBLIOTECA_NOME
CREATE OR REPLACE VIEW vw_historico_emprestimos AS
SELECT
    e.id_emprestimo,
    l.num_cartao,
    l.nome_completo        AS nome_leitor,
    l.cod_biblioteca,
    CASE
        WHEN p.num_cartao  IS NOT NULL THEN 'PROFESSOR'
        WHEN a.num_cartao  IS NOT NULL THEN 'ADULTO'
        WHEN cr.num_cartao IS NOT NULL THEN 'CRIANCA'
        ELSE 'DESCONHECIDO'
    END AS tipo_leitor,
    mb.titulo              AS material_titulo,
    c.area_tematica        AS categoria_area,
    e.data_retirada,
    e.data_devolucao,
    ROUND(e.data_devolucao - e.data_retirada) AS dias_uso,
    e.prazo_devolucao,
    CASE
        WHEN e.data_devolucao IS NULL              THEN NULL
        WHEN e.data_devolucao <= e.prazo_devolucao THEN 'TRUE'
        ELSE 'FALSE'
    END AS devolvido_no_prazo,
    e.estado_material_saida,
    e.estado_material_retorno,
    CASE
        WHEN e.estado_material_retorno IS NULL                              THEN NULL
        WHEN e.estado_material_retorno <> e.estado_material_saida THEN 'TRUE'
        ELSE 'FALSE'
    END AS material_danificado,
    e.multa_valor,
    CASE WHEN e.multa_paga = 'S' THEN 'TRUE' ELSE 'FALSE' END AS multa_paga,
    CASE WHEN e.data_devolucao IS NOT NULL AND e.data_devolucao > e.prazo_devolucao
         THEN ROUND(e.data_devolucao - e.prazo_devolucao)
         ELSE 0
    END AS dias_atraso,
    bs.nome_biblioteca     AS biblioteca_nome,
    f.nome_funcionario     AS funcionario_nome
FROM EMPRESTIMO e
JOIN leitor                l  ON e.num_cartao      = l.num_cartao
JOIN REPL_FUNCIONARIOS     f  ON e.cod_funcionario = f.cod_funcionario
JOIN biblioteca_snap       bs ON f.cod_biblioteca  = bs.cod_biblioteca
JOIN material_bibliografico mb ON e.cod_material    = mb.cod_material
JOIN categoria             c  ON mb.cod_categoria  = c.id_categoria
LEFT JOIN professor        p  ON l.num_cartao      = p.num_cartao
LEFT JOIN adulto           a  ON l.num_cartao      = a.num_cartao
LEFT JOIN crianca          cr ON l.num_cartao      = cr.num_cartao;

CREATE OR REPLACE VIEW vw_relatorio_programas AS
SELECT p.cod_programa,
       p.nome_programa,
       p.cod_biblioteca,
       p.estado_programa,
       COUNT(pp.num_cartao)                                                         AS total_participantes,
       SUM(CASE WHEN pp.estado_participacao = 'Concluido' THEN 1 ELSE 0 END)        AS concluidos,
       SUM(CASE WHEN pp.estado_participacao = 'Activo'    THEN 1 ELSE 0 END)        AS em_curso,
       SUM(CASE WHEN pp.estado_participacao = 'Desistiu'  THEN 1 ELSE 0 END)        AS desistencias,
       MAX(np.ordem)                                                                 AS nivel_maximo_atingido
  FROM PROGRAMA_ALFABETIZACAO p
  LEFT JOIN PARTICIPACAO_PROGRAMA pp ON pp.cod_programa = p.cod_programa
  LEFT JOIN NIVEL_PROGRESSAO np      ON np.id_nivel    = pp.id_nivel_atual
 GROUP BY p.cod_programa, p.nome_programa, p.cod_biblioteca, p.estado_programa;
