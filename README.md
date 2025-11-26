# Artesanías Sunset

E-commerce para artesanías guatemaltecas con arquitectura modular estricta.

## Descripción
Sistema fullstack Node.js + Express + EJS + PostgreSQL donde las órdenes se procesan mediante WhatsApp.
Arquitectura piramidal modular: cada componente es independiente y reemplazable.

## Requisitos
- Node.js 18+
- PostgreSQL 14+

## Instalación

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/andregil003/ARSUNSET.git
   cd ARSUNSET
   ```

2. **Instalar dependencias**
   ```bash
   npm install
   ```

3. **Configurar entorno**
   - Copiar `.env.example` a `.env`
   - Configurar las variables de entorno (Base de datos, Sesión, etc.)

4. **Inicializar Base de Datos**
   - Asegurarse que PostgreSQL esté corriendo y la base de datos `artesanias_sunset` exista.
   - Ejecutar el script de inicialización:
     ```bash
     node scripts/init-db.js
     ```

## Ejecución

- **Desarrollo (con nodemon)**
   ```bash
   npm run dev
   ```

- **Producción**
   ```bash
   npm start
   ```

## Estructura del Proyecto

```
/src
├── /config       # Configuración de entorno
├── /core         # App y Server setup
├── /db           # Conexión a BD
├── /middleware   # Middlewares globales
├── /modules      # Módulos de negocio (Auth, Products, etc.)
└── index.js      # Cargador dinámico de módulos
```

## Guía de Desarrollo
- **Nuevos Módulos**: Crear carpeta en `src/modules/<nombre>` con `routes`, `controller`, `service`, `model`.
- **Estilos**: Usar variables CSS en `public/css/colors.css`.
- **Base de Datos**: Usar siempre consultas parametrizadas en `*.model.js`.

## Convenciones
- Rutas: `kebab-case`
- Funciones JS: `camelCase`
- Tablas DB: `snake_case`
