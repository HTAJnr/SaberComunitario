-- ============================================================
-- EmprestimosProg_Intro.sql
-- Dados iniciais de teste -- EmprestimosProgramasDB
-- Executar DEPOIS de: Create + Sequences + Views + Auditoria +
--                     Functions + Procedures + Triggers + Indexes
--
-- Linux/CentOS: export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
-- sqlplus usr_emprestimosdb/"YC20220156"@XE @EmprestimosProg_Intro.sql
--
-- Formatos de codigo (dicionario v4):
--   FUNCIONARIO : FUC20250000
--   LEITOR      : XXX20250000  (XXX = iniciais da biblioteca)
--   MATERIAL    : MAT20XX0000
--   PROGRAMA    : PROBIBXXX20XXYYYY
--
-- Codigos de leitor (BibNacional_Intro.sql):
--   BIBMPC0001 -> MPC20250001, MPC20250002, MPC20250003
--   BIBGZA0001 -> GZA20250001, GZA20250002
--   BIBSOF0001 -> SOF20250001, SOF20250002
--   BIBQLM0001 -> QLM20250001, QLM20250002
--   BIBNMP0001 -> NMP20250001, NMP20250002
--
-- Dados de LEITOR e FUNCIONARIO vivem no BibliotecaNacionalDB.
-- Este script popula apenas as tabelas locais:
--   EMPRESTIMO, SUSPENSAO,
--   PROGRAMA_ALFABETIZACAO, NIVEL_PROGRESSAO,
--   PROGRAMA_MATERIAL, PROGRAMA_FUNCIONARIO, PARTICIPACAO_PROGRAMA
-- ============================================================

-- ============================================================
-- 1. EMPRESTIMOS
-- ============================================================

-- Emprestimo activo -- leitor MPC20250001, material MAT20230001
INSERT INTO EMPRESTIMO (id_emprestimo, num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, estado_material_saida, multa_paga)
VALUES (SEQ_EMPRESTIMO.NEXTVAL, 'MPC20250001', 'FUC20250003', 'MAT20230001',
    TO_DATE('2025-04-20','YYYY-MM-DD'), TO_DATE('2025-05-04','YYYY-MM-DD'),
    'Bom', 'N');
-- id_emprestimo = 1

-- Emprestimo devolvido a tempo -- leitor MPC20250002
INSERT INTO EMPRESTIMO (id_emprestimo, num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, data_devolucao,
    estado_material_saida, estado_material_retorno, multa_paga)
VALUES (SEQ_EMPRESTIMO.NEXTVAL, 'MPC20250002', 'FUC20250003', 'MAT20220001',
    TO_DATE('2025-03-01','YYYY-MM-DD'), TO_DATE('2025-03-15','YYYY-MM-DD'),
    TO_DATE('2025-03-14','YYYY-MM-DD'),
    'Bom', 'Bom', 'S');
-- id_emprestimo = 2

-- Emprestimo devolvido com 5 dias de atraso -- leitor GZA20250001
-- Suspensao de 7 dias aplicada (RN03: 1-7 dias atraso = 7 dias suspensao)
INSERT INTO EMPRESTIMO (id_emprestimo, num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, data_devolucao,
    estado_material_saida, estado_material_retorno,
    multa_valor, multa_paga)
VALUES (SEQ_EMPRESTIMO.NEXTVAL, 'GZA20250001', 'FUC20250005', 'MAT20240001',
    TO_DATE('2025-02-01','YYYY-MM-DD'), TO_DATE('2025-02-15','YYYY-MM-DD'),
    TO_DATE('2025-02-20','YYYY-MM-DD'),
    'Bom', 'Bom', 75.00, 'N');
-- id_emprestimo = 3

-- Emprestimo devolvido com 65 dias de atraso -- leitor SOF20250002
-- Atraso > 60 dias: leitor bloqueado, material marcado como Indisponivel
INSERT INTO EMPRESTIMO (id_emprestimo, num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, data_devolucao,
    estado_material_saida, estado_material_retorno,
    multa_valor, multa_paga)
