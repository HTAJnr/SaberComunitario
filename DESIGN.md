# Design.md — Saber Comunitário

Documentação do sistema de design visual do frontend da aplicação de gestão de bibliotecas comunitárias.

---

## Visão Geral

A interface é uma **Single Page Application (SPA)** com tema escuro exclusivo. A linguagem visual é sóbria, densa em informação, e orientada para uso em ecrã de secretária. Não existe modo claro.

**Stack visual:**
- Tailwind CSS (CDN, com `darkMode: 'class'`)
- FontAwesome 6.5.2 (CDN)
- CSS customizado em `frontend/css/style.css`
- HTML do `<html>` com `class="dark"` sempre activo

---

## Paleta de Cores

### Fundos (camadas)

| Camada | Valor | Uso |
|--------|-------|-----|
| Fundo de página | `#0f172a` | Background geral, inputs |
| Sidebar / Cards | `#1e293b` | Painéis, cartões, sidebar |
| Hover / Destaque | `#334155` | Estados hover em elementos interactivos |

### Texto

| Nível | Cor | Uso |
|-------|-----|-----|
| Primário | `#ffffff` | Títulos, valores principais |
| Secundário | `#cbd5e1` | Texto de apoio, subtítulos |
| Terciário | `#94a3b8` | Labels, cabeçalhos de tabela |
| Desactivado / Placeholder | `#64748b` | Texto dimmed, placeholders |

### Bordas

| Tipo | Cor |
|------|-----|
| Principal | `#334155` |
| Subtil (linhas de tabela) | `#1e293b` |

### Cores de Acção

| Função | Cor | Hover |
|--------|-----|-------|
| Acção primária (botão, foco) | `#4f46e5` | `#4338ca` |
| Perigo / Eliminar | `#7f1d1d` | `#991b1b` |
| Sucesso | `#22c55e` | — |
| Aviso | `#eab308` | — |
| Informação | `#3b82f6` | — |

### Badges de Estado

| Nome | Fundo | Texto |
|------|-------|-------|
| Verde (activo, disponível) | `#14532d` | `#86efac` |
| Vermelho (suspenso, em falta) | `#7f1d1d` | `#fca5a5` |
| Amarelo (pendente, reservado) | `#713f12` | `#fcd34d` |
| Azul (informativo) | `#1e3a5f` | `#93c5fd` |
| Cinzento (inactivo, default) | `#1e293b` | `#94a3b8` |

### Ícones nos Cards de Dashboard

| Métrica | Fundo | Ícone |
|---------|-------|-------|
| Leitores | `bg-blue-900/40` | `#3b82f6` |
| Empréstimos | `bg-yellow-900/40` | `#eab308` |
| Materiais | `bg-green-900/40` | `#22c55e` |
| Multas / Alertas | `bg-red-900/40` | `#f87171` |

---

## Tipografia

**Fonte:** Sans-serif do sistema (default Tailwind — sem fonte custom importada).

| Contexto | Tamanho | Peso |
|----------|---------|------|
| Título de página | `text-xl` (20px) | 700 (bold) |
| Cabeçalho de secção | `text-lg` (18px) | 700 |
| Título de card | base | 600 (semibold) |
| Texto de botão | `text-sm` (14px) | 500–600 |
| Células de tabela | `text-sm` (14px) | 400 |
| Labels de formulário | `text-xs` (12px) | 500 |
| Texto auxiliar / IDs | `text-xs` (12px) | 400, cor `#64748b` |
| Navegação lateral | `text-sm` (14px) | 500 |

---

## Layout

### Estrutura Geral

```
┌─────────────────────────────────────────────┐
│  SIDEBAR (w-64 / 256px, fixo)  │  MAIN (flex-1, overflow-auto) │
│                                 │                                 │
│  Logo + Nome + Utilizador       │  Conteúdo da secção activa      │
│  Navegação vertical             │  (injectado dinamicamente)      │
│  Botão de Logout                │                                 │
└─────────────────────────────────────────────┘
```

### Sidebar

- Largura: `w-64` (256px), fixa
- Divisão interna: `flex flex-col` com 3 zonas:
  1. **Header** (`p-5`): logo 36×36px + nome da app + email do utilizador
  2. **Nav** (`flex-1 p-3`): links de navegação em coluna com `gap`
  3. **Footer** (`p-3`): botão de logout

### Main Content

- `flex-1`, `overflow-auto`
- Padding interno por secção: `p-6` (24px)
- Título de secção: `mb-6`, com separação visual

### Grids de Dashboard

```
Métricas:   grid-cols-2  →  lg:grid-cols-4
Cards info: grid-cols-1  →  lg:grid-cols-2
```

---

