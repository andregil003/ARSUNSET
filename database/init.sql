-- ========================================
-- ARTESANÍAS SUNSET - 
-- PostgreSQL 14+
-- ========================================

-- ========================================
-- LIMPIEZA
-- ========================================

DROP TABLE IF EXISTS wholesale_pricing CASCADE;
DROP TABLE IF EXISTS blog_post_images CASCADE;
DROP TABLE IF EXISTS blog_posts CASCADE;
DROP TABLE IF EXISTS blog_categories CASCADE;
DROP TABLE IF EXISTS wishlist CASCADE;
DROP TABLE IF EXISTS newsletter_subscribers CASCADE;
DROP TABLE IF EXISTS password_reset_tokens CASCADE;
DROP TABLE IF EXISTS cart_items CASCADE;
DROP TABLE IF EXISTS exchange_rates CASCADE;
DROP TABLE IF EXISTS promotions CASCADE;
DROP TABLE IF EXISTS shipping_rates CASCADE;
DROP TABLE IF EXISTS shipping_zones CASCADE;
DROP TABLE IF EXISTS product_reviews CASCADE;
DROP TABLE IF EXISTS product_variants CASCADE;
DROP TABLE IF EXISTS customer_addresses CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS cities CASCADE;
DROP TABLE IF EXISTS countries CASCADE;
DROP TABLE IF EXISTS currencies CASCADE;
DROP TABLE IF EXISTS "session" CASCADE;

-- ========================================
-- SESIONES (Express Session)
-- ========================================

CREATE TABLE "session" (
    "sid" VARCHAR NOT NULL COLLATE "default",
    "sess" JSON NOT NULL,
    "expire" TIMESTAMP(6) NOT NULL,
    CONSTRAINT "session_pkey" PRIMARY KEY ("sid")
) WITH (OIDS=FALSE);

CREATE INDEX "IDX_session_expire" ON "session" ("expire");

COMMENT ON TABLE "session" IS 'Sesiones de usuarios (express-session)';

-- ========================================
-- GEOGRAFÍA
-- ========================================

