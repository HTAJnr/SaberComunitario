-- ============================================
-- INDICES - EventosBibliotecasDB (v4)
-- ============================================

-- Eventos por biblioteca (join frequente)
CREATE INDEX idx_evento_biblioteca
    ON EVENTO(cod_biblioteca)
    TABLESPACE tbs_eventosdb_idx;

-- Filtro por status
CREATE INDEX idx_evento_status
    ON EVENTO(status_evento)
    TABLESPACE tbs_eventosdb_idx;

-- Horarios de eventos por data de ocorrencia
CREATE INDEX idx_hor_ev_data
    ON HORARIO_EVENTO(data_ocorrencia)
    TABLESPACE tbs_eventosdb_idx;

-- Horarios da biblioteca por dia
CREATE INDEX idx_hor_bib_dia
    ON HORARIO_BIBLIOTECA(cod_biblioteca, dia_semana)
    TABLESPACE tbs_eventosdb_idx;

-- Indices da tabela de auditoria
CREATE INDEX iaud_evt_evento
    ON AUDITORIA_EVENTOS(id_evento)
    TABLESPACE tbs_eventosdb_idx;

CREATE INDEX iaud_evt_bib
    ON AUDITORIA_EVENTOS(cod_biblioteca)
    TABLESPACE tbs_eventosdb_idx;

CREATE INDEX iaud_evt_data
    ON AUDITORIA_EVENTOS(data_operacao)
    TABLESPACE tbs_eventosdb_idx;

CREATE INDEX iaud_evt_res
    ON AUDITORIA_EVENTOS(resultado)
    TABLESPACE tbs_eventosdb_idx;

-- ============================================================
-- INDICES ADICIONAIS — ausentes no ficheiro original
-- ============================================================

-- EVENTO — data e responsavel (usados em ORDER BY e JOIN frequentes)
CREATE INDEX iev_dt     ON EVENTO(data_evento)                 TABLESPACE tbs_eventosdb_idx;
CREATE INDEX iev_resp   ON EVENTO(cod_funcionario_responsavel)  TABLESPACE tbs_eventosdb_idx;

-- PARTICIPACAO_EVENTO — por evento (para contar inscritos e listar participantes)
CREATE INDEX ip_ev      ON PARTICIPACAO_EVENTO(id_evento)       TABLESPACE tbs_eventosdb_idx;

-- AVALIACAO_EVENTO — por evento e por leitor
CREATE INDEX iav_ev     ON AVALIACAO_EVENTO(id_evento)          TABLESPACE tbs_eventosdb_idx;
CREATE INDEX iav_leit   ON AVALIACAO_EVENTO(num_cartao)         TABLESPACE tbs_eventosdb_idx;
