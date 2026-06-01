-- ============================================================
-- EmprestimosDB_Snapshots.sql — Snapshots (Materialized Views)
-- Executar como usr_emprestimosdb
-- Executar DEPOIS de: EmprestimosDB_Database_Links.sql
--
-- Pre-requisitos (grants em nos remotos):
--   Helder: GRANT SELECT ON LEITOR            TO app_emprestimosdb
--   Helder: GRANT SELECT ON vw_leitor_publico TO app_emprestimosdb
--   Helder: GRANT SELECT ON ADULTO            TO app_emprestimosdb
--   Helder: GRANT SELECT ON PROFESSOR         TO app_emprestimosdb
--   Helder: GRANT SELECT ON CRIANCA           TO app_emprestimosdb
--   Yasin:  GRANT SELECT ON MATERIAL_BIBLIOGRAFICO TO app_emprestimosdb
--   Yasin:  GRANT SELECT ON CATEGORIA              TO app_emprestimosdb
--   Gerson: GRANT SELECT ON BIBLIOTECA             TO app_emprestimosdb
--
-- BUILD IMMEDIATE popula o snapshot no momento da criacao
-- REFRESH COMPLETE a cada hora (NEXT SYSDATE + 1/24)
-- ============================================================


-- ============================================================
-- SNAPSHOT 1 — biblioteca_snap
-- Replica bibliotecas do EventosBibliotecasDB (Gerson)
-- Necessario para: validar cod_biblioteca em programas e emprestimos
-- ============================================================
DROP MATERIALIZED VIEW biblioteca_snap;

CREATE MATERIALIZED VIEW biblioteca_snap
  BUILD IMMEDIATE
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT * FROM biblioteca@eventosdb;


-- ============================================================
-- SNAPSHOT 2 — snap_leitor
-- Replica leitores do BibliotecaNacionalDB (Helder)
-- Necessario para: validar status_leitor, distancia_biblioteca
-- e historico_pontualidade ao criar emprestimos (RN01, RN02)
-- Se o Helder estiver offline, os emprestimos continuam a funcionar
-- ============================================================
DROP MATERIALIZED VIEW snap_leitor;

CREATE MATERIALIZED VIEW snap_leitor
  BUILD IMMEDIATE
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT num_cartao, nome_completo, cod_biblioteca,
       status_leitor, historico_pontualidade, distancia_biblioteca
FROM leitor@nacionaldb;


-- ============================================================
-- SNAPSHOT 3 — snap_adulto
-- Replica adultos do BibliotecaNacionalDB (Helder)
-- Necessario para: detectar tipo ADULTO, verificar nivel_literacia
-- na restricao de nivel de leitura (RN04.2)
-- ============================================================
DROP MATERIALIZED VIEW snap_adulto;

CREATE MATERIALIZED VIEW snap_adulto
  BUILD IMMEDIATE
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT num_cartao, nivel_literacia
FROM ADULTO@nacionaldb;


-- ============================================================
-- SNAPSHOT 4 — snap_professor
-- Replica professores do BibliotecaNacionalDB (Helder)
-- Necessario para: detectar tipo PROFESSOR e aplicar
-- prazo de emprestimo alargado (+ 7 dias, RN02)
-- ============================================================
DROP MATERIALIZED VIEW snap_professor;

CREATE MATERIALIZED VIEW snap_professor
  BUILD IMMEDIATE
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT num_cartao
FROM PROFESSOR@nacionaldb;


-- ============================================================
-- SNAPSHOT 5 — snap_crianca
-- Replica criancas do BibliotecaNacionalDB (Helder)
-- Necessario para: detectar tipo CRIANCA e bloquear
-- emprestimo de material para adultos (RN04.1)
-- ============================================================
DROP MATERIALIZED VIEW snap_crianca;

CREATE MATERIALIZED VIEW snap_crianca
  BUILD IMMEDIATE
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT num_cartao
FROM CRIANCA@nacionaldb;


-- ============================================================
-- SNAPSHOT 6 — snap_material
-- Replica materiais bibliograficos do MateriaisDB (Yasin)
-- Necessario para: verificar disponibilidade do material,
-- obter valor_aquisicao para calculo de multas (RN05),
-- verificar estado antes de criar emprestimo
-- Se o Yasin estiver offline, os emprestimos continuam a funcionar
-- ============================================================
DROP MATERIALIZED VIEW snap_material;

CREATE MATERIALIZED VIEW snap_material
  BUILD IMMEDIATE
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT cod_material, titulo, autor, cod_biblioteca,
       estado_material_conservacao, motivo_indisponibilidade,
       valor_aquisicao, cod_categoria
FROM MATERIAL_BIBLIOGRAFICO@materiaisdb;


-- ============================================================
-- SNAPSHOT 7 — snap_categoria
-- Replica categorias do MateriaisDB (Yasin)
-- Necessario para: verificar faixa_etaria (RN04.1 — bloquear
-- criancas em material adulto) e nivel_leitura (RN04.2 —
-- recomendacao de literacia)
-- Pre-requisito: Yasin executar GRANT SELECT ON CATEGORIA
--                              TO app_emprestimosdb
-- ============================================================
DROP MATERIALIZED VIEW snap_categoria;

CREATE MATERIALIZED VIEW snap_categoria
  BUILD IMMEDIATE
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT id_categoria, area_tematica, faixa_etaria, nivel_leitura
FROM CATEGORIA@materiaisdb;


-- ============================================================
-- SNAPSHOT 8 — repl_funcionarios
-- Replica funcionarios do BibliotecaNacionalDB (Helder)
-- Necessario para: autenticacao offline quando NacionalDB indisponivel
-- Inclui SENHA para que o login funcione apenas com dados locais
-- ============================================================
DROP MATERIALIZED VIEW repl_funcionarios;

CREATE MATERIALIZED VIEW repl_funcionarios
  BUILD IMMEDIATE
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT f.cod_funcionario, f.nome_funcionario, f.email, f.contacto,
       f.id_funcao, f.cod_biblioteca, fn.nivel_acesso, fn.nome_funcao, f.senha,
       f.genero, f.data_nasc, f.endereco, f.formacao, f.experiencia,
       f.data_contratacao, f.data_demissao
FROM funcionario@nacionaldb f,
     funcao_funcionario@nacionaldb fn
WHERE f.id_funcao = fn.id_funcao AND f.data_demissao IS NULL;


-- ============================================================
-- SNAPSHOT 9 — repl_funcao_funcionario
-- Replica funcoes do BibliotecaNacionalDB
-- Necessario para: JOIN FUNCAO_FUNCIONARIO na query de login offline
-- ============================================================
DROP MATERIALIZED VIEW repl_funcao_funcionario;

CREATE MATERIALIZED VIEW repl_funcao_funcionario
  BUILD IMMEDIATE
  REFRESH COMPLETE
  START WITH SYSDATE
  NEXT SYSDATE + 1/24
AS
SELECT id_funcao, nome_funcao, nivel_acesso, descricao
FROM funcao_funcionario@nacionaldb;

-- Grants imediatos — aplicar apos criacao das MVs
GRANT SELECT ON repl_funcionarios       TO app_emprestimosdb;
GRANT SELECT ON repl_funcao_funcionario TO app_emprestimosdb;

-- ============================================================
-- Recompilar objectos dependentes das MVs
-- ============================================================
ALTER TRIGGER trg_valida_emprestimo COMPILE;
ALTER VIEW vw_emprestimos_ativos COMPILE;
ALTER VIEW vw_historico_emprestimos COMPILE;
