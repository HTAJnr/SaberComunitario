# Saber Comunitário

Sistema de Gestão de Bibliotecas Comunitárias Distribuído — Trabalho Prático BD2 (ISCTEM).  
Node.js + Express + Oracle 10g XE · Frontend vanilla HTML/JS · Base de dados distribuída em 4 nós Oracle.

---

## Arquitectura do sistema

O sistema é composto por quatro nós Oracle independentes, cada um a correr numa VM CentOS 6.8, e por uma aplicação web que acede ao nó principal via driver `oracledb`.

| Nó | Schema | VM | Módulo |
|---|---|---|---|
| BibliotecaNacionalDB | `usr_NACIONALDB` | VM Hélder | Leitores, funcionários, bibliotecas |
| MateriaisDB | `usr_materiaisdb` | VM Yasin | Materiais, transferências, doações |
| EmpréstimosDB | `usr_emprestimosdb` | VM Yannis | Empréstimos, multas, programas |
| EventosBibliotecasDB | `usr_eventosdb` | VM Gerson | Eventos, participações, horários |

Os nós comunicam entre si através de **Database Links** Oracle e partilham dados via **Snapshots** (Materialized Views) e **Sinónimos públicos**.

---

## Instalação da base de dados

### Pré-requisito único (1 vez, antes da primeira instalação em cada VM)

```sql
ALTER SYSTEM SET audit_trail = 'DB' SCOPE = SPFILE;
SHUTDOWN IMMEDIATE;
STARTUP;
```

### Instalar cada nó

Em cada VM, copiar todos os ficheiros da pasta correspondente para `/root/TP/` (ou o caminho configurado nos scripts) e executar o script principal como SYSDBA:

**BibliotecaNacionalDB** (VM do Hélder):
```bash
sqlplus sys/"bd2.isctem" as sysdba @/root/TP/BibNacional_Main.sql
```

**MateriaisDB** (VM do Yasin):
```bash
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
sqlplus sys/bd2.isctem as sysdba @/root/No_MateriaisDB/MateriaisDB_Main.sql
```

**EmpréstimosDB** (VM do Yannis):
```bash
sqlplus / as sysdba @/root/TP/EmprestimosDB_Main.sql
```

**EventosBibliotecasDB** (VM do Gerson):
```bash
sqlplus sys/bd2.isctem as sysdba @/root/TP/EventosDB_Main.sql
```

O script `*_Main.sql` de cada nó instala tudo pela ordem correcta: tablespaces → utilizadores → roles → database links → snapshots → sinónimos → tabelas → sequências → vistas → funções → procedures → triggers → índices → grants → dados iniciais → auditoria.

> **Nota sobre snapshots:** os snapshots de cada nó dependem de grants concedidos por outros nós. Após todos os nós estarem instalados e os grants cross-node aplicados, os snapshots comentados nos scripts `*_Main.sql` podem ser descomentados e executados.

---

## Scripts SQL — estrutura de cada nó

```
resources/scripts/
├── BibliotecaNacional/
│   ├── BibNacional_Main.sql         ← ponto de entrada (executar este)
│   ├── BibNacional_Tablespaces.sql
│   ├── BibNacional_Users.sql
│   ├── BibNacional_Roles.sql
│   ├── BibNacional_Database_Links.sql
│   ├── BibNacional_Snapshots.sql
│   ├── BibNacional_Synonyms.sql
│   ├── BibNacional_Create.sql
│   ├── BibNacional_Sequences.sql
│   ├── BibNacional_Views.sql
│   ├── BibNacional_Functions.sql
│   ├── BibNacional_Procedures.sql
│   ├── BibNacional_Triggers.sql
│   ├── BibNacional_Indexes.sql
│   ├── BibNacional_Grants.sql
│   ├── BibNacional_Intro.sql        ← dados iniciais
│   └── BibNacional_Audit.sql
├── MateriaisDB/        (estrutura idêntica, prefixo MateriaisDB_)
├── Emprestimos/        (estrutura idêntica, prefixo EmprestimosDB_)
└── Eventos/            (estrutura idêntica, prefixo EventosDB_)
```

---

## Instalação da aplicação web

### Pré-requisitos

| Ferramenta | Versão mínima |
|---|---|
| Node.js | 18 LTS |
| Oracle Instant Client Basic | 21.x |

