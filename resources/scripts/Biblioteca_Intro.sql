-- ============================================================
-- SABER COMUNITÁRIO — DADOS DE TESTE v2
-- Executar DEPOIS de: Create + Sequences + Views + Functions + Procedures + Triggers + Indexes
--
-- ACENTOS: Para evitar corrupção de caracteres, execute com:
--   Windows CMD:  set NLS_LANG=AMERICAN_AMERICA.AL32UTF8
--   Linux/CentOS: export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
-- Depois: sqlplus user/pass@XE @Biblioteca_Intro.sql
-- O ficheiro deve estar guardado em UTF-8 (sem BOM).
--
-- Formatos de código (conforme DDv3):
--   BIBLIOTECA    : BIBXXX0000   (XXX = código de província)
--   FUNCIONARIO   : FUC20250000
--   MATERIAL      : MAT20190000 / MAT20200000 / etc.
--   LEITOR        : XXX20250000  (XXX = iniciais da biblioteca)
--   PROGRAMA      : PROBIBXXX20250000
--
-- Senhas (bcrypt, cost=10):
--   Ana Sitoe     → AS2026@Saber
--   Carlos Nhambiu→ CN2026@Saber
--   Beatriz Cossa → BC2026@Saber
--   Domingos Mach.→ DM2026@Saber
--   Esperança Bila→ EB2026@Saber
--   Fernando Mond.→ FM2026@Saber
--   Graça Tembe   → GT2026@Saber
--   Helder Zunguze→ HZ2026@Saber
--   Ilda Macuacua → IM2026@Saber
--   Jorge Nuvunga → JN2026@Saber
-- ============================================================

-- ============================================================
-- 1. BIBLIOTECAS
--    BIBMPC0001 = Maputo Cidade  (MPC)
--    BIBGZA0001 = Gaza           (GZA)
--    BIBSOF0001 = Sofala         (SOF)
-- ============================================================
INSERT INTO BIBLIOTECA (cod_biblioteca, nome_biblioteca, provincia, endereco,
    latitude, longitude, contacto_biblioteca, data_inauguracao, capacidade,
    infraestrutura, servicos)
VALUES ('BIBMPC0001', 'Biblioteca Comunitaria Polana', 'Maputo Cidade',
    'Av. Julius Nyerere, 1234, Polana, Maputo', -25.966, 32.583,
    '+258 21 321 001', TO_DATE('2018-03-15','YYYY-MM-DD'), 120,
    'Sala de leitura, sala infantil, sala de informatica, auditorio',
    'Emprestimo domiciliario, internet gratuita, clube de leitura');

INSERT INTO BIBLIOTECA (cod_biblioteca, nome_biblioteca, provincia, endereco,
    latitude, longitude, contacto_biblioteca, data_inauguracao, capacidade,
    infraestrutura, servicos)
VALUES ('BIBGZA0001', 'Biblioteca Comunitaria Xai-Xai', 'Gaza',
    'Rua da Independencia, 45, Xai-Xai', -25.052, 33.644,
    '+258 22 224 002', TO_DATE('2019-07-04','YYYY-MM-DD'), 80,
    'Sala de leitura, sala multimedia, jardim exterior',
    'Emprestimo domiciliario, programa de alfabetizacao, eventos culturais');

INSERT INTO BIBLIOTECA (cod_biblioteca, nome_biblioteca, provincia, endereco,
    latitude, longitude, contacto_biblioteca, data_inauguracao, capacidade,
    infraestrutura, servicos)
VALUES ('BIBSOF0001', 'Biblioteca Comunitaria da Beira', 'Sofala',
    'Av. Samora Machel, 789, Beira', -19.838, 34.838,
    '+258 23 312 003', TO_DATE('2020-01-20','YYYY-MM-DD'), 100,
    'Sala de leitura, laboratorio de informatica, sala de reunioes',
    'Emprestimo domiciliario, internet, cursos de informatica basica');

-- ============================================================
-- 2. HORÁRIOS DAS BIBLIOTECAS
-- ============================================================
INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBMPC0001', 'Segunda-feira', '08:00', '18:00');
INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBMPC0001', 'Terca-feira',   '08:00', '18:00');
INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBMPC0001', 'Quarta-feira',  '08:00', '18:00');
INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBMPC0001', 'Quinta-feira',  '08:00', '18:00');
INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBMPC0001', 'Sexta-feira',   '08:00', '18:00');
INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBMPC0001', 'Sabado',        '08:00', '13:00');

INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBGZA0001', 'Segunda-feira', '07:30', '17:30');
INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBGZA0001', 'Terca-feira',   '07:30', '17:30');
INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBGZA0001', 'Quarta-feira',  '07:30', '17:30');
INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBGZA0001', 'Quinta-feira',  '07:30', '17:30');
INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBGZA0001', 'Sexta-feira',   '07:30', '17:30');

INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBSOF0001', 'Segunda-feira', '08:00', '17:00');
INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBSOF0001', 'Terca-feira',   '08:00', '17:00');
INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBSOF0001', 'Quarta-feira',  '08:00', '17:00');
INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBSOF0001', 'Quinta-feira',  '08:00', '17:00');
INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBSOF0001', 'Sexta-feira',   '08:00', '17:00');
INSERT INTO HORARIO_BIBLIOTECA (cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES ('BIBSOF0001', 'Sabado',        '09:00', '12:00');

-- ============================================================
-- 3. FUNÇÕES / NÍVEIS DE ACESSO
-- ============================================================
INSERT INTO FUNCAO_FUNCIONARIO (nome_funcao, nivel_acesso) VALUES ('Administrador', 'Administrador');
-- id_funcao = 1
INSERT INTO FUNCAO_FUNCIONARIO (nome_funcao, nivel_acesso) VALUES ('Coordenador',   'Coordenador');
-- id_funcao = 2
INSERT INTO FUNCAO_FUNCIONARIO (nome_funcao, nivel_acesso) VALUES ('Bibliotecario',  'Bibliotecario');
-- id_funcao = 3
INSERT INTO FUNCAO_FUNCIONARIO (nome_funcao, nivel_acesso) VALUES ('Assistente',     'Assistente');
-- id_funcao = 4

-- ============================================================
-- 4. FUNCIONÁRIOS  (cod_funcionario: FUC20250001 … FUC20251000)
--    BIBMPC0001: Ana(Admin), Carlos(Coord), Beatriz(Biblio), Domingos(Assist)
--    BIBGZA0001: Esperança(Coord), Fernando(Biblio), Graça(Assist)
--    BIBSOF0001: Helder(Coord), Ilda(Biblio), Jorge(Assist)
-- ============================================================

-- Ana Maria Sitoe — Administrador  (senha: AS2026@Saber)
INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250001', 'Ana Maria Sitoe', 'Feminino', TO_DATE('1985-06-12','YYYY-MM-DD'),
    '+258 84 100 0001', 'Av. Eduardo Mondlane, 22, Maputo',
    'Licenciatura em Biblioteconomia', '10 anos em gestao de bibliotecas publicas',
    TO_DATE('2018-03-15','YYYY-MM-DD'),
    'BIBMPC0001', 1, 'ana.sitoe@sabercom.mz',
    '$2b$10$SjRi/FfNalqbt0CQTc2AOusi2PM8C7tGDRfhanQIeQtihSs/NJa.e');

