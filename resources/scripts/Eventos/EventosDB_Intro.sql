-- ============================================================
-- DADOS INICIAIS - EventosBibliotecasDB (v5)
-- Executar DEPOIS de: Create + Sequences + Views + Triggers + Indexes
--
-- Linux/CentOS: export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
-- sqlplus usr_eventosdb/"eventos1234"@XE @EventosDB_Intro.sql
--
-- Tabelas populadas: BIBLIOTECA, HORARIO_BIBLIOTECA,
--   BIBLIOTECA_RESPONSAVEL, EVENTO, HORARIO_EVENTO,
--   EVENTO_RECURSO, PARTICIPACAO_EVENTO, AVALIACAO_EVENTO
--
-- Bibliotecas:
--   BIBMPC0001 - Maputo (Sul)
--   BIBGZA0001 - Xai-Xai, Gaza (Sul)
--   BIBSOF0001 - Beira, Sofala (Centro)
--   BIBQLM0001 - Quelimane, Zambezia (Centro)
--   BIBNMP0001 - Nampula (Norte)
--
-- Codigos de leitor (BibNacional_Intro.sql):
--   BIBMPC0001 -> MPC20250001, MPC20250002, MPC20250003
--   BIBGZA0001 -> GZA20250001, GZA20250002
--   BIBSOF0001 -> SOF20250001, SOF20250002
--   BIBQLM0001 -> QLM20250001, QLM20250002
--   BIBNMP0001 -> NMP20250001, NMP20250002
-- ============================================================

-- ============================================================
-- 1. BIBLIOTECAS
-- ============================================================

-- Sul
INSERT INTO BIBLIOTECA (cod_biblioteca, nome_biblioteca, endereco,
    latitude, longitude, contacto_biblioteca, data_inauguracao, capacidade,
    infraestrutura, servicos, provincia)
VALUES ('BIBMPC0001', 'Biblioteca Comunitaria Polana',
    'Av. Julius Nyerere, 1234, Polana, Maputo',
    -25.966, 32.583, '+258 21 321 001',
    TO_DATE('2018-03-15','YYYY-MM-DD'), 120,
    'Sala de leitura, sala infantil, sala de informatica, auditorio',
    'Emprestimo domiciliario, internet gratuita, clube de leitura',
    'Maputo Cidade');

INSERT INTO BIBLIOTECA (cod_biblioteca, nome_biblioteca, endereco,
    latitude, longitude, contacto_biblioteca, data_inauguracao, capacidade,
    infraestrutura, servicos, provincia)
VALUES ('BIBGZA0001', 'Biblioteca Comunitaria Xai-Xai',
    'Rua da Independencia, 45, Xai-Xai',
    -25.052, 33.644, '+258 22 224 002',
    TO_DATE('2019-07-04','YYYY-MM-DD'), 80,
    'Sala de leitura, sala multimedia, jardim exterior',
    'Emprestimo domiciliario, programa de alfabetizacao, eventos culturais',
    'Gaza');

-- Centro
INSERT INTO BIBLIOTECA (cod_biblioteca, nome_biblioteca, endereco,
    latitude, longitude, contacto_biblioteca, data_inauguracao, capacidade,
    infraestrutura, servicos, provincia)
VALUES ('BIBSOF0001', 'Biblioteca Comunitaria da Beira',
    'Av. Samora Machel, 789, Beira',
    -19.838, 34.838, '+258 23 312 003',
    TO_DATE('2020-01-20','YYYY-MM-DD'), 100,
    'Sala de leitura, laboratorio de informatica, sala de reunioes',
    'Emprestimo domiciliario, internet, cursos de informatica basica',
    'Sofala');

INSERT INTO BIBLIOTECA (cod_biblioteca, nome_biblioteca, endereco,
    latitude, longitude, contacto_biblioteca, data_inauguracao, capacidade,
    infraestrutura, servicos, provincia)
VALUES ('BIBQLM0001', 'Biblioteca Comunitaria de Quelimane',
    'Rua da Republica, 78, Quelimane',
    -17.879, 36.888, '+258 24 215 004',
    TO_DATE('2021-04-01','YYYY-MM-DD'), 90,
    'Sala de leitura, sala multiuso, espaco infantil',
    'Emprestimo domiciliario, actividades de leitura, apoio escolar',
    'Zambezia');

