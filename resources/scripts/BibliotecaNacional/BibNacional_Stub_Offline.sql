-- ============================================================
-- BibNacional_Stub_Offline.sql
-- Substituto temporário da MV biblioteca_snap para quando o
-- nó EventosDB (Gerson) está offline.
--
-- Executar como usr_NACIONALDB:
--   sqlplus usr_NACIONALDB/"HTAJnr#020403" @/root/TP/BibNacional_Stub_Offline.sql
--
-- QUANDO O EVENTOSDB VOLTAR A ESTAR ONLINE:
--   DROP TABLE biblioteca_snap;
--   e correr BibNacional_Snapshots.sql para recriar a MV real.
-- ============================================================

DROP TABLE biblioteca_snap;

CREATE TABLE biblioteca_snap (
    cod_biblioteca      VARCHAR2(10)  PRIMARY KEY,
    nome_biblioteca     VARCHAR2(100) NOT NULL,
    endereco            VARCHAR2(200),
    latitude            NUMBER(9,6),
    longitude           NUMBER(9,6),
    contacto_biblioteca VARCHAR2(50),
    data_inauguracao    DATE,
    capacidade          NUMBER(5),
    infraestrutura      VARCHAR2(500),
    servicos            VARCHAR2(500),
    provincia           VARCHAR2(17)
);

-- As três bibliotecas referenciadas nos dados de teste (Intro.sql)
INSERT INTO biblioteca_snap (cod_biblioteca, nome_biblioteca, endereco, provincia)
VALUES ('BIBMPC0001', 'Biblioteca Nacional de Mocambique',
        'Av. Vladimir Lenine, 4, Maputo', 'Maputo Cidade');

INSERT INTO biblioteca_snap (cod_biblioteca, nome_biblioteca, endereco, provincia)
VALUES ('BIBGZA0001', 'Biblioteca Comunitaria de Xai-Xai',
        'Rua 1 de Maio, Xai-Xai', 'Gaza');

INSERT INTO biblioteca_snap (cod_biblioteca, nome_biblioteca, endereco, provincia)
VALUES ('BIBSOF0001', 'Biblioteca Comunitaria da Beira',
        'Av. das FPLM, Beira', 'Sofala');

COMMIT;
