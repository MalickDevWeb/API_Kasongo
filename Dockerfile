# 🐳 Image PHP FPM
FROM php:8.2-fpm

# Argument d'environnement (défaut = dev)
ARG APP_ENV=development
ENV APP_ENV=${APP_ENV}

# Installer dépendances système et extensions PHP
RUN apt-get update && apt-get install -y \
    git curl zip unzip libpng-dev libjpeg-dev libfreetype6-dev libpq-dev libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_pgsql bcmath zip

# Installer Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Créer le répertoire de travail
WORKDIR /var/www

# Copier tout le code en une fois
COPY . .

# Copier le bon fichier .env selon l'environnement
RUN if [ "$APP_ENV" = "production" ]; then cp .env.production .env; else cp .env.development .env; fi

# Installer dépendances Laravel et générer autoload
RUN composer install --no-interaction --prefer-dist && composer dump-autoload --optimize

# Permissions pour Laravel
RUN chown -R www-data:www-data storage bootstrap/cache

# Exposer le port PHP-FPM
EXPOSE 9000

# Commande par défaut
CMD ["php-fpm"]