-- Norte
INSERT INTO BIBLIOTECA (cod_biblioteca, nome_biblioteca, endereco,
    latitude, longitude, contacto_biblioteca, data_inauguracao, capacidade,
    infraestrutura, servicos, provincia)
VALUES ('BIBNMP0001', 'Biblioteca Comunitaria de Nampula',
    'Av. Francisco Manyanga, 234, Nampula',
    -15.116, 39.264, '+258 26 217 005',
    TO_DATE('2023-02-10','YYYY-MM-DD'), 85,
    'Sala de leitura, sala de informatica, area de estudo',
    'Emprestimo domiciliario, internet, programa de alfabetizacao',
    'Nampula');

-- ============================================================
-- 2. HORARIOS DAS BIBLIOTECAS
--    id_horario_bib: explicito (sem sequencia no DDL)
-- ============================================================

-- BIBMPC0001: Segunda a Sexta 08:00-18:00, Sabado 08:00-13:00
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (1, 'BIBMPC0001', 'Segunda-feira', '08:00', '18:00');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (2, 'BIBMPC0001', 'Terca-feira',   '08:00', '18:00');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (3, 'BIBMPC0001', 'Quarta-feira',  '08:00', '18:00');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (4, 'BIBMPC0001', 'Quinta-feira',  '08:00', '18:00');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (5, 'BIBMPC0001', 'Sexta-feira',   '08:00', '18:00');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (6, 'BIBMPC0001', 'Sabado',        '08:00', '13:00');

-- BIBGZA0001: Segunda a Sexta 07:30-17:30
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (7,  'BIBGZA0001', 'Segunda-feira', '07:30', '17:30');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (8,  'BIBGZA0001', 'Terca-feira',   '07:30', '17:30');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (9,  'BIBGZA0001', 'Quarta-feira',  '07:30', '17:30');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (10, 'BIBGZA0001', 'Quinta-feira',  '07:30', '17:30');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (11, 'BIBGZA0001', 'Sexta-feira',   '07:30', '17:30');

-- BIBSOF0001: Segunda a Sexta 08:00-17:00, Sabado 09:00-12:00
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (12, 'BIBSOF0001', 'Segunda-feira', '08:00', '17:00');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (13, 'BIBSOF0001', 'Terca-feira',   '08:00', '17:00');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (14, 'BIBSOF0001', 'Quarta-feira',  '08:00', '17:00');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (15, 'BIBSOF0001', 'Quinta-feira',  '08:00', '17:00');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (16, 'BIBSOF0001', 'Sexta-feira',   '08:00', '17:00');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (17, 'BIBSOF0001', 'Sabado',        '09:00', '12:00');

-- BIBQLM0001: Segunda a Sexta 08:00-17:30, Sabado 09:00-13:00
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (18, 'BIBQLM0001', 'Segunda-feira', '08:00', '17:30');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (19, 'BIBQLM0001', 'Terca-feira',   '08:00', '17:30');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (20, 'BIBQLM0001', 'Quarta-feira',  '08:00', '17:30');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (21, 'BIBQLM0001', 'Quinta-feira',  '08:00', '17:30');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (22, 'BIBQLM0001', 'Sexta-feira',   '08:00', '17:30');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (23, 'BIBQLM0001', 'Sabado',        '09:00', '13:00');

-- BIBNMP0001: Segunda a Sexta 08:00-17:00
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (24, 'BIBNMP0001', 'Segunda-feira', '08:00', '17:00');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (25, 'BIBNMP0001', 'Terca-feira',   '08:00', '17:00');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (26, 'BIBNMP0001', 'Quarta-feira',  '08:00', '17:00');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (27, 'BIBNMP0001', 'Quinta-feira',  '08:00', '17:00');
INSERT INTO HORARIO_BIBLIOTECA (id_horario_bib, cod_biblioteca, dia_semana, hora_abertura, hora_fecho)
VALUES (28, 'BIBNMP0001', 'Sexta-feira',   '08:00', '17:00');

