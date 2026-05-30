-- ============================================================
-- EmprestimosProg_Intro.sql
-- Dados iniciais de teste — EmprestimosProgramasDB
-- Executar DEPOIS de: Create + Sequences + Views + Auditoria +
--                     Functions + Procedures + Triggers + Indexes
--
-- Linux/CentOS: export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
-- sqlplus usr_emprestimosdb/YC20220156@XE @EmprestimosProg_Intro.sql
--
-- Formatos de codigo (dicionario v4):
--   FUNCIONARIO : FUC20250000
--   LEITOR      : XXX20250000  (XXX = iniciais da biblioteca)
--   MATERIAL    : MAT20XX0000
--   PROGRAMA    : PROBIBXXX20XXYYYY
--
-- Codigos de leitor (BibNacional_Intro.sql — Helder):
--   BIBMPC0001 → MPC20250001, MPC20250002, MPC20250003
--   BIBGZA0001 → GZA20250001, GZA20250002
--   BIBSOF0001 → SOF20250001, SOF20250002
--
-- Dados de LEITOR e FUNCIONARIO vivem no BibliotecaNacionalDB (Helder).
-- Este script popula apenas as tabelas locais:
--   REPL_FUNCIONARIOS, EMPRESTIMO, SUSPENSAO,
--   PROGRAMA_ALFABETIZACAO, NIVEL_PROGRESSAO,
--   PROGRAMA_MATERIAL, PROGRAMA_FUNCIONARIO, PARTICIPACAO_PROGRAMA
-- ============================================================

-- ============================================================
-- 1. REPL_FUNCIONARIOS
--    Replica parcial de funcionarios vinda do BibliotecaNacionalDB
--    Todos os 10 funcionarios do sistema (FUC20250001-FUC20251000)
-- ============================================================
INSERT INTO REPL_FUNCIONARIOS (cod_funcionario, nome_funcionario, nivel_acesso,
    id_funcao, cod_biblioteca, nome_funcao)
VALUES ('FUC20250001', 'Ana Maria Sitoe', 'Administrador', 1, 'BIBMPC0001', 'Administrador');

INSERT INTO REPL_FUNCIONARIOS (cod_funcionario, nome_funcionario, nivel_acesso,
    id_funcao, cod_biblioteca, nome_funcao)
VALUES ('FUC20250002', 'Carlos Nhambiu', 'Coordenador', 2, 'BIBMPC0001', 'Coordenador');

INSERT INTO REPL_FUNCIONARIOS (cod_funcionario, nome_funcionario, nivel_acesso,
    id_funcao, cod_biblioteca, nome_funcao)
VALUES ('FUC20250003', 'Beatriz Cossa', 'Bibliotecario', 3, 'BIBMPC0001', 'Bibliotecario');

INSERT INTO REPL_FUNCIONARIOS (cod_funcionario, nome_funcionario, nivel_acesso,
    id_funcao, cod_biblioteca, nome_funcao)
VALUES ('FUC20250004', 'Domingos Machava', 'Assistente', 4, 'BIBMPC0001', 'Assistente');

INSERT INTO REPL_FUNCIONARIOS (cod_funcionario, nome_funcionario, nivel_acesso,
    id_funcao, cod_biblioteca, nome_funcao)
VALUES ('FUC20250005', 'Esperanca Bila', 'Coordenador', 2, 'BIBGZA0001', 'Coordenador');

INSERT INTO REPL_FUNCIONARIOS (cod_funcionario, nome_funcionario, nivel_acesso,
    id_funcao, cod_biblioteca, nome_funcao)
VALUES ('FUC20250006', 'Fernando Mondlane', 'Bibliotecario', 3, 'BIBGZA0001', 'Bibliotecario');

INSERT INTO REPL_FUNCIONARIOS (cod_funcionario, nome_funcionario, nivel_acesso,
    id_funcao, cod_biblioteca, nome_funcao)
VALUES ('FUC20250007', 'Graca Tembe', 'Assistente', 4, 'BIBGZA0001', 'Assistente');

INSERT INTO REPL_FUNCIONARIOS (cod_funcionario, nome_funcionario, nivel_acesso,
    id_funcao, cod_biblioteca, nome_funcao)
VALUES ('FUC20250008', 'Helder Zunguze', 'Coordenador', 2, 'BIBSOF0001', 'Coordenador');

INSERT INTO REPL_FUNCIONARIOS (cod_funcionario, nome_funcionario, nivel_acesso,
    id_funcao, cod_biblioteca, nome_funcao)
