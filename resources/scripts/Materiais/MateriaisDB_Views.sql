-- ============================================================
-- MateriaisDB_Views.sql — Todas as vistas do no MateriaisDB
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: usr_materiaisdb
-- Executar DEPOIS de: MateriaisDB_Create.sql
-- ============================================================


-- ============================================================
-- FRAGMENTACAO HORIZONTAL 1 — Por Biblioteca
-- Criterio: cod_biblioteca
-- ============================================================
CREATE OR REPLACE VIEW frag_mat_BCP AS
    SELECT * FROM MATERIAL_BIBLIOGRAFICO
    WHERE cod_biblioteca = 'BCP';

CREATE OR REPLACE VIEW frag_mat_BCX AS
    SELECT * FROM MATERIAL_BIBLIOGRAFICO
    WHERE cod_biblioteca = 'BCX';

CREATE OR REPLACE VIEW frag_mat_BCB AS
    SELECT * FROM MATERIAL_BIBLIOGRAFICO
    WHERE cod_biblioteca = 'BCB';

CREATE OR REPLACE VIEW frag_mat_outros AS
    SELECT * FROM MATERIAL_BIBLIOGRAFICO
    WHERE cod_biblioteca NOT IN ('BCP','BCX','BCB');

CREATE OR REPLACE VIEW vw_mat_global AS
    SELECT * FROM frag_mat_BCP   UNION ALL
    SELECT * FROM frag_mat_BCX   UNION ALL
    SELECT * FROM frag_mat_BCB   UNION ALL
    SELECT * FROM frag_mat_outros;


-- ============================================================
-- FRAGMENTACAO HORIZONTAL 2 — Por Estado de Conservacao
-- Criterio: estado_material_conservacao
-- ============================================================
CREATE OR REPLACE VIEW vw_frag_material_disponivel AS
    SELECT * FROM MATERIAL_BIBLIOGRAFICO
    WHERE estado_material_conservacao != 'Indisponivel';

CREATE OR REPLACE VIEW vw_frag_material_indisponivel AS
    SELECT * FROM MATERIAL_BIBLIOGRAFICO
    WHERE estado_material_conservacao = 'Indisponivel';


-- ============================================================
-- FRAGMENTACAO MISTA — Horizontal por biblioteca + Vertical
-- ============================================================
CREATE OR REPLACE VIEW vw_mat_catalogo_publico AS
    SELECT cod_material, titulo, autor, editora, ano_publicacao,
           ISBN, idioma, num_paginas, estado_material_conservacao,
           cod_categoria, cod_biblioteca
    FROM MATERIAL_BIBLIOGRAFICO;

CREATE OR REPLACE VIEW vw_mat_patrimonial AS
    SELECT cod_material, origem_material, data_aquisicao,
           valor_aquisicao, localizacao_estante,
           motivo_indisponibilidade, id_itemDoado, cod_biblioteca
    FROM MATERIAL_BIBLIOGRAFICO;

CREATE OR REPLACE VIEW frag_misto_BIBMPC AS
    SELECT cod_material, titulo, autor, editora, ano_publicacao,
           ISBN, idioma, num_paginas, estado_material_conservacao,
           cod_categoria, cod_biblioteca
    FROM MATERIAL_BIBLIOGRAFICO WHERE cod_biblioteca = 'BIBMPC0001';

CREATE OR REPLACE VIEW frag_misto_BIBGZA AS
    SELECT cod_material, titulo, autor, editora, ano_publicacao,
           ISBN, idioma, num_paginas, estado_material_conservacao,
           cod_categoria, cod_biblioteca
    FROM MATERIAL_BIBLIOGRAFICO WHERE cod_biblioteca = 'BIBGZA0001';

CREATE OR REPLACE VIEW frag_misto_BIBSOF AS
    SELECT cod_material, titulo, autor, editora, ano_publicacao,
           ISBN, idioma, num_paginas, estado_material_conservacao,
           cod_categoria, cod_biblioteca
    FROM MATERIAL_BIBLIOGRAFICO WHERE cod_biblioteca = 'BIBSOF0001';