-- Carlos Nhambiu — Coordenador BCP  (senha: CN2026@Saber)
INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250002', 'Carlos Nhambiu', 'Masculino', TO_DATE('1980-03-25','YYYY-MM-DD'),
    '+258 82 200 0002', 'Rua Consiglieri Pedroso, 5, Maputo',
    'Mestrado em Ciencia da Informacao', '8 anos como coordenador de biblioteca',
    TO_DATE('2018-03-15','YYYY-MM-DD'),
    'BIBMPC0001', 2, 'carlos.nhambiu@sabercom.mz',
    '$2b$10$TwqX/ik40poKWy1sxqSjcO3DJaeLJSmprsKlB3wDgcMCfW8zVXKGW');

-- Beatriz Cossa — Bibliotecária BCP  (senha: BC2026@Saber)
INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250003', 'Beatriz Cossa', 'Feminino', TO_DATE('1992-09-08','YYYY-MM-DD'),
    '+258 86 300 0003', 'Av. Mao Tse Tung, 101, Maputo',
    'Licenciatura em Letras', '3 anos como bibliotecaria escolar',
    TO_DATE('2019-01-07','YYYY-MM-DD'),
    'BIBMPC0001', 3, 'beatriz.cossa@sabercom.mz',
    '$2b$10$KHjHsH8VakqR6I5hdTjWveDwRSv5GdSDAdIpvSKyiWi2lSXtEmL9K');

-- Domingos Machava — Assistente BCP  (senha: DM2026@Saber)
INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250004', 'Domingos Machava', 'Masculino', TO_DATE('1998-11-30','YYYY-MM-DD'),
    '+258 84 400 0004', 'Bairro da Maxaquene, Maputo',
    'Tecnico Medio em Administracao', '1 ano em atendimento ao publico',
    TO_DATE('2021-02-01','YYYY-MM-DD'),
    'BIBMPC0001', 4, 'domingos.machava@sabercom.mz',
    '$2b$10$uqMaQZ3KVa8CjodDPckDwORfq.Hrekl/Lm8XYTVlqs.JPbsG48XrW');

-- Esperança Bila — Coordenadora BCX  (senha: EB2026@Saber)
INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250005', 'Esperanca Bila', 'Feminino', TO_DATE('1983-04-17','YYYY-MM-DD'),
    '+258 82 500 0005', 'Rua 1 de Maio, 33, Xai-Xai',
    'Licenciatura em Educacao', '7 anos em coordenacao de programas de leitura',
    TO_DATE('2019-07-04','YYYY-MM-DD'),
    'BIBGZA0001', 2, 'esperanca.bila@sabercom.mz',
    '$2b$10$/ix0jiN1UHr3hwVjZP8Zv.2H6Mcy2np.zvmNjUXucpolbTmmQyJJ.');

-- Fernando Mondlane — Bibliotecário BCX  (senha: FM2026@Saber)
INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250006', 'Fernando Mondlane', 'Masculino', TO_DATE('1990-07-22','YYYY-MM-DD'),
    '+258 86 600 0006', 'Bairro Central, Xai-Xai',
    'Licenciatura em Biblioteconomia', '4 anos em bibliotecas municipais',
    TO_DATE('2019-09-01','YYYY-MM-DD'),
    'BIBGZA0001', 3, 'fernando.mondlane@sabercom.mz',
    '$2b$10$4tcufPk.5BbFxVSt44sUyOwQalIIXJBqo/zo5NvNuBthsJ1ZswNNe');

-- Graça Tembe — Assistente BCX  (senha: GT2026@Saber)
INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250007', 'Graca Tembe', 'Feminino', TO_DATE('1997-02-14','YYYY-MM-DD'),
    '+258 84 700 0007', 'Av. dos Trabalhadores, 12, Xai-Xai',
    'Tecnico Medio em Secretariado', '2 anos em arquivo e documentacao',
    TO_DATE('2020-03-02','YYYY-MM-DD'),
    'BIBGZA0001', 4, 'graca.tembe@sabercom.mz',
    '$2b$10$uCsfi0HiGjvss6g4BAHpV.7zhrJbeOKFAyxKISllvx.xpgYCHHE.q');

-- Helder Zunguze — Coordenador BCB  (senha: HZ2026@Saber)
INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250008', 'Helder Zunguze', 'Masculino', TO_DATE('1979-08-05','YYYY-MM-DD'),
    '+258 82 800 0008', 'Av. das FPLM, 56, Beira',
    'Mestrado em Gestao Cultural', '12 anos em instituicoes culturais e bibliotecas',
    TO_DATE('2020-01-20','YYYY-MM-DD'),
    'BIBSOF0001', 2, 'helder.zunguze@sabercom.mz',
    '$2b$10$CCtyQs3EhI53theKmaR.PeHsxMohBDlP8swLz/koJ416OCkyxUEq.');

-- Ilda Macuacua — Bibliotecária BCB  (senha: IM2026@Saber)
INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250009', 'Ilda Macuacua', 'Feminino', TO_DATE('1994-12-01','YYYY-MM-DD'),
    '+258 86 900 0009', 'Bairro da Munhava, Beira',
    'Licenciatura em Ciencias da Comunicacao', '3 anos em gestao de acervos',
    TO_DATE('2020-04-01','YYYY-MM-DD'),
    'BIBSOF0001', 3, 'ilda.macuacua@sabercom.mz',
    '$2b$10$2RDwmE2XrKUUwNHz1I1h6uX5hHZZyM.E.qyumfAECgMY7ArlWp.km');

