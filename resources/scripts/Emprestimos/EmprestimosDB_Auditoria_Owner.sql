-- ============================================================
-- EmprestimosProg_Auditoria_Owner.sql
-- Executar como usr_emprestimosdb
-- ============================================================
DROP SEQUENCE SEQ_AUDITORIA_EMP;
DROP TABLE AUDITORIA_EMPRESTIMOS CASCADE CONSTRAINTS;

CREATE SEQUENCE SEQ_AUDITORIA_EMP
    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE TABLE AUDITORIA_EMPRESTIMOS (
    id_auditoria   NUMBER        NOT NULL,
    data_operacao  DATE          DEFAULT SYSDATE NOT NULL,
    operacao       VARCHAR2(50)  NOT NULL,
    num_cartao     VARCHAR2(12),
    cod_material   VARCHAR2(12),
    id_emprestimo  NUMBER,
    resultado      VARCHAR2(10)  NOT NULL,
    motivo_falha   VARCHAR2(300),
    nos_afetados   VARCHAR2(200),
    observacoes    VARCHAR2(300)
) TABLESPACE tbs_emprestimosdb;

ALTER TABLE AUDITORIA_EMPRESTIMOS
    ADD CONSTRAINT AUDITORIA_EMP_PK PRIMARY KEY (id_auditoria);
ALTER TABLE AUDITORIA_EMPRESTIMOS
    ADD CONSTRAINT chk_resultado_emp
    CHECK (resultado IN ('SUCESSO','FALHA'));

CREATE INDEX iaud_emp_cartao ON AUDITORIA_EMPRESTIMOS(num_cartao)
    TABLESPACE tbs_emprestimosdb_idx;
CREATE INDEX iaud_emp_data   ON AUDITORIA_EMPRESTIMOS(data_operacao)
    TABLESPACE tbs_emprestimosdb_idx;
CREATE INDEX iaud_emp_res    ON AUDITORIA_EMPRESTIMOS(resultado)
    TABLESPACE tbs_emprestimosdb_idx;

CREATE OR REPLACE PROCEDURE prc_registar_auditoria(
    p_operacao      IN VARCHAR2,
    p_num_cartao    IN VARCHAR2    DEFAULT NULL,
    p_cod_material  IN VARCHAR2    DEFAULT NULL,
    p_id_emprestimo IN NUMBER      DEFAULT NULL,
    p_resultado     IN VARCHAR2,
    p_motivo_falha  IN VARCHAR2    DEFAULT NULL,
    p_nos_afetados  IN VARCHAR2    DEFAULT NULL,
    p_observacoes   IN VARCHAR2    DEFAULT NULL
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO AUDITORIA_EMPRESTIMOS (
        id_auditoria, data_operacao, operacao,
        num_cartao, cod_material, id_emprestimo,
        resultado, motivo_falha, nos_afetados, observacoes
    ) VALUES (
        SEQ_AUDITORIA_EMP.NEXTVAL, SYSDATE, p_operacao,
        p_num_cartao, p_cod_material, p_id_emprestimo,
        p_resultado, p_motivo_falha, p_nos_afetados, p_observacoes
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END;
/

CREATE OR REPLACE VIEW VW_AUDITORIA AS
SELECT
    id_auditoria,
    data_operacao,
    operacao,
    resultado,
    motivo_falha,
    nos_afetados,
    observacoes,
    'EMPRESTIMOS' AS no_origem
FROM AUDITORIA_EMPRESTIMOS;

