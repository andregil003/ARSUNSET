import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { query, pool } from '../src/db/pool.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const initSqlPath = path.join(__dirname, '../database/init.sql');

async function initDb() {
    try {
        console.log('Reading init.sql...');
        const sql = fs.readFileSync(initSqlPath, 'utf8');

        console.log('Executing init.sql...');
        await query(sql);

        console.log('Database initialized successfully.');
    } catch (error) {
        console.error('Failed to initialize database:', error);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

initDb();
