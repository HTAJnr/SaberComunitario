-- ============================================================
-- MateriaisDB_Intro.sql — Dados iniciais do no MateriaisDB
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: usr_materiaisdb
-- Executar DEPOIS de: MateriaisDB_Triggers.sql
--
-- IMPORTANTE: Definir charset antes de executar:
--   export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
-- ============================================================

-- ============================================================
-- 1. CATEGORIAS
-- ============================================================
INSERT INTO CATEGORIA (id_categoria, area_tematica, faixa_etaria, nivel_leitura)
VALUES (1, 'Literatura Mocambicana', 'Adulto', 'Intermedio');
INSERT INTO CATEGORIA (id_categoria, area_tematica, faixa_etaria, nivel_leitura)
VALUES (2, 'Historia de Africa', 'Adulto', 'Avancado');
INSERT INTO CATEGORIA (id_categoria, area_tematica, faixa_etaria, nivel_leitura)
VALUES (3, 'Ciencias Naturais', 'Juvenil', 'Basico');
INSERT INTO CATEGORIA (id_categoria, area_tematica, faixa_etaria, nivel_leitura)
VALUES (4, 'Matematica', 'Juvenil', 'Intermedio');
INSERT INTO CATEGORIA (id_categoria, area_tematica, faixa_etaria, nivel_leitura)
VALUES (5, 'Contos Infantis', 'Infantil', 'Basico');
INSERT INTO CATEGORIA (id_categoria, area_tematica, faixa_etaria, nivel_leitura)
VALUES (6, 'Saude e Bem-Estar', 'Todas as Idades', 'Basico');
INSERT INTO CATEGORIA (id_categoria, area_tematica, faixa_etaria, nivel_leitura)
VALUES (7, 'Tecnologia e Informatica', 'Adulto', 'Intermedio');
INSERT INTO CATEGORIA (id_categoria, area_tematica, faixa_etaria, nivel_leitura)
VALUES (8, 'Agricultura e Ambiente', 'Adulto', 'Basico');

-- ============================================================
-- 2. MATERIAIS BIBLIOGRAFICOS — BIBMPC0001
-- ============================================================
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20190001', 'Vozes Anoitecidas', 'Mia Couto', 'Caminho', 1986, '978-972-21-0279-8', 'Portugues', 134, 'Bom', 'Comprado', TO_DATE('2019-03-01','YYYY-MM-DD'), 450.00, 'A1-01', 1, 'BIBMPC0001', NULL);
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20190002', 'Neighbours', 'Lilia Momple', 'Associacao dos Escritores Mocambicanos', 1995, '978-972-8279-01-5', 'Portugues', 120, 'Bom', 'Comprado', TO_DATE('2019-03-01','YYYY-MM-DD'), 380.00, 'A1-02', 1, 'BIBMPC0001', NULL);
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20200001', 'Matematica 10a Classe', 'INDE', 'INDE Mocambique', 2015, NULL, 'Portugues', 240, 'Degradado', 'Comprado', TO_DATE('2020-01-10','YYYY-MM-DD'), 320.00, 'B2-05', 4, 'BIBMPC0001', NULL);
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20240001', 'O Leao e o Coelho Astuto', 'Autor Coletivo', 'Editora Escolar', 2018, NULL, 'Portugues', 48, 'Bom', 'Doado', TO_DATE('2024-02-10','YYYY-MM-DD'), 'C3-01', 5, 'BIBMPC0001', 1);
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20240002', 'Saude para Todos', 'Ministerio da Saude', 'MISAU', 2020, NULL, 'Portugues', 96, 'Bom', 'Doado', TO_DATE('2024-02-10','YYYY-MM-DD'), 'D4-02', 6, 'BIBMPC0001', 1);
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20190003', 'Terra Sonambula', 'Mia Couto', 'Caminho', 1992, '978-972-21-0814-1', 'Portugues', 215, 'Bom', 'Comprado', TO_DATE('2019-06-01','YYYY-MM-DD'), 520.00, 'A1-03', 1, 'BIBMPC0001', NULL);
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20190004', 'Terra Sonambula', 'Mia Couto', 'Caminho', 1992, '978-972-21-0814-1', 'Portugues', 215, 'Bom', 'Comprado', TO_DATE('2019-06-01','YYYY-MM-DD'), 520.00, 'A1-04', 1, 'BIBMPC0001', NULL);
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20240003', 'O Olho de Hertzog', 'Paulina Chiziane', 'Ndjira', 2020, '978-989-802-345-2', 'Portugues', 188, 'Bom', 'Doado', TO_DATE('2024-05-20','YYYY-MM-DD'), 'A2-01', 1, 'BIBMPC0001', 3);

