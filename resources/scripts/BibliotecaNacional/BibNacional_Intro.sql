-- ============================================================
-- BibNacional_Intro.sql — Dados de teste do nó BibliotecaNacionalDB
-- Executar DEPOIS de: Create + Sequences + Views + Functions + Procedures + Triggers + Indexes
--
-- Tabelas locais: FUNCAO_FUNCIONARIO, FUNCIONARIO, FUNCIONARIO_HABILIDADE,
--   HORARIO_FUNCIONARIO, LEITOR, ADULTO, ADULTO_INTERESSE, PROFESSOR,
--   PROFESSOR_DISCIPLINA, CRIANCA, DOADOR, DOACAO, ITEM_DOACAO, CERTIFICADO_DOACAO
--
-- Referências cross-node (sem FK DDL — restrição lógica):
--   FUNCIONARIO.cod_biblioteca → BIBLIOTECA@eventosdb
--   DOACAO.cod_biblioteca      → BIBLIOTECA@eventosdb
--   LEITOR.cod_biblioteca      → BIBLIOTECA@eventosdb
--
-- ACENTOS: execute com NLS_LANG=AMERICAN_AMERICA.AL32UTF8
-- Ficheiro guardado em UTF-8 (sem BOM).
--
-- Senhas (bcrypt, cost=10):
--   Ana Sitoe      → AS2026@Saber
--   Carlos Nhambiu → CN2026@Saber
--   Beatriz Cossa  → BC2026@Saber
--   Domingos Mach. → DM2026@Saber
--   Esperança Bila → EB2026@Saber
--   Fernando Mond. → FM2026@Saber
--   Graça Tembe    → GT2026@Saber
--   Helder Zunguze → HZ2026@Saber
--   Ilda Macuacua  → IM2026@Saber
--   Jorge Nuvunga  → JN2026@Saber
-- ============================================================

-- ============================================================
-- 1. FUNÇÕES / NÍVEIS DE ACESSO
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
-- 2. FUNCIONÁRIOS  (cod_funcionario: FUC20250001 … FUC20251000)
--    BIBMPC0001: Ana(Admin), Carlos(Coord), Beatriz(Biblio), Domingos(Assist)
--    BIBGZA0001: Esperança(Coord), Fernando(Biblio), Graça(Assist)
--    BIBSOF0001: Helder(Coord), Ilda(Biblio), Jorge(Assist)
-- ============================================================

INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250001', 'Ana Maria Sitoe', 'Feminino', TO_DATE('1985-06-12','YYYY-MM-DD'),
    '+258 84 100 0001', 'Av. Eduardo Mondlane, 22, Maputo',
    'Licenciatura em Biblioteconomia', '10 anos em gestao de bibliotecas publicas',
    TO_DATE('2018-03-15','YYYY-MM-DD'),
    'BIBMPC0001', 1, 'ana.sitoe@sabercom.mz',
    '$2b$10$SjRi/FfNalqbt0CQTc2AOusi2PM8C7tGDRfhanQIeQtihSs/NJa.e');

INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250002', 'Carlos Nhambiu', 'Masculino', TO_DATE('1980-03-25','YYYY-MM-DD'),
    '+258 82 200 0002', 'Rua Consiglieri Pedroso, 5, Maputo',
    'Mestrado em Ciencia da Informacao', '8 anos como coordenador de biblioteca',
    TO_DATE('2018-03-15','YYYY-MM-DD'),
    'BIBMPC0001', 2, 'carlos.nhambiu@sabercom.mz',
    '$2b$10$TwqX/ik40poKWy1sxqSjcO3DJaeLJSmprsKlB3wDgcMCfW8zVXKGW');

INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250003', 'Beatriz Cossa', 'Feminino', TO_DATE('1992-09-08','YYYY-MM-DD'),
    '+258 86 300 0003', 'Av. Mao Tse Tung, 101, Maputo',
    'Licenciatura em Letras', '3 anos como bibliotecaria escolar',
    TO_DATE('2019-01-07','YYYY-MM-DD'),
    'BIBMPC0001', 3, 'beatriz.cossa@sabercom.mz',
    '$2b$10$KHjHsH8VakqR6I5hdTjWveDwRSv5GdSDAdIpvSKyiWi2lSXtEmL9K');

INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250004', 'Domingos Machava', 'Masculino', TO_DATE('1998-11-30','YYYY-MM-DD'),
    '+258 84 400 0004', 'Bairro da Maxaquene, Maputo',
    'Tecnico Medio em Administracao', '1 ano em atendimento ao publico',
    TO_DATE('2021-02-01','YYYY-MM-DD'),
    'BIBMPC0001', 4, 'domingos.machava@sabercom.mz',
    '$2b$10$uqMaQZ3KVa8CjodDPckDwORfq.Hrekl/Lm8XYTVlqs.JPbsG48XrW');

INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250005', 'Esperanca Bila', 'Feminino', TO_DATE('1983-04-17','YYYY-MM-DD'),
    '+258 82 500 0005', 'Rua 1 de Maio, 33, Xai-Xai',
    'Licenciatura em Educacao', '7 anos em coordenacao de programas de leitura',
    TO_DATE('2019-07-04','YYYY-MM-DD'),
    'BIBGZA0001', 2, 'esperanca.bila@sabercom.mz',
    '$2b$10$/ix0jiN1UHr3hwVjZP8Zv.2H6Mcy2np.zvmNjUXucpolbTmmQyJJ.');

INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250006', 'Fernando Mondlane', 'Masculino', TO_DATE('1990-07-22','YYYY-MM-DD'),
    '+258 86 600 0006', 'Bairro Central, Xai-Xai',
    'Licenciatura em Biblioteconomia', '4 anos em bibliotecas municipais',
    TO_DATE('2019-09-01','YYYY-MM-DD'),
    'BIBGZA0001', 3, 'fernando.mondlane@sabercom.mz',
    '$2b$10$4tcufPk.5BbFxVSt44sUyOwQalIIXJBqo/zo5NvNuBthsJ1ZswNNe');

INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250007', 'Graca Tembe', 'Feminino', TO_DATE('1997-02-14','YYYY-MM-DD'),
    '+258 84 700 0007', 'Av. dos Trabalhadores, 12, Xai-Xai',
    'Tecnico Medio em Secretariado', '2 anos em arquivo e documentacao',
    TO_DATE('2020-03-02','YYYY-MM-DD'),
    'BIBGZA0001', 4, 'graca.tembe@sabercom.mz',
    '$2b$10$uCsfi0HiGjvss6g4BAHpV.7zhrJbeOKFAyxKISllvx.xpgYCHHE.q');

INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250008', 'Helder Zunguze', 'Masculino', TO_DATE('1979-08-05','YYYY-MM-DD'),
    '+258 82 800 0008', 'Av. das FPLM, 56, Beira',
    'Mestrado em Gestao Cultural', '12 anos em instituicoes culturais e bibliotecas',
    TO_DATE('2020-01-20','YYYY-MM-DD'),
    'BIBSOF0001', 2, 'helder.zunguze@sabercom.mz',
    '$2b$10$CCtyQs3EhI53theKmaR.PeHsxMohBDlP8swLz/koJ416OCkyxUEq.');

INSERT INTO FUNCIONARIO (cod_funcionario, nome_funcionario, genero, data_nasc,
    contacto, endereco, formacao, experiencia, data_contratacao,
    cod_biblioteca, id_funcao, email, senha)
VALUES ('FUC20250009', 'Ilda Macuacua', 'Feminino', TO_DATE('1994-12-01','YYYY-MM-DD'),
    '+258 86 900 0009', 'Bairro da Munhava, Beira',
    'Licenciatura em Ciencias da Comunicacao', '3 anos em gestao de acervos',
    TO_DATE('2020-04-01','YYYY-MM-DD'),
    'BIBSOF0001', 3, 'ilda.macuacua@sabercom.mz',
    '$2b$10$2RDwmE2XrKUUwNHz1I1h6uX5hHZZyM.E.qyumfAECgMY7ArlWp.km');

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
-- 3. HABILIDADES DOS FUNCIONÁRIOS
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
-- 4. HORÁRIOS DOS FUNCIONÁRIOS
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
-- 5. LEITORES  (domínio movido do EmpréstimosProgramasDB — v3)
--    num_cartao: [3-letra biblioteca][ano][seq 4 dígitos]
--    MPC = BIBMPC0001 | GZA = BIBGZA0001 | SOF = BIBSOF0001
--    Ordem de inserção: LEITOR → ADULTO → ADULTO_INTERESSE
--                       → PROFESSOR → PROFESSOR_DISCIPLINA → CRIANCA
-- ============================================================

-- 5a. LEITOR (base — todos os tipos)
INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, contacto, foto_path, distancia_biblioteca,
    historico_pontualidade, cod_biblioteca, status_leitor)
VALUES ('MPC20250001', 'Maria Chissano', TO_DATE('1975-03-20','YYYY-MM-DD'),
    'Feminino', 'Secundario', 'Bairro Central, Maputo',
    '+258 84 111 0001', NULL, 1.5, 'Pontual', 'BIBMPC0001', 'Activo');

INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, contacto, foto_path, distancia_biblioteca,
    historico_pontualidade, cod_biblioteca, status_leitor)
VALUES ('MPC20250002', 'Pedro Cumbe', TO_DATE('1978-07-15','YYYY-MM-DD'),
    'Masculino', 'Superior', 'Av. 24 de Julho, Maputo',
    '+258 82 222 0002', NULL, 0.8, 'Pontual', 'BIBMPC0001', 'Activo');
-- Pedro é Professor — inserido em ADULTO + PROFESSOR a seguir

INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, contacto, foto_path, distancia_biblioteca,
    historico_pontualidade, cod_biblioteca, status_leitor)
VALUES ('MPC20250003', 'Joao Nhaca', TO_DATE('2012-01-10','YYYY-MM-DD'),
    'Masculino', 'Primario', 'Bairro Sommerschield, Maputo',
    NULL, NULL, 2.0, 'Pontual', 'BIBMPC0001', 'Activo');
-- Joao é Criança — inserido em CRIANCA a seguir

INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, contacto, foto_path, distancia_biblioteca,
    historico_pontualidade, cod_biblioteca, status_leitor)
VALUES ('GZA20250001', 'Rosa Temane', TO_DATE('1965-11-05','YYYY-MM-DD'),
    'Feminino', 'Primario', 'Rua 1 de Maio, Xai-Xai',
    '+258 86 333 0001', NULL, 3.2, 'Irregular', 'BIBGZA0001', 'Activo');

INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, contacto, foto_path, distancia_biblioteca,
    historico_pontualidade, cod_biblioteca, status_leitor)
VALUES ('GZA20250002', 'Abel Chivambo', TO_DATE('1982-04-22','YYYY-MM-DD'),
    'Masculino', 'Superior', 'Av. Eduardo Mondlane, Xai-Xai',
    '+258 84 444 0002', NULL, 1.1, 'Pontual', 'BIBGZA0001', 'Activo');
-- Abel é Professor

INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, contacto, foto_path, distancia_biblioteca,
    historico_pontualidade, cod_biblioteca, status_leitor)
VALUES ('SOF20250001', 'Angelina Mabunda', TO_DATE('2014-08-30','YYYY-MM-DD'),
    'Feminino', 'Primario', 'Bairro da Munhava, Beira',
    NULL, NULL, 0.5, 'Pontual', 'BIBSOF0001', 'Activo');
-- Angelina é Criança

INSERT INTO LEITOR (num_cartao, nome_completo, data_nasc, genero, nivel_escolar,
    localizacao_leitor, contacto, foto_path, distancia_biblioteca,
    historico_pontualidade, cod_biblioteca, status_leitor)
VALUES ('SOF20250002', 'Antonio Fonseca', TO_DATE('1990-02-17','YYYY-MM-DD'),
    'Masculino', 'Tecnico', 'Rua Correia de Brito, Beira',
    '+258 82 555 0002', NULL, 1.8, 'Pontual', 'BIBSOF0001', 'Activo');

-- 5b. ADULTO (todos os adultos — inclui os professores)
INSERT INTO ADULTO (num_cartao, profissao, nivel_literacia)
VALUES ('MPC20250001', 'Comerciante', 'Funcional');

INSERT INTO ADULTO (num_cartao, profissao, nivel_literacia)
VALUES ('MPC20250002', 'Professor do Ensino Secundario', 'Avancado');

INSERT INTO ADULTO (num_cartao, profissao, nivel_literacia)
VALUES ('GZA20250001', 'Agricultora', 'Basico');

INSERT INTO ADULTO (num_cartao, profissao, nivel_literacia)
VALUES ('GZA20250002', 'Professor do Ensino Primario', 'Avancado');

INSERT INTO ADULTO (num_cartao, profissao, nivel_literacia)
VALUES ('SOF20250002', 'Tecnico de Informatica', 'Avancado');

-- 5c. ADULTO_INTERESSE
INSERT INTO ADULTO_INTERESSE VALUES ('MPC20250001', 'Literatura Mocambicana');
INSERT INTO ADULTO_INTERESSE VALUES ('MPC20250001', 'Historia');
INSERT INTO ADULTO_INTERESSE VALUES ('GZA20250001', 'Agricultura');
INSERT INTO ADULTO_INTERESSE VALUES ('GZA20250001', 'Saude');
INSERT INTO ADULTO_INTERESSE VALUES ('SOF20250002', 'Informatica');
INSERT INTO ADULTO_INTERESSE VALUES ('SOF20250002', 'Ciencias');

