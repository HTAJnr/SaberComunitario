const { getNoOrigem } = require('../db');
const { registarBackground } = require('./auditoria');

function autenticar(req, res, next) {
  if (!req.session.funcionario) {
    return res.status(401).json({
      erro: true,
      codigo: 'NAO_AUTENTICADO',
      mensagem: 'Sessão expirada. Faça login novamente.'
    });
  }
  next();
}

function exigirNivel(...niveis) {
  return [
    autenticar,
    (req, res, next) => {
      const nivel = req.session.nivel_acesso || req.session.funcionario?.NIVEL_ACESSO || '';
      if (!niveis.includes(nivel)) {
        const codFunc = String(req.session.cod_funcionario || '0');
        registarBackground({
          cod_func: codFunc,
          operacao: 'ACESSO_NEGADO',
          objeto: `${req.method} ${req.path}`,
          resultado: 'FALHA',
          motivo: `Nível '${nivel}' sem permissão. Requer: ${niveis.join(' ou ')}`,
        });
        return res.status(403).json({
          erro: true,
          codigo: 'SEM_PERMISSAO',
          mensagem: 'Nível de acesso insuficiente para esta operação.'
        });
      }
      next();
    }
  ];
}

function exigirNo(...nos) {
  return (req, res, next) => {
    const noActual = getNoOrigem();
    if (!nos.includes(noActual)) {
      const codFunc = String(req.session?.cod_funcionario || '0');
      registarBackground({
        cod_func: codFunc,
        operacao: 'ACESSO_NEGADO',
        objeto: `${req.method} ${req.path}`,
        resultado: 'FALHA',
        motivo: `Nó '${noActual}' sem permissão. Requer: ${nos.join(' ou ')}`,
      });
      return res.status(403).json({
        erro: true,
        codigo: 'NO_ERRADO',
        mensagem: 'Operação não disponível neste contexto. Privilégios insuficientes.',
      });
    }
    next();
  };
}

module.exports = { autenticar, exigirNivel, exigirNo };
