import pg from 'pg';
import config from '../config/env.js';

const { Pool } = pg;

const pool = new Pool({
    connectionString: config.db.url,
    // Optional: Add ssl config for production if needed
    // ssl: config.env === 'production' ? { rejectUnauthorized: false } : false
});

pool.on('error', (err, client) => {
    console.error('Unexpected error on idle client', err);
    process.exit(-1);
});

export const query = async (text, params) => {
    const start = Date.now();
    try {
        const res = await pool.query(text, params);
        const duration = Date.now() - start;
        // console.log('executed query', { text, duration, rows: res.rowCount });
        return res;
    } catch (error) {
        console.error('Error executing query', { text, error });
        throw error;
    }
};

export const getClient = async () => {
    const client = await pool.connect();
    const query = client.query;
    const release = client.release;

    // Monkey patch the query method to keep track of the last query executed
    const timeout = 5000;
    const lastQuery = Symbol('lastQuery');

    client.query = (...args) => {
        client[lastQuery] = args;
        return query.apply(client, args);
    };

    client.release = () => {
        // clear our timeout
        clearTimeout(client.connectionTimeout);
        // set the methods back to their old un-monkey-patched version
        client.query = query;
        client.release = release;
        return release.apply(client);
    };

    return client;
};

export { pool };

export default {
    query,
    getClient,
    pool // Export pool for session store
};
