-- ==========================================
-- DADOS INICIAIS (SEED DATA)
-- ==========================================

-- Doador anónimo (id=0) — obrigatório para doações sem identificação do doador (RN10)
-- O trigger protege_anonimo impede a eliminação deste registo
INSERT INTO DOADOR (ID_DOADOR, NOME_DOADOR, TIPO_DOADOR)
VALUES (0, 'Anónimo', 'Individual');

COMMIT;
