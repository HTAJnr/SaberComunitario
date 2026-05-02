# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

### API Health Checks

```
GET http://localhost:3000/api/test-connection   # Verify Oracle DB connection
GET http://localhost:3000/api/tables            # List all DB user tables
```

### Database Setup

Run once in Oracle SQL client:

```sql
@resources/scripts/Main.sql
```

This executes scripts in order: tables → sequences → views → functions → procedures → triggers → indexes.

## Architecture

### Backend (`backend/`)

- `server.js` — Express setup, mounts all routes under `/api`, serves `../frontend` as static files
- `db.js` — Oracle connection pool via `oracledb` (thick mode, requires Oracle Instant Client)
- `routes/` — One file per domain: `auth`, `dashboard`, `leitores`, `materiais`, `emprestimos`, `funcionarios`, `eventos`, `doacoes`

Every route follows the same pattern:

```javascript
let conn;
try {
  conn = await getConnection();
  const result = await conn.execute(query, params, { outFormat: oracledb.OUT_FORMAT_OBJECT });
  res.json(result.rows);
} catch (err) {
  res.status(500).json({ erro: err.message });
} finally {
  if (conn) await conn.close();
}
```

Session auth guard used in all protected routes:

```javascript
if (!req.session.funcionario) return res.status(401).json({ erro: 'Não autenticado.' });
```

### Frontend (`frontend/`)

- `index.html` — Layout shell: sidebar nav + `#conteudo-principal` div
- `js/main.js` — All SPA logic (~1400 lines): hash router, API wrappers, section loaders, modal builders
- `sections/*.html` — HTML templates injected into the main content area
- `css/style.css` — Dark theme base (Tailwind via CDN handles utilities)

Hash-based routing: `#dashboard`, `#leitores`, `#materiais`, `#emprestimos`, `#funcionarios`, `#eventos`, `#doacoes`. Each hash maps to a `carregar*()` async function.

Fetch wrapper in `main.js`:

```javascript
api(path, opts); // base wrapper — always includes credentials: 'include'
get(path);
post(path, body);
put(path, body);
del(path);
```

UI utilities: `toast(msg, tipo)`, `confirmar(msg, cb, opts)`, `badge(text, color)`, `badgeEstado(state)`, `fmtData(date)`, `fmtMoeda(value)`.

### Database (Oracle)

The Oracle instance is **Oracle Database 10g (SQL\*Plus 10.2)** running on a **CentOS 6.8 VM**. SQL syntax and features must be compatible with Oracle 10g — avoid functions or syntax introduced in later versions (e.g., `LISTAGG` is 11g+, `FETCH FIRST` is 12c+).

Key views used by the API (defined in `resources/scripts/Views.sql`):

- `vw_leitores_completos`, `vw_materiais_completos`, `vw_emprestimos_ativos`, `vw_historico_emprestimos`, `vw_metricas_sistema`

Tables use a supertype/subtype inheritance pattern:

- `LEITOR` → `ADULTO`, `CRIANCA`, `PROFESSOR`
- `MATERIAL_BIBLIOGRAFICO` → `LIVRO_FISICO`, `EBOOK`, `PERIODICO`

Multi-table inserts (main + subtype) must be committed together or rolled back.

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

**Dynamic WHERE building** (used throughout routes):

```javascript
let where = 'WHERE 1=1';
const params = {};
if (req.query.filtro) {
  where += ' AND CAMPO = :filtro';
  params.filtro = req.query.filtro;
}
```

**Modal pattern in frontend**: Each CRUD section builds form HTML dynamically, injects into `#modal-conteudo`, then reads values by element ID on submit.

**Demo login** (bypasses DB): `demo@biblioteca.mz` / `demo` — returns a hardcoded `DEMO_USER` object in `auth.js`.

## Frontend Work

Before making any changes to frontend files (`frontend/`), always read these docs in `resources/docs/` first:

- **`DESIGN.md`** — sistema de design completo: tokens de cor por tema de região, componentes CSS, tipografia, badges, modais, drawers. Todas as adições de UI devem seguir este documento.
- **`SCREENS.md`** — especificação ecrã a ecrã: campos, permissões por role, comportamentos de cada tela.
- **`frontend_guide.md`** — o que o frontend precisa do backend: rotas, payloads, formatos de resposta, erros padronizados.

**Correcção importante documentada:** A tabela `FUNCIONARIO` não tem `foto_path`. Avatares de funcionários são sempre iniciais. Ver §7.6 do DESIGN.md e §17 do frontend_guide.md.

## Language

All code, comments, UI text, and API error messages are in Portuguese (Portugal). Oracle column names are in uppercase (Oracle convention). Keep this consistent when adding features.
