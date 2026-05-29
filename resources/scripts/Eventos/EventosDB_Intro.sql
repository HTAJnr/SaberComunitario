-- ============================================
-- DADOS INICIAIS - EventosBibliotecasDB (v4)
-- ============================================
INSERT INTO BIBLIOTECA VALUES (
    'BIBMPM0001', 'Biblioteca de Maputo',
    'Av. 25 Setembro, Maputo',
    -25.966115, 32.573229,
    '21 123456', DATE '2000-01-01',
    200, 'Sala de leitura, Internet', 'Emprestimo, Eventos',
    'Maputo Cidade');

INSERT INTO BIBLIOTECA VALUES (
    'BIBMPP0001', 'Biblioteca da Matola',
    'Rua A, Matola',
    -25.920000, 32.460000,
    '21 654321', DATE '2005-06-01',
    150, 'Sala de leitura', 'Emprestimo, Eventos',
    'Maputo Provincia');

INSERT INTO BIBLIOTECA VALUES (
    'BIBSOF0001', 'Biblioteca da Beira',
    'Rua do Porto, Beira',
    -19.836667, 34.838889,
    '23 111111', DATE '1998-03-15',
    100, 'Sala de leitura', 'Emprestimo',
    'Sofala');

INSERT INTO BIBLIOTECA VALUES (
    'BIBNMP0001', 'Biblioteca de Nampula',
    'Av. Eduardo, Nampula',
    -15.116667, 39.266667,
    '26 222222', DATE '2010-09-01',
    120, 'Sala de leitura', 'Emprestimo, Eventos',
    'Nampula');

COMMIT;

SELECT cod_biblioteca, nome_biblioteca, provincia FROM BIBLIOTECA;
