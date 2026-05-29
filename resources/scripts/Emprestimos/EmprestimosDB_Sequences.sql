-- ============================================================
-- EmprestimosProg_Sequences.sql
-- Executar como: usr_emprestimosdb
--
-- Notas:
--   SEQ_PROGRAMA removida: cod_programa de PROGRAMA_ALFABETIZACAO
--     e VARCHAR2(18) gerado pelo backend (formato PROBIBXXX20XXYYYY)
--   SEQ_PARTICIPACAO removida: PARTICIPACAO_PROGRAMA passou a ter
--     PK composta (num_cartao, cod_programa) — sem surrogate key
-- ============================================================
DROP SEQUENCE SEQ_EMPRESTIMO;
DROP SEQUENCE SEQ_SUSPENSAO;
DROP SEQUENCE SEQ_NIVEL;
DROP SEQUENCE SEQ_AUDITORIA_EMP;

CREATE SEQUENCE SEQ_EMPRESTIMO    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_SUSPENSAO     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_NIVEL         START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_AUDITORIA_EMP START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

