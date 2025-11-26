import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import session from 'express-session';
import connectPgSimple from 'connect-pg-simple';
import path from 'path';
import { fileURLToPath } from 'url';
import config from '../config/env.js';
import { pool } from '../db/pool.js';
import { errorHandler } from '../middleware/errorHandler.js';
import routes from '../index.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PgSession = connectPgSimple(session);

// Security Middleware
app.use(helmet());

// Logging Middleware
app.use(morgan(config.env === 'production' ? 'combined' : 'dev'));

// Body Parsing Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static Files
app.use(express.static(path.join(__dirname, '../../public')));

// Session Configuration
app.use(session({
    store: new PgSession({
        pool: pool,
        tableName: 'session',
        createTableIfMissing: true
    }),
    secret: config.session.secret,
    resave: false,
    saveUninitialized: false,
    cookie: {
        secure: config.env === 'production', // true in production
        httpOnly: true,
        maxAge: config.session.maxAge
    }
}));

// View Engine Setup
app.set('views', [
    path.join(__dirname, '../../views'),
    path.join(__dirname, '../../src/modules')
]);
app.set('view engine', 'ejs');

// Mount Routes (Module Loader)
app.use('/', routes);

// 404 Handler
app.use((req, res, next) => {
    const err = new Error('Not Found');
    err.statusCode = 404;
    next(err);
});

// Error Handler
app.use(errorHandler);

export default app;
