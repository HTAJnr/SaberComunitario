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

-- Verificar
SELECT OBJECT_NAME, STATUS
FROM USER_OBJECTS
WHERE OBJECT_TYPE = 'SEQUENCE'
ORDER BY OBJECT_NAME;
