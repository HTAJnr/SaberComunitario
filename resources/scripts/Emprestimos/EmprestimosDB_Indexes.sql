-- ============================================================
-- EmprestimosProg_Indexes.sql
-- Executar como: usr_emprestimosdb
-- ============================================================

-- ------------------------------------------------------------
-- EMPRESTIMO
-- Consultas frequentes: por leitor, por material, por prazo/datas
-- ------------------------------------------------------------
CREATE INDEX ie_cartao   ON EMPRESTIMO(num_cartao)      TABLESPACE tbs_emprestimosdb_idx;
CREATE INDEX ie_material ON EMPRESTIMO(cod_material)    TABLESPACE tbs_emprestimosdb_idx;
CREATE INDEX ie_prazo    ON EMPRESTIMO(prazo_devolucao) TABLESPACE tbs_emprestimosdb_idx;
CREATE INDEX ie_dt_dev   ON EMPRESTIMO(data_devolucao)  TABLESPACE tbs_emprestimosdb_idx;
CREATE INDEX ie_dt_ret   ON EMPRESTIMO(data_retirada)   TABLESPACE tbs_emprestimosdb_idx;

-- ------------------------------------------------------------
-- SUSPENSAO
-- Consultas frequentes: por leitor, por emprestimo, por estado
-- ------------------------------------------------------------
CREATE INDEX isusp_nc    ON SUSPENSAO(num_cartao)       TABLESPACE tbs_emprestimosdb_idx;
CREATE INDEX isusp_emp   ON SUSPENSAO(id_emprestimo)    TABLESPACE tbs_emprestimosdb_idx;
CREATE INDEX isusp_est   ON SUSPENSAO(estado_suspensao) TABLESPACE tbs_emprestimosdb_idx;

-- ------------------------------------------------------------
-- PROGRAMA_ALFABETIZACAO
-- ------------------------------------------------------------
CREATE INDEX iprog_bib   ON PROGRAMA_ALFABETIZACAO(cod_biblioteca)  TABLESPACE tbs_emprestimosdb_idx;
CREATE INDEX iprog_est   ON PROGRAMA_ALFABETIZACAO(estado_programa) TABLESPACE tbs_emprestimosdb_idx;

-- ------------------------------------------------------------
-- NIVEL_PROGRESSAO
-- Indice em cod_programa: JOIN frequente com PROGRAMA_ALFABETIZACAO
-- ------------------------------------------------------------
CREATE INDEX inivel_prog ON NIVEL_PROGRESSAO(cod_programa) TABLESPACE tbs_emprestimosdb_idx;

-- ------------------------------------------------------------
-- PARTICIPACAO_PROGRAMA
-- PK composta (num_cartao, cod_programa) ja tem indice automatico
-- ipart_prg: cod_programa para pesquisas por programa
-- ipart_est: estado_participacao para filtros de activos/concluidos
-- ------------------------------------------------------------
CREATE INDEX ipart_prg   ON PARTICIPACAO_PROGRAMA(cod_programa)        TABLESPACE tbs_emprestimosdb_idx;
CREATE INDEX ipart_est   ON PARTICIPACAO_PROGRAMA(estado_participacao) TABLESPACE tbs_emprestimosdb_idx;
