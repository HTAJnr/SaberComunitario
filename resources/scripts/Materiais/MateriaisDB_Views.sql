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

GRANT SELECT ON vw_mat_disponivel TO role_materiaisdb_read;


-- ============================================================
-- VISTA DE AUDITORIA
-- ============================================================
CREATE OR REPLACE VIEW VW_AUDITORIA AS
    SELECT id_auditoria, data_operacao, operacao, resultado,
           motivo_falha, nos_afetados, observacoes,
           'MATERIAIS' AS no_origem
    FROM AUDITORIA_MATERIAIS;