-- ============================================================
-- 3. RESPONSAVEIS DAS BIBLIOTECAS
-- ============================================================
INSERT INTO BIBLIOTECA_RESPONSAVEL (cod_biblioteca, cod_funcionario, data_inicio, papel)
VALUES ('BIBMPC0001', 'FUC20250002', TO_DATE('2018-03-15','YYYY-MM-DD'), 'Principal');

INSERT INTO BIBLIOTECA_RESPONSAVEL (cod_biblioteca, cod_funcionario, data_inicio, papel)
VALUES ('BIBGZA0001', 'FUC20250005', TO_DATE('2019-07-04','YYYY-MM-DD'), 'Principal');

INSERT INTO BIBLIOTECA_RESPONSAVEL (cod_biblioteca, cod_funcionario, data_inicio, papel)
VALUES ('BIBSOF0001', 'FUC20250008', TO_DATE('2020-01-20','YYYY-MM-DD'), 'Principal');

INSERT INTO BIBLIOTECA_RESPONSAVEL (cod_biblioteca, cod_funcionario, data_inicio, papel)
VALUES ('BIBQLM0001', 'FUC20250011', TO_DATE('2021-04-01','YYYY-MM-DD'), 'Principal');

INSERT INTO BIBLIOTECA_RESPONSAVEL (cod_biblioteca, cod_funcionario, data_inicio, papel)
VALUES ('BIBNMP0001', 'FUC20250014', TO_DATE('2023-02-10','YYYY-MM-DD'), 'Principal');

-- ============================================================
-- 4. EVENTOS
--    id_evento gerado por SEQ_EVENTO.NEXTVAL
-- ============================================================

-- Evento 1 - Realizado (BIBMPC0001, Sabado 2025-03-15, 10:00-12:00)
INSERT INTO EVENTO (id_evento, cod_biblioteca, cod_funcionario_responsavel,
    titulo_evento, descricao_evento, local_evento,
    publico_alvo, data_evento, capacidade, status_evento, recorrente)
VALUES (SEQ_EVENTO.NEXTVAL, 'BIBMPC0001', 'FUC20250003',
    'Clube de Leitura - Mia Couto',
    'Sessao de leitura e debate sobre Vozes Anoitecidas',
    'Sala de Leitura, Biblioteca Polana',
    'Todos', TO_DATE('2025-03-15','YYYY-MM-DD'), 30, 'Realizado', 'N');
-- id_evento = 1

-- Evento 2 - Planeado (BIBGZA0001, Sexta-feira 2025-06-06, 09:00-13:00)
INSERT INTO EVENTO (id_evento, cod_biblioteca, cod_funcionario_responsavel,
    titulo_evento, descricao_evento, local_evento,
    publico_alvo, data_evento, capacidade, status_evento, recorrente)
VALUES (SEQ_EVENTO.NEXTVAL, 'BIBGZA0001', 'FUC20250005',
    'Dia da Crianca na Biblioteca',
    'Actividades de leitura e jogos educativos para criancas',
    'Jardim Exterior, Biblioteca Xai-Xai',
    'Iniciantes', TO_DATE('2025-06-06','YYYY-MM-DD'), 50, 'Planeado', 'N');
-- id_evento = 2

-- Evento 3 - Planeado, recorrente (BIBSOF0001, Terca-feira 2025-05-20, 14:00-17:00)
INSERT INTO EVENTO (id_evento, cod_biblioteca, cod_funcionario_responsavel,
    titulo_evento, descricao_evento, local_evento,
    publico_alvo, data_evento, capacidade, status_evento, recorrente)
VALUES (SEQ_EVENTO.NEXTVAL, 'BIBSOF0001', 'FUC20250008',
    'Workshop Informatica Basica',
    'Aulas praticas de informatica para adultos sem experiencia previa',
    'Laboratorio de Informatica, Biblioteca da Beira',
    'Intermedios', TO_DATE('2025-05-20','YYYY-MM-DD'), 20, 'Planeado', 'S');
-- id_evento = 3

-- Evento 4 - Planeado (BIBQLM0001, Quarta-feira 2026-01-07, 09:00-16:00)
-- 2026-01-07 e Quarta-feira. BIBQLM0001 abre Qua 08:00-17:30 -> valido
INSERT INTO EVENTO (id_evento, cod_biblioteca, cod_funcionario_responsavel,
    titulo_evento, descricao_evento, local_evento,
    publico_alvo, data_evento, capacidade, status_evento, recorrente)
