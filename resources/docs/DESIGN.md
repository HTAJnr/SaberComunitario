# DESIGN.md — Saber Comunitário

## Sistema de Design — Regras Absolutas para o Claude Code

---

## 1. Identidade Visual

**Nome da app:** Saber Comunitário  
**Subtítulo:** Fundo Bibliográfico de Moçambique  
**Logo:** Ver na pasta imgs em resources, tem todas lá

---

## 2. Sistema de Temas por Região

A cor do tema é determinada pela `provincia` da biblioteca do funcionário logado. Carregada no login, aplicada via CSS custom properties no `<html>` ou `<body>`.

### Regiões e Províncias

| Região | Províncias                                       | CSS class      |
| ------ | ------------------------------------------------ | -------------- |
| Sul    | Maputo Cidade, Maputo Província, Gaza, Inhambane | `theme-sul`    |
| Centro | Sofala, Manica, Tete, Zambézia                   | `theme-centro` |
| Norte  | Nampula, Cabo Delgado, Niassa                    | `theme-norte`  |

### Tokens de Cor por Tema

```css
/* === TEMA SUL (padrão) === */
.theme-sul {
  --theme-sidebar-bg: #063a35;
  --theme-sidebar-hover: rgba(255, 255, 255, 0.07);
  --theme-sidebar-active: rgba(255, 255, 255, 0.12);
  --theme-accent: #1aab96;
  --theme-accent-light: #e1f5ee;
  --theme-accent-text: #0f6e56;
  --theme-accent-border: #5dcaa5;
  --theme-pill-bg: #e1f5ee;
  --theme-pill-text: #0f6e56;
  --theme-pill-border: #5dcaa5;
  --theme-region-label: 'Sul de Moçambique';
}

/* === TEMA CENTRO === */
.theme-centro {
  --theme-sidebar-bg: #2a3010;
  --theme-sidebar-hover: rgba(255, 255, 255, 0.07);
  --theme-sidebar-active: rgba(255, 255, 255, 0.12);
  --theme-accent: #8fa830;
  --theme-accent-light: #eaf3de;
  --theme-accent-text: #3b6d11;
  --theme-accent-border: #97c459;
  --theme-pill-bg: #eaf3de;
  --theme-pill-text: #3b6d11;
  --theme-pill-border: #97c459;
}

/* === TEMA NORTE === */
.theme-norte {
  --theme-sidebar-bg: #3d1c04;
  --theme-sidebar-hover: rgba(255, 255, 255, 0.07);
  --theme-sidebar-active: rgba(255, 255, 255, 0.12);
  --theme-accent: #e07820;
  --theme-accent-light: #faeeda;
  --theme-accent-text: #854f0b;
  --theme-accent-border: #ef9f27;
  --theme-pill-bg: #faeeda;
  --theme-pill-text: #854f0b;
  --theme-pill-border: #ef9f27;
}
```

Usar sempre `var(--theme-accent)` etc. nos componentes. Nunca hardcodar cores de acento.

---

## 3. Layout Base (App Shell)

```
┌─────────────────────────────────────────────────────────┐
│  SIDEBAR (210px fixo)  │  MAIN CONTENT (flex: 1)        │
│  ─────────────────────  │  ──────────────────────────── │
│  [Logo + Nome]          │  TOPBAR (48px)                 │
│  [Região + Biblioteca]  │  ──────────────────────────── │
│  [Nav items]            │  CONTENT AREA (scroll)         │
│  ...                    │                                │
│  [User footer]          │                                │
└─────────────────────────────────────────────────────────┘
```

- Sidebar: `width: 210px`, `min-width: 210px`, `background: var(--theme-sidebar-bg)`, `height: 100vh`, `position: fixed` ou `flex-shrink: 0`
- Main: `flex: 1`, `overflow: hidden`, `display: flex`, `flex-direction: column`
- Content area: `flex: 1`, `overflow-y: auto`, `padding: 20px 24px`, `background: #f7f7f5` (light) / `#1a1a1a` (dark)

---

## 4. Sidebar — Anatomia

```
[Logo 34px] [Saber Comunitário / Fundo Bibliográfico]
─────────────────────────────────────────────
REGIÃO: Sul de Moçambique          (label muted)
[■ Bib. Esperança      ⌄]          (selector)
   BIBMPM0001 · Maputo
─────────────────────────────────────────────
Principal
  ▣ Dashboard
  ◉ Leitores               [badge]
  ⇄ Empréstimos
  ▦ Materiais

Operações
  ⇆ Transferências         [badge]
  ◈ Eventos
  ◇ Doações
  ◎ Prog. Alfabetização

Gestão
  ⬡ Funcionários
  ⊞ Biblioteca
  ⚙ Permissões             (só Admin/Coord)
─────────────────────────────────────────────
[Avatar] Nome do utilizador
         Função
```