CREATE TABLE countries (
    country_id SERIAL PRIMARY KEY,
    country_code VARCHAR(20) NOT NULL UNIQUE,
    country_name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE countries IS 'Catálogo de países';

CREATE TABLE cities (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    country_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_cities_country 
        FOREIGN KEY (country_id) 
        REFERENCES countries(country_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

COMMENT ON TABLE cities IS 'Ciudades por país';

-- ========================================
-- MULTI-MONEDA
-- ========================================

CREATE TABLE currencies (
    currency_id SERIAL PRIMARY KEY,
    currency_code VARCHAR(3) UNIQUE NOT NULL,
    currency_name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE currencies IS 'Monedas soportadas (GTQ, USD)';

CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    rate DECIMAL(10,6) NOT NULL CHECK (rate > 0),
    effective_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_exchange_from 
        FOREIGN KEY (from_currency) 
        REFERENCES currencies(currency_code)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_exchange_to 
        FOREIGN KEY (to_currency) 
        REFERENCES currencies(currency_code)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

COMMENT ON TABLE exchange_rates IS 'Tasas de cambio entre monedas';

-- ========================================
-- USUARIOS
-- ========================================

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(25),
    city_id INTEGER,
    newsletter_subscribed BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    google_id VARCHAR(255) UNIQUE,
    facebook_id VARCHAR(255) UNIQUE,
    last_password_change TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,
    
    CONSTRAINT fk_customers_city 
        FOREIGN KEY (city_id) 
        REFERENCES cities(city_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

COMMENT ON TABLE customers IS 'Clientes registrados - Auto-suscritos a newsletter';
COMMENT ON COLUMN customers.newsletter_subscribed IS 'Auto TRUE al registrarse, puede desactivar en perfil';
COMMENT ON COLUMN customers.last_password_change IS 'Fecha último cambio de contraseña';
COMMENT ON COLUMN customers.failed_login_attempts IS 'Contador de intentos fallidos (reset al login exitoso)';
COMMENT ON COLUMN customers.locked_until IS 'Fecha hasta la cual la cuenta está bloqueada';

-- Índice para email case-insensitive
CREATE UNIQUE INDEX idx_customers_email_lower ON customers(LOWER(email));

CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('Admin', 'Editor')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    last_password_change TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP
);

COMMENT ON TABLE employees IS 'Administradores - Solo creados desde pgAdmin';
COMMENT ON COLUMN employees.last_password_change IS 'Fecha último cambio de contraseña';
COMMENT ON COLUMN employees.failed_login_attempts IS 'Contador de intentos fallidos';
COMMENT ON COLUMN employees.locked_until IS 'Fecha hasta la cual la cuenta está bloqueada';

-- Índice para email case-insensitive
CREATE UNIQUE INDEX idx_employees_email_lower ON employees(LOWER(email));

-- ========================================
-- AUTENTICACIÓN
-- ========================================

CREATE TABLE password_reset_tokens (
    token_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    token VARCHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    used BOOLEAN DEFAULT FALSE,
    
    CONSTRAINT fk_reset_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
);

COMMENT ON TABLE password_reset_tokens IS 'Tokens para recuperación de contraseña (1 hora)';

CREATE INDEX idx_reset_token_active 
ON password_reset_tokens(token, expires_at) 
WHERE used = FALSE;

-- ========================================
-- CATÁLOGO
-- ========================================

CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    slug VARCHAR(255) UNIQUE,
    meta_title VARCHAR(255),
    meta_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE categories IS 'Categorías de productos';

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    description TEXT,
    category_id INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    has_variants BOOLEAN DEFAULT FALSE,
    stock_type VARCHAR(20) DEFAULT 'in_stock' 
        CHECK (stock_type IN ('in_stock', 'on_demand')),
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    weight DECIMAL(10,2) DEFAULT 0,
    volume DECIMAL(10,2) DEFAULT 0,
    image_url TEXT,
    slug VARCHAR(255) UNIQUE,
    meta_title VARCHAR(255),
    meta_description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    origin_region VARCHAR(100),
    artisan_story TEXT,
    production_time_days INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by INTEGER,
    deleted_at TIMESTAMP,
    deleted_by INTEGER,
    
    CONSTRAINT fk_products_category 
        FOREIGN KEY (category_id) 
        REFERENCES categories(category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_products_updated_by 
        FOREIGN KEY (updated_by) 
        REFERENCES employees(employee_id)
        ON DELETE SET NULL,
    
    CONSTRAINT fk_products_deleted_by 
        FOREIGN KEY (deleted_by) 
        REFERENCES employees(employee_id)
        ON DELETE SET NULL
);

COMMENT ON TABLE products IS 'Productos - Soporta stock físico y bajo pedido';
COMMENT ON COLUMN products.has_variants IS 'TRUE si tiene tallas/colores';
COMMENT ON COLUMN products.stock_type IS 'in_stock=físico | on_demand=bajo pedido';
COMMENT ON COLUMN products.stock IS 'Solo aplica si stock_type=in_stock';
COMMENT ON COLUMN products.origin_region IS 'Región de origen: Chichicastenango, Antigua, etc';
COMMENT ON COLUMN products.artisan_story IS 'Historia del artesano/técnica';
COMMENT ON COLUMN products.production_time_days IS 'Días de producción (solo para on_demand)';
COMMENT ON COLUMN products.updated_by IS 'Empleado que realizó última modificación';
COMMENT ON COLUMN products.deleted_at IS 'Fecha de eliminación lógica (soft delete)';
COMMENT ON COLUMN products.deleted_by IS 'Empleado que eliminó el producto';

CREATE INDEX idx_products_active_date 
ON products(is_active, created_at DESC) 
WHERE is_active = TRUE AND deleted_at IS NULL;

-- Índice para búsqueda full-text en español
CREATE INDEX idx_products_name_search 
ON products USING gin(to_tsvector('spanish', product_name));

-- Índice para filtros por precio
CREATE INDEX idx_products_price 
ON products(price) 
WHERE is_active = TRUE AND deleted_at IS NULL;

-- ========================================
-- PRECIOS AL POR MAYOR (Fase 2)
-- ========================================

CREATE TABLE wholesale_pricing (
    pricing_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    min_quantity INTEGER NOT NULL CHECK (min_quantity > 0),
    wholesale_price DECIMAL(10,2) NOT NULL CHECK (wholesale_price >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_wholesale_product 
        FOREIGN KEY (product_id) 
        REFERENCES products(product_id)
        ON DELETE CASCADE,
    
    CONSTRAINT uk_product_quantity UNIQUE (product_id, min_quantity)
);

COMMENT ON TABLE wholesale_pricing IS 'Precios por volumen - Ejemplo: 10+ unidades = Q80 c/u';
COMMENT ON COLUMN wholesale_pricing.min_quantity IS 'Cantidad mínima para aplicar este precio';
COMMENT ON COLUMN wholesale_pricing.wholesale_price IS 'Precio unitario al por mayor';

CREATE INDEX idx_wholesale_product ON wholesale_pricing(product_id, min_quantity);

-- ========================================
-- VARIANTES
-- ========================================

CREATE TABLE product_variants (
    variant_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    variant_name VARCHAR(100) NOT NULL,
    sku VARCHAR(100) UNIQUE,
    size VARCHAR(50),
    color VARCHAR(50),
    material VARCHAR(100),
    additional_price DECIMAL(10,2) DEFAULT 0,
    stock INTEGER DEFAULT 0 CHECK (stock >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_variants_product 
        FOREIGN KEY (product_id) 
        REFERENCES products(product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

COMMENT ON TABLE product_variants IS 'Variantes: tallas, colores, materiales opcionales';
COMMENT ON COLUMN product_variants.additional_price IS 'Precio extra sobre products.price';
COMMENT ON COLUMN product_variants.stock IS 'Stock solo si el producto padre tiene stock_type=in_stock';

CREATE INDEX idx_variants_product_active 
ON product_variants(product_id, is_active);

-- ========================================
-- RESEÑAS 
-- ========================================

CREATE TABLE product_reviews (
    review_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    customer_id INTEGER,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    is_verified_purchase BOOLEAN DEFAULT FALSE,
    is_visible BOOLEAN DEFAULT TRUE,
    is_approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_reviews_product 
        FOREIGN KEY (product_id) 
        REFERENCES products(product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_reviews_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT uk_one_review_per_customer UNIQUE (product_id, customer_id)
);

COMMENT ON TABLE product_reviews IS 'Reseñas - Admin puede ocultar con is_visible';

CREATE INDEX idx_reviews_product_rating 
ON product_reviews(product_id, rating DESC);

-- ========================================
-- DIRECCIONES
-- ========================================

CREATE TABLE customer_addresses (
    address_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    city_id INTEGER NOT NULL,
    address_line TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    address_type VARCHAR(50) DEFAULT 'Residencial'
        CHECK (address_type IN ('Residencial', 'Comercial', 'Trabajo')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_addresses_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_addresses_city 
        FOREIGN KEY (city_id) 
        REFERENCES cities(city_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

COMMENT ON TABLE customer_addresses IS 'Direcciones de envío por cliente';

-- Índice único para prevenir múltiples direcciones por defecto
CREATE UNIQUE INDEX idx_customer_one_default 
ON customer_addresses(customer_id) 
WHERE is_default = TRUE;

-- ========================================
-- WISHLIST
-- ========================================

CREATE TABLE wishlist (
    wishlist_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    variant_id INTEGER,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_wishlist_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_wishlist_product 
        FOREIGN KEY (product_id) 
        REFERENCES products(product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_wishlist_variant 
        FOREIGN KEY (variant_id) 
        REFERENCES product_variants(variant_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT uk_wishlist_item UNIQUE (customer_id, product_id, variant_id)
);

COMMENT ON TABLE wishlist IS 'Lista de deseos - Solo usuarios registrados';
COMMENT ON COLUMN wishlist.variant_id IS 'Variante específica elegida (ej: Huipil talla M)';

CREATE INDEX idx_wishlist_customer ON wishlist(customer_id);

-- ========================================
-- CARRITO TEMPORAL
-- ========================================

CREATE TABLE cart_items (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255),
    customer_id INTEGER,
    product_id INTEGER NOT NULL,
    variant_id INTEGER,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0 AND quantity <= 15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_cart_product 
        FOREIGN KEY (product_id) 
        REFERENCES products(product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_cart_variant 
        FOREIGN KEY (variant_id) 
        REFERENCES product_variants(variant_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_cart_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT chk_cart_owner CHECK (
        (session_id IS NOT NULL) OR (customer_id IS NOT NULL)
    )
);

COMMENT ON TABLE cart_items IS 'Carrito - Invitados (session_id) + Registrados (customer_id)';
COMMENT ON COLUMN cart_items.updated_at IS 'Para limpieza automática (30 días)';

CREATE INDEX idx_cart_session ON cart_items(session_id) WHERE customer_id IS NULL;
CREATE INDEX idx_cart_customer ON cart_items(customer_id) WHERE customer_id IS NOT NULL;
CREATE INDEX idx_cart_cleanup ON cart_items(updated_at) WHERE customer_id IS NULL;

-- ========================================
-- BLOG 
-- ========================================

CREATE TABLE blog_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE blog_categories IS 'Categorías dinámicas: Promociones, Noticias, Cultura, etc.';

CREATE TABLE blog_posts (
    post_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    featured_image_url TEXT,
    category_id INTEGER NOT NULL,
    featured_product_id INTEGER,
    promo_code_id INTEGER,
    is_published BOOLEAN DEFAULT FALSE,
    is_pinned BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMP,
    created_by INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_blog_category 
        FOREIGN KEY (category_id) 
        REFERENCES blog_categories(category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_blog_product 
        FOREIGN KEY (featured_product_id) 
        REFERENCES products(product_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_blog_employee 
        FOREIGN KEY (created_by) 
        REFERENCES employees(employee_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

COMMENT ON TABLE blog_posts IS 'Posts de blog - Promociones, noticias, galería de trabajos';
COMMENT ON COLUMN blog_posts.is_pinned IS 'Muestra en home';
COMMENT ON COLUMN blog_posts.featured_product_id IS 'Producto destacado en el post';

CREATE INDEX idx_blog_published ON blog_posts(is_published, published_at DESC);
CREATE INDEX idx_blog_pinned ON blog_posts(is_pinned) WHERE is_pinned = TRUE;

CREATE TABLE blog_post_images (
    image_id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    image_url TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,
    caption TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_blog_images_post 
        FOREIGN KEY (post_id) 
        REFERENCES blog_posts(post_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

COMMENT ON TABLE blog_post_images IS 'Múltiples imágenes por post (slideshow)';

CREATE INDEX idx_blog_images_post ON blog_post_images(post_id, display_order);

-- ========================================
-- NEWSLETTER
-- ========================================

CREATE TABLE newsletter_subscribers (
    subscriber_id SERIAL PRIMARY KEY,
    email VARCHAR(100) NOT NULL UNIQUE,
    subscribed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE newsletter_subscribers IS 'Suscriptores NO registrados - Solo email';
COMMENT ON COLUMN newsletter_subscribers.is_active IS 'Admin desactiva manualmente';

CREATE INDEX idx_newsletter_active ON newsletter_subscribers(is_active);

-- ========================================
-- VISTA: SUSCRIPTORES CONSOLIDADOS
-- ========================================

CREATE OR REPLACE VIEW all_subscribers AS
SELECT 
    email, 
    'customer' as source,
    created_at as subscribed_at
FROM customers 
WHERE newsletter_subscribed = TRUE
UNION
SELECT 
    email, 
    'guest' as source,
    subscribed_at
FROM newsletter_subscribers 
WHERE is_active = TRUE;

COMMENT ON VIEW all_subscribers IS 'Vista unificada de todos los suscriptores al newsletter (clientes + invitados)';

-- ========================================
-- ENVÍOS
-- ========================================

CREATE TABLE shipping_zones (
    zone_id SERIAL PRIMARY KEY,
    zone_name VARCHAR(100) NOT NULL,
    countries TEXT[],
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE shipping_zones IS 'Zonas de envío: Guatemala, USA, Centroamérica';

CREATE TABLE shipping_rates (
    rate_id SERIAL PRIMARY KEY,
    zone_id INTEGER NOT NULL,
    min_weight DECIMAL(10,2) DEFAULT 0,
    max_weight DECIMAL(10,2),
    base_cost DECIMAL(10,2) NOT NULL CHECK (base_cost >= 0),
    cost_per_kg DECIMAL(10,2) DEFAULT 0,
    estimated_days INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_rates_zone 
        FOREIGN KEY (zone_id) 
        REFERENCES shipping_zones(zone_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

COMMENT ON TABLE shipping_rates IS 'Tarifas por peso y zona';

-- ========================================
-- PROMOCIONES (Fase 2 - Mejorado)
-- ========================================

CREATE TABLE promotions (
    promo_id SERIAL PRIMARY KEY,
    promo_code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value DECIMAL(10,2) NOT NULL CHECK (discount_value > 0),
    applies_to VARCHAR(20) DEFAULT 'order_total'
        CHECK (applies_to IN ('order_total', 'category', 'product', 'quantity')),
    target_id INTEGER,
    min_quantity INTEGER,
    min_purchase DECIMAL(10,2) DEFAULT 0,
    max_uses INTEGER,
    current_uses INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE promotions IS 'Códigos promocionales y descuentos por volumen';
COMMENT ON COLUMN promotions.applies_to IS 'order_total=descuento general | category=por categoría | product=producto específico | quantity=por cantidad';
COMMENT ON COLUMN promotions.target_id IS 'ID de categoría o producto (si aplica)';
COMMENT ON COLUMN promotions.min_quantity IS 'Cantidad mínima de productos para descuento por volumen';

-- ========================================
-- ÓRDENES
-- ========================================

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    employee_id INTEGER,
    shipping_address_id INTEGER,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL DEFAULT 'Pendiente' 
        CHECK (status IN ('Pendiente', 'Procesando', 'Enviado', 'Entregado', 'Cancelado')),
    shipping_status VARCHAR(50) DEFAULT 'Preparando'
        CHECK (shipping_status IN ('Preparando', 'En tránsito', 'Entregado', 'Fallido')),
    tracking_number VARCHAR(100),
    total DECIMAL(10,2) NOT NULL CHECK (total >= 0),
    currency_code VARCHAR(3) NOT NULL DEFAULT 'GTQ',
    promo_id INTEGER,
    discount_applied DECIMAL(10,2) DEFAULT 0 CHECK (discount_applied >= 0),
    shipping_rate_id INTEGER,
    shipping_cost DECIMAL(10,2) DEFAULT 0 CHECK (shipping_cost >= 0),
    guest_email VARCHAR(100),
    guest_name VARCHAR(100),
    guest_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    deleted_by INTEGER,
    
    CONSTRAINT fk_orders_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_orders_employee 
        FOREIGN KEY (employee_id) 
        REFERENCES employees(employee_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_orders_address 
        FOREIGN KEY (shipping_address_id) 
        REFERENCES customer_addresses(address_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_orders_currency
        FOREIGN KEY (currency_code)
        REFERENCES currencies(currency_code)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_orders_promo 
        FOREIGN KEY (promo_id) 
        REFERENCES promotions(promo_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_orders_shipping_rate 
        FOREIGN KEY (shipping_rate_id) 
        REFERENCES shipping_rates(rate_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_orders_deleted_by 
        FOREIGN KEY (deleted_by) 
        REFERENCES employees(employee_id)
        ON DELETE SET NULL
);

COMMENT ON TABLE orders IS 'Órdenes - Clientes registrados + invitados (guest checkout)';
COMMENT ON COLUMN orders.currency_code IS 'Moneda de venta (GTQ/USD)';
COMMENT ON COLUMN orders.deleted_at IS 'Fecha de cancelación/eliminación lógica';
COMMENT ON COLUMN orders.deleted_by IS 'Empleado que canceló la orden';

CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date DESC);
CREATE INDEX idx_orders_status_date ON orders(status, order_date DESC);
CREATE INDEX idx_orders_guest_email ON orders(LOWER(guest_email)) WHERE guest_email IS NOT NULL;

-- Índice para reportes de ventas (excluye canceladas)
CREATE INDEX idx_orders_date_status 
ON orders(order_date, status) 
WHERE status != 'Cancelado' AND deleted_at IS NULL;

CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    variant_id INTEGER,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_items_order 
        FOREIGN KEY (order_id) 
        REFERENCES orders(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_items_product 
        FOREIGN KEY (product_id) 
        REFERENCES products(product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_items_variant 
        FOREIGN KEY (variant_id) 
        REFERENCES product_variants(variant_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

COMMENT ON TABLE order_items IS 'Detalle de productos por orden';

CREATE INDEX idx_order_items_order_product ON order_items(order_id, product_id);
CREATE INDEX idx_order_items_variant ON order_items(variant_id);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(50) NOT NULL 
        CHECK (payment_method IN ('Efectivo', 'Tarjeta', 'Transferencia', 'PayPal', 'Contra Entrega')),
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    status VARCHAR(50) NOT NULL DEFAULT 'Pendiente'
        CHECK (status IN ('Pendiente', 'Aprobado', 'Rechazado', 'Reembolsado')),
    transaction_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_payments_order 
        FOREIGN KEY (order_id) 
        REFERENCES orders(order_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

COMMENT ON TABLE payments IS 'Pagos por orden - Múltiples métodos incluyendo contra entrega';

-- ========================================
-- TRIGGERS DE VALIDACIÓN
-- ========================================

-- 1. Validar fechas de promociones
CREATE OR REPLACE FUNCTION validate_promo_dates()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.valid_until IS NOT NULL AND NEW.valid_until <= NEW.valid_from THEN
        RAISE EXCEPTION 'La fecha valid_until debe ser posterior a valid_from';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_promo_dates
    BEFORE INSERT OR UPDATE ON promotions
    FOR EACH ROW
    EXECUTE FUNCTION validate_promo_dates();

COMMENT ON FUNCTION validate_promo_dates() IS 'Valida que las fechas de promociones sean coherentes';

-- 2. Validar stock de variantes según producto padre
CREATE OR REPLACE FUNCTION validate_variant_stock()
RETURNS TRIGGER AS $$
DECLARE
    parent_stock_type VARCHAR(20);
BEGIN
    -- Obtener el stock_type del producto padre
    SELECT stock_type INTO parent_stock_type
    FROM products
    WHERE product_id = NEW.product_id;
    
    -- Si el producto es bajo pedido, la variante no puede tener stock físico
    IF parent_stock_type = 'on_demand' AND NEW.stock > 0 THEN
        RAISE EXCEPTION 'Las variantes de productos bajo pedido (on_demand) no pueden tener stock físico';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_variant_stock
    BEFORE INSERT OR UPDATE ON product_variants
    FOR EACH ROW
    EXECUTE FUNCTION validate_variant_stock();

COMMENT ON FUNCTION validate_variant_stock() IS 'Valida que variantes de productos on_demand no tengan stock físico';

-- 3. Prevención de overselling - Reservar stock al crear orden
CREATE OR REPLACE FUNCTION reserve_stock_on_order()
RETURNS TRIGGER AS $$
DECLARE
    product_stock_type VARCHAR(20);
    current_stock INTEGER;
    variant_stock INTEGER;
BEGIN
    -- Obtener información del producto
    SELECT stock_type, stock INTO product_stock_type, current_stock
    FROM products
    WHERE product_id = NEW.product_id;
    
    -- Solo verificar stock si el producto es in_stock
    IF product_stock_type = 'in_stock' THEN
        -- Si hay variante, verificar stock de la variante
        IF NEW.variant_id IS NOT NULL THEN
            SELECT stock INTO variant_stock
            FROM product_variants
            WHERE variant_id = NEW.variant_id;
            
            IF variant_stock < NEW.quantity THEN
                RAISE EXCEPTION 'Stock insuficiente para la variante solicitada. Disponible: %, Solicitado: %', 
                    variant_stock, NEW.quantity;
            END IF;
            
            -- Decrementar stock de la variante
            UPDATE product_variants
            SET stock = stock - NEW.quantity
            WHERE variant_id = NEW.variant_id;
        ELSE
            -- Verificar y decrementar stock del producto base
            IF current_stock < NEW.quantity THEN
                RAISE EXCEPTION 'Stock insuficiente. Disponible: %, Solicitado: %', 
                    current_stock, NEW.quantity;
            END IF;
            
            UPDATE products
            SET stock = stock - NEW.quantity
            WHERE product_id = NEW.product_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_reserve_stock
    AFTER INSERT ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION reserve_stock_on_order();

COMMENT ON FUNCTION reserve_stock_on_order() IS 'Reserva stock automáticamente al crear items de orden, previene overselling';

-- 4. Restaurar stock al cancelar orden
CREATE OR REPLACE FUNCTION restore_stock_on_cancel()
RETURNS TRIGGER AS $$
DECLARE
    item_record RECORD;
    product_stock_type VARCHAR(20);
BEGIN
    -- Solo restaurar si la orden cambió a Cancelado
    IF NEW.status = 'Cancelado' AND OLD.status != 'Cancelado' THEN
        -- Iterar sobre todos los items de la orden
        FOR item_record IN 
            SELECT product_id, variant_id, quantity 
            FROM order_items 
            WHERE order_id = NEW.order_id
        LOOP
            -- Obtener tipo de stock del producto
            SELECT stock_type INTO product_stock_type
            FROM products
            WHERE product_id = item_record.product_id;
            
            -- Solo restaurar si es in_stock
            IF product_stock_type = 'in_stock' THEN
                IF item_record.variant_id IS NOT NULL THEN
                    -- Restaurar stock de variante
                    UPDATE product_variants
                    SET stock = stock + item_record.quantity
                    WHERE variant_id = item_record.variant_id;
                ELSE
                    -- Restaurar stock de producto base
                    UPDATE products
                    SET stock = stock + item_record.quantity
                    WHERE product_id = item_record.product_id;
                END IF;
            END IF;
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_restore_stock
    AFTER UPDATE ON orders
    FOR EACH ROW
    WHEN (NEW.status = 'Cancelado' AND OLD.status != 'Cancelado')
    EXECUTE FUNCTION restore_stock_on_cancel();

COMMENT ON FUNCTION restore_stock_on_cancel() IS 'Restaura stock automáticamente cuando una orden se cancela';

-- ========================================
-- DATOS INICIALES
-- ========================================

INSERT INTO currencies (currency_code, currency_name, symbol) VALUES
('GTQ', 'Quetzal Guatemalteco', 'Q'),
('USD', 'Dólar Estadounidense', '$');

INSERT INTO exchange_rates (from_currency, to_currency, rate) VALUES
('GTQ', 'USD', 0.125),
('USD', 'GTQ', 8.00);

INSERT INTO countries (country_code, country_name) VALUES
('GTM', 'Guatemala'),
('USA', 'Estados Unidos'),
('SLV', 'El Salvador'),
('HND', 'Honduras'),
('NIC', 'Nicaragua'),
('CRI', 'Costa Rica'),
('PAN', 'Panamá'),
('BLZ', 'Belice'),
('MEX', 'México');

INSERT INTO cities (city_name, country_id) VALUES
('Guatemala City', 1),
('Antigua Guatemala', 1),
('Quetzaltenango', 1),
('Chichicastenango', 1),
('Panajachel', 1),
('Cobán', 1);

INSERT INTO shipping_zones (zone_name, countries) VALUES
('Guatemala', ARRAY['GTM']),
('Estados Unidos', ARRAY['USA']),
('Centroamérica', ARRAY['SLV', 'HND', 'NIC', 'CRI', 'PAN', 'BLZ']);

INSERT INTO shipping_rates (zone_id, min_weight, max_weight, base_cost, cost_per_kg, estimated_days) VALUES
(1, 0, 5, 25.00, 5.00, 3),
(1, 5, NULL, 50.00, 8.00, 5),
(2, 0, 5, 150.00, 25.00, 10),
(2, 5, NULL, 250.00, 40.00, 15),
(3, 0, 5, 75.00, 15.00, 7),
(3, 5, NULL, 125.00, 20.00, 10);

INSERT INTO blog_categories (category_name, slug) VALUES
('Promociones', 'promociones'),
('Noticias', 'noticias'),
('Cultura Maya', 'cultura-maya'),
('Testimonios', 'testimonios'),
('Técnicas Artesanales', 'tecnicas');

-- ========================================
-- FUNCIÓN DE LIMPIEZA AUTOMÁTICA
-- ========================================
CREATE OR REPLACE FUNCTION cleanup_abandoned_guest_carts()
RETURNS void 
LANGUAGE plpgsql
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM cart_items 
    WHERE customer_id IS NULL 
      AND updated_at < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE 'Limpieza: % carritos de invitados eliminados', deleted_count;
    
    DELETE FROM "session" WHERE expire < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE 'Limpieza: % sesiones expiradas eliminadas', deleted_count;
END;
$$;

COMMENT ON FUNCTION cleanup_abandoned_guest_carts() IS 
'Limpia carritos abandonados (>30 días) y sesiones expiradas - Ejecutar mensualmente';

-- ========================================
-- FIN DEL SCHEMA 
-- ========================================