VALUES ('FUC20250009', 'Ilda Macuacua', 'Bibliotecario', 3, 'BIBSOF0001', 'Bibliotecario');

INSERT INTO REPL_FUNCIONARIOS (cod_funcionario, nome_funcionario, nivel_acesso,
    id_funcao, cod_biblioteca, nome_funcao)
VALUES ('FUC20251000', 'Jorge Nuvunga', 'Assistente', 4, 'BIBSOF0001', 'Assistente');

-- ============================================================
-- 2. EMPRESTIMOS
--    num_cartao e cod_material referenciam dados remotos
--    (BibliotecaNacionalDB e MateriaisDB respectivamente)
-- ============================================================

-- Emprestimo activo — leitor MPC20250001, material MAT20230001
INSERT INTO EMPRESTIMO (id_emprestimo, num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, estado_material_saida, multa_paga)
VALUES (SEQ_EMPRESTIMO.NEXTVAL, 'MPC20250001', 'FUC20250003', 'MAT20230001',
    TO_DATE('2025-04-20','YYYY-MM-DD'), TO_DATE('2025-05-04','YYYY-MM-DD'),
    'Bom', 'N');
-- id_emprestimo = 1

-- Emprestimo devolvido a tempo — leitor MPC20250002
INSERT INTO EMPRESTIMO (id_emprestimo, num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, data_devolucao,
    estado_material_saida, estado_material_retorno, multa_paga)
VALUES (SEQ_EMPRESTIMO.NEXTVAL, 'MPC20250002', 'FUC20250003', 'MAT20220001',
    TO_DATE('2025-03-01','YYYY-MM-DD'), TO_DATE('2025-03-15','YYYY-MM-DD'),
    TO_DATE('2025-03-14','YYYY-MM-DD'),
    'Bom', 'Bom', 'S');
-- id_emprestimo = 2

-- Emprestimo devolvido com 5 dias de atraso — leitor GZA20250001
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

-- Emprestimo devolvido com 65 dias de atraso — leitor SOF20250001
-- Atraso > 60 dias: leitor bloqueado, material marcado como Indisponivel
INSERT INTO EMPRESTIMO (id_emprestimo, num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, data_devolucao,
    estado_material_saida, estado_material_retorno,
    multa_valor, multa_paga)
VALUES (SEQ_EMPRESTIMO.NEXTVAL, 'SOF20250001', 'FUC20250008', 'MAT20190001',
    TO_DATE('2024-11-01','YYYY-MM-DD'), TO_DATE('2024-11-15','YYYY-MM-DD'),
    TO_DATE('2025-01-19','YYYY-MM-DD'),
    'Bom', 'Perdido', 975.00, 'N');
-- id_emprestimo = 4

-- ============================================================
-- 3. SUSPENSOES
--    Suspensao gerada pelo atraso de 5 dias do emprestimo 3
-- ============================================================
INSERT INTO SUSPENSAO (id_suspensao, num_cartao, id_emprestimo,
    data_inicio, data_fim, dias_suspensao, estado_suspensao, observacoes)
VALUES (SEQ_SUSPENSAO.NEXTVAL, 'GZA20250001', 3,
    TO_DATE('2025-02-20','YYYY-MM-DD'), TO_DATE('2025-02-27','YYYY-MM-DD'),
    7, 'Cumprida', 'Atraso de 5 dias — suspensao de 7 dias aplicada automaticamente');
-- id_suspensao = 1

-- ============================================================
-- 4. PROGRAMAS DE ALFABETIZACAO
--    cod_programa: PROBIBXXX20XXYYYY
--    XXX: MPC=Maputo Cidade, GZA=Gaza, SOF=Sofala
-- ============================================================

-- Programa Maputo Cidade
INSERT INTO PROGRAMA_ALFABETIZACAO (
    cod_programa, cod_biblioteca, nome_programa, descricao,
    publico_alvo, duracao_semanas, metodologia, resultados_esperados, estado_programa)
VALUES (
    'PROBIBMPC20250001', 'BIBMPC0001',
    'Ler para Crescer — Maputo',
    'Programa de alfabetizacao basica para adultos no bairro da Polana',
    'Iniciantes', 24,
    'Metodo fonetico com reforco visual e fichas de leitura progressiva',
    'Participantes capazes de ler e escrever frases simples em Portugues',
    'Activo');
-- cod_programa = PROBIBMPC20250001

