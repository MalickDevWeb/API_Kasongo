# 🐳 Image PHP FPM avec Nginx pour production
FROM php:8.2-fpm

# Argument d'environnement (par défaut = development)
ARG APP_ENV=development
ENV APP_ENV=${APP_ENV}

# Installer dépendances système + extensions PHP nécessaires
RUN apt-get update && apt-get install -y \
    git curl zip unzip libpng-dev libjpeg-dev libfreetype6-dev libpq-dev libzip-dev nginx \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_pgsql bcmath zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Installer Composer globalement
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Définir le répertoire de travail
WORKDIR /var/www

# Copier le code source
COPY . .

# Choisir le bon fichier d'environnement selon le contexte
RUN if [ "$APP_ENV" = "production" ] && [ -f .env.production ]; then \
         cp .env.production .env; \
    elif [ "$APP_ENV" = "development" ] && [ -f .env.development ]; then \
         cp .env.development .env; \
    else \
         cp .env.example .env; \
    fi

# Installer les dépendances PHP sans les paquets de dev pour la prod
RUN composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev

# ⚙️ Générer la clé d'application Laravel (résout le problème)
RUN php artisan key:generate

# Optimiser les performances (cache config/routes/views)
RUN php artisan config:cache && php artisan route:cache && php artisan view:cache

# Fixer les permissions pour Laravel
RUN chown -R www-data:www-data storage bootstrap/cache

# Configurer Nginx
RUN rm /etc/nginx/sites-enabled/default
COPY nginx.conf /etc/nginx/sites-available/default
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Exposer le port HTTP
EXPOSE 80

# Commande de démarrage
CMD service nginx start && php-fpm
