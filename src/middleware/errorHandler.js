import config from '../config/env.js';

export const errorHandler = (err, req, res, next) => {
    console.error(err.stack);

    const statusCode = err.statusCode || 500;
    const message = err.message || 'Internal Server Error';

    // Determine response type based on Accept header
    const wantsJson = req.get('Content-Type') === 'application/json' || req.xhr || (req.headers.accept && req.headers.accept.indexOf('json') > -1);

    if (wantsJson) {
        return res.status(statusCode).json({
            success: false,
            error: {
                code: statusCode,
                message: config.env === 'production' ? 'Something went wrong' : message
            }
        });
    }

    // Render error view for HTML requests
    // Ensure we have a generic error view or use a simple send for now if views aren't set up
    try {
        res.status(statusCode).render('error', {
            title: `Error ${statusCode}`,
            message: config.env === 'production' ? 'Something went wrong' : message,
            error: config.env === 'development' ? err : {}
        });
    } catch (renderError) {
        // Fallback if render fails
        res.status(statusCode).send(`<h1>Error ${statusCode}</h1><p>${config.env === 'production' ? 'Something went wrong' : message}</p>`);
    }
};
