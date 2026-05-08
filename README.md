# Saber Comunitário

Sistema de Gestão de Bibliotecas Comunitárias Distribuído — Trabalho Prático BD2 (ISCTEM).
Node.js + Express + Oracle 10g XE · Frontend vanilla HTML/JS · BD distribuída em 4 nós.

---

## Pré-requisitos

| Ferramenta | Versão mínima | Notas |
|---|---|---|
| [Node.js](https://nodejs.org/) | 18 LTS | Inclui npm |
| [Oracle Instant Client Basic](https://www.oracle.com/database/technologies/instant-client/downloads.html) | 21.x | **Obrigatório** — modo espesso (thick) |
| Git | qualquer | Para clonar e gerir branches |
| VM CentOS 6.8 com Oracle XE | — | Fornecida pelo professor |

---

## 1 · Oracle Instant Client

O driver `oracledb` usa o modo espesso, que exige os binários nativos do Instant Client instalados na máquina.

### Windows

1. Descarrega o **Basic Package (ZIP)** para Windows 64-bit:  
   [oracle.com → Instant Client → Windows x86-64](https://www.oracle.com/database/technologies/instant-client/winx64-64-downloads.html)

2. Descomprime o ZIP directamente em `C:\instantclient_21_20`  
   (o nome da pasta tem de coincidir com o que puseres em `INSTANT_CLIENT_PATH` no `.env`)

3. Adiciona a pasta ao `PATH` do sistema:  
   - Pesquisa **"Variáveis de ambiente"** no menu Iniciar  
   - Em **Variáveis do sistema** → `Path` → **Editar** → **Novo** → `C:\instantclient_21_20`  
   - Clica OK em tudo e abre um novo terminal

4. Verifica:
   ```cmd
   where oci.dll
   ```
   Deve devolver `C:\instantclient_21_20\oci.dll`.

> **Alternativa rápida:** se não quiseres mexer no PATH do sistema, define correctamente o `INSTANT_CLIENT_PATH` no `.env` — o `db.js` chama `oracledb.initOracleClient({ libDir })` com esse caminho.

---

### macOS

1. Descarrega o **Basic Package (ZIP)**:
   - Intel (x86_64): [Instant Client macOS Intel](https://www.oracle.com/database/technologies/instant-client/macos-intel-x86-downloads.html)
   - Apple Silicon (ARM64): [Instant Client macOS ARM64](https://www.oracle.com/database/technologies/instant-client/macos-arm64-downloads.html)

2. Descomprime para `~/instantclient_21_20` ou `/opt/oracle/instantclient_21_20`

3. Adiciona à biblioteca dinâmica:
   ```bash
   export DYLD_LIBRARY_PATH=~/instantclient_21_20:$DYLD_LIBRARY_PATH
   ```
   Para persistir, adiciona essa linha ao `~/.zshrc` (ou `~/.bash_profile`) e executa `source ~/.zshrc`.

4. macOS Catalina ou superior — remove a quarentena dos binários:
   ```bash
   xattr -d com.apple.quarantine ~/instantclient_21_20/*.dylib 2>/dev/null || true
   ```

5. Actualiza `INSTANT_CLIENT_PATH` no `.env`:
   ```
   INSTANT_CLIENT_PATH=/Users/<teu-utilizador>/instantclient_21_20
   ```

---

### Linux

**Opção A — RPM (Red Hat / CentOS / Fedora):**
```bash
sudo rpm -ivh oracle-instantclient21.20-basic-21.20.0.0.0-1.x86_64.rpm
# Caminho instalado: /usr/lib/oracle/21.20/client64/lib
```

**Opção B — ZIP:**
```bash
mkdir -p /opt/oracle
cd /opt/oracle
unzip instantclient-basic-linux.x64-21.20.0.0.0.zip
# Fica em /opt/oracle/instantclient_21_20
```

Configura a biblioteca dinâmica (permanente):
```bash
sudo sh -c "echo /opt/oracle/instantclient_21_20 > /etc/ld.so.conf.d/oracle-instantclient.conf"
sudo ldconfig
```

Ou por sessão:
```bash
export LD_LIBRARY_PATH=/opt/oracle/instantclient_21_20:$LD_LIBRARY_PATH
```

Actualiza `INSTANT_CLIENT_PATH` no `.env`:
```
INSTANT_CLIENT_PATH=/opt/oracle/instantclient_21_20
```

---

## 2 · Configurar o .env

Recebeste um ficheiro `backend/.env.example`. Renomeia-o para `.env`:

```bash
# Windows
copy backend\.env.example backend\.env

# macOS / Linux
cp backend/.env.example backend/.env
```

Depois edita `backend/.env` com os teus valores:

| Variável | Significado | Exemplo |
|---|---|---|
| `DB_HOST` | IP da VM CentOS onde corre o Oracle XE | `172.20.10.11` |
| `DB_PORT` | Porta Oracle (padrão) | `1521` |
| `DB_SERVICE` | Nome do serviço Oracle | `XE` |
| `DB_USER` | Utilizador da base de dados | `JnrLite` |
| `DB_PASSWORD` | Palavra-passe do utilizador | `1234` |
| `INSTANT_CLIENT_PATH` | Caminho absoluto para o Instant Client | `C:/instantclient_21_20` |
| `PORT` | Porta do servidor Express | `3000` |
| `NLS_LANG` | Charset Oracle (não alterar) | `AMERICAN_AMERICA.AL32UTF8` |

> `INSTANT_CLIENT_PATH` usa barras `/` mesmo no Windows — o Node.js aceita nos dois sentidos, mas o driver Oracle prefere `/`.

---

## 3 · Instalar dependências e arrancar

```bash
cd backend
npm install
npm start
```

Para desenvolvimento com reinício automático em cada alteração de ficheiro:
```bash
npm run dev
```

Abre o browser em **http://localhost:3000**

---

## 4 · Login de demonstração

Para testar o frontend **sem base de dados**, usa:

| Campo | Valor |
|---|---|
| Email | `demo@biblioteca.mz` |
| Palavra-passe | `demo` |

Este utilizador é simulado em memória (`auth.js`) e não faz qualquer query à BD — útil para ver o layout enquanto a VM não está disponível.

---

## 5 · Scripts Oracle (inicializar a BD)

Os scripts SQL estão em `resources/scripts/`. Executa na VM CentOS com `sqlplus` na seguinte ordem:

```sql
@Main.sql          -- Cria tablespaces, utilizadores, permissões
@Sequences.sql     -- Sequências para PKs automáticas
@Functions.sql     -- Funções PL/SQL
@Procedures.sql    -- Procedures PL/SQL
@Triggers.sql      -- Triggers de negócio
@Views.sql         -- Vistas e fragmentos
@Indexes.sql       -- Índices de desempenho
@Biblioteca_Intro.sql  -- Dados iniciais (bibliotecas, funcionários de teste)
```

---

## 6 · Estrutura do projecto

```
TP_BD2_WEB/
├── backend/
│   ├── .env.example        ← copia para .env e preenche
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
│       ├── bibliotecas.js
│       └── ...
├── frontend/
│   ├── index.html          ← SPA única — tudo é injectado aqui
│   ├── css/style.css
│   ├── js/
│   │   ├── componentes.js  ← helpers partilhados (carrega PRIMEIRO)
│   │   ├── dashboard.js
│   │   ├── leitores.js
│   │   ├── materiais.js
│   │   ├── emprestimos.js
│   │   ├── eventos.js
│   │   ├── doacoes.js
│   │   ├── transferencias.js
│   │   ├── programas.js
│   │   └── main.js         ← estado global e router (carrega POR ÚLTIMO)
│   └── sections/           ← templates HTML injectados pelo router
└── resources/
    ├── docs/               ← DD v3, Regras de Negócio, Enunciado PDF
    └── scripts/            ← scripts SQL Oracle
```

---

## 7 · Níveis de acesso

| Nível | Descrição resumida |
|---|---|
| `Administrador` | Acesso total — rede, bibliotecas, funcionários, permissões |
| `Coordenador` | Gestão operacional completa da sua biblioteca |
| `Bibliotecario` | Operações do dia-a-dia — materiais, empréstimos, eventos |
| `Assistente` | Consulta e operações básicas de atendimento |

---

## 8 · Workflow de colaboração (Git)

### Branches

Cada membro trabalha na sua branch dedicada:

| Membro | Branch | Nó de BD |
|---|---|---|
| Yasin | `feature/yasin-materiais` | MateriaisDB |
| Yannis | `feature/yannis-emprestimos` | EmpréstimosDB |
| Hélder | `feature/helder-biblioteca-nacional` | BibliotecaNacionalDB |
| Gerson | `feature/gerson-eventos` | EventosBibliotecasDB |

### Regras

- **Nunca faças push directamente para `main`** — só via Pull Request
- Trabalha exclusivamente na tua branch
- Só abres PR quando o código compila e testaste manualmente
- Antes de abrir PR, sincroniza com `main`:
  ```bash
  git fetch origin
  git merge origin/main
  ```

### Comandos do dia-a-dia

```bash
# Clonar e ir para a tua branch
git clone <url-do-repositorio>
git checkout feature/<tua-branch>

# Fazer commit do teu trabalho
git add backend/routes/materiais.js
git commit -m "feat(materiais): trigger de protecção de transferência RN06"

# Publicar e abrir Pull Request
git push origin feature/<tua-branch>
# → GitHub → Compare & pull request
```

### Branch protection no GitHub (configurar pelo dono do repo)

1. Repositório → **Settings** → **Branches** → **Add branch ruleset**
2. Target: `main`
3. Activar:
   - ✅ Require a pull request before merging
   - ✅ Require at least 1 approval
   - ✅ Do not allow bypassing the above settings
     
---

## Dependências do backend

| Pacote | Versão | Função |
|---|---|---|
| `express` | ^4.19.2 | Framework REST API |
| `oracledb` | ^6.6.0 | Driver Oracle (thick mode) |
| `dotenv` | ^16.4.5 | Carregar variáveis do `.env` |
| `cors` | ^2.8.5 | Cross-origin para o frontend |
| `express-session` | ^1.19.0 | Gestão de sessão do utilizador |
| `bcryptjs` | ^3.0.3 | Hash de palavras-passe |
