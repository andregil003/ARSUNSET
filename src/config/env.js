import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load .env from project root
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const requiredEnvVars = [
    'PORT',
    'DATABASE_URL',
    'SESSION_SECRET',
    'BCRYPT_ROUNDS'
];

const missingVars = requiredEnvVars.filter(key => !process.env[key]);

if (missingVars.length > 0) {
    console.error(`ERROR: Missing required environment variables: ${missingVars.join(', ')}`);
    process.exit(1);
}

const config = {
    env: process.env.NODE_ENV || 'development',
    port: parseInt(process.env.PORT, 10),
    baseUrl: process.env.BASE_URL || 'http://localhost:3000',
    db: {
        url: process.env.DATABASE_URL,
        host: process.env.DB_HOST,
        port: parseInt(process.env.DB_PORT, 10),
        name: process.env.DB_NAME,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
    },
    session: {
        secret: process.env.SESSION_SECRET,
        maxAge: 24 * 60 * 60 * 1000, // 24 hours
    },
    security: {
        bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS, 10),
        maxLoginAttempts: parseInt(process.env.MAX_LOGIN_ATTEMPTS, 10) || 5,
        lockTime: parseInt(process.env.LOCK_TIME, 10) || 900000, // 15 mins
    },
    upload: {
        dir: process.env.UPLOAD_DIR || './public/uploads',
        maxSize: parseInt(process.env.MAX_FILE_SIZE, 10) || 5242880, // 5MB
    },
    rateLimit: {
        window: parseInt(process.env.RATE_LIMIT_WINDOW, 10) || 900000,
        max: parseInt(process.env.RATE_LIMIT_MAX, 10) || 100,
    }
};

export default config;