VALUES (SEQ_EVENTO.NEXTVAL, 'BIBQLM0001', 'FUC20250011',
    'Feira do Livro - Quelimane 2026',
    'Exposicao e troca de livros com participacao da comunidade escolar',
    'Sala Multiuso, Biblioteca Quelimane',
    'Todos', TO_DATE('2026-01-07','YYYY-MM-DD'), 60, 'Planeado', 'N');
-- id_evento = 4

-- Evento 5 - Planeado (BIBNMP0001, Sexta-feira 2025-09-12, 10:00-12:00)
-- 2025-09-12 e Sexta-feira. BIBNMP0001 abre Sex 08:00-17:00 -> valido
INSERT INTO EVENTO (id_evento, cod_biblioteca, cod_funcionario_responsavel,
    titulo_evento, descricao_evento, local_evento,
    publico_alvo, data_evento, capacidade, status_evento, recorrente)
VALUES (SEQ_EVENTO.NEXTVAL, 'BIBNMP0001', 'FUC20250014',
    'Sessao de Leitura - Tradicao Oral Macua',
    'Sessao de contos tradicionais Macua com narradores locais',
    'Area de Estudo, Biblioteca Nampula',
    'Todos', TO_DATE('2025-09-12','YYYY-MM-DD'), 40, 'Planeado', 'N');
-- id_evento = 5

-- Evento 6 - Planeado futuro (BIBMPC0001, Terca-feira 2027-03-09, 09:00-13:00)
-- 2027-03-09 e Terca-feira. BIBMPC0001 abre Ter 08:00-18:00 -> valido
INSERT INTO EVENTO (id_evento, cod_biblioteca, cod_funcionario_responsavel,
    titulo_evento, descricao_evento, local_evento,
    publico_alvo, data_evento, capacidade, status_evento, recorrente)
VALUES (SEQ_EVENTO.NEXTVAL, 'BIBMPC0001', 'FUC20250002',
    'Encontro Nacional de Leitores 2027',
    'Encontro anual de leitores das 5 bibliotecas da rede Saber Comunitario',
    'Auditorio, Biblioteca Polana',
    'Todos', TO_DATE('2027-03-09','YYYY-MM-DD'), 100, 'Planeado', 'N');
-- id_evento = 6

-- ============================================================
-- 5. HORARIOS DE EVENTOS
-- ============================================================
INSERT INTO HORARIO_EVENTO (id_horario_ev, id_evento, dia_semana, data_ocorrencia, hora_inicio, hora_fim)
VALUES (SEQ_HORARIO_EVENTO.NEXTVAL, 1, 'Sabado',
    TO_DATE('2025-03-15','YYYY-MM-DD'), '10:00', '12:00');

INSERT INTO HORARIO_EVENTO (id_horario_ev, id_evento, dia_semana, data_ocorrencia, hora_inicio, hora_fim)
VALUES (SEQ_HORARIO_EVENTO.NEXTVAL, 2, 'Sexta-feira',
    TO_DATE('2025-06-06','YYYY-MM-DD'), '09:00', '13:00');

INSERT INTO HORARIO_EVENTO (id_horario_ev, id_evento, dia_semana, data_ocorrencia, hora_inicio, hora_fim)
VALUES (SEQ_HORARIO_EVENTO.NEXTVAL, 3, 'Terca-feira',
    TO_DATE('2025-05-20','YYYY-MM-DD'), '14:00', '17:00');

INSERT INTO HORARIO_EVENTO (id_horario_ev, id_evento, dia_semana, data_ocorrencia, hora_inicio, hora_fim)
VALUES (SEQ_HORARIO_EVENTO.NEXTVAL, 4, 'Quarta-feira',
    TO_DATE('2026-01-07','YYYY-MM-DD'), '09:00', '16:00');

INSERT INTO HORARIO_EVENTO (id_horario_ev, id_evento, dia_semana, data_ocorrencia, hora_inicio, hora_fim)
VALUES (SEQ_HORARIO_EVENTO.NEXTVAL, 5, 'Sexta-feira',
    TO_DATE('2025-09-12','YYYY-MM-DD'), '10:00', '12:00');