VALUES (SEQ_EMPRESTIMO.NEXTVAL, 'SOF20250002', 'FUC20250008', 'MAT20190001',
    TO_DATE('2024-11-01','YYYY-MM-DD'), TO_DATE('2024-11-15','YYYY-MM-DD'),
    TO_DATE('2025-01-19','YYYY-MM-DD'),
    'Bom', 'Perdido', 975.00, 'N');
-- id_emprestimo = 4

-- Emprestimo activo -- leitor QLM20250001, material MAT20250010
INSERT INTO EMPRESTIMO (id_emprestimo, num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, estado_material_saida, multa_paga)
VALUES (SEQ_EMPRESTIMO.NEXTVAL, 'QLM20250001', 'FUC20250011', 'MAT20250010',
    TO_DATE('2026-01-15','YYYY-MM-DD'), TO_DATE('2026-01-29','YYYY-MM-DD'),
    'Bom', 'N');
-- id_emprestimo = 5

-- Emprestimo devolvido a tempo -- leitor NMP20250001, material MAT20250013
INSERT INTO EMPRESTIMO (id_emprestimo, num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, data_devolucao,
    estado_material_saida, estado_material_retorno, multa_paga)
VALUES (SEQ_EMPRESTIMO.NEXTVAL, 'NMP20250001', 'FUC20250014', 'MAT20250013',
    TO_DATE('2025-07-01','YYYY-MM-DD'), TO_DATE('2025-07-15','YYYY-MM-DD'),
    TO_DATE('2025-07-14','YYYY-MM-DD'),
    'Bom', 'Bom', 'S');
-- id_emprestimo = 6

-- Emprestimo antigo devolvido -- leitor GZA20250002, material MAT20210001 (2023)
INSERT INTO EMPRESTIMO (id_emprestimo, num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, data_devolucao,
    estado_material_saida, estado_material_retorno, multa_paga)
VALUES (SEQ_EMPRESTIMO.NEXTVAL, 'GZA20250002', 'FUC20250005', 'MAT20210001',
    TO_DATE('2023-08-05','YYYY-MM-DD'), TO_DATE('2023-08-19','YYYY-MM-DD'),
    TO_DATE('2023-08-18','YYYY-MM-DD'),
    'Bom', 'Bom', 'S');
-- id_emprestimo = 7

-- ============================================================
-- 3. SUSPENSOES
-- ============================================================
INSERT INTO SUSPENSAO (id_suspensao, num_cartao, id_emprestimo,
    data_inicio, data_fim, dias_suspensao, estado_suspensao, observacoes)
VALUES (SEQ_SUSPENSAO.NEXTVAL, 'GZA20250001', 3,
    TO_DATE('2025-02-20','YYYY-MM-DD'), TO_DATE('2025-02-27','YYYY-MM-DD'),
    7, 'Cumprida', 'Atraso de 5 dias -- suspensao de 7 dias aplicada automaticamente');
-- id_suspensao = 1

-- ============================================================
-- 4. PROGRAMAS DE ALFABETIZACAO
-- ============================================================

-- Programa Maputo Cidade
INSERT INTO PROGRAMA_ALFABETIZACAO (
    cod_programa, cod_biblioteca, nome_programa, descricao,
    publico_alvo, duracao_semanas, metodologia, resultados_esperados, estado_programa)
VALUES (
    'PROBIBMPC20250001', 'BIBMPC0001',
    'Ler para Crescer - Maputo',
    'Programa de alfabetizacao basica para adultos no bairro da Polana',
    'Iniciantes', 24,
    'Metodo fonetico com reforco visual e fichas de leitura progressiva',
    'Participantes capazes de ler e escrever frases simples em Portugues',
    'Activo');

-- Programa Gaza
INSERT INTO PROGRAMA_ALFABETIZACAO (
    cod_programa, cod_biblioteca, nome_programa, descricao,
    publico_alvo, duracao_semanas, metodologia, resultados_esperados, estado_programa)