-- Jorge Nuvunga — Assistente BCB  (senha: JN2026@Saber)
INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20251000', 'Jorge Nuvunga', 'Masculino', TO_DATE('2000-05-18','YYYY-MM-DD'),
    '+258 84 100 0010', 'Rua Correia de Brito, 8, Beira',
    'Tecnico Medio em Informatica', 'Estagiario',
    TO_DATE('2022-01-10','YYYY-MM-DD'),
    'BIBSOF0001', 4, 'jorge.nuvunga@sabercom.mz',
    '$2b$10$BcG6s8HWGAFW/x0sB6sz.euIp46nNVMqpb7CpmWqRjxH3DCX877yW');

-- ============================================================
-- 5. HABILIDADES DOS FUNCIONÁRIOS
-- ============================================================
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250001', 'Gestao de Acervos');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250001', 'Formacao de Equipas');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250001', 'Catalogacao MARC');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250002', 'Catalogacao MARC');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250002', 'Atendimento ao Publico');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250003', 'Atendimento ao Publico');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250003', 'Animacao de Leitura');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250004', 'Atendimento ao Publico');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250005', 'Coordenacao de Programas');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250005', 'Alfabetizacao de Adultos');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250006', 'Catalogacao MARC');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250006', 'Gestao de Acervos');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250007', 'Arquivo e Documentacao');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250008', 'Gestao Cultural');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250008', 'Coordenacao de Programas');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250009', 'Catalogacao MARC');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20250009', 'Animacao de Leitura');
INSERT INTO FUNCIONARIO_HABILIDADE VALUES ('FUC20251000', 'Informatica Basica');

-- ============================================================
-- 6. HORÁRIOS DOS FUNCIONÁRIOS
-- ============================================================
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250001', 'Segunda-feira', '08:00', '17:00');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250001', 'Quarta-feira',  '08:00', '17:00');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250001', 'Sexta-feira',   '08:00', '17:00');

INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250002', 'Segunda-feira', '08:00', '18:00');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250002', 'Terca-feira',   '08:00', '18:00');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250002', 'Quarta-feira',  '08:00', '18:00');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250002', 'Quinta-feira',  '08:00', '18:00');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250002', 'Sexta-feira',   '08:00', '18:00');

INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250003', 'Segunda-feira', '08:00', '18:00');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250003', 'Terca-feira',   '08:00', '18:00');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250003', 'Quarta-feira',  '08:00', '18:00');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250003', 'Quinta-feira',  '08:00', '18:00');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250003', 'Sexta-feira',   '08:00', '18:00');

INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250005', 'Segunda-feira', '07:30', '17:30');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250005', 'Terca-feira',   '07:30', '17:30');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250005', 'Quarta-feira',  '07:30', '17:30');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250005', 'Quinta-feira',  '07:30', '17:30');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250005', 'Sexta-feira',   '07:30', '17:30');

INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250008', 'Segunda-feira', '08:00', '17:00');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250008', 'Terca-feira',   '08:00', '17:00');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250008', 'Quarta-feira',  '08:00', '17:00');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250008', 'Quinta-feira',  '08:00', '17:00');
INSERT INTO HORARIO_FUNCIONARIO (cod_funcionario, dia_semana, hora_entrada, hora_saida)
VALUES ('FUC20250008', 'Sexta-feira',   '08:00', '17:00');

-- ============================================================
-- 7. RESPONSÁVEIS DAS BIBLIOTECAS (Coordenadores)
-- ============================================================
INSERT INTO BIBLIOTECA_RESPONSAVEL (cod_biblioteca, cod_funcionario, data_inicio, papel)
VALUES ('BIBMPC0001', 'FUC20250002', TO_DATE('2018-03-15','YYYY-MM-DD'), 'Principal');

INSERT INTO BIBLIOTECA_RESPONSAVEL (cod_biblioteca, cod_funcionario, data_inicio, papel)
VALUES ('BIBGZA0001', 'FUC20250005', TO_DATE('2019-07-04','YYYY-MM-DD'), 'Principal');

INSERT INTO BIBLIOTECA_RESPONSAVEL (cod_biblioteca, cod_funcionario, data_inicio, papel)
VALUES ('BIBSOF0001', 'FUC20250008', TO_DATE('2020-01-20','YYYY-MM-DD'), 'Principal');

-- ============================================================
-- 8. CATEGORIAS  (id_categoria explícito — não depende do trigger)
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
-- 9. DOADORES (antes dos materiais doados)
-- ============================================================
INSERT INTO DOADOR (id_doador, nome_doador, tipo_doador, contacto, observacoes)
VALUES (0, 'Anonimo', 'Individual', NULL, 'Doador anonimo do sistema — nunca eliminar');

INSERT INTO DOADOR (nome_doador, tipo_doador, contacto, endereco, observacoes)
VALUES ('Fundacao para o Desenvolvimento Comunitario', 'Institucional',
    '+258 21 490 000', 'Av. Kenneth Kaunda, 1231, Maputo',
    'Parceiro principal desde 2018');
-- id_doador = 1

INSERT INTO DOADOR (nome_doador, tipo_doador, contacto, endereco, observacoes)
VALUES ('Manuel Antonio Guebuza', 'Individual',
    '+258 84 111 2222', 'Bairro Sommerschield, Maputo',
    'Doador recorrente, prefere literatura nacional');
-- id_doador = 2

INSERT INTO DOADOR (nome_doador, tipo_doador, contacto, endereco, observacoes)
VALUES ('Editora Mocambicana SARL', 'Institucional',
    '+258 21 300 500', 'Av. Guerra Popular, 40, Maputo',
    'Doacao anual de titulos proprios');
-- id_doador = 3

-- ============================================================
-- 10. DOAÇÕES E ITENS (antes dos materiais doados)
-- ============================================================

-- Doação 1 — Fundação (Institucional) → 2 itens, total > 1000 MT mas sem certificado automático
INSERT INTO DOACAO (id_doador, data_doacao)
VALUES (1, TO_DATE('2024-02-10','YYYY-MM-DD'));
-- id_doacao = 1

INSERT INTO ITEM_DOACAO (id_doacao, cod_biblioteca, quantidade, valor_estimado, observacoes)
VALUES (1, 'BIBMPC0001', 50, 35.00, 'Lote de livros infantis novos');
-- id_itemDoado = 1