## Componentes

### Botões

```css
/* Primário */
.btn-primary {
  background: #4f46e5;
  color: white;
  font-weight: 600;
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
  transition: background 0.15s;
}
.btn-primary:hover { background: #4338ca; }

/* Secundário */
.btn-secondary {
  background: #1e293b;
  color: #94a3b8;
  border: 1px solid #475569;
  font-weight: 600;
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
}
.btn-secondary:hover { background: #334155; color: white; }

/* Ghost */
.btn-ghost {
  background: transparent;
  color: #94a3b8;
  border: 1px solid #475569;
  font-weight: 500;
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
}
.btn-ghost:hover { background: #334155; color: white; }

/* Perigo (pequeno) */
.btn-danger {
  background: #7f1d1d;
  color: #fca5a5;
  font-size: 0.75rem;
  padding: 0.3rem 0.75rem;
  border-radius: 0.375rem;
  font-weight: 500;
}
.btn-danger:hover { background: #991b1b; }

/* Modificador pequeno */
.btn-sm {
  padding: 0.25rem 0.625rem;
  font-size: 0.75rem;
  border-radius: 0.375rem;
}
```

### Inputs

```css
.input-dark {
  background: #0f172a;
  border: 1px solid #334155;
  color: white;
  border-radius: 0.5rem;
  padding: 0.5rem 0.75rem;
  font-size: 0.875rem;
  transition: border-color 0.15s;
}
.input-dark:focus { border-color: #6366f1; outline: none; }
.input-dark::placeholder { color: #64748b; }
```

**Input com ícone integrado:** o container é `relative`; o ícone é `absolute left-3 top-1/2 -translate-y-1/2 text-slate-500`; o input tem `pl-8`.

### Labels

```css
.label-dark {
  display: block;
  font-size: 0.75rem;
  color: #94a3b8;
  margin-bottom: 0.25rem;
  font-weight: 500;
}
```

### Cards

```css
.card {
  background: #1e293b;
  border: 1px solid #334155;
  border-radius: 0.75rem;
  padding: 1rem;
}
```

### Badges

```css
.badge {
  display: inline-block;
  padding: 0.125rem 0.5rem;
  border-radius: 9999px;
  font-size: 0.7rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
/* Variantes: .badge-green, .badge-red, .badge-yellow, .badge-blue, .badge-gray */
```

### Navegação Lateral

```css
.nav-link {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  padding: 0.5rem 0.75rem;
  border-radius: 0.5rem;
  font-size: 0.875rem;
  font-weight: 500;
  color: #94a3b8;
  transition: all 0.15s;
}
.nav-link:hover { background: #1e293b; color: white; }
.nav-link.active {
  background: #312e81;
  color: #a5b4fc;
  border-left: 2px solid #6366f1;
}
```

### Tabs

```css
.tab-btn {
  padding: 0.375rem 0.875rem;
  border-radius: 0.5rem;
  font-size: 0.875rem;
  font-weight: 500;
  color: #94a3b8;
  background: transparent;
  border: 1px solid #334155;
  transition: all 0.15s;
}
.tab-btn:hover { background: #1e293b; color: white; }
.tab-active {
  background: #312e81;
  color: #a5b4fc;
  border-color: #4338ca;
}
```

### Tabelas

- `w-full text-sm`
- Cabeçalho: `border-b border-slate-700`, texto `#94a3b8`
- Células: `py-2 px-3`
- Linhas do corpo: `border-b border-[#1e293b]`, hover `bg-[#0f172a]`, `transition: background 0.1s`
- Container: `overflow-x-auto` para scroll horizontal em ecrãs pequenos

### Modais

```
Overlay: fixed inset-0, bg-black/60, z-50
Box:     bg-slate-800, border border-slate-700, rounded-xl, max-w-xl, max-h-[90vh], shadow-2xl
Header:  p-5, border-b border-slate-700, flex justify-between, título + botão fechar
Content: p-5, overflow-y-auto
Error:   bg-red-900/50, border border-red-500, text-red-300, rounded-lg, p-3
Footer:  p-5, border-t border-slate-700, flex justify-end, gap-3
```

**Modal de confirmação:** z-[60] (acima do modal principal), box menor (`max-w-sm`), texto de aviso centrado, dois botões (cancelar + confirmar em vermelho).

**Formulários dentro de modais:**
- Layout padrão: `grid grid-cols-2 gap-3`
- Campos full-width: `col-span-2`
- Secções separadas: `mt-3 space-y-3`

### Toasts (Notificações)