VALUES (
    'PROBIBGZA20250001', 'BIBGZA0001',
    'Ler para Crescer - Gaza',
    'Programa de alfabetizacao comunitaria em Xai-Xai',
    'Iniciantes', 20,
    'Metodo Paulo Freire adaptado ao contexto local',
    'Participantes com capacidade de leitura funcional no quotidiano',
    'Activo');

-- Programa Sofala
INSERT INTO PROGRAMA_ALFABETIZACAO (
    cod_programa, cod_biblioteca, nome_programa, descricao,
    publico_alvo, duracao_semanas, metodologia, resultados_esperados, estado_programa)
VALUES (
    'PROBIBSOF20250001', 'BIBSOF0001',
    'Beira Digital - Informatica Basica',
    'Introducao ao uso de computadores e internet para a comunidade de Munhava',
    'Todos', 16,
    'Aulas praticas semanais em laboratorio de informatica',
    'Participantes capazes de usar o computador e navegar na internet com autonomia',
    'Activo');

-- Programa Quelimane
INSERT INTO PROGRAMA_ALFABETIZACAO (
    cod_programa, cod_biblioteca, nome_programa, descricao,
    publico_alvo, duracao_semanas, metodologia, resultados_esperados, estado_programa)
VALUES (
    'PROBIBQLM20250001', 'BIBQLM0001',
    'Letras do Rio - Quelimane',
    'Programa de alfabetizacao para adultos na regiao de Coalane e arredores',
    'Iniciantes', 18,
    'Metodo silabico com apoio de imagens e contos locais',
    'Participantes capazes de ler cartazes, noticias e formularios basicos',
    'Activo');

-- Programa Nampula
INSERT INTO PROGRAMA_ALFABETIZACAO (
    cod_programa, cod_biblioteca, nome_programa, descricao,
    publico_alvo, duracao_semanas, metodologia, resultados_esperados, estado_programa)
VALUES (
    'PROBIBNMP20250001', 'BIBNMP0001',
    'Leitura Viva - Nampula',
    'Programa de alfabetizacao e promocao de leitura em Nampula cidade',
    'Iniciantes', 20,
    'Contos tradicionais Macua como ponto de partida para o ensino da escrita',
    'Participantes com autonomia de leitura e escrita em Portugues basico',
    'Activo');

-- ============================================================
-- 5. NIVEIS DE PROGRESSAO
--    Ordem de insercao define os IDs:
--      1-3  -> PROBIBMPC20250001
--      4-6  -> PROBIBGZA20250001
--      7-8  -> PROBIBSOF20250001
--      9-10 -> PROBIBQLM20250001
--      11-12 -> PROBIBNMP20250001
-- ============================================================

-- Niveis do Programa Maputo (PROBIBMPC20250001)
INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBMPC20250001',
    'Nivel 1 - Letras e Sons',
    'Reconhecimento do alfabeto e sons basicos', 1);
-- id_nivel = 1

INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBMPC20250001',
    'Nivel 2 - Silabas e Palavras',
    'Formacao de silabas e vocabulario basico', 2);
-- id_nivel = 2

INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBMPC20250001',
    'Nivel 3 - Frases e Textos',
    'Leitura de frases curtas e textos simples', 3);
-- id_nivel = 3

-- Niveis do Programa Gaza (PROBIBGZA20250001)
INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBGZA20250001',
    'Nivel 1 - Letras e Sons',
    'Reconhecimento do alfabeto e sons basicos', 1);
-- id_nivel = 4

INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBGZA20250001',
    'Nivel 2 - Silabas e Palavras',
    'Formacao de silabas e vocabulario basico', 2);
-- id_nivel = 5

INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBGZA20250001',
    'Nivel 3 - Frases e Textos',
    'Leitura de frases curtas e textos simples', 3);
-- id_nivel = 6