-- ============================================================
-- 2. MATERIAIS BIBLIOGRAFICOS — BIBGZA0001
-- ============================================================
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20240004', 'Ciencias Naturais 7a Classe', 'INDE', 'INDE Mocambique', 2016, NULL, 'Portugues', 180, 'Bom', 'Doado', TO_DATE('2024-02-10','YYYY-MM-DD'), 'B1-01', 3, 'BIBGZA0001', 2);
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20200002', 'Agricultura Familiar em Mocambique', 'FAO', 'FAO', 2019, NULL, 'Portugues', 120, 'Bom', 'Comprado', TO_DATE('2020-05-12','YYYY-MM-DD'), 280.00, 'C2-01', 8, 'BIBGZA0001', NULL);
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20210001', 'A Balada de Amor ao Vento', 'Paulina Chiziane', 'Ndjira', 1990, '978-972-8148-10-0', 'Portugues', 168, 'Bom', 'Comprado', TO_DATE('2021-03-15','YYYY-MM-DD'), 400.00, 'A1-01', 1, 'BIBGZA0001', NULL);

-- ============================================================
-- 2. MATERIAIS BIBLIOGRAFICOS — BIBSOF0001
-- ============================================================
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20240005', 'Introducao a Informatica', 'Varios Autores', 'Escolar Editora', 2021, NULL, 'Portugues', 210, 'Bom', 'Doado', TO_DATE('2024-09-01','YYYY-MM-DD'), 'D1-01', 7, 'BIBSOF0001', 4);
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20240006', 'Historia de Mocambique Vol.1', 'Malyn Newitt', 'Publicacoes Europa-America', 1997, '978-972-1-04148-9', 'Portugues', 352, 'Degradado', 'Doado', TO_DATE('2024-09-01','YYYY-MM-DD'), 'B1-01', 2, 'BIBSOF0001', 4);
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20210002', 'Contos do Nasreddin', 'Tradicao Oral', 'Ndjira', 2010, NULL, 'Portugues', 96, 'Bom', 'Comprado', TO_DATE('2021-07-20','YYYY-MM-DD'), 200.00, 'C3-01', 5, 'BIBSOF0001', NULL);

-- ============================================================
-- 3. LIVROS FISICOS
-- ============================================================
INSERT INTO LIVRO_FISICO VALUES ('MAT20190001');
INSERT INTO LIVRO_FISICO VALUES ('MAT20190002');
INSERT INTO LIVRO_FISICO VALUES ('MAT20200001');
INSERT INTO LIVRO_FISICO VALUES ('MAT20240001');
INSERT INTO LIVRO_FISICO VALUES ('MAT20240002');
INSERT INTO LIVRO_FISICO VALUES ('MAT20190003');
INSERT INTO LIVRO_FISICO VALUES ('MAT20190004');
INSERT INTO LIVRO_FISICO VALUES ('MAT20240003');
INSERT INTO LIVRO_FISICO VALUES ('MAT20240004');
INSERT INTO LIVRO_FISICO VALUES ('MAT20200002');
INSERT INTO LIVRO_FISICO VALUES ('MAT20210001');
INSERT INTO LIVRO_FISICO VALUES ('MAT20240005');
INSERT INTO LIVRO_FISICO VALUES ('MAT20240006');
INSERT INTO LIVRO_FISICO VALUES ('MAT20210002');