**Nav item activo:** `border-left: 2px solid var(--theme-accent)`, `background: var(--theme-sidebar-active)`, `color: white`  
**Nav item hover:** `background: var(--theme-sidebar-hover)`, `color: rgba(255,255,255,0.85)`  
**Nav item normal:** `color: rgba(255,255,255,0.55)`

**Badge de notificação:** `background: rgba(255,80,80,0.22)`, `color: #ff9999`, `font-size: 10px`, `border-radius: 8px`, `padding: 1px 6px`

---

## 5. Topbar

Altura: `48px`. Fundo: branco (light mode). Bordas: `border-bottom: 0.5px solid #e5e5e5`.

**Esquerda:** título da página (14px, weight 500) + subtítulo (11px, muted)  
**Direita:** region pill + sino de notificações

**Region pill:**

```css
.region-pill {
  font-size: 10px;
  font-weight: 500;
  padding: 3px 10px;
  border-radius: 20px;
  background: var(--theme-pill-bg);
  color: var(--theme-pill-text);
  border: 0.5px solid var(--theme-pill-border);
}
```

---

## 6. Tipografia

| Uso                      | Tamanho | Weight  | Cor                                       |
| ------------------------ | ------- | ------- | ----------------------------------------- |
| Título de página         | 14px    | 500     | `#111`                                    |
| Subtítulo/meta           | 11px    | 400     | `#888`                                    |
| Label de secção sidebar  | 9px     | 500     | `rgba(255,255,255,0.28)`                  |
| Nav item                 | 12.5px  | 400/500 | ver sidebar                               |
| Rótulo de stat card      | 10px    | 400     | `#888`                                    |
| Valor de stat card       | 22–24px | 500     | `#111`                                    |
| Texto de tabela          | 12px    | 400     | `#111`                                    |
| Header de tabela         | 9px     | 500     | `#888`, uppercase, letter-spacing: 0.06em |
| Código (num_cartao, cod) | 10–11px | 400     | `#888`, `font-family: monospace`          |
| Badge                    | 9–10px  | 500     | ver badges                                |

**Fonte:** `system-ui, -apple-system, sans-serif` para o corpo. `monospace` para códigos.

---

## 7. Componentes Comuns

### 7.1 Stat Card

```
┌──────────────────────┐
│ ▬▬▬  (accent bar)    │  ← 3px height, 28px width, var(--theme-accent)
│ Empréstimos activos  │  ← 10px, muted
│ 24                   │  ← 22px, weight 500
│ ↑ +3 esta semana     │  ← 10px, verde (#1d9e75) ou vermelho (#e24b4a)
└──────────────────────┘
background: white, border: 0.5px solid #e5e5e5, border-radius: 8px, padding: 12px 14px
```

### 7.2 Badges de Status (Leitor)

```css
.badge-activo {
  background: #e1f5ee;
  color: #0f6e56;
}
.badge-suspenso {
  background: #faeeda;
  color: #854f0b;
}
.badge-bloqueado {
  background: #fcebeb;
  color: #a32d2d;
}
/* Todos: font-size: 9px, font-weight: 500, padding: 2px 7px, border-radius: 10px */
```

### 7.3 Badges de Tipo de Leitor

```css
.badge-adulto {
  background: #e6f1fb;
  color: #185fa5;
}
.badge-professor {
  background: #eeedfe;
  color: #533ab7;
}
.badge-crianca {
  background: #e1f5ee;
  color: #0f6e56;
}
```

### 7.4 Badges de Transferência / Empréstimo

```css
.badge-pendente {
  background: #faeeda;
  color: #854f0b;
}
.badge-aprovada {
  background: #e1f5ee;
  color: #0f6e56;
}
.badge-rejeitada {
  background: #fcebeb;
  color: #a32d2d;
}
.badge-concluida {
  background: #f1efe8;
  color: #5f5e5a;
}
.badge-activo {
  background: #e1f5ee;
  color: #0f6e56;
}
.badge-vencido {
  background: #fcebeb;
  color: #a32d2d;
}
```

### 7.5 Tabela de Dados

```css
table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}
th {
  font-size: 9px;
  font-weight: 500;
  color: #888;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  padding: 0 12px 10px;
  border-bottom: 0.5px solid #e5e5e5;
  text-align: left;
}
td {
  padding: 10px 12px;
  border-bottom: 0.5px solid #f0f0f0;
  color: #111;
}
tr:last-child td {
  border-bottom: none;
}
tr:hover td {
  background: #fafafa;
}
```

### 7.6 Avatar de Funcionário (iniciais)

A tabela `FUNCIONARIO` **não tem** coluna `foto_path`. Funcionários usam **sempre** avatar com iniciais — sem suporte a foto de perfil.

```html
<div class="avatar-initials">AM</div>
```

