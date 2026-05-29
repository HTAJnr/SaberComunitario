-- ============================================================
-- SEQUENCIAS - EventosBibliotecasDB (v4)
-- Executar como usr_eventosdb
-- ============================================================

CREATE SEQUENCE SEQ_AUDITORIA_EVT
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE SEQ_EVENTO
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE SEQ_HORARIO_EVENTO
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequencias adicionadas — ausentes no ficheiro original
-- SEQ_AVALIACAO: usada pelo backend (INSERT INTO AVALIACAO_EVENTO com SEQ_AVALIACAO.NEXTVAL)
CREATE SEQUENCE SEQ_AVALIACAO
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- SEQ_RECURSO: usada pelo trigger trg_recurso_id (auto-incremento de EVENTO_RECURSO)
CREATE SEQUENCE SEQ_RECURSO
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;
