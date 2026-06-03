-- ============================================================
-- MateriaisDB_Snapshots.sql — Snapshots (Materialized Views)
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: usr_materiaisdb
-- Executar DEPOIS de: MateriaisDB_Database_Links.sql
--
-- NOTA: Os nos remotos devem estar online durante a criacao
-- BUILD IMMEDIATE popula o snapshot imediatamente
-- REFRESH COMPLETE a cada hora (NEXT SYSDATE + 1/24)
-- ============================================================


-- ============================================================
-- SNAPSHOT 1 — repl_funcionarios
-- Replica funcionarios do BibliotecaNacionalDB (Helder)
-- Permite verificar dados de funcionarios sem depender
-- da disponibilidade do no do Helder
-- ============================================================
DROP TABLE repl_funcionarios;
DROP MATERIALIZED VIEW repl_funcionarios;

-- Campos completos para autenticacao offline (inclui SENHA e EMAIL)
CREATE MATERIALIZED VIEW repl_funcionarios
  BUILD DEFERRED
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT f.cod_funcionario, f.nome_funcionario, f.email, f.contacto,
       f.id_funcao, f.cod_biblioteca, fn.nivel_acesso, fn.nome_funcao, f.senha,
       f.genero, f.data_nasc, f.endereco, f.formacao, f.experiencia,
       f.data_contratacao, f.data_demissao
FROM usr_nacionaldb.funcionario@link_nacionaldb f,
     usr_nacionaldb.funcao_funcionario@link_nacionaldb fn
WHERE f.id_funcao = fn.id_funcao AND f.data_demissao IS NULL;


-- ============================================================
-- SNAPSHOT 4 — repl_funcao_funcionario
-- Replica funcoes do BibliotecaNacionalDB
-- Necessario para: JOIN FUNCAO_FUNCIONARIO na query de login offline
-- ============================================================
DROP TABLE repl_funcao_funcionario;
DROP MATERIALIZED VIEW repl_funcao_funcionario;

CREATE MATERIALIZED VIEW repl_funcao_funcionario
  BUILD DEFERRED
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT id_funcao, nome_funcao, nivel_acesso, descricao
FROM usr_nacionaldb.funcao_funcionario@link_nacionaldb;

-- ============================================================
-- SNAPSHOT 2 — biblioteca_snap
-- Replica bibliotecas do EventosBibliotecasDB (Gerson)
-- Permite verificar dados de bibliotecas sem depender
-- da disponibilidade do no do Gerson
-- ============================================================
DROP TABLE biblioteca_snap;
DROP MATERIALIZED VIEW biblioteca_snap;

CREATE MATERIALIZED VIEW biblioteca_snap
  BUILD DEFERRED
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT * FROM usr_eventosdb.biblioteca@link_eventosdb;


-- ============================================================
-- SNAPSHOT 3 — snap_leitor_publico
-- Replica leitores publicos do BibliotecaNacionalDB (Helder)
-- Permite verificar dados de leitores sem depender
-- da disponibilidade do no do Helder
-- ============================================================
DROP TABLE snap_leitor_publico;
DROP MATERIALIZED VIEW snap_leitor_publico;

CREATE MATERIALIZED VIEW snap_leitor_publico
  BUILD DEFERRED
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT num_cartao, nome_completo, cod_biblioteca,
       status_leitor, historico_pontualidade, distancia_biblioteca
FROM usr_nacionaldb.leitor@link_nacionaldb;

-- Grants imediatos — tolerante a MV inexistente (NacionalDB offline durante install)
BEGIN
  BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON repl_funcionarios TO app_materiaisdb';       EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN EXECUTE IMMEDIATE 'GRANT SELECT ON repl_funcao_funcionario TO app_materiaisdb'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/

-- Recompilar trigger dependente das MVs (se ja existir)
BEGIN
  BEGIN EXECUTE IMMEDIATE 'ALTER TRIGGER trg_valida_transferencia COMPILE'; EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/

-- ============================================================
-- Recriar sinonimos publicos cross-node dependentes de BibliotecaNacionalDB
-- (agora que o no NacionalDB esta activo)
-- ============================================================
CONNECT sys/"bd2.isctem" AS SYSDBA
@@MateriaisDB_Synonyms.sql
CONNECT usr_materiaisdb/"YM20240260"

