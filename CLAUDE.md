# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Stack

- Primary language: JavaScript
- Documentation: Markdown
- Frontend: HTML/CSS

When creating new files, default to JavaScript unless specified otherwise. Follow existing code conventions in the repo.

## Editing Approach

- Prefer editing existing files over creating new ones
- Read the file first before making edits to understand context
- Use targeted Edit operations rather than rewriting whole files with Write

## Planning

- For multi-step tasks, present a plan before making changes
- Confirm scope on tasks touching 3+ files

## Project Overview

**Saber Comunitário** — a distributed community library management system (Trabalho Prático BD2). Node.js/Express REST API + vanilla JS SPA frontend + Oracle Database.

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
DB_HOST=XXX.XXX.XXX.XXX
DB_PORT=1521
DB_SERVICE=XE
DB_USER=userName
DB_PASSWORD=userPass
INSTANT_CLIENT_PATH=C:/instantclient_21_20
PORT=3000
NLS_LANG=AMERICAN_AMERICA.AL32UTF8
```

Oracle Instant Client must exist at `INSTANT_CLIENT_PATH` for the thick client mode (`oracledb.initOracleClient()`).

## Frontend JS Structure

`main.js` is the core — global state, HTTP helpers, auth, router, generic modals. All section logic lives in its own file:

| File                 | Contents                                                          |
| -------------------- | ----------------------------------------------------------------- |
| `js/componentes.js`  | Reusable helpers (`emptyState`, etc.) — **loads first**           |
| `js/dashboard.js`    | `carregarDashboard`, dashboard render helpers                     |
| `js/leitores.js`     | Reader wizard, drawer, modals                                     |
| `js/materiais.js`    | Materials CRUD                                                    |
| `js/emprestimos.js`  | Loans and returns                                                 |
| `js/funcionarios.js` | Staff CRUD                                                        |
| `js/eventos.js`      | Events and participations                                         |
| `js/doacoes.js`      | Donations, donors, certificates                                   |
| `js/main.js`         | Global state, auth, router — **loads last**                       |

**Mandatory rules:**

- `main.js` is always the **last** `<script>` in `index.html` — section files must be loaded before it because `sectionLoaders` references their functions directly.
- When adding a new section: create `js/<section>.js`, add `<script>` before `main.js` in `index.html`, and add an entry in `sectionLoaders` and `SECTION_TOPBAR` in `main.js`.
- **Never recreate inline** helpers that already exist in `componentes.js`. Always use `emptyState(icon, msg, sub?)` for empty states with the `.empty-state` class.
- Section-local state (`tabActual`, `idActual`, etc.) lives in the section file, not in `main.js`. Only `utilizadorActual` and `modalSalvarFn` live in `main.js`.

## Code Quality Rules

**DRY — Don't Repeat Yourself:**
- Before writing any helper, badge, layout block, or utility function, search for an existing equivalent.
- If a pattern appears (or will appear) in 2+ places, it belongs in `componentes.js`. Create it there and import via the existing script-load order.
- The shared helpers currently in `componentes.js`: `emptyState`, `campoDetalhe`, `secaoDetalhe`, `avatarCirculo`, `regiaoDeProvinccia`, `PROVINCIAS_SUL`, `PROVINCIAS_CENTRO`. Use these — never redefine inline.

**Frontend / Backend separation:**
- The backend must never contain hardcoded UI strings, HTML fragments, or presentation logic. It returns data; the frontend renders it.
- API responses use neutral field names and values (e.g., status codes as strings like `'Activo'`). Display labels, badge classes, and formatting live exclusively in frontend JS.

**Before touching the frontend — always check:**
1. The DB create script (`resources/` or `sql/`) to know the exact table/column names and constraints.
2. The corresponding backend route to know what the API actually returns (field names, shape, pagination).

**Before touching the backend — always check:**
1. The DB create script to confirm table structure, column types, constraints, sequences, and triggers that may fire automatically.

**Business rules — always verify:**
- Check for triggers that run automatically (e.g., certificate auto-generation on donation insert).
- Check for existing guards/validations so you don't duplicate or conflict with them.
- If a route writes data that has a FK dependency, confirm the referenced row exists before inserting.
- Return the correct HTTP status: 400 bad input, 404 not found, 409 conflict (duplicate / already exists), 403 forbidden.

## Key Patterns

**Modal pattern in frontend**: Each CRUD section builds form HTML dynamically, injects into `#modal-conteudo`, then reads values by element ID on submit.

**Demo login** (bypasses DB): `demo@biblioteca.mz` / `demo` — returns a hardcoded `DEMO_USER` object in `auth.js`.

## Backend Route Patterns

Every route file follows this exact structure — do not re-explore existing routes to learn these patterns:

**Imports:**

```javascript
const express = require('express');
const router = express.Router();
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
req.session.cod_funcionario; // VARCHAR2(12) — '0' for demo user
req.session.cod_biblioteca; // VARCHAR2(10)
req.session.nivel_acesso; // 'Administrador' | 'Coordenador' | 'Bibliotecario'
req.session.funcionario; // full object with uppercase keys (COD_FUNCIONARIO, etc.)
```

**Demo user guard (before DB calls, on any write that stores cod_funcionario as FK):**

