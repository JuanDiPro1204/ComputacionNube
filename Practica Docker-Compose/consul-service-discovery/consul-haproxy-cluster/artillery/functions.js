module.exports = {
  logResponse,
  setRandomDuration,
  trackNodeResponses,
  simulateFailure
};

// Contador global de respuestas por nodo
const nodeResponses = {};

function logResponse(requestParams, response, context, ee, next) {
  if (response.body) {
    try {
      const body = JSON.parse(response.body);
      const nodeName = body.node?.name || 'unknown';
      
      // Contar respuestas por nodo
      if (!nodeResponses[nodeName]) {
        nodeResponses[nodeName] = 0;
      }
      nodeResponses[nodeName]++;
      
      // Log cada 10 respuestas
      if (Object.values(nodeResponses).reduce((a, b) => a + b, 0) % 10 === 0) {
        console.log('Node distribution:', nodeResponses);
      }
    } catch (e) {
      // Ignore JSON parse errors
    }
  }
  return next();
}

function trackNodeResponses(requestParams, response, context, ee, next) {
  if (response.body) {
    try {
      const body = JSON.parse(response.body);
      const nodeName = body.node?.name || 'unknown';
      
      // Emitir evento customizado para métricas
      ee.emit('counter', 'nodes.' + nodeName, 1);
    } catch (e) {
      // Ignore JSON parse errors
    }
  }
  return next();
}

function setRandomDuration(requestParams, context, ee, next) {
  // Duración aleatoria entre 50ms y 500ms
  context.vars.duration = Math.floor(Math.random() * 450) + 50;
  return next();
}

function simulateFailure(requestParams, context, ee, next) {
  // 5% de probabilidad de simular un error
  if (Math.random() < 0.05) {
    context.vars.errorCode = 500;
  } else {
    context.vars.errorCode = 200;
  }
  return next();
}