-- Modulos do Programa Sofala (PROBIBSOF20250001)
INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBSOF20250001',
    'Modulo 1 - Hardware e SO',
    'Uso basico do computador e sistema operativo', 1);
-- id_nivel = 7

INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBSOF20250001',
    'Modulo 2 - Internet',
    'Navegacao e seguranca na internet', 2);
-- id_nivel = 8

-- Niveis do Programa Quelimane (PROBIBQLM20250001)
INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBQLM20250001',
    'Nivel 1 - Letras e Sons',
    'Reconhecimento do alfabeto e sons basicos', 1);
-- id_nivel = 9

INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBQLM20250001',
    'Nivel 2 - Silabas e Palavras',
    'Formacao de silabas e leitura de palavras do dia-a-dia', 2);
-- id_nivel = 10

-- Niveis do Programa Nampula (PROBIBNMP20250001)
INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBNMP20250001',
    'Nivel 1 - Contos e Letras',
    'Reconhecimento do alfabeto atraves de contos Macua', 1);
-- id_nivel = 11

INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBNMP20250001',
    'Nivel 2 - Leitura Funcional',
    'Leitura de textos curtos do quotidiano', 2);
-- id_nivel = 12

-- ============================================================
-- 6. PROGRAMA_FUNCIONARIO
-- ============================================================
INSERT INTO PROGRAMA_FUNCIONARIO (cod_programa, cod_funcionario, papel)
VALUES ('PROBIBMPC20250001', 'FUC20250002', 'Responsavel');

INSERT INTO PROGRAMA_FUNCIONARIO (cod_programa, cod_funcionario, papel)
VALUES ('PROBIBMPC20250001', 'FUC20250003', 'Instrutor');

INSERT INTO PROGRAMA_FUNCIONARIO (cod_programa, cod_funcionario, papel)
VALUES ('PROBIBGZA20250001', 'FUC20250005', 'Responsavel');

INSERT INTO PROGRAMA_FUNCIONARIO (cod_programa, cod_funcionario, papel)
VALUES ('PROBIBGZA20250001', 'FUC20250006', 'Instrutor');

INSERT INTO PROGRAMA_FUNCIONARIO (cod_programa, cod_funcionario, papel)
VALUES ('PROBIBSOF20250001', 'FUC20250008', 'Responsavel');

INSERT INTO PROGRAMA_FUNCIONARIO (cod_programa, cod_funcionario, papel)
VALUES ('PROBIBSOF20250001', 'FUC20251000', 'Instrutor');

INSERT INTO PROGRAMA_FUNCIONARIO (cod_programa, cod_funcionario, papel)
VALUES ('PROBIBQLM20250001', 'FUC20250011', 'Responsavel');

INSERT INTO PROGRAMA_FUNCIONARIO (cod_programa, cod_funcionario, papel)
VALUES ('PROBIBQLM20250001', 'FUC20250012', 'Instrutor');

INSERT INTO PROGRAMA_FUNCIONARIO (cod_programa, cod_funcionario, papel)
VALUES ('PROBIBNMP20250001', 'FUC20250014', 'Responsavel');

INSERT INTO PROGRAMA_FUNCIONARIO (cod_programa, cod_funcionario, papel)
VALUES ('PROBIBNMP20250001', 'FUC20250015', 'Instrutor');

-- ============================================================
-- 7. PROGRAMA_MATERIAL
-- ============================================================

-- PROBIBMPC20250001 usa materiais de BIBMPC0001
INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material, observacoes)
VALUES ('PROBIBMPC20250001', 'MAT20190001', 'Material de apoio principal -- leitura de prosa');

INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material, observacoes)
VALUES ('PROBIBMPC20250001', 'MAT20240002', 'Textos praticos para exercicios de leitura');

-- PROBIBGZA20250001 usa materiais de BIBGZA0001
INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material, observacoes)
VALUES ('PROBIBGZA20250001', 'MAT20240004', 'Material de apoio principal');

INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material, observacoes)
VALUES ('PROBIBGZA20250001', 'MAT20250001', 'Textos praticos para exercicios de leitura');

-- PROBIBSOF20250001 usa materiais de BIBSOF0001
INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material, observacoes)
VALUES ('PROBIBSOF20250001', 'MAT20240005', 'Manual principal do programa de informatica');

-- PROBIBQLM20250001 usa materiais de BIBQLM0001
INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material, observacoes)
VALUES ('PROBIBQLM20250001', 'MAT20250011', 'Contos locais usados como base para o ensino');

INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material, observacoes)
VALUES ('PROBIBQLM20250001', 'MAT20250012', 'Dicionario de referencia para os participantes');

-- PROBIBNMP20250001 usa materiais de BIBNMP0001
INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material, observacoes)
VALUES ('PROBIBNMP20250001', 'MAT20250013', 'Literatura Macua como base metodologica');

INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material, observacoes)
VALUES ('PROBIBNMP20250001', 'MAT20260002', 'Material de matematica basica para adultos');

-- ============================================================
-- 8. PARTICIPACAO_PROGRAMA
-- ============================================================

-- Participacoes no Programa Maputo (niveis 1-3)
INSERT INTO PARTICIPACAO_PROGRAMA (num_cartao, cod_programa, id_nivel_atual, data_inscricao)
VALUES ('MPC20250001', 'PROBIBMPC20250001', 2, TO_DATE('2025-02-05','YYYY-MM-DD'));

INSERT INTO PARTICIPACAO_PROGRAMA (num_cartao, cod_programa, id_nivel_atual, data_inscricao)
VALUES ('MPC20250002', 'PROBIBMPC20250001', 3, TO_DATE('2025-02-05','YYYY-MM-DD'));

-- Participacoes no Programa Gaza (niveis 4-6)
INSERT INTO PARTICIPACAO_PROGRAMA (num_cartao, cod_programa, id_nivel_atual, data_inscricao)
VALUES ('GZA20250001', 'PROBIBGZA20250001', 4, TO_DATE('2025-03-05','YYYY-MM-DD'));

INSERT INTO PARTICIPACAO_PROGRAMA (num_cartao, cod_programa, id_nivel_atual, data_inscricao)
VALUES ('GZA20250002', 'PROBIBGZA20250001', 5, TO_DATE('2025-03-05','YYYY-MM-DD'));

-- Participacoes no Programa Sofala (niveis 7-8)
INSERT INTO PARTICIPACAO_PROGRAMA (num_cartao, cod_programa, id_nivel_atual, data_inscricao)
VALUES ('SOF20250001', 'PROBIBSOF20250001', 8, TO_DATE('2025-04-05','YYYY-MM-DD'));

INSERT INTO PARTICIPACAO_PROGRAMA (num_cartao, cod_programa, id_nivel_atual, data_inscricao)
VALUES ('SOF20250002', 'PROBIBSOF20250001', 7, TO_DATE('2025-04-05','YYYY-MM-DD'));

-- Participacoes no Programa Quelimane (niveis 9-10)
INSERT INTO PARTICIPACAO_PROGRAMA (num_cartao, cod_programa, id_nivel_atual, data_inscricao)
VALUES ('QLM20250001', 'PROBIBQLM20250001', 9, TO_DATE('2025-08-10','YYYY-MM-DD'));

INSERT INTO PARTICIPACAO_PROGRAMA (num_cartao, cod_programa, id_nivel_atual, data_inscricao)
VALUES ('QLM20250002', 'PROBIBQLM20250001', 10, TO_DATE('2025-08-10','YYYY-MM-DD'));

-- Participacoes no Programa Nampula (niveis 11-12)
INSERT INTO PARTICIPACAO_PROGRAMA (num_cartao, cod_programa, id_nivel_atual, data_inscricao)
VALUES ('NMP20250001', 'PROBIBNMP20250001', 11, TO_DATE('2025-09-15','YYYY-MM-DD'));

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================
COMMIT;
