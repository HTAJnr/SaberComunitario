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

## Language

All code, comments, UI text, and API error messages are in Portuguese (Portugal). Oracle column names are in uppercase (Oracle convention). Keep this consistent when adding features.

## Session Discipline

- Ler ROADMAP.md no início de cada sessão — trabalhar UMA tarefa de cada vez
- Frontend está bloqueado (ver ROADMAP.md Fase 4) enquanto houver tarefas de backend
- Cada sessão termina com commit — mesmo WIP
- Não editar resources/docs/ a não ser que seja estritamente necessário
- Para correcções de ficheiro único, executar directamente sem plan mode
