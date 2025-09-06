const express = require('express');
const os = require('os');
const app = express();

// Obtener información del entorno
const NODE_NAME = process.env.NODE_NAME || os.hostname();
const PORT = process.env.PORT || 3000;
const NODE_IP = process.env.NODE_IP || getLocalIP();

let requestCount = 0;
const startTime = new Date();

// Función para obtener IP local
function getLocalIP() {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const interface of interfaces[name]) {
            if (interface.family === 'IPv4' && !interface.internal) {
                return interface.address;
            }
        }
    }
    return '127.0.0.1';
}

// Middleware para contar requests
app.use((req, res, next) => {
    requestCount++;
    next();
});

// Ruta principal
app.get('/', (req, res) => {
    const uptime = Math.floor((new Date() - startTime) / 1000);
    
    res.json({
        message: `Hello from ${NODE_NAME}!`,
        node: {
            name: NODE_NAME,
            ip: NODE_IP,
            port: PORT,
            hostname: os.hostname(),
            platform: os.platform(),
            arch: os.arch()
        },
        stats: {
            uptime: `${uptime}s`,
            requests: requestCount,
            timestamp: new Date().toISOString(),
            memory: process.memoryUsage(),
            load: os.loadavg()
        },
        consul: {
            datacenter: 'dc1',
            service: 'web',
            tags: ['nodejs', 'web', NODE_NAME]
        }
    });
});

// Health check endpoint para Consul
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        node: NODE_NAME,
        uptime: Math.floor((new Date() - startTime) / 1000),
        timestamp: new Date().toISOString()
    });
});

// Endpoint para información detallada
app.get('/info', (req, res) => {
    res.json({
        node: {
            name: NODE_NAME,
            ip: NODE_IP,
            port: PORT,
            hostname: os.hostname(),
            platform: os.platform(),
            arch: os.arch(),
            cpus: os.cpus().length,
            memory: {
                total: Math.round(os.totalmem() / 1024 / 1024) + 'MB',
                free: Math.round(os.freemem() / 1024 / 1024) + 'MB'
            }
        },
        process: {
            pid: process.pid,
            uptime: Math.floor(process.uptime()),
            memory: process.memoryUsage(),
            version: process.version
        },
        system: {
            uptime: Math.floor(os.uptime()),
            loadavg: os.loadavg()
        }
    });
});

// Endpoint para simular carga de trabajo
app.get('/work', (req, res) => {
    const duration = parseInt(req.query.duration) || 100;
    const start = Date.now();
    
    // Simular trabajo CPU intensivo
    while (Date.now() - start < duration) {
        Math.random() * Math.random();
    }
    
    res.json({
        message: `Work completed on ${NODE_NAME}`,
        duration: `${Date.now() - start}ms`,
        node: NODE_NAME,
        timestamp: new Date().toISOString()
    });
});

// Endpoint para testing de disponibilidad
app.get('/status/:code', (req, res) => {
    const code = parseInt(req.params.code) || 200;
    res.status(code).json({
        message: `Response with status ${code} from ${NODE_NAME}`,
        node: NODE_NAME,
        timestamp: new Date().toISOString()
    });
});

// Manejo de errores
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        error: 'Internal Server Error',
        node: NODE_NAME,
        timestamp: new Date().toISOString()
    });
});

// Iniciar servidor
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Web service started on ${NODE_NAME}:${PORT}`);
    console.log(`📊 Health check: http://${NODE_IP}:${PORT}/health`);
    console.log(`ℹ️  Info endpoint: http://${NODE_IP}:${PORT}/info`);
    console.log(`🔧 Work endpoint: http://${NODE_IP}:${PORT}/work?duration=500`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('🛑 Received SIGTERM, shutting down gracefully...');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('🛑 Received SIGINT, shutting down gracefully...');
    process.exit(0);
});