INSERT INTO ITEM_DOACAO (id_doacao, cod_biblioteca, quantidade, valor_estimado, observacoes)
VALUES (1, 'BIBGZA0001', 30, 40.00, 'Livros de ciencias para jovens');
-- id_itemDoado = 2

-- Doação 2 — Manuel Guebuza (Individual, >= 1000 MT → trigger gera certificado automático)
INSERT INTO DOACAO (id_doador, data_doacao)
VALUES (2, TO_DATE('2024-05-20','YYYY-MM-DD'));
-- id_doacao = 2

INSERT INTO ITEM_DOACAO (id_doacao, cod_biblioteca, quantidade, valor_estimado, observacoes)
VALUES (2, 'BIBMPC0001', 20, 60.00, 'Romances de autores mocambicanos');
-- id_itemDoado = 3  →  total 1200 MT, tipo Individual → certificado gerado pelo trigger

-- Doação 3 — Editora Moçambicana (Institucional — sem certificado automático)
INSERT INTO DOACAO (id_doador, data_doacao)
VALUES (3, TO_DATE('2024-09-01','YYYY-MM-DD'));
-- id_doacao = 3

INSERT INTO ITEM_DOACAO (id_doacao, cod_biblioteca, quantidade, valor_estimado, observacoes)
VALUES (3, 'BIBSOF0001', 40, 45.00, 'Titulos publicados pela editora em 2024');
-- id_itemDoado = 4

-- Doação 4 — Anónimo (< 1000 MT — sem certificado)
INSERT INTO DOACAO (id_doador, data_doacao)
VALUES (0, TO_DATE('2025-01-15','YYYY-MM-DD'));
-- id_doacao = 4

INSERT INTO ITEM_DOACAO (id_doacao, cod_biblioteca, quantidade, valor_estimado, observacoes)
VALUES (4, 'BIBGZA0001', 10, 25.00, 'Revistas diversas');
-- id_itemDoado = 5  →  total 250 MT → sem certificado

-- ============================================================
-- 11. MATERIAIS BIBLIOGRÁFICOS  (formato: MAT20XXYYYY)
-- ============================================================

-- ---- LIVROS FÍSICOS — BIBMPC0001 ----
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20190001', 'Vozes Anoitecidas', 'Mia Couto', 'Caminho', 1986,
    '978-972-21-0279-8', 'Portugues', 134, 'Bom', 'Comprado',
    TO_DATE('2019-03-01','YYYY-MM-DD'), 450.00, 'A1-01', 1, 'BIBMPC0001', NULL);

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20190002', 'Neighbours', 'Lilia Momple',
    'Associacao dos Escritores Mocambicanos', 1995,
    '978-972-8279-01-5', 'Portugues', 120, 'Bom', 'Comprado',
    TO_DATE('2019-03-01','YYYY-MM-DD'), 380.00, 'A1-02', 1, 'BIBMPC0001', NULL);

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20200001', 'Matematica 10a Classe', 'INDE', 'INDE Mocambique', 2015,
    NULL, 'Portugues', 240, 'Degradado', 'Comprado',
    TO_DATE('2020-01-10','YYYY-MM-DD'), 320.00, 'B2-05', 4, 'BIBMPC0001', NULL);

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20240001', 'O Leao e o Coelho Astuto', 'Autor Coletivo', 'Editora Escolar', 2018,
    NULL, 'Portugues', 48, 'Bom', 'Doado',
    TO_DATE('2024-02-10','YYYY-MM-DD'), 'C3-01', 5, 'BIBMPC0001', 1);

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20240002', 'Saude para Todos', 'Ministerio da Saude', 'MISAU', 2020,
    NULL, 'Portugues', 96, 'Bom', 'Doado',
    TO_DATE('2024-02-10','YYYY-MM-DD'), 'D4-02', 6, 'BIBMPC0001', 1);

-- Dois exemplares do mesmo ISBN — permite testar transferência sem bloquear último exemplar
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20190003', 'Terra Sonambula', 'Mia Couto', 'Caminho', 1992,
    '978-972-21-0814-1', 'Portugues', 215, 'Bom', 'Comprado',
    TO_DATE('2019-06-01','YYYY-MM-DD'), 520.00, 'A1-03', 1, 'BIBMPC0001', NULL);

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20190004', 'Terra Sonambula', 'Mia Couto', 'Caminho', 1992,
    '978-972-21-0814-1', 'Portugues', 215, 'Bom', 'Comprado',
    TO_DATE('2019-06-01','YYYY-MM-DD'), 520.00, 'A1-04', 1, 'BIBMPC0001', NULL);

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20240003', 'O Olho de Hertzog', 'Paulina Chiziane', 'Ndjira', 2020,
    '978-989-802-345-2', 'Portugues', 188, 'Bom', 'Doado',
    TO_DATE('2024-05-20','YYYY-MM-DD'), 'A2-01', 1, 'BIBMPC0001', 3);

-- ---- LIVROS FÍSICOS — BIBGZA0001 ----
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20240004', 'Ciencias Naturais 7a Classe', 'INDE', 'INDE Mocambique', 2016,
    NULL, 'Portugues', 180, 'Bom', 'Doado',
    TO_DATE('2024-02-10','YYYY-MM-DD'), 'B1-01', 3, 'BIBGZA0001', 2);

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20200002', 'Agricultura Familiar em Mocambique', 'FAO', 'FAO', 2019,
    NULL, 'Portugues', 120, 'Bom', 'Comprado',
    TO_DATE('2020-05-12','YYYY-MM-DD'), 280.00, 'C2-01', 8, 'BIBGZA0001', NULL);

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20210001', 'A Balada de Amor ao Vento', 'Paulina Chiziane', 'Ndjira', 1990,
    '978-972-8148-10-0', 'Portugues', 168, 'Bom', 'Comprado',
    TO_DATE('2021-03-15','YYYY-MM-DD'), 400.00, 'A1-01', 1, 'BIBGZA0001', NULL);

