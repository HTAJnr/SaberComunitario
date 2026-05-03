# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Stack section

- Primary language: JavaScript
- Documentation: Markdown
- Frontend: HTML/CSS

When creating new files, default to JavaScript unless specified otherwise. Follow existing code conventions in the repo.
Add under a ## Editing Approach section in CLAUDE.md\n\n## Editing Approach

- Prefer editing existing files over creating new ones
- Read the file first before making edits to understand context
- Use targeted Edit operations rather than rewriting whole files with Write
  Add as a ## Planning section near the top of CLAUDE.md\n\n## Planning
- For multi-step tasks, present a plan before making changes
- Confirm scope on tasks touching 3+ files

## Project Overview

**Saber Comunitário** — a distributed community library management system (Trabalho Prático BD1). Node.js/Express REST API + vanilla JS SPA frontend + Oracle Database.

## Commands

```bash
# From backend/ directory
npm install        # Install dependencies that are in use
npm start          # Start server (node server.js)
npm run dev        # Start with file watcher (node --watch server.js)
```

No build step for frontend — static files are served directly by Express from `../frontend`.

## Architecture

### Database (Oracle)

The Oracle instance is **Oracle Database 10g (SQL\*Plus 10.2)** running on a **CentOS 6.8 VM**. SQL syntax and features must be compatible with Oracle 10g — avoid functions or syntax introduced in later versions (e.g., `LISTAGG` is 11g+, `FETCH FIRST` is 12c+).

## Environment Configuration (`backend/.env`)

```
DB_HOST=172.20.10.3
DB_PORT=1521
DB_SERVICE=XE
DB_USER=JnrLite
DB_PASSWORD=1234
INSTANT_CLIENT_PATH=C:/instantclient_21_20
PORT=3000
NLS_LANG=AMERICAN_AMERICA.AL32UTF8
```

Oracle Instant Client must exist at `INSTANT_CLIENT_PATH` for the thick client mode (`oracledb.initOracleClient()`).

## Key Patterns

**Modal pattern in frontend**: Each CRUD section builds form HTML dynamically, injects into `#modal-conteudo`, then reads values by element ID on submit.

**Demo login** (bypasses DB): `demo@biblioteca.mz` / `demo` — returns a hardcoded `DEMO_USER` object in `auth.js`.

## Backend Route Patterns

Every route file follows this exact structure — do not re-explore existing routes to learn these patterns:

**Imports:**
```javascript
const express = require('express');
const router  = express.Router();
const { getConnection, oracledb } = require('../db');
const { autenticar, exigirNivel } = require('../middleware/permissoes');
```

**Connection + error handling (every handler):**
```javascript
let conn;
try {
  conn = await getConnection();
  const result = await conn.execute(SQL, binds, { outFormat: oracledb.OUT_FORMAT_OBJECT });
  await conn.commit();          // only on writes
  res.json(...)                 // or res.status(201).json(...)
} catch (err) {
  if (conn) await conn.rollback();   // only on writes
  console.error('\x1b[31m[ROTA ACTION]\x1b[0m');
  console.error('     BD: TABLE/VIEW name');
  console.error('     Detalhe:', err.message);
  res.status(500).json({ erro: err.message });
} finally {
  if (conn) await conn.close();
}
```

**Session fields (flat on `req.session`):**
```javascript
req.session.cod_funcionario   // VARCHAR2(12) — '0' for demo user
req.session.cod_biblioteca    // VARCHAR2(10)
req.session.nivel_acesso      // 'Administrador' | 'Coordenador' | 'Bibliotecario'
req.session.funcionario       // full object with uppercase keys (COD_FUNCIONARIO, etc.)
```

**Demo user guard (before DB calls, on any write that stores cod_funcionario as FK):**
```javascript
if (req.session.cod_funcionario === 0) {
  return res.status(400).json({ erro: 'Utilizador demo não pode realizar esta acção.' });
}
```

**Auth middleware:**
- `autenticar` — qualquer utilizador autenticado
- `exigirNivel('Administrador', 'Coordenador')` — restringe por nível (aceita N argumentos)

**Oracle 10g SQL rules:**
- Paginação: ROWNUM duplo (sem `FETCH FIRST` — é 12c+)
- Sem `LISTAGG` (é 11g+)
- Primary keys: `SEQ_NOME.NEXTVAL` + `RETURNING id INTO :id_out`
- Bind out: `{ dir: oracledb.BIND_OUT, type: oracledb.NUMBER }`
- Oracle devolve colunas em MAIÚSCULAS: `result.rows[0].COD_BIBLIOTECA`

**Paginação ROWNUM:**
```sql
SELECT * FROM (
  SELECT t.*, ROWNUM AS RN FROM (
    SELECT ... FROM tabela WHERE ... ORDER BY campo DESC
  ) t WHERE ROWNUM <= :rn_max
) WHERE RN > :rn_min
-- binds: rn_max = offset + limit, rn_min = offset
```

**Export (simples, não named):**
```javascript
module.exports = router;
```
Named exports só em `doacoes.js` (caso especial com dois routers).

**Montar em server.js:**
```javascript
// linha ~16 (imports)
const xRouter = require('./routes/x');
// linha ~51 (app.use)
app.use('/api/x', xRouter);
// linha 67 (log de arranque) — actualizar a string de rotas
```

## Language

All code, comments, UI text, and API error messages are in Portuguese (Portugal). Oracle column names are in uppercase (Oracle convention). Keep this consistent when adding features.

## Session Discipline

- Ler ROADMAP.md no início de cada sessão — trabalhar UMA tarefa de cada vez
- Frontend está bloqueado (ver ROADMAP.md Fase 4) enquanto houver tarefas de backend
- Cada sessão termina com commit — mesmo WIP
- Não editar resources/docs/ a não ser que seja estritamente necessário
- Para correcções de ficheiro único, executar directamente sem plan mode

## Commits

No final de cada alteração ou implementação concluída, fornecer sempre uma mensagem de commit pronta a usar, no formato:

```
tipo(âmbito): descrição curta em português

Corpo opcional se necessário.
```

Tipos: `feat`, `fix`, `refactor`, `docs`, `chore`. Exemplo:
```
feat(transferencias): implementar route completa §8 — GET lista, POST solicitar, PATCH aprovar/rejeitar/concluir
```