CREATE OR REPLACE VIEW frag_misto_outros AS
    SELECT cod_material, titulo, autor, editora, ano_publicacao,
           ISBN, idioma, num_paginas, estado_material_conservacao,
           cod_categoria, cod_biblioteca
    FROM MATERIAL_BIBLIOGRAFICO
    WHERE cod_biblioteca NOT IN ('BIBMPC0001','BIBGZA0001','BIBSOF0001');


-- ============================================================
-- VISTA DE SERVICO — Para outros nos
-- Expoe disponibilidade sem dados patrimoniais
-- ============================================================
CREATE OR REPLACE VIEW vw_mat_disponivel AS
    SELECT cod_material, titulo, autor, cod_biblioteca,
           estado_material_conservacao,
           CASE
               WHEN estado_material_conservacao = 'Bom'          THEN 'Sim'
               WHEN estado_material_conservacao = 'Degradado'    THEN 'Sim'
               WHEN estado_material_conservacao = 'Indisponivel' THEN 'Nao'
           END AS disponivel_emprestimo
    FROM MATERIAL_BIBLIOGRAFICO;



-- ============================================================
-- VISTA DE AUDITORIA
-- ============================================================
CREATE OR REPLACE VIEW VW_AUDITORIA AS
    SELECT id_auditoria, data_operacao, operacao, resultado,
           motivo_falha, nos_afetados, observacoes,
           'MATERIAIS' AS no_origem
    FROM AUDITORIA_MATERIAIS;


-- ============================================================
-- VISTAS PARA O BACKEND
-- BIBLIOTECA usa sinónimo → biblioteca_snap (MV local, resiliente).
-- FUNCIONARIO usa sinónimo → repl_funcionarios (MV local, resiliente).
-- emprestimo_activo usa sinónimo → VW_EMPRESTIMOS_ACTIVOS@emprestimosdb
--   (live link — falha se EmprestimosDB offline; não há snapshot local).
-- ============================================================

-- Catálogo completo com tipo de material, disponibilidade e biblioteca
CREATE OR REPLACE VIEW vw_materiais_completos AS
SELECT
    m.cod_material,
    CASE
        WHEN lf.cod_material IS NOT NULL THEN 'LIVRO_FISICO'
        WHEN eb.cod_material IS NOT NULL THEN 'EBOOK'
        WHEN p.cod_material  IS NOT NULL THEN 'PERIODICO'
    END AS tipo_material,
    m.titulo, m.autor, m.editora, m.ano_publicacao,
    m.ISBN, m.idioma, m.num_paginas,
    m.estado_material_conservacao AS estado_conservacao,
    c.area_tematica AS categoria_area_tematica,
    c.faixa_etaria  AS categoria_faixa_etaria,
    c.nivel_leitura AS categoria_nivel_leitura,
    b.nome_biblioteca AS biblioteca_nome,
    b.endereco        AS biblioteca_localizacao,
    b.cod_biblioteca,
    CASE
        WHEN m.estado_material_conservacao = 'Indisponivel' THEN 'N'
        WHEN EXISTS (
            SELECT 1 FROM emprestimo_activo ea
             WHERE ea.cod_material = m.cod_material
        ) THEN 'N'
        WHEN EXISTS (
            SELECT 1 FROM TRANSFERENCIA t
             WHERE t.cod_material = m.cod_material
               AND t.estado_transferencia IN ('Pendente', 'Aprovada')
        ) THEN 'N'
        ELSE 'S'
    END AS disponivel_emprestimo,
    m.localizacao_estante,
    eb.formato           AS ebook_formato,
    eb.tamanho_arquivo   AS ebook_tamanho,
    eb.url_acesso        AS ebook_url,
    p.edicao             AS periodico_edicao,
    p.periodicidade      AS periodico_periodicidade,
    p.data_publicacao    AS periodico_data_publicacao,
    p.ISSN               AS periodico_issn