-- Programa Gaza
INSERT INTO PROGRAMA_ALFABETIZACAO (
    cod_programa, cod_biblioteca, nome_programa, descricao,
    publico_alvo, duracao_semanas, metodologia, resultados_esperados, estado_programa)
VALUES (
    'PROBIBGZA20250001', 'BIBGZA0001',
    'Ler para Crescer — Gaza',
    'Programa de alfabetizacao comunitaria em Xai-Xai',
    'Iniciantes', 20,
    'Metodo Paulo Freire adaptado ao contexto local',
    'Participantes com capacidade de leitura funcional no quotidiano',
    'Activo');
-- cod_programa = PROBIBGZA20250001

-- Programa Sofala
INSERT INTO PROGRAMA_ALFABETIZACAO (
    cod_programa, cod_biblioteca, nome_programa, descricao,
    publico_alvo, duracao_semanas, metodologia, resultados_esperados, estado_programa)
VALUES (
    'PROBIBSOF20250001', 'BIBSOF0001',
    'Beira Digital — Informatica Basica',
    'Introducao ao uso de computadores e internet para a comunidade de Munhava',
    'Todos', 16,
    'Aulas praticas semanais em laboratorio de informatica',
    'Participantes capazes de usar o computador e navegar na internet com autonomia',
    'Activo');
-- cod_programa = PROBIBSOF20250001

-- ============================================================
-- 5. NIVEIS DE PROGRESSAO
--    id_nivel gerado por SEQ_NIVEL.NEXTVAL
--    Ordem de insercao define os IDs (importante para PARTICIPACAO_PROGRAMA)
--      1-3 → PROBIBMPC20250001 (niveis 1, 2, 3)
--      4-6 → PROBIBGZA20250001 (niveis 1, 2, 3)
--      7-8 → PROBIBSOF20250001 (modulos 1, 2)
-- ============================================================

-- Niveis do Programa Maputo (PROBIBMPC20250001)
INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBMPC20250001',
    'Nivel 1 — Letras e Sons',
    'Reconhecimento do alfabeto e sons basicos', 1);
-- id_nivel = 1

INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBMPC20250001',
    'Nivel 2 — Silabas e Palavras',
    'Formacao de silabas e vocabulario basico', 2);
-- id_nivel = 2

INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBMPC20250001',
    'Nivel 3 — Frases e Textos',
    'Leitura de frases curtas e textos simples', 3);
-- id_nivel = 3

-- Niveis do Programa Gaza (PROBIBGZA20250001)
INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBGZA20250001',
    'Nivel 1 — Letras e Sons',
    'Reconhecimento do alfabeto e sons basicos', 1);
-- id_nivel = 4

INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBGZA20250001',
    'Nivel 2 — Silabas e Palavras',
    'Formacao de silabas e vocabulario basico', 2);
-- id_nivel = 5

INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBGZA20250001',
    'Nivel 3 — Frases e Textos',
    'Leitura de frases curtas e textos simples', 3);
-- id_nivel = 6

-- Modulos do Programa Sofala (PROBIBSOF20250001)
INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBSOF20250001',
    'Modulo 1 — Hardware e SO',
    'Uso basico do computador e sistema operativo', 1);
-- id_nivel = 7

INSERT INTO NIVEL_PROGRESSAO (id_nivel, cod_programa, nome_nivel, descricao, ordem)
VALUES (SEQ_NIVEL.NEXTVAL, 'PROBIBSOF20250001',
    'Modulo 2 — Internet',
    'Navegacao e seguranca na internet', 2);
-- id_nivel = 8

-- ============================================================
-- 6. PROGRAMA_FUNCIONARIO
--    papel: 'Responsavel', 'Instrutor', 'Auxiliar'
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

-- ============================================================
-- 7. PROGRAMA_MATERIAL
--    cod_material referencia MateriaisDB (Yasin)
--    Materiais devem pertencer a biblioteca do programa (ou acessiveis via transferencia)
-- ============================================================

-- PROBIBMPC20250001 usa materiais de BIBMPC0001
INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material, observacoes)
VALUES ('PROBIBMPC20250001', 'MAT20190001', 'Material de apoio principal — leitura de prosa');

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

-- ============================================================
-- 8. PARTICIPACAO_PROGRAMA
--    PK composta (num_cartao, cod_programa) — sem SEQ_PARTICIPACAO
--    num_cartao: codigos de BibNacional_Intro.sql (Helder)
--    id_nivel_atual referencia NIVEL_PROGRESSAO (ver secao 5 acima)
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

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================
COMMIT;