-- ============================================================
-- 4. EBOOKS
-- ============================================================
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, valor_aquisicao, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20230001', 'Guia de Saude Materno-Infantil', 'Ministerio da Saude', 'MISAU', 2022, NULL, 'Portugues', 80, 'Bom', 'Comprado', TO_DATE('2023-01-05','YYYY-MM-DD'), 0.00, 6, 'BIBMPC0001', NULL);
INSERT INTO EBOOK (cod_material, formato, tamanho_arquivo, url_acesso)
VALUES ('MAT20230001', 'PDF', 4.20, 'https://biblioteca.sabercom.mz/ebooks/saude-materno.pdf');

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, valor_aquisicao, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20230002', 'Programacao em Python para Iniciantes', 'Joao Ferreira', 'FCA', 2021, '978-972-722-810-5', 'Portugues', 320, 'Bom', 'Comprado', TO_DATE('2023-06-01','YYYY-MM-DD'), 150.00, 7, 'BIBMPC0001', NULL);
INSERT INTO EBOOK (cod_material, formato, tamanho_arquivo, url_acesso)
VALUES ('MAT20230002', 'EPUB', 2.80, 'https://biblioteca.sabercom.mz/ebooks/python-iniciantes.epub');

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, valor_aquisicao, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20220001', 'Atlas de Mocambique Digital', 'Instituto Nacional de Estatistica', 'INE', 2020, NULL, 'Portugues', 150, 'Bom', 'Comprado', TO_DATE('2022-11-10','YYYY-MM-DD'), 0.00, 2, 'BIBSOF0001', NULL);
INSERT INTO EBOOK (cod_material, formato, tamanho_arquivo, url_acesso)
VALUES ('MAT20220001', 'PDF', 18.50, 'https://biblioteca.sabercom.mz/ebooks/atlas-moz.pdf');

-- ============================================================
-- 5. PERIODICOS
-- ============================================================
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20240007', 'Revista de Ciencias da Saude de Mocambique', 'Universidade Eduardo Mondlane', 'UEM', 2024, NULL, 'Portugues', 64, 'Bom', 'Comprado', TO_DATE('2024-07-01','YYYY-MM-DD'), 120.00, 'P1-01', 6, 'BIBGZA0001', NULL);
INSERT INTO PERIODICO (cod_material, edicao, periodicidade, data_publicacao, ISSN)
VALUES ('MAT20240007', 'Vol. 12, No 2', 'Trimestral', TO_DATE('2024-06-30','YYYY-MM-DD'), '2220-2234');

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao, ISBN, idioma, num_paginas, estado_material_conservacao, origem_material, data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20250001', 'Boletim de Agricultura Sustentavel', 'Ministerio da Agricultura', 'MINAG', 2025, NULL, 'Portugues', 32, 'Bom', 'Comprado', TO_DATE('2025-01-10','YYYY-MM-DD'), 80.00, 'P1-02', 8, 'BIBGZA0001', NULL);
INSERT INTO PERIODICO (cod_material, edicao, periodicidade, data_publicacao, ISSN)
VALUES ('MAT20250001', 'Ano 3, No 1', 'Mensal', TO_DATE('2025-01-01','YYYY-MM-DD'), NULL);

-- ============================================================
-- 6. TRANSFERENCIA
-- Trigger desactivado temporariamente — EmprestimosDB pode
-- estar offline durante a instalacao inicial
-- ============================================================
ALTER TRIGGER trg_transferencia_insert DISABLE;

INSERT INTO TRANSFERENCIA (id_transferencia, data_solicitacao, estado_transferencia,
    cod_material, cod_biblioteca_origem, cod_biblioteca_destino,
    cod_funcionario_solicitante, motivo)
VALUES (1, TO_DATE('2025-04-25','YYYY-MM-DD'), 'Pendente',
    'MAT20190004', 'BIBMPC0001', 'BIBGZA0001',
    'FUC20250002', 'Solicitacao de BCX - alta procura de Mia Couto na regiao de Gaza');

ALTER TRIGGER trg_transferencia_insert ENABLE;

COMMIT;