-- ---- LIVROS FÍSICOS — BIBSOF0001 ----
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20240005', 'Introducao a Informatica', 'Varios Autores', 'Escolar Editora', 2021,
    NULL, 'Portugues', 210, 'Bom', 'Doado',
    TO_DATE('2024-09-01','YYYY-MM-DD'), 'D1-01', 7, 'BIBSOF0001', 4);

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20240006', 'Historia de Mocambique Vol.1', 'Malyn Newitt',
    'Publicacoes Europa-America', 1997,
    '978-972-1-04148-9', 'Portugues', 352, 'Degradado', 'Doado',
    TO_DATE('2024-09-01','YYYY-MM-DD'), 'B1-01', 2, 'BIBSOF0001', 4);

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20210002', 'Contos do Nasreddin', 'Tradicao Oral', 'Ndjira', 2010,
    NULL, 'Portugues', 96, 'Bom', 'Comprado',
    TO_DATE('2021-07-20','YYYY-MM-DD'), 200.00, 'C3-01', 5, 'BIBSOF0001', NULL);

-- Registar subtipos LIVRO_FISICO
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

-- ---- EBOOKS ----
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, valor_aquisicao, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20230001', 'Guia de Saude Materno-Infantil', 'Ministerio da Saude', 'MISAU', 2022,
    NULL, 'Portugues', 80, 'Bom', 'Comprado',
    TO_DATE('2023-01-05','YYYY-MM-DD'), 0.00, 6, 'BIBMPC0001', NULL);

INSERT INTO EBOOK (cod_material, formato, tamanho_arquivo, url_acesso)
VALUES ('MAT20230001', 'PDF', 4.20, 'https://biblioteca.sabercom.mz/ebooks/saude-materno.pdf');

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, valor_aquisicao, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20230002', 'Programacao em Python para Iniciantes', 'Joao Ferreira', 'FCA', 2021,
    '978-972-722-810-5', 'Portugues', 320, 'Bom', 'Comprado',
    TO_DATE('2023-06-01','YYYY-MM-DD'), 150.00, 7, 'BIBMPC0001', NULL);

INSERT INTO EBOOK (cod_material, formato, tamanho_arquivo, url_acesso)
VALUES ('MAT20230002', 'EPUB', 2.80, 'https://biblioteca.sabercom.mz/ebooks/python-iniciantes.epub');

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, valor_aquisicao, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20220001', 'Atlas de Mocambique Digital',
    'Instituto Nacional de Estatistica', 'INE', 2020,
    NULL, 'Portugues', 150, 'Bom', 'Comprado',
    TO_DATE('2022-11-10','YYYY-MM-DD'), 0.00, 2, 'BIBSOF0001', NULL);

INSERT INTO EBOOK (cod_material, formato, tamanho_arquivo, url_acesso)
VALUES ('MAT20220001', 'PDF', 18.50, 'https://biblioteca.sabercom.mz/ebooks/atlas-moz.pdf');

-- ---- PERIÓDICOS ----
INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20240007', 'Revista de Ciencias da Saude de Mocambique',
    'Universidade Eduardo Mondlane', 'UEM', 2024,
    NULL, 'Portugues', 64, 'Bom', 'Comprado',
    TO_DATE('2024-07-01','YYYY-MM-DD'), 120.00, 'P1-01', 6, 'BIBGZA0001', NULL);

INSERT INTO PERIODICO (cod_material, edicao, periodicidade, data_publicacao, ISSN)
VALUES ('MAT20240007', 'Vol. 12, No 2', 'Trimestral', TO_DATE('2024-06-30','YYYY-MM-DD'), '2220-2234');

INSERT INTO MATERIAL_BIBLIOGRAFICO (cod_material, titulo, autor, editora, ano_publicacao,
    ISBN, idioma, num_paginas, estado_material_conservacao, origem_material,
    data_aquisicao, valor_aquisicao, localizacao_estante, cod_categoria, cod_biblioteca, id_itemDoado)
VALUES ('MAT20250001', 'Boletim de Agricultura Sustentavel',
    'Ministerio da Agricultura', 'MINAG', 2025,
    NULL, 'Portugues', 32, 'Bom', 'Comprado',
    TO_DATE('2025-01-10','YYYY-MM-DD'), 80.00, 'P1-02', 8, 'BIBGZA0001', NULL);

INSERT INTO PERIODICO (cod_material, edicao, periodicidade, data_publicacao, ISSN)
VALUES ('MAT20250001', 'Ano 3, No 1', 'Mensal', TO_DATE('2025-01-01','YYYY-MM-DD'), NULL);

-- ============================================================
-- 12. LEITORES  (num_cartao: XXX20250000 — iniciais da biblioteca)
--   BIBMPC0001 → BCP    BIBGZA0001 → BCX    BIBSOF0001 → BCB
-- ============================================================

-- ---- BIBMPC0001 ----
INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, contacto, distancia_biblioteca, cod_biblioteca)
VALUES ('BCP20250001', 'Amelia Dos Santos Nguenha', TO_DATE('1990-04-10','YYYY-MM-DD'),
    'Feminino', 'Universitario', 'Av. 24 de Julho, 55, Maputo',
    '+258 84 201 0001', 1.2, 'BIBMPC0001');
INSERT INTO ADULTO (num_cartao, profissao, nivel_literacia)
VALUES ('BCP20250001', 'Professora Secundaria', 'Avancado');
INSERT INTO ADULTO_INTERESSE VALUES ('BCP20250001', 'Literatura Africana');
INSERT INTO ADULTO_INTERESSE VALUES ('BCP20250001', 'Pedagogia');

INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, contacto, distancia_biblioteca, cod_biblioteca)
VALUES ('BCP20250002', 'Sergio Antonio Cumbe', TO_DATE('1985-11-22','YYYY-MM-DD'),
    'Masculino', 'Ensino Medio', 'Bairro da Coop, Maputo',
    '+258 82 202 0002', 2.5, 'BIBMPC0001');
INSERT INTO ADULTO (num_cartao, profissao, nivel_literacia)
VALUES ('BCP20250002', 'Tecnico de Saude', 'Funcional');
INSERT INTO ADULTO_INTERESSE VALUES ('BCP20250002', 'Saude Comunitaria');
INSERT INTO ADULTO_INTERESSE VALUES ('BCP20250002', 'Agricultura');

INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, contacto, distancia_biblioteca, historico_pontualidade, cod_biblioteca)
VALUES ('BCP20250003', 'Rosa Maria Chibante', TO_DATE('1978-07-03','YYYY-MM-DD'),
    'Feminino', 'Primario', 'Bairro Xipamanine, Maputo',
    '+258 86 203 0003', 3.8, 'Irregular', 'BIBMPC0001');
INSERT INTO ADULTO (num_cartao, profissao, nivel_literacia)
VALUES ('BCP20250003', 'Comerciante', 'Basico');

