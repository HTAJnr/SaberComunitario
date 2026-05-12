-- ============================================================
-- BibNacional_Main.sql — Script de instalação completo
-- Executar como SYSDBA:
--   sqlplus sys/bd2.isctem as sysdba @/root/TP/BibNacional_Main.sql
-- ============================================================

-- 1. Tablespaces
@/root/TP/BibNacional_Tablespaces.sql

-- 2. Utilizadores
@/root/TP/BibNacional_Users.sql

-- 3. Roles e permissões
@/root/TP/BibNacional_Roles.sql

-- Passa para o schema owner — o resto corre como usr_NACIONALDB
CONNECT usr_NACIONALDB/"HTAJnr#020403"

-- 3.5. Database Links
@/root/TP/BibNacional_Database_Links.sql

-- 3.6. Snapshots locais (MV de BIBLIOTECA — depende dos database links)
@/root/TP/BibNacional_Snapshots.sql

-- 3.7. Sinónimos (transparência de localização — depende dos database links e snapshots)
@/root/TP/BibNacional_Synonyms.sql

-- 4. Estruturas base (tabelas + constraints)
@/root/TP/BibNacional_Create.sql

-- 5. Sequências
@/root/TP/BibNacional_Sequences.sql

-- 6. Views
@/root/TP/BibNacional_Views.sql

-- 7. Funções
@/root/TP/BibNacional_Functions.sql

-- 8. Procedimentos
@/root/TP/BibNacional_Procedures.sql

-- 9. Triggers
@/root/TP/BibNacional_Triggers.sql

-- 10. Índices
@/root/TP/BibNacional_Indexes.sql

-- 11. Grants e permissões (após todos os objectos criados)
-- Executar ainda como usr_NACIONALDB — GRANT em objectos do próprio schema é permitido.
-- A atribuição de roles a utilizadores (GRANT role TO user) está em Roles.sql (SYSDBA).
@/root/TP/BibNacional_Grants.sql

-- 12. Dados iniciais
@/root/TP/BibNacional_Intro.sql
