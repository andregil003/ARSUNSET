/**
 * Artesanías Sunset - Main Frontend Script
 * Handles: Theme toggling, Mobile Menu, Accessibility, AJAX Helpers
 */

const App = (() => {
    // Constants
    const KEYS = {
        THEME: 'arsunset_theme_preference',
    };

    const SELECTORS = {
        THEME_TOGGLE: '#theme-toggle',
        MOBILE_MENU_BTN: '#mobile-menu-btn',
        MOBILE_MENU: '#mobile-menu',
        CLOSE_MENU_BTN: '#close-menu-btn',
        TOAST_CONTAINER: '#toast-container',
    };

    // State
    let isMenuOpen = false;

    /**
     * Initialize Theme
     * Checks localStorage and system preference
     */
    const initTheme = () => {
        const savedTheme = localStorage.getItem(KEYS.THEME);
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;

        if (savedTheme === 'dark' || (!savedTheme && prefersDark)) {
            document.documentElement.setAttribute('data-theme', 'dark');
        } else {
            document.documentElement.setAttribute('data-theme', 'light');
        }
    };

    /**
     * Toggle Theme
     * Persists to localStorage
     */
    const toggleTheme = () => {
        const currentTheme = document.documentElement.getAttribute('data-theme');
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';

        document.documentElement.setAttribute('data-theme', newTheme);
        localStorage.setItem(KEYS.THEME, newTheme);
    };

    /**
     * Mobile Menu Logic with Focus Trap
     */
    const initMobileMenu = () => {
        const btn = document.querySelector(SELECTORS.MOBILE_MENU_BTN);
        const menu = document.querySelector(SELECTORS.MOBILE_MENU);
        const closeBtn = document.querySelector(SELECTORS.CLOSE_MENU_BTN);

        if (!btn || !menu) return;

        const toggleMenu = (show) => {
            isMenuOpen = show;
            menu.setAttribute('aria-hidden', !show);
            btn.setAttribute('aria-expanded', show);

            if (show) {
                menu.classList.add('show');
                trapFocus(menu);
            } else {
                menu.classList.remove('show');
                btn.focus(); // Return focus to button
            }
        };

        btn.addEventListener('click', () => toggleMenu(true));
        if (closeBtn) closeBtn.addEventListener('click', () => toggleMenu(false));

        // Close on Escape
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && isMenuOpen) toggleMenu(false);
        });
    };

    /**
     * Accessibility: Focus Trap
     * Keeps focus within the modal/menu when open
     */
    const trapFocus = (element) => {
        const focusableElements = element.querySelectorAll(
            'a[href], button, textarea, input, select'
        );
        const firstElement = focusableElements[0];
        const lastElement = focusableElements[focusableElements.length - 1];

        element.addEventListener('keydown', (e) => {
            if (e.key === 'Tab') {
                if (e.shiftKey) { /* shift + tab */
                    if (document.activeElement === firstElement) {
                        lastElement.focus();
                        e.preventDefault();
                    }
                } else { /* tab */
                    if (document.activeElement === lastElement) {
                        firstElement.focus();
                        e.preventDefault();
                    }
                }
            }
        });

        if (firstElement) firstElement.focus();
    };

    /**
     * AJAX Request Helper
     * Wrapper for axios/fetch with error handling and timeouts
     * @param {string} url 
     * @param {object} options 
     */
    const request = async (url, options = {}) => {
        const defaultOptions = {
            timeout: 10000, // 10s timeout
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            }
        };

        const config = { ...defaultOptions, ...options };

        try {
            // Using axios if available, otherwise fetch could be implemented here
            // Assuming axios is loaded via script tag as per prompt requirements
            if (typeof axios === 'undefined') {
                throw new Error('Axios library not loaded');
            }

            const response = await axios(url, config);
            return response.data;
        } catch (error) {
            handleRequestError(error);
            throw error; // Re-throw for caller to handle specific logic if needed
        }
    };

    /**
     * Centralized Error Handler
     */
    const handleRequestError = (error) => {
        console.error('Request Error:', error);

        let message = 'Ocurrió un error inesperado.';

        if (error.response) {
            // Server responded with a status code out of 2xx range
            const status = error.response.status;
            if (status >= 400 && status < 500) {
                message = error.response.data.error?.message || 'Error de validación o solicitud incorrecta.';
            } else if (status >= 500) {
                message = 'Error del servidor. Por favor intente más tarde.';
            }
        } else if (error.request) {
            // Request made but no response (timeout, network)
            message = 'No se pudo conectar con el servidor. Verifique su conexión.';
        } else {
            message = error.message;
        }

        showToast(message, 'error');
    };

    /**
     * UI Feedback: Toast Notification
     */
    const showToast = (message, type = 'info') => {
        // Simple alert for now, or append to a toast container if it exists
        // In a real implementation, we would append a DOM element
        const container = document.querySelector(SELECTORS.TOAST_CONTAINER);
        if (container) {
            const toast = document.createElement('div');
            toast.className = `toast toast-${type}`;
            toast.textContent = message;
            container.appendChild(toast);

            setTimeout(() => {
                toast.remove();
            }, 5000);
        } else {
            // Fallback
            console.warn(`[${type.toUpperCase()}] ${message}`);
            if (type === 'error') alert(message);
        }
    };

    // Public API
    return {
        init: () => {
            initTheme();
            initMobileMenu();

            const themeBtn = document.querySelector(SELECTORS.THEME_TOGGLE);
            if (themeBtn) themeBtn.addEventListener('click', toggleTheme);
        },
        request,
        showToast
    };
})();

// Initialize on load
document.addEventListener('DOMContentLoaded', App.init);