-- Professor
INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, contacto, distancia_biblioteca, cod_biblioteca)
VALUES ('BCP20250004', 'Antonio Pedro Mucavele', TO_DATE('1975-01-15','YYYY-MM-DD'),
    'Masculino', 'Universitario', 'Av. Ho Chi Min, 12, Maputo',
    '+258 84 204 0004', 0.8, 'BIBMPC0001');
INSERT INTO ADULTO (num_cartao, profissao, nivel_literacia)
VALUES ('BCP20250004', 'Professor Universitario', 'Avancado');
INSERT INTO PROFESSOR (num_cartao, escola_instituto, nivel_ensino, num_alunos)
VALUES ('BCP20250004', 'Universidade Eduardo Mondlane', 'Universitario', 120);
INSERT INTO PROFESSOR_DISCIPLINA VALUES ('BCP20250004', 'Historia de Africa');
INSERT INTO PROFESSOR_DISCIPLINA VALUES ('BCP20250004', 'Estudos Mocambicanos');

-- Criança
INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, distancia_biblioteca, cod_biblioteca)
VALUES ('BCP20250005', 'Tomas Cumbe Nguenha', TO_DATE('2014-09-05','YYYY-MM-DD'),
    'Masculino', 'Primario', 'Av. 24 de Julho, 55, Maputo', 1.2, 'BIBMPC0001');
INSERT INTO CRIANCA (num_cartao, nome_responsavel, telefone_responsavel, escola_frequenta, classe)
VALUES ('BCP20250005', 'Amelia Dos Santos Nguenha', '+258 84 201 0001',
    'EP1 Julius Nyerere', '4a Classe');

-- ---- BIBGZA0001 ----
INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, contacto, distancia_biblioteca, cod_biblioteca)
VALUES ('BCX20250001', 'Luisa Ernestina Chambal', TO_DATE('1993-06-28','YYYY-MM-DD'),
    'Feminino', 'Universitario', 'Bairro 1o de Maio, Xai-Xai',
    '+258 82 301 0001', 1.0, 'BIBGZA0001');
INSERT INTO ADULTO (num_cartao, profissao, nivel_literacia)
VALUES ('BCX20250001', 'Enfermeira', 'Avancado');
INSERT INTO ADULTO_INTERESSE VALUES ('BCX20250001', 'Saude Publica');
INSERT INTO ADULTO_INTERESSE VALUES ('BCX20250001', 'Literatura Mocambicana');

INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, contacto, distancia_biblioteca, cod_biblioteca)
VALUES ('BCX20250002', 'Carlos Joao Macie', TO_DATE('1988-03-12','YYYY-MM-DD'),
    'Masculino', 'Ensino Medio', 'Bairro Central, Xai-Xai',
    '+258 86 302 0002', 0.5, 'BIBGZA0001');
INSERT INTO ADULTO (num_cartao, profissao, nivel_literacia)
VALUES ('BCX20250002', 'Agricultor', 'Funcional');
INSERT INTO ADULTO_INTERESSE VALUES ('BCX20250002', 'Agricultura');

INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, distancia_biblioteca, cod_biblioteca)
VALUES ('BCX20250003', 'Esperanca Macie', TO_DATE('2015-12-01','YYYY-MM-DD'),
    'Feminino', 'Primario', 'Bairro Central, Xai-Xai', 0.5, 'BIBGZA0001');
INSERT INTO CRIANCA (num_cartao, nome_responsavel, telefone_responsavel, escola_frequenta, classe)
VALUES ('BCX20250003', 'Carlos Joao Macie', '+258 86 302 0002', 'EP2 de Xai-Xai', '3a Classe');

-- ---- BIBSOF0001 ----
INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, contacto, distancia_biblioteca, cod_biblioteca)
VALUES ('BCB20250001', 'Beatriz Francisca Langa', TO_DATE('1982-08-19','YYYY-MM-DD'),
    'Feminino', 'Universitario', 'Av. Samora Machel, 100, Beira',
    '+258 84 401 0001', 1.5, 'BIBSOF0001');
INSERT INTO ADULTO (num_cartao, profissao, nivel_literacia)
VALUES ('BCB20250001', 'Contabilista', 'Avancado');
INSERT INTO ADULTO_INTERESSE VALUES ('BCB20250001', 'Tecnologia e Informatica');
INSERT INTO ADULTO_INTERESSE VALUES ('BCB20250001', 'Gestao Empresarial');

INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, contacto, distancia_biblioteca, cod_biblioteca)
VALUES ('BCB20250002', 'Dario Simao Fumo', TO_DATE('1999-02-07','YYYY-MM-DD'),
    'Masculino', 'Ensino Medio', 'Bairro da Munhava, Beira',
    '+258 82 402 0002', 2.2, 'BIBSOF0001');
INSERT INTO ADULTO (num_cartao, profissao, nivel_literacia)
VALUES ('BCB20250002', 'Estudante', 'Funcional');

-- ============================================================
-- 13. EMPRÉSTIMOS
-- ============================================================

-- 1 — Devolvido a tempo (BCP, Amélia, Vozes Anoitecidas)
INSERT INTO EMPRESTIMO (num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, data_devolucao,
    estado_material_saida, estado_material_retorno)
VALUES ('BCP20250001', 'FUC20250003', 'MAT20190001',
    TO_DATE('2025-01-10','YYYY-MM-DD'), TO_DATE('2025-01-24','YYYY-MM-DD'),
    TO_DATE('2025-01-22','YYYY-MM-DD'), 'Bom', 'Bom');

-- 2 — Devolvido 3 dias depois do prazo → trigger gera SUSPENSAO automaticamente
INSERT INTO EMPRESTIMO (num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, data_devolucao,
    estado_material_saida, estado_material_retorno)
VALUES ('BCP20250003', 'FUC20250002', 'MAT20190002',
    TO_DATE('2025-02-01','YYYY-MM-DD'), TO_DATE('2025-02-15','YYYY-MM-DD'),
    TO_DATE('2025-02-18','YYYY-MM-DD'), 'Bom', 'Bom');
-- Rosa fica com status_leitor = 'Suspenso'

-- 3 — Devolvido a tempo (BCP, Sérgio, Terra Sonâmbula ex.1)
-- ex.1 devolvido para que ex.2 possa ser transferido sem violar regra último exemplar
INSERT INTO EMPRESTIMO (num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, data_devolucao,
    estado_material_saida, estado_material_retorno)
VALUES ('BCP20250002', 'FUC20250003', 'MAT20190003',
    TO_DATE('2025-04-01','YYYY-MM-DD'), TO_DATE('2025-04-15','YYYY-MM-DD'),
    TO_DATE('2025-04-12','YYYY-MM-DD'), 'Bom', 'Bom');

-- 4 — Activo (BCX, Luísa, A Balada de Amor ao Vento)
INSERT INTO EMPRESTIMO (num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, estado_material_saida)
VALUES ('BCX20250001', 'FUC20250006', 'MAT20210001',
    TO_DATE('2025-03-01','YYYY-MM-DD'), TO_DATE('2025-03-15','YYYY-MM-DD'), 'Bom');

-- 5 — Professor, activo (BCP, António Mucavele, O Olho de Hertzog)
INSERT INTO EMPRESTIMO (num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, estado_material_saida)
VALUES ('BCP20250004', 'FUC20250002', 'MAT20240003',
    TO_DATE('2025-04-20','YYYY-MM-DD'), TO_DATE('2025-05-04','YYYY-MM-DD'), 'Bom');

-- 6 — Devolvido a tempo (BCB, Beatriz, Introdução à Informática)
INSERT INTO EMPRESTIMO (num_cartao, cod_funcionario, cod_material,
    data_retirada, prazo_devolucao, data_devolucao,
    estado_material_saida, estado_material_retorno)
VALUES ('BCB20250001', 'FUC20250009', 'MAT20240005',
    TO_DATE('2025-03-10','YYYY-MM-DD'), TO_DATE('2025-03-24','YYYY-MM-DD'),
    TO_DATE('2025-03-20','YYYY-MM-DD'), 'Bom', 'Bom');

-- ============================================================
-- 14. TRANSFERÊNCIA
-- MAT20190003 está em empréstimo activo — usa MAT20190004 (2º exemplar Terra Sonâmbula)
-- ============================================================
INSERT INTO TRANSFERENCIA (data_solicitacao, estado_transferencia,
    cod_material, cod_biblioteca_origem, cod_biblioteca_destino,
    cod_funcionario_solicitante, motivo)
VALUES (TO_DATE('2025-04-25','YYYY-MM-DD'), 'Pendente',
    'MAT20190004', 'BIBMPC0001', 'BIBGZA0001',
    'FUC20250002', 'Solicitacao de BCX — alta procura de Mia Couto na regiao de Gaza');

-- ============================================================
-- 15. EVENTOS
-- ============================================================

-- Evento 1 — Realizado (BIBMPC0001)
INSERT INTO EVENTO (cod_biblioteca, cod_funcionario_responsavel,
    titulo_evento, descricao_evento, local_evento,
    publico_alvo, data_evento, capacidade, status_evento, recorrente)
VALUES ('BIBMPC0001', 'FUC20250003',
    'Clube de Leitura — Mia Couto',
    'Sessao de leitura e debate sobre Vozes Anoitecidas',
    'Sala de Leitura, Biblioteca Polana',
    'Todos', TO_DATE('2025-03-15','YYYY-MM-DD'), 30, 'Realizado', 'N');
-- id_evento = 1

INSERT INTO HORARIO_EVENTO (id_evento, dia_semana, data_ocorrencia, hora_inicio, hora_fim)
VALUES (1, 'Sabado', TO_DATE('2025-03-15','YYYY-MM-DD'), '10:00', '12:00');

INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (1, 'Copias de Vozes Anoitecidas', 25);
INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (1, 'Cadeiras', 30);

INSERT INTO PARTICIPACAO_EVENTO (num_cartao, id_evento, data_inscricao, presenca_confirmacao)
VALUES ('BCP20250001', 1, TO_DATE('2025-03-10','YYYY-MM-DD'), 'S');
INSERT INTO PARTICIPACAO_EVENTO (num_cartao, id_evento, data_inscricao, presenca_confirmacao)
VALUES ('BCP20250004', 1, TO_DATE('2025-03-11','YYYY-MM-DD'), 'S');
INSERT INTO PARTICIPACAO_EVENTO (num_cartao, id_evento, data_inscricao, presenca_confirmacao)
VALUES ('BCP20250002', 1, TO_DATE('2025-03-12','YYYY-MM-DD'), 'N');

INSERT INTO AVALIACAO_EVENTO (id_evento, num_cartao, nota, comentario, data_avaliacao)
VALUES (1, 'BCP20250001', 5, 'Excelente sessao, muito enriquecedora!',
    TO_DATE('2025-03-15','YYYY-MM-DD'));
INSERT INTO AVALIACAO_EVENTO (id_evento, num_cartao, nota, comentario, data_avaliacao)
VALUES (1, 'BCP20250004', 4, 'Boa discussao, poderia ter mais tempo de debate.',
    TO_DATE('2025-03-15','YYYY-MM-DD'));

-- Evento 2 — Planeado (BIBGZA0001)
INSERT INTO EVENTO (cod_biblioteca, cod_funcionario_responsavel,
    titulo_evento, descricao_evento, local_evento,
    publico_alvo, data_evento, capacidade, status_evento, recorrente)
VALUES ('BIBGZA0001', 'FUC20250005',
    'Dia da Crianca na Biblioteca',
    'Actividades de leitura e jogos educativos para criancas',
    'Jardim Exterior, Biblioteca Xai-Xai',
    'Iniciantes', TO_DATE('2025-06-01','YYYY-MM-DD'), 50, 'Planeado', 'N');
-- id_evento = 2

INSERT INTO HORARIO_EVENTO (id_evento, dia_semana, data_ocorrencia, hora_inicio, hora_fim)
VALUES (2, 'Domingo', TO_DATE('2025-06-01','YYYY-MM-DD'), '09:00', '13:00');

INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (2, 'Livros Infantis', 40);
INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (2, 'Mesas', 10);
INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (2, 'Cadeiras', 50);

INSERT INTO PARTICIPACAO_EVENTO (num_cartao, id_evento, data_inscricao)
VALUES ('BCX20250003', 2, TO_DATE('2025-05-20','YYYY-MM-DD'));
INSERT INTO PARTICIPACAO_EVENTO (num_cartao, id_evento, data_inscricao)
VALUES ('BCX20250001', 2, TO_DATE('2025-05-21','YYYY-MM-DD'));