INSERT INTO HORARIO_EVENTO (id_horario_ev, id_evento, dia_semana, data_ocorrencia, hora_inicio, hora_fim)
VALUES (SEQ_HORARIO_EVENTO.NEXTVAL, 6, 'Terca-feira',
    TO_DATE('2027-03-09','YYYY-MM-DD'), '09:00', '13:00');

-- ============================================================
-- 6. RECURSOS DOS EVENTOS
-- ============================================================
INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (1, 'Copias de Vozes Anoitecidas', 25);
INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (1, 'Cadeiras', 30);

INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (2, 'Livros Infantis', 40);
INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (2, 'Mesas', 10);
INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (2, 'Cadeiras', 50);

INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (3, 'Computadores', 20);
INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (3, 'Cadeiras', 20);

INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (4, 'Mesas de exposicao', 15);
INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (4, 'Cadeiras', 60);
INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (4, 'Livros em exposicao', 200);

INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (5, 'Cadeiras', 40);
INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (5, 'Microfone', 1);

INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (6, 'Cadeiras', 100);
INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (6, 'Microfones', 3);
INSERT INTO EVENTO_RECURSO (id_evento, nome_recurso, quantidade)
VALUES (6, 'Projetor', 1);

-- ============================================================
-- 7. PARTICIPACOES EM EVENTOS
-- ============================================================

-- Evento 1 (BIBMPC0001 - Clube de Leitura)
INSERT INTO PARTICIPACAO_EVENTO (num_cartao, id_evento, data_inscricao, presenca_confirmacao)
VALUES ('MPC20250001', 1, TO_DATE('2025-03-10','YYYY-MM-DD'), 'S');
INSERT INTO PARTICIPACAO_EVENTO (num_cartao, id_evento, data_inscricao, presenca_confirmacao)
VALUES ('MPC20250002', 1, TO_DATE('2025-03-11','YYYY-MM-DD'), 'S');
INSERT INTO PARTICIPACAO_EVENTO (num_cartao, id_evento, data_inscricao, presenca_confirmacao)
VALUES ('MPC20250003', 1, TO_DATE('2025-03-12','YYYY-MM-DD'), 'N');

-- Evento 2 (BIBGZA0001 - Dia da Crianca)
INSERT INTO PARTICIPACAO_EVENTO (num_cartao, id_evento, data_inscricao)
VALUES ('GZA20250001', 2, TO_DATE('2025-05-20','YYYY-MM-DD'));
INSERT INTO PARTICIPACAO_EVENTO (num_cartao, id_evento, data_inscricao)
VALUES ('GZA20250002', 2, TO_DATE('2025-05-21','YYYY-MM-DD'));

-- Evento 4 (BIBQLM0001 - Feira do Livro)
INSERT INTO PARTICIPACAO_EVENTO (num_cartao, id_evento, data_inscricao)
VALUES ('QLM20250001', 4, TO_DATE('2025-12-15','YYYY-MM-DD'));
INSERT INTO PARTICIPACAO_EVENTO (num_cartao, id_evento, data_inscricao)
VALUES ('QLM20250002', 4, TO_DATE('2025-12-16','YYYY-MM-DD'));

-- Evento 5 (BIBNMP0001 - Tradicao Oral)
INSERT INTO PARTICIPACAO_EVENTO (num_cartao, id_evento, data_inscricao)
VALUES ('NMP20250001', 5, TO_DATE('2025-09-05','YYYY-MM-DD'));

-- ============================================================
-- 8. AVALIACOES DE EVENTOS
-- ============================================================
INSERT INTO AVALIACAO_EVENTO (id_evento, num_cartao, nota, comentario, data_avaliacao)
VALUES (1, 'MPC20250001', 5, 'Excelente sessao, muito enriquecedora!',
    TO_DATE('2025-03-15','YYYY-MM-DD'));
INSERT INTO AVALIACAO_EVENTO (id_evento, num_cartao, nota, comentario, data_avaliacao)
VALUES (1, 'MPC20250002', 4, 'Boa discussao, poderia ter mais tempo de debate.',
    TO_DATE('2025-03-15','YYYY-MM-DD'));

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================
COMMIT;
