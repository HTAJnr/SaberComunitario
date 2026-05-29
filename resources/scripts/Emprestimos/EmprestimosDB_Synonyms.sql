-- ============================================================
-- EmprestimosProg_Synonyms.sql
-- ATENCAO: requer privilegio CREATE PUBLIC SYNONYM
-- Executar como SYSDBA antes deste script:
--   GRANT CREATE PUBLIC SYNONYM TO usr_emprestimosdb;
-- ============================================================
-- SINONIMOS PUBLICOS — BibliotecaNacionalDB (Helder)
CREATE OR REPLACE PUBLIC SYNONYM leitor
    FOR leitor@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM adulto
    FOR adulto@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM adulto_interesse
    FOR adulto_interesse@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM professor
    FOR professor@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM professor_disciplina
    FOR professor_disciplina@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM crianca
    FOR crianca@nacionaldb;
CREATE OR REPLACE PUBLIC SYNONYM funcao_funcionario
    FOR funcao_funcionario@nacionaldb;

-- SINONIMOS PUBLICOS — MateriaisDB (Yasin)
CREATE OR REPLACE PUBLIC SYNONYM material_bibliografico
    FOR material_bibliografico@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM categoria
    FOR categoria@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM transferencia
    FOR transferencia@materiaisdb;
