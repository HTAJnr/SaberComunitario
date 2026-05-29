-- ============================================================
-- FUNCOES - EventosBibliotecasDB (v4)
-- Executar como usr_eventosdb
-- (Reservado para funcoes futuras)
-- ============================================================

-- Verificar
SELECT OBJECT_NAME, STATUS
FROM USER_OBJECTS
WHERE OBJECT_TYPE = 'FUNCTION'
ORDER BY OBJECT_NAME;