-- ============================================================
-- SEED: TRANSFERENCIA (executar após MVs criadas)
-- trg_transferencia_insert e protege_ultimo_exemplar_insert
-- desactivados para bypass da validação de empréstimo activo.
-- trg_valida_transferencia desactivado: repl_funcionarios e
-- snapshots podem nao ter sido populados neste ponto.
-- ============================================================
ALTER TRIGGER trg_transferencia_insert DISABLE;
ALTER TRIGGER protege_ultimo_exemplar_insert DISABLE;
ALTER TRIGGER trg_valida_transferencia DISABLE;

-- T1 - Pendente: BIBMPC0001 -> BIBGZA0001 (Sul->Sul, Abr 2025)
INSERT INTO TRANSFERENCIA (id_transferencia, data_solicitacao, estado_transferencia,
    cod_material, cod_biblioteca_origem, cod_biblioteca_destino,
    cod_funcionario_solicitante, motivo)
VALUES (1, TO_DATE('25/04/2025','DD/MM/YYYY'), 'Pendente',
    'MAT20190004', 'BIBMPC0001', 'BIBGZA0001',
    'FUC20250002', 'Solicitacao de BCX - alta procura de Mia Couto na regiao de Gaza');

-- T2 - Aprovada: BIBNMP0001 -> BIBQLM0001 (Norte->Centro, Out 2025)
INSERT INTO TRANSFERENCIA (id_transferencia, data_solicitacao, estado_transferencia,
    cod_material, cod_biblioteca_origem, cod_biblioteca_destino,
    cod_funcionario_solicitante, motivo)
VALUES (2, TO_DATE('12/10/2025','DD/MM/YYYY'), 'Aprovada',
    'MAT20250013', 'BIBNMP0001', 'BIBQLM0001',
    'FUC20250014', 'Pedido de BIBQLM0001 - interesse em literatura Macua para feira do livro 2026');

-- T3 - Pendente: BIBGZA0001 -> BIBNMP0001 (Sul->Norte, Mai 2026)
INSERT INTO TRANSFERENCIA (id_transferencia, data_solicitacao, estado_transferencia,
    cod_material, cod_biblioteca_origem, cod_biblioteca_destino,
    cod_funcionario_solicitante, motivo)
VALUES (3, TO_DATE('10/05/2026','DD/MM/YYYY'), 'Pendente',
    'MAT20200002', 'BIBGZA0001', 'BIBNMP0001',
    'FUC20250005', 'Reequilibrio de acervo: excesso de literatura agricola em Gaza, defice em Nampula');

-- T4 - Concluida: BIBQLM0001 -> BIBMPC0001 (Centro->Sul, Abr/Mai 2026)
INSERT INTO TRANSFERENCIA (id_transferencia, data_solicitacao, data_aprovacao_destino, data_conclusao,
    estado_transferencia, cod_material, cod_biblioteca_origem, cod_biblioteca_destino,
    cod_funcionario_solicitante, cod_funcionario_aprovador, motivo)
VALUES (4, TO_DATE('15/04/2026','DD/MM/YYYY'), TO_DATE('22/04/2026','DD/MM/YYYY'), TO_DATE('02/05/2026','DD/MM/YYYY'),
    'Concluida', 'MAT20260001', 'BIBQLM0001', 'BIBMPC0001',
    'FUC20250011', 'FUC20250002',
    'Material de agricultura sustentavel requisitado por BIBMPC0001 para programa de adultos');

-- T5 - Concluida: BIBSOF0001 -> BIBNMP0001 (Centro->Norte, Jul/Ago 2025)
INSERT INTO TRANSFERENCIA (id_transferencia, data_solicitacao, data_aprovacao_destino, data_conclusao,
    estado_transferencia, cod_material, cod_biblioteca_origem, cod_biblioteca_destino,
    cod_funcionario_solicitante, cod_funcionario_aprovador, motivo)
VALUES (5, TO_DATE('10/07/2025','DD/MM/YYYY'), TO_DATE('25/07/2025','DD/MM/YYYY'), TO_DATE('05/08/2025','DD/MM/YYYY'),
    'Concluida', 'MAT20220001', 'BIBSOF0001', 'BIBNMP0001',
    'FUC20250008', 'FUC20250014',
    'Pedido de Nampula para apoio a programa de educacao geografica e ambiental');