FROM MATERIAL_BIBLIOGRAFICO m
INNER JOIN CATEGORIA c ON m.cod_categoria = c.id_categoria
INNER JOIN BIBLIOTECA b ON m.cod_biblioteca = b.cod_biblioteca
LEFT JOIN LIVRO_FISICO lf ON m.cod_material = lf.cod_material
LEFT JOIN EBOOK        eb ON m.cod_material = eb.cod_material
LEFT JOIN PERIODICO    p  ON m.cod_material = p.cod_material;
/

-- Transferências com actores e localizações (últimos 24 meses)
CREATE OR REPLACE VIEW vw_transferencias_detalhadas AS
SELECT
    t.id_transferencia,
    t.estado_transferencia,
    t.motivo,
    t.data_solicitacao,
    t.data_aprovacao_destino AS data_aprovacao,
    t.data_conclusao,
    CASE
        WHEN t.estado_transferencia IN ('Pendente', 'Aprovada')
        THEN TRUNC(SYSDATE - t.data_solicitacao)
        ELSE NULL
    END AS dias_pendente,
    m.titulo                   AS material_titulo,
    m.cod_material             AS material_codigo,
    m.estado_material_conservacao AS material_estado,
    bo.nome_biblioteca         AS biblioteca_origem_nome,
    bo.endereco                AS biblioteca_origem_localizacao,
    bd.nome_biblioteca         AS biblioteca_destino_nome,
    bd.endereco                AS biblioteca_destino_localizacao,
    fs.nome_funcionario        AS funcionario_solicitante_nome,
    fs.contacto                AS contacto,
    fa.nome_funcionario        AS funcionario_aprovador_nome,
    fa.contacto                AS funcionario_aprovador_contacto
FROM TRANSFERENCIA t
INNER JOIN MATERIAL_BIBLIOGRAFICO m ON t.cod_material             = m.cod_material
INNER JOIN BIBLIOTECA bo            ON t.cod_biblioteca_origem   = bo.cod_biblioteca
INNER JOIN BIBLIOTECA bd            ON t.cod_biblioteca_destino  = bd.cod_biblioteca
INNER JOIN FUNCIONARIO fs           ON t.cod_funcionario_solicitante = fs.cod_funcionario
LEFT  JOIN FUNCIONARIO fa           ON t.cod_funcionario_aprovador   = fa.cod_funcionario
WHERE t.data_solicitacao >= ADD_MONTHS(SYSDATE, -24);
/

-- Estatísticas do acervo por categoria (usa emprestimo_activo live link)
CREATE OR REPLACE VIEW vw_materiais_por_categoria AS
SELECT
    c.area_tematica,
    c.faixa_etaria,
    c.nivel_leitura,
    COUNT(m.cod_material) AS total_materiais,
    SUM(CASE
        WHEN m.estado_material_conservacao != 'Indisponivel'
         AND NOT EXISTS (
             SELECT 1 FROM emprestimo_activo ea WHERE ea.cod_material = m.cod_material
         )
         AND NOT EXISTS (
             SELECT 1 FROM TRANSFERENCIA t
              WHERE t.cod_material = m.cod_material
                AND t.estado_transferencia IN ('Pendente', 'Aprovada')
         )
        THEN 1 ELSE 0
    END) AS total_disponiveis,
    SUM(CASE
        WHEN EXISTS (SELECT 1 FROM emprestimo_activo ea WHERE ea.cod_material = m.cod_material)
        THEN 1 ELSE 0
    END) AS total_emprestados,
    SUM(CASE
        WHEN m.estado_material_conservacao = 'Indisponivel' THEN 1 ELSE 0
    END) AS total_indisponiveis,
    ROUND(
        SUM(CASE
            WHEN EXISTS (SELECT 1 FROM emprestimo_activo ea WHERE ea.cod_material = m.cod_material)
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(m.cod_material), 0) * 100,
    2) AS taxa_circulacao
FROM CATEGORIA c
LEFT JOIN MATERIAL_BIBLIOGRAFICO m ON m.cod_categoria = c.id_categoria
GROUP BY c.area_tematica, c.faixa_etaria, c.nivel_leitura;
/