```css
.avatar-initials {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  overflow: hidden;
  flex-shrink: 0;
  background: var(--theme-accent-light);
  color: var(--theme-accent-text);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 500;
}
```

> **Nota:** `foto_path` existe em `LEITOR` mas **não é exibido na interface** — leitores também usam avatar com iniciais. Materiais não têm imagem. Nenhuma entidade tem foto visível na UI.

### 7.7 Botão Primário

```css
.btn-primary {
  background: var(--theme-accent);
  color: white;
  border: none;
  border-radius: 6px;
  padding: 7px 14px;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
}
.btn-primary:hover {
  filter: brightness(1.08);
}
```

### 7.8 Botão Secundário / Ghost

```css
.btn-ghost {
  background: transparent;
  color: #555;
  border: 0.5px solid #ddd;
  border-radius: 6px;
  padding: 7px 14px;
  font-size: 12px;
  cursor: pointer;
}
.btn-ghost:hover {
  background: #f5f5f5;
}
```

### 7.9 Input / Select

```css
input,
select,
textarea {
  border: 0.5px solid #ddd;
  border-radius: 6px;
  padding: 7px 10px;
  font-size: 12px;
  width: 100%;
  outline: none;
  color: #111;
}
input:focus,
select:focus {
  border-color: var(--theme-accent);
  box-shadow: 0 0 0 2px var(--theme-accent-light);
}
```

### 7.10 Modal

```css
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}
.modal {
  background: white;
  border-radius: 12px;
  padding: 24px;
  width: 480px;
  max-width: 94vw;
  max-height: 90vh;
  overflow-y: auto;
}
.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}
.modal-title {
  font-size: 15px;
  font-weight: 500;
}
.modal-close {
  background: none;
  border: none;
  font-size: 18px;
  cursor: pointer;
  color: #888;
}
```

### 7.11 Drawer (painel lateral)

Para perfis de leitor, detalhe de empréstimo, etc.:

```css
.drawer {
  position: fixed;
  top: 0;
  right: 0;
  width: 380px;
  height: 100vh;
  background: white;
  border-left: 0.5px solid #e5e5e5;
  z-index: 90;
  overflow-y: auto;
  padding: 24px;
  transform: translateX(100%);
  transition: transform 0.2s ease;
}
.drawer.open {
  transform: translateX(0);
}
```

### 7.12 Step Indicator (para wizards)

```
● Dados do Leitor  ──  ○ Material  ──  ○ Confirmar
```

```css
.step {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
}
.step-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}
.step-dot.active {
  background: var(--theme-accent);
}
.step-dot.done {
  background: var(--theme-accent);
  opacity: 0.5;
}
.step-dot.pending {
  background: #ddd;
}
.step-line {
  width: 32px;
  height: 1px;
  background: #ddd;
}
```

### 7.13 Empty State

Quando uma tabela não tem dados:

```html
<div class="empty-state">
  <div class="empty-icon">○</div>
  <div class="empty-text">Nenhum resultado encontrado</div>
  <div class="empty-sub">Ajusta os filtros ou adiciona um novo registo</div>
</div>
```

```css
.empty-state {
  text-align: center;
  padding: 40px 20px;
  color: #888;
}
.empty-icon {
  font-size: 32px;
  margin-bottom: 12px;
  opacity: 0.3;
}
.empty-text {
  font-size: 13px;
  font-weight: 500;
  color: #555;
}
.empty-sub {
  font-size: 11px;
  margin-top: 4px;
}
```

---

## 8. Grid de Estatísticas

```css
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 10px;
  margin-bottom: 20px;
}
```

---

## 9. Regras Invioláveis

1. **Nunca usar foto para leitores ou materiais.** Avatares de leitores são sempre iniciais (letras). Materiais não têm imagem.
2. **Funcionários têm foto opcional** com fallback automático para iniciais.
3. **Temas de região são aplicados no login** com base em `BIBLIOTECA.provincia`. Não existe selecção manual pelo utilizador final.
4. **Cores de acento vêm sempre de `var(--theme-accent)`**, nunca hardcoded.
5. **Badges de status têm sempre fundo colorido claro** (nunca só texto colorido sem fundo).
6. **Códigos de sistema** (`num_cartao`, `cod_material`, `cod_funcionario`, etc.) são sempre apresentados em `font-family: monospace`, cor muted, nunca bold.
7. **Acções destrutivas** (eliminar, bloquear, rejeitar) têm sempre modal de confirmação antes de executar.
8. **Formulários longos usam wizard** (steps), máximo 3 steps por wizard.
9. **O sidebar é sempre visível** — não existe modo hamburger/mobile nesta versão.
10. **Permissões controlam visibilidade de elementos**, não apenas de rotas. Um Assistente não vê o botão "Eliminar" mesmo que tente aceder directamente.