-- T6 - Concluida: BIBGZA0001 -> BIBMPC0001 (Sul->Sul, Set/Out 2025)
INSERT INTO TRANSFERENCIA (id_transferencia, data_solicitacao, data_aprovacao_destino, data_conclusao,
    estado_transferencia, cod_material, cod_biblioteca_origem, cod_biblioteca_destino,
    cod_funcionario_solicitante, cod_funcionario_aprovador, motivo)
VALUES (6, TO_DATE('03/09/2025','DD/MM/YYYY'), TO_DATE('15/09/2025','DD/MM/YYYY'), TO_DATE('08/10/2025','DD/MM/YYYY'),
    'Concluida', 'MAT20240007', 'BIBGZA0001', 'BIBMPC0001',
    'FUC20250005', 'FUC20250002',
    'Material cientifico da UEM mais relevante para publico academico e de saude de Maputo');

-- T7 - Rejeitada: BIBNMP0001 -> BIBQLM0001 (Norte->Centro, Mar 2026)
INSERT INTO TRANSFERENCIA (id_transferencia, data_solicitacao,
    estado_transferencia, cod_material, cod_biblioteca_origem, cod_biblioteca_destino,
    cod_funcionario_solicitante, motivo)
VALUES (7, TO_DATE('15/03/2026','DD/MM/YYYY'),
    'Rejeitada', 'MAT20260004', 'BIBNMP0001', 'BIBQLM0001',
    'FUC20250014',
    'Pedido recusado: BIBQLM0001 sem capacidade para novos periodicos ate Q4 2026');

-- T8 - Pendente: BIBMPC0001 -> BIBNMP0001 (Sul->Norte, Mai 2026)
INSERT INTO TRANSFERENCIA (id_transferencia, data_solicitacao,
    estado_transferencia, cod_material, cod_biblioteca_origem, cod_biblioteca_destino,
    cod_funcionario_solicitante, motivo)
VALUES (8, TO_DATE('05/05/2026','DD/MM/YYYY'),
    'Pendente', 'MAT20240002', 'BIBMPC0001', 'BIBNMP0001',
    'FUC20250002',
    'Reforco de materiais de saude para programa comunitario em Nampula');

-- T9 - Pendente: BIBSOF0001 -> BIBGZA0001 (Centro->Sul, Mai 2026)
INSERT INTO TRANSFERENCIA (id_transferencia, data_solicitacao,
    estado_transferencia, cod_material, cod_biblioteca_origem, cod_biblioteca_destino,
    cod_funcionario_solicitante, motivo)
VALUES (9, TO_DATE('20/05/2026','DD/MM/YYYY'),
    'Pendente', 'MAT20210002', 'BIBSOF0001', 'BIBGZA0001',
    'FUC20250008',
    'BIBGZA0001 solicita reforco de contos infantis para programa de leitura de Junho 2026');

-- T10 - Pendente: BIBNMP0001 -> BIBQLM0001 (Norte->Centro, Mai 2026)
INSERT INTO TRANSFERENCIA (id_transferencia, data_solicitacao,
    estado_transferencia, cod_material, cod_biblioteca_origem, cod_biblioteca_destino,
    cod_funcionario_solicitante, motivo)
VALUES (10, TO_DATE('28/05/2026','DD/MM/YYYY'),
    'Pendente', 'MAT20260003', 'BIBNMP0001', 'BIBQLM0001',
    'FUC20250014',
    'BIBQLM0001 organiza encontro sobre desenvolvimento rural na Zambezia em Julho 2026');

ALTER TRIGGER trg_transferencia_insert ENABLE;
ALTER TRIGGER protege_ultimo_exemplar_insert ENABLE;
ALTER TRIGGER trg_valida_transferencia ENABLE;

-- Avancar SEQ_TRANSFERENCIA para alem dos IDs inseridos explicitamente
ALTER SEQUENCE SEQ_TRANSFERENCIA INCREMENT BY 10;
SELECT SEQ_TRANSFERENCIA.NEXTVAL FROM DUAL;
ALTER SEQUENCE SEQ_TRANSFERENCIA INCREMENT BY 1;

COMMIT;