-- 5d. PROFESSOR (FK para ADULTO — inserir depois dos adultos)
INSERT INTO PROFESSOR (num_cartao, escola_instituto, nivel_ensino, num_alunos)
VALUES ('MPC20250002', 'Escola Secundaria de Maputo', 'Secundario', 35);

INSERT INTO PROFESSOR (num_cartao, escola_instituto, nivel_ensino, num_alunos)
VALUES ('GZA20250002', 'EP1 de Xai-Xai', 'Primario', 42);

-- 5e. PROFESSOR_DISCIPLINA
INSERT INTO PROFESSOR_DISCIPLINA VALUES ('MPC20250002', 'Portugues');
INSERT INTO PROFESSOR_DISCIPLINA VALUES ('MPC20250002', 'Historia');
INSERT INTO PROFESSOR_DISCIPLINA VALUES ('GZA20250002', 'Matematica');
INSERT INTO PROFESSOR_DISCIPLINA VALUES ('GZA20250002', 'Ciencias Naturais');

-- 5f. CRIANCA (FK para LEITOR)
INSERT INTO CRIANCA (num_cartao, nome_responsavel, telefone_responsavel,
    escola_frequenta, classe)
VALUES ('MPC20250003', 'Felicidade Nhaca', '+258 84 900 0003',
    'EP1 Maputo Centro', '5a');

INSERT INTO CRIANCA (num_cartao, nome_responsavel, telefone_responsavel,
    escola_frequenta, classe)
VALUES ('SOF20250001', 'Cristina Mabunda', '+258 82 800 0001',
    'EP2 da Munhava', '3a');

-- ============================================================
-- 6. DOADORES  (id_doador = 0 reservado para Anónimo — RN10)
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
-- 7. DOAÇÕES E ITENS
-- ============================================================

-- Doação 1 — Fundação (Institucional) → sem certificado automático
INSERT INTO DOACAO (id_doador, cod_biblioteca, data_doacao)
VALUES (1, 'BIBMPC0001', TO_DATE('2024-02-10','YYYY-MM-DD'));
-- id_doacao = 1

INSERT INTO ITEM_DOACAO (id_doacao, nome_item, tipo_item, quantidade, valor_estimado, observacoes)
VALUES (1, 'Lote de livros infantis novos', 'Livro', 50, 35.00, 'Lote de livros infantis novos');
-- id_itemDoado = 1

INSERT INTO ITEM_DOACAO (id_doacao, nome_item, tipo_item, quantidade, valor_estimado, observacoes)
VALUES (1, 'Livros de ciencias para jovens', 'Livro', 30, 40.00, 'Livros de ciencias para jovens');
-- id_itemDoado = 2

-- Doação 2 — Manuel Guebuza (Individual, total 1200 MT → trigger gera certificado automático)
INSERT INTO DOACAO (id_doador, cod_biblioteca, data_doacao)
VALUES (2, 'BIBMPC0001', TO_DATE('2024-05-20','YYYY-MM-DD'));
-- id_doacao = 2

INSERT INTO ITEM_DOACAO (id_doacao, nome_item, tipo_item, quantidade, valor_estimado, observacoes)
VALUES (2, 'Romances de autores mocambicanos', 'Livro', 20, 60.00, 'Romances de autores mocambicanos');
-- id_itemDoado = 3  →  total 1200 MT, tipo Individual → CERT gerado pelo trigger

-- Doação 3 — Editora Moçambicana (Institucional — sem certificado automático)
INSERT INTO DOACAO (id_doador, cod_biblioteca, data_doacao)
VALUES (3, 'BIBSOF0001', TO_DATE('2024-09-01','YYYY-MM-DD'));
-- id_doacao = 3

INSERT INTO ITEM_DOACAO (id_doacao, nome_item, tipo_item, quantidade, valor_estimado, observacoes)
VALUES (3, 'Titulos publicados pela editora em 2024', 'Livro', 40, 45.00, 'Titulos publicados pela editora em 2024');
-- id_itemDoado = 4

-- Doação 4 — Anónimo (total 250 MT — sem certificado)
INSERT INTO DOACAO (id_doador, cod_biblioteca, data_doacao)
VALUES (0, 'BIBGZA0001', TO_DATE('2025-01-15','YYYY-MM-DD'));
-- id_doacao = 4

INSERT INTO ITEM_DOACAO (id_doacao, nome_item, tipo_item, quantidade, valor_estimado, observacoes)
VALUES (4, 'Revistas diversas', 'Outro', 10, 25.00, 'Revistas diversas');
-- id_itemDoado = 5  →  total 250 MT → sem certificado

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================
COMMIT;