```javascript
if (req.session.cod_funcionario === 0) {
  return res.status(400).json({ erro: 'Utilizador demo não pode realizar esta acção.' });
}
```

**Auth middleware:**

- `autenticar` — any authenticated user
- `exigirNivel('Administrador', 'Coordenador')` — restricts by level (accepts N arguments)

**Oracle 10g SQL rules:**

- Pagination: double ROWNUM (no `FETCH FIRST` — that's 12c+)
- No `LISTAGG` (that's 11g+)
- Primary keys: `SEQ_NAME.NEXTVAL` + `RETURNING id INTO :id_out`
- Bind out: `{ dir: oracledb.BIND_OUT, type: oracledb.NUMBER }`
- Oracle returns columns in UPPERCASE: `result.rows[0].COD_BIBLIOTECA`

**ROWNUM pagination:**

```sql
SELECT * FROM (
  SELECT t.*, ROWNUM AS RN FROM (
    SELECT ... FROM tabela WHERE ... ORDER BY campo DESC
  ) t WHERE ROWNUM <= :rn_max
) WHERE RN > :rn_min
-- binds: rn_max = offset + limit, rn_min = offset
```

**Export (simple, not named):**

```javascript
module.exports = router;
```

Named exports only in `doacoes.js` (special case with two routers).

**Mounting in server.js:**

```javascript
// line ~16 (imports)
const xRouter = require('./routes/x');
// line ~51 (app.use)
app.use('/api/x', xRouter);
// line 67 (startup log) — update the routes string
```

## Language

All code, comments, UI text, and API error messages are in Portuguese (Portugal). Oracle column names are in uppercase (Oracle convention). Keep this consistent when adding features.

## Session Discipline

- Work ONE task at a time
- Each session ends with a commit — even WIP
- For single-file fixes, execute directly without plan mode

## Permissions Matrix

`nivel_acesso` comes from `FUNCAO_FUNCIONARIO.nivel_acesso`: `'Administrador'` | `'Coordenador'` | `'Bibliotecario'` | `'Assistente'`

| Módulo                            | Admin | Coord | Biblio | Assist |
| --------------------------------- | ----- | ----- | ------ | ------ |
| Dashboard (rede)                  | ✓     | —     | —      | —      |
| Dashboard (biblioteca)            | ✓     | ✓     | ✓      | ✓      |
| Leitores — ver lista              | ✓     | ✓     | ✓      | ✓      |
| Leitores — cadastrar              | ✓     | ✓     | ✓      | ✓      |
| Leitores — editar                 | ✓     | ✓     | ✓      | —      |
| Leitores — eliminar               | ✓     | —     | —      | —      |
| Leitores — alterar status         | ✓     | ✓     | —      | —      |
| Empréstimos — ver                 | ✓     | ✓     | ✓      | ✓      |
| Empréstimos — criar               | ✓     | ✓     | ✓      | ✓      |
| Empréstimos — devolver            | ✓     | ✓     | ✓      | ✓      |
| Empréstimos — eliminar            | ✓     | —     | —      | —      |
| Multas — marcar paga              | ✓     | ✓     | ✓      | —      |
| Materiais — ver                   | ✓     | ✓     | ✓      | ✓      |
| Materiais — adicionar             | ✓     | ✓     | ✓      | —      |
| Materiais — editar                | ✓     | ✓     | ✓      | —      |
| Materiais — eliminar              | ✓     | ✓     | —      | —      |
| Transferências — ver              | ✓     | ✓     | —      | —      |
| Transferências — solicitar        | ✓     | ✓     | —      | —      |
| Transferências — aprovar/rejeitar | ✓     | ✓     | —      | —      |
| Eventos — ver                     | ✓     | ✓     | ✓      | ✓      |
| Eventos — criar/editar            | ✓     | ✓     | ✓      | —      |
| Eventos — cancelar                | ✓     | ✓     | —      | —      |
| Eventos — gerir participantes     | ✓     | ✓     | ✓      | ✓      |
| Doações — ver                     | ✓     | ✓     | ✓      | —      |
| Doações — registar                | ✓     | ✓     | —      | —      |
| Certificados — emitir             | ✓     | ✓     | —      | —      |
| Programas — ver                   | ✓     | ✓     | ✓      | ✓      |
| Programas — criar/editar          | ✓     | ✓     | —      | —      |
| Programas — gerir participantes   | ✓     | ✓     | ✓      | —      |
| Funcionários — ver                | ✓     | ✓     | —      | —      |
| Funcionários — cadastrar/editar   | ✓     | ✓     | —      | —      |
| Funcionários — eliminar           | ✓     | —     | —      | —      |
| Permissões — ver/gerir            | ✓     | —     | —      | —      |
| Bibliotecas (rede)                | ✓     | —     | —      | —      |
| Biblioteca (própria)              | ✓     | ✓     | —      | —      |
| Suspensões — reduzir              | ✓     | ✓     | —      | —      |

## Commits

At the end of each completed change or implementation, always provide a ready-to-use commit message in the format:

```
type(scope): short description in Portuguese

Optional body if needed.
```

Types: `feat`, `fix`, `refactor`, `docs`, `chore`. Example:

```
feat(transferencias): implementar route completa §8 — GET lista, POST solicitar, PATCH aprovar/rejeitar/concluir
```