-- Evento 3 — Planeado, recorrente (BIBSOF0001)
INSERT INTO EVENTO (cod_biblioteca, cod_funcionario_responsavel,
    titulo_evento, descricao_evento, local_evento,
    publico_alvo, data_evento, capacidade, status_evento, recorrente)
VALUES ('BIBSOF0001', 'FUC20250008',
    'Workshop Informatica Basica',
    'Aulas praticas de informatica para adultos sem experiencia previa',
    'Laboratorio de Informatica, Biblioteca da Beira',
    'Intermedios', TO_DATE('2025-05-20','YYYY-MM-DD'), 20, 'Planeado', 'S');
-- id_evento = 3

INSERT INTO HORARIO_EVENTO (id_evento, dia_semana, data_ocorrencia, hora_inicio, hora_fim)
VALUES (3, 'Terca-feira', TO_DATE('2025-05-20','YYYY-MM-DD'), '14:00', '17:00');

-- ============================================================
-- 16. PROGRAMAS DE ALFABETIZAÇÃO  (formato: PROBIBXXX20XXYYYY)
-- ============================================================

INSERT INTO PROGRAMA_ALFABETIZACAO (cod_programa, cod_biblioteca, nome_programa,
    descricao, publico_alvo, duracao_semanas, metodologia,
    resultados_esperados, estado_programa)
VALUES ('PROBIBGZA20250001', 'BIBGZA0001',
    'Ler para Crescer — Gaza',
    'Programa de alfabetizacao funcional para adultos de Gaza',
    'Iniciantes', 24, 'Metodo Paulo Freire adaptado ao contexto local',
    'Alfabetizacao de 80% dos participantes em 6 meses', 'Activo');

INSERT INTO NIVEL_PROGRESSAO (cod_programa, nome_nivel, descricao, ordem)
VALUES ('PROBIBGZA20250001', 'Nivel 1 — Letras e Sons',
    'Reconhecimento do alfabeto e sons basicos', 1);
-- id_nivel = 1

INSERT INTO NIVEL_PROGRESSAO (cod_programa, nome_nivel, descricao, ordem)
VALUES ('PROBIBGZA20250001', 'Nivel 2 — Silabas e Palavras',
    'Formacao de silabas e vocabulario basico', 2);
-- id_nivel = 2

INSERT INTO NIVEL_PROGRESSAO (cod_programa, nome_nivel, descricao, ordem)
VALUES ('PROBIBGZA20250001', 'Nivel 3 — Frases e Textos',
    'Leitura de frases curtas e textos simples', 3);
-- id_nivel = 3

INSERT INTO PROGRAMA_FUNCIONARIO (cod_programa, cod_funcionario, papel)
VALUES ('PROBIBGZA20250001', 'FUC20250005', 'Responsavel');
INSERT INTO PROGRAMA_FUNCIONARIO (cod_programa, cod_funcionario, papel)
VALUES ('PROBIBGZA20250001', 'FUC20250006', 'Instrutor');

INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material, observacoes)
VALUES ('PROBIBGZA20250001', 'MAT20240004', 'Material de apoio principal');
INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material, observacoes)
VALUES ('PROBIBGZA20250001', 'MAT20250001', 'Textos praticos para exercicios de leitura');

INSERT INTO PARTICIPACAO_PROGRAMA (num_cartao, cod_programa, id_nivel_atual,
    data_inscricao, estado_participacao)
VALUES ('BCX20250002', 'PROBIBGZA20250001', 2,
    TO_DATE('2025-02-01','YYYY-MM-DD'), 'Activo');
INSERT INTO PARTICIPACAO_PROGRAMA (num_cartao, cod_programa, id_nivel_atual,
    data_inscricao, estado_participacao)
VALUES ('BCX20250001', 'PROBIBGZA20250001', 3,
    TO_DATE('2025-02-01','YYYY-MM-DD'), 'Activo');

-- Programa BCB
INSERT INTO PROGRAMA_ALFABETIZACAO (cod_programa, cod_biblioteca, nome_programa,
    descricao, publico_alvo, duracao_semanas, metodologia,
    resultados_esperados, estado_programa)
VALUES ('PROBIBSOF20250001', 'BIBSOF0001',
    'Beira Digital — Informatica Basica',
    'Formacao em informatica para adultos sem experiencia previa',
    'Iniciantes', 12, 'Aulas praticas semanais em laboratorio',
    'Participantes capazes de usar computador, internet e processador de texto', 'Activo');

INSERT INTO NIVEL_PROGRESSAO (cod_programa, nome_nivel, descricao, ordem)
VALUES ('PROBIBSOF20250001', 'Modulo 1 — Hardware e SO',
    'Uso basico do computador e sistema operativo', 1);
-- id_nivel = 4

INSERT INTO NIVEL_PROGRESSAO (cod_programa, nome_nivel, descricao, ordem)
VALUES ('PROBIBSOF20250001', 'Modulo 2 — Internet',
    'Navegacao e seguranca na internet', 2);
-- id_nivel = 5

INSERT INTO PROGRAMA_FUNCIONARIO (cod_programa, cod_funcionario, papel)
VALUES ('PROBIBSOF20250001', 'FUC20250008', 'Responsavel');
INSERT INTO PROGRAMA_FUNCIONARIO (cod_programa, cod_funcionario, papel)
VALUES ('PROBIBSOF20250001', 'FUC20251000', 'Instrutor');

INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material, observacoes)
VALUES ('PROBIBSOF20250001', 'MAT20240005', 'Manual principal do programa');
INSERT INTO PROGRAMA_MATERIAL (cod_programa, cod_material, observacoes)
VALUES ('PROBIBSOF20250001', 'MAT20220001', 'Atlas digital — exercicio de navegacao');

INSERT INTO PARTICIPACAO_PROGRAMA (num_cartao, cod_programa, id_nivel_atual,
    data_inscricao, estado_participacao)
VALUES ('BCB20250001', 'PROBIBSOF20250001', 5,
    TO_DATE('2025-03-01','YYYY-MM-DD'), 'Activo');
INSERT INTO PARTICIPACAO_PROGRAMA (num_cartao, cod_programa, id_nivel_atual,
    data_inscricao, estado_participacao)
VALUES ('BCB20250002', 'PROBIBSOF20250001', 4,
    TO_DATE('2025-03-01','YYYY-MM-DD'), 'Activo');

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================
COMMIT;
