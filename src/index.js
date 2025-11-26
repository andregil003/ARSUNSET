import express from 'express';
import fs from 'fs';
import path from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

const router = express.Router();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const modulesPath = path.join(__dirname, 'modules');

// Ensure modules directory exists
if (!fs.existsSync(modulesPath)) {
    fs.mkdirSync(modulesPath, { recursive: true });
}

const modules = fs.readdirSync(modulesPath);

for (const moduleName of modules) {
    const modulePath = path.join(modulesPath, moduleName);
    const routesFile = path.join(modulePath, `${moduleName}.routes.js`);

    if (fs.statSync(modulePath).isDirectory() && fs.existsSync(routesFile)) {
        try {
            // Dynamic import requires file URL
            const routeModule = await import(pathToFileURL(routesFile).href);

            // Mount the router
            // If the module exports a default router, use it
            if (routeModule.default) {
                // Use the module name as the base path, or root if it's a core module like 'home'?
                // The prompt says: "montar cada <module>.routes.js usando app.use()".
                // It doesn't specify the path prefix. Usually modules define their own paths.
                // But to avoid collisions, maybe we should prefix?
                // "Rutas: kebab-case (ej: /productos-destacados)"
                // This suggests routes are defined inside the router with their full path or relative to root.
                // Let's assume the router handles the pathing or we mount at root.
                // Mounting at root gives most flexibility.
                router.use('/', routeModule.default);
                console.log(`Module loaded: ${moduleName}`);
            } else {
                console.warn(`Module ${moduleName} routes file does not export default router`);
            }
        } catch (error) {
            console.error(`Failed to load module ${moduleName}:`, error);
        }
    }
}

export default router;
