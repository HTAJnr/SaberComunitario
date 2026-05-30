-- ============================================================
-- EmprestimosDB_Synonyms.sql
-- ATENCAO: requer privilegio CREATE PUBLIC SYNONYM
-- Executar como SYSDBA antes deste script:
--   GRANT CREATE PUBLIC SYNONYM TO usr_emprestimosdb;
-- ============================================================

-- SINONIMOS PUBLICOS � BibliotecaNacionalDB (Helder)
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
-- Necessario para autenticacao: a query de login acede a FUNCIONARIO via dblink
CREATE OR REPLACE PUBLIC SYNONYM funcionario
    FOR funcionario@nacionaldb;
-- Necessario para queries que referenciam BIBLIOTECA (replica local de EventosDB)
CREATE OR REPLACE PUBLIC SYNONYM biblioteca
    FOR biblioteca_snap;

-- SINONIMOS PUBLICOS � MateriaisDB (Yasin)
CREATE OR REPLACE PUBLIC SYNONYM material_bibliografico
    FOR material_bibliografico@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM categoria
    FOR categoria@materiaisdb;
CREATE OR REPLACE PUBLIC SYNONYM transferencia
    FOR transferencia@materiaisdb;

-- SINONIMOS PUBLICOS � Objectos locais (usr_emprestimosdb)
CREATE OR REPLACE PUBLIC SYNONYM emprestimo
    FOR usr_emprestimosdb.emprestimo;
CREATE OR REPLACE PUBLIC SYNONYM suspensao
    FOR usr_emprestimosdb.suspensao;
CREATE OR REPLACE PUBLIC SYNONYM repl_funcionarios
    FOR usr_emprestimosdb.repl_funcionarios;
CREATE OR REPLACE PUBLIC SYNONYM programa_alfabetizacao
    FOR usr_emprestimosdb.programa_alfabetizacao;
CREATE OR REPLACE PUBLIC SYNONYM nivel_progressao
    FOR usr_emprestimosdb.nivel_progressao;
CREATE OR REPLACE PUBLIC SYNONYM programa_material
    FOR usr_emprestimosdb.programa_material;
CREATE OR REPLACE PUBLIC SYNONYM programa_funcionario
    FOR usr_emprestimosdb.programa_funcionario;
CREATE OR REPLACE PUBLIC SYNONYM participacao_programa
    FOR usr_emprestimosdb.participacao_programa;
CREATE OR REPLACE PUBLIC SYNONYM vw_emprestimos_activos
    FOR usr_emprestimosdb.vw_emprestimos_activos;
CREATE OR REPLACE PUBLIC SYNONYM vw_suspensoes_activas
    FOR usr_emprestimosdb.vw_suspensoes_activas;
CREATE OR REPLACE PUBLIC SYNONYM frag_emp_activos_op
    FOR usr_emprestimosdb.frag_emp_activos_op;
CREATE OR REPLACE PUBLIC SYNONYM vw_auditoria
    FOR usr_emprestimosdb.vw_auditoria;
CREATE OR REPLACE PUBLIC SYNONYM vw_relatorio_programas
    FOR usr_emprestimosdb.vw_relatorio_programas;

