-- ============================================================
-- EventosDB_Procedures.sql — Procedures do no EventosDB
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: usr_eventosdb
-- Executar DEPOIS de: EventosDB_Sequences.sql, EventosDB_Create.sql
-- ============================================================


-- ============================================================
-- PROCEDURE 1 — insere_participacao_evento (RN)
-- Insere participacao em evento; verifica duplicado na BD (barreira de seguranca)
-- Validacoes de horario, publico-alvo e evento passado feitas no backend
-- Chamada pelo backend: BEGIN insere_participacao_evento(:nc, :id_ev, :presenca); END;
-- ============================================================
CREATE OR REPLACE PROCEDURE insere_participacao_evento (
    p_num_cartao           IN PARTICIPACAO_EVENTO.num_cartao%TYPE,
    p_id_evento            IN PARTICIPACAO_EVENTO.id_evento%TYPE,
    p_presenca_confirmacao IN PARTICIPACAO_EVENTO.presenca_confirmacao%TYPE
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
      FROM PARTICIPACAO_EVENTO
     WHERE num_cartao = p_num_cartao AND id_evento = p_id_evento;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20600, 'Leitor ja inscrito neste evento');
    END IF;

    INSERT INTO PARTICIPACAO_EVENTO (num_cartao, id_evento, data_inscricao, presenca_confirmacao)
    VALUES (p_num_cartao, p_id_evento, SYSDATE, NVL(p_presenca_confirmacao, 'N'));

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END insere_participacao_evento;
/

-- ============================================================
-- prc_refresh_snapshots
-- Forca REFRESH COMPLETE em todas as MVs locais deste no.
-- Chamada pelo backend via POST /api/manutencao/refresh-snapshots.
-- ============================================================
CREATE OR REPLACE PROCEDURE prc_refresh_snapshots AS
    v_falhas NUMBER := 0;
BEGIN
    DBMS_MVIEW.REFRESH_ALL_MVIEWS(v_falhas);
    DBMS_OUTPUT.PUT_LINE('Refresh concluido. Falhas: ' || v_falhas);
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20300, 'Erro no refresh de snapshots: ' || SQLERRM);
END;
/
