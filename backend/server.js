require('dotenv').config();
const express = require('express');
const cors = require('cors');
const session = require('express-session');
const path = require('path');

const apiRoutes = require('./routes/api');
const authRoutes = require('./routes/auth');
const dashboardRoutes = require('./routes/dashboard');
const leitoresRoutes = require('./routes/leitores');
const materiaisRoutes = require('./routes/materiais');
const emprestimosRoutes = require('./routes/emprestimos');
const funcionariosRoutes = require('./routes/funcionarios');
const eventosRoutes = require('./routes/eventos');
const { doacoesRouter, doadoresRouter } = require('./routes/doacoes');
const transfRouter    = require('./routes/transferencias');
const programasRouter = require('./routes/programas');
const bibliotecasRouter = require('./routes/bibliotecas');
const suspensoesRouter  = require('./routes/suspensoes');
const auditoriaRouter   = require('./routes/auditoria');
const manutencaoRouter  = require('./routes/manutencao');
const { inicializarNoOrigem } = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(session({
  secret: process.env.SESSION_SECRET || 'biblioteca-secret-2024',
  resave: false,
  saveUninitialized: false,
  cookie: { maxAge: 8 * 60 * 60 * 1000 } // 8 horas
}));

// Remove acentos de todos os campos string no req.body
function normalizarBody(obj) {
  if (!obj || typeof obj !== 'object') return;
  for (const key of Object.keys(obj)) {
    if (typeof obj[key] === 'string') {
      obj[key] = obj[key].normalize('NFD').replace(/[̀-ͯ]/g, '');
    } else if (typeof obj[key] === 'object') {
      normalizarBody(obj[key]);
    }
  }
}
app.use((req, res, next) => { normalizarBody(req.body); next(); });

// Log de cada pedido HTTP recebido
app.use((req, res, next) => {
  const inicio = Date.now();
  res.on('finish', () => {
    const ms = Date.now() - inicio;
    const cor = res.statusCode >= 500 ? '\x1b[31m' : res.statusCode >= 400 ? '\x1b[33m' : '\x1b[32m';
    console.log(`${cor}[REQUEST]\x1b[0m ${req.method} ${req.path} → ${res.statusCode} (${ms}ms)`);
  });
  next();
});

app.use('/api', apiRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/leitores', leitoresRoutes);
app.use('/api/materiais', materiaisRoutes);
app.use('/api/emprestimos', emprestimosRoutes);
app.use('/api/funcionarios', funcionariosRoutes);
app.use('/api/eventos', eventosRoutes);
app.use('/api/doacoes', doacoesRouter);
app.use('/api/doadores', doadoresRouter);
app.use('/api/transferencias', transfRouter);
app.use('/api/programas',     programasRouter);
app.use('/api/bibliotecas',   bibliotecasRouter);
app.use('/api/suspensoes',    suspensoesRouter);
app.use('/api/auditoria',    auditoriaRouter);
app.use('/api/manutencao',   manutencaoRouter);

app.use(express.static(path.join(__dirname, '..', 'frontend')));
app.use('/resources', express.static(path.join(__dirname, '..', 'resources')));

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'frontend', 'index.html'));
});

app.listen(PORT, () => {
  console.log('\x1b[36m════════════════════════════════════════\x1b[0m');
  console.log(`\x1b[36m[SERVER]\x1b[0m Saber Comunitário arrancou`);
  console.log(`\x1b[36m[SERVER]\x1b[0m URL:     http://localhost:${PORT}`);
  console.log(`\x1b[36m[SERVER]\x1b[0m Oracle:  ${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_SERVICE}`);
  console.log(`\x1b[36m[SERVER]\x1b[0m User:    ${process.env.DB_USER}${process.env.DB_PRIVILEGE ? ' AS ' + process.env.DB_PRIVILEGE : ''}`);
  console.log(`\x1b[36m[SERVER]\x1b[0m Rotas:   /api/auth | /api/dashboard | /api/leitores | /api/materiais`);
  console.log(`\x1b[36m[SERVER]\x1b[0m          /api/emprestimos | /api/funcionarios | /api/eventos | /api/doacoes | /api/doadores`);
  console.log(`\x1b[36m[SERVER]\x1b[0m          /api/transferencias | /api/programas | /api/bibliotecas | /api/suspensoes | /api/auditoria`);
  console.log('\x1b[36m════════════════════════════════════════\x1b[0m');
  inicializarNoOrigem();
});