```css
/* Posição: fixed bottom-6 right-6, z-50 */
/* Padding: px-5 py-3, rounded-xl, shadow-2xl, text-sm font-medium */

/* Sucesso: background #15803d, text #dcfce7 */
/* Erro:    background #7f1d1d, text #fee2e2 */
/* Duração: aparece 3s, fade-out com transition: opacity 0.3s */
```

---

## Sistema de Ícones

**Biblioteca:** FontAwesome 6.5.2 (CDN, classe `fa-solid`).

| Ícone | Classe FA | Contexto |
|-------|-----------|----------|
| Dashboard | `fa-chart-bar` | Nav |
| Leitores | `fa-users` | Nav, Dashboard |
| Materiais | `fa-book` | Nav |
| Empréstimos | `fa-arrow-right-arrow-left` | Nav, Dashboard |
| Funcionários | `fa-user-tie` | Nav |
| Eventos | `fa-calendar-days` | Nav |
| Doações | `fa-hand-holding-heart` | Nav |
| Logout | `fa-right-from-bracket` | Nav footer |
| Editar | `fa-pen` | Acção em tabela |
| Eliminar | `fa-trash` | Acção em tabela |
| Adicionar | `fa-plus` | Botão principal |
| Devolver | `fa-rotate-left` | Acção empréstimo |
| Guardar | `fa-floppy-disk` | Botão modal |
| Fechar | `fa-xmark` | Botão de fechar modal |
| Pesquisar | `fa-magnifying-glass` | Input de filtro |
| Email | `fa-envelope` | Login |
| Password | `fa-lock` | Login |
| Sucesso | `fa-circle-check` | Estado |
| Erro | `fa-circle-exclamation` | Estado, caixa de erro |

**Dimensionamento:**
- Navegação: dimensão herdada do texto
- Cabeçalhos de secção: `text-xl`
- Botões: `text-sm` com `mr-1` ou `mr-2` de espaçamento
- Cards de dashboard: `text-xl` dentro de container 48×48px

---

## Animações e Transições

### Animações definidas em `style.css`

| Classe | Comportamento |
|--------|---------------|
| `.spinner` | Rotação 360° em 0.8s, linear, infinito. Borda `#334155` com topo `#3b82f6` (efeito de carregamento) |
| `.fade-in` | opacity 0→1 + translateY(6px→0) em 0.3s ease-out |
| `.status-ok-pulse` | Pulso de glow verde (`drop-shadow #22c55e`) em 2s, ease-in-out, infinito |

### Transições em elementos interactivos

| Elemento | Propriedade | Duração |
|----------|-------------|---------|
| Botões | background / all | 0.15s |
| Inputs | border-color | 0.15s |
| Nav links | all | 0.15s |
| Tab buttons | all | 0.15s |
| Linhas de tabela | background | 0.1s |
| Modais / Toasts | opacity | 0.3s |

---

## Ecrã de Login

Estrutura visual distinta das secções internas:

- Fundo: página `#0f172a` com card central `bg-slate-800 border border-slate-700 rounded-2xl`
- Logo: 80×80px centrado no topo do card
- Título: `text-2xl font-bold text-white`
- Subtítulo: `text-slate-400 text-sm`
- Inputs com ícone integrado (ver padrão acima)
- Botão de login: `py-2.5` (maior altura), full-width, flex centrado
- Caixa de erro: `bg-red-900/50 border border-red-500`, animação `fade-in`

---

## Comportamento Responsivo

| Elemento | Móvel | Desktop (lg:) |
|----------|-------|--------------|
| Métricas dashboard | 2 colunas | 4 colunas |
| Cards de info | 1 coluna | 2 colunas |
| Tabelas | Scroll horizontal | Full width |
| Filtros | `flex-wrap` | Linha única |
| Sidebar | `w-64` fixo (sem adaptação para mobile implementada) | Igual |

---

## Marca

- **Nome:** Saber Comunitário
- **Logo:** `resources/imgs/Logo.png` — 36×36px na sidebar, 80×80px no login
- **Cor primária de marca:** Índigo (`#4f46e5`)
- **Cor de sucesso:** Verde (`#22c55e`)
- **Cor de perigo:** Vermelho (`#7f1d1d` fundo, `#fca5a5` texto)
- **Idioma:** Português de Portugal em toda a interface

---

## Hierarquia Visual Resumida

```
Fundo escuro (#0f172a)
  └── Sidebar / Cards (#1e293b)
        └── Texto primário: branco
        └── Texto secundário: #cbd5e1
        └── Labels / Cabeçalhos tabela: #94a3b8
        └── Placeholders / Texto mudo: #64748b
              └── Acções: índigo (#4f46e5) primário, vermelho (#7f1d1d) perigo
              └── Estados: verde (activo), amarelo (pendente), azul (info), cinza (inactivo)
```
