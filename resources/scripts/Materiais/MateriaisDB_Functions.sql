-- ============================================================
-- MateriaisDB_Functions.sql — Funcoes do no MateriaisDB
-- Sistema de Gestao de Bibliotecas Comunitarias Distribuido
-- Executar como: usr_materiaisdb
-- Executar ANTES de: MateriaisDB_Triggers.sql
-- ============================================================


-- ============================================================
-- FUNCAO 1 — normaliza_titulo
-- Normaliza titulo para comparacao insensivel a acentos e maiusculas/minusculas
-- Usada pelos triggers protege_ultimo_exemplar_insert e protege_ultimo_exemplar_update
-- para comparar titulos quando o material nao tem ISBN
-- ============================================================
CREATE OR REPLACE FUNCTION normaliza_titulo(p_titulo IN VARCHAR2)
RETURN VARCHAR2
IS
    v_titulo_limpo VARCHAR2(4000);
BEGIN
    v_titulo_limpo := TRANSLATE(TRIM(REGEXP_REPLACE(p_titulo, '\s+', ' ')),
        'aàâãeèéêiìíîoòóôõuùúûcÀÁÂÃÈÉÊÌÍÎÒÓÔÕÙÚÛÇ',
        'aaaaeeeeiiiioooooouuucAAAAEEEIIIOOOOOUUUC'
    );
    RETURN UPPER(v_titulo_limpo);
END normaliza_titulo;
/