### Oracle Instant Client

O driver `oracledb` usa o modo espesso, que exige os binários nativos do Instant Client.

**Windows:** descarregar o Basic Package (ZIP) de [oracle.com](https://www.oracle.com/database/technologies/instant-client/winx64-64-downloads.html), descomprimir em `C:\instantclient_21_20` e adicionar essa pasta ao `PATH` do sistema.

**macOS:** descomprimir em `~/instantclient_21_20` e adicionar ao `DYLD_LIBRARY_PATH`:
```bash
export DYLD_LIBRARY_PATH=~/instantclient_21_20:$DYLD_LIBRARY_PATH
```

**Linux:**
```bash
sudo sh -c "echo /opt/oracle/instantclient_21_20 > /etc/ld.so.conf.d/oracle-instantclient.conf"
sudo ldconfig
```

### Configurar o ficheiro `.env`

Copiar `backend/.env.example` para `backend/.env` e preencher:

| Variável | Descrição | Exemplo |
|---|---|---|
| `DB_HOST` | IP da VM Oracle | `172.20.10.11` |
| `DB_PORT` | Porta Oracle | `1521` |
| `DB_SERVICE` | Nome do serviço | `XE` |
| `DB_USER` | Utilizador do schema | `usr_NACIONALDB` |
| `DB_PASSWORD` | Palavra-passe | `HTAJnr#020403` |
| `INSTANT_CLIENT_PATH` | Caminho do Instant Client | `C:/instantclient_21_20` |
| `PORT` | Porta da aplicação | `3000` |
| `NLS_LANG` | Charset (não alterar) | `AMERICAN_AMERICA.AL32UTF8` |

### Arrancar a aplicação

```bash
cd backend
npm install
npm start
```

Abre o browser em **http://localhost:3000**

---

## Estrutura do projecto

```
TP_BD2_WEB/
├── backend/
│   ├── .env.example
│   ├── server.js           ← ponto de entrada Express
│   ├── db.js               ← ligação Oracle (thick mode)
│   ├── middleware/
│   │   └── permissoes.js   ← autenticação e controlo de acesso
│   └── routes/             ← uma rota por módulo
│       ├── auth.js
│       ├── leitores.js
│       ├── materiais.js
│       ├── emprestimos.js
│       ├── funcionarios.js
│       ├── eventos.js
│       ├── doacoes.js
│       ├── transferencias.js
│       ├── programas.js
│       └── bibliotecas.js
├── frontend/
│   ├── index.html          ← SPA — toda a interface é injectada aqui
│   ├── css/style.css
│   └── js/
│       ├── componentes.js  ← helpers partilhados (carrega primeiro)
│       ├── dashboard.js
│       ├── leitores.js
│       ├── materiais.js
│       ├── emprestimos.js
│       ├── eventos.js
│       ├── doacoes.js
│       ├── transferencias.js
│       ├── programas.js
│       └── main.js         ← estado global e router (carrega por último)
└── resources/
    ├── docs/               ← Dicionário de Dados, Regras de Negócio, Enunciado
    └── scripts/            ← scripts SQL Oracle (4 nós)
```

---

## Níveis de acesso

| Nível | Descrição |
|---|---|
| `Administrador` | Acesso total — rede, bibliotecas, funcionários, permissões |
| `Coordenador` | Gestão operacional completa da biblioteca |
| `Bibliotecario` | Operações do dia-a-dia — materiais, empréstimos, eventos |
| `Assistente` | Consulta e operações básicas de atendimento |

---

## Login de demonstração

Para testar o frontend sem base de dados configurada:

| Campo | Valor |
|---|---|
| Email | `demo@biblioteca.mz` |
| Palavra-passe | `demo` |

Este utilizador é simulado em memória e não efectua qualquer query à base de dados.

---

## Dependências do backend

| Pacote | Versão | Função |
|---|---|---|
| `express` | ^4.19.2 | Framework REST API |
| `oracledb` | ^6.6.0 | Driver Oracle (thick mode) |
| `dotenv` | ^16.4.5 | Variáveis de ambiente |
| `cors` | ^2.8.5 | Cross-origin |
| `express-session` | ^1.19.0 | Gestão de sessão |
| `bcryptjs` | ^3.0.3 | Hash de palavras-passe |
