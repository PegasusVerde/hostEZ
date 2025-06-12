# Usar a imaxe base de PHP 8.2 con Apache
FROM php:8.2-apache

# Instalar dependencias e extensións necesarias, usando libmariadb-dev
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    default-mysql-client \
    libmariadb-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql gd \
    && a2enmod rewrite

# Copiar configuración personalizada
COPY custom-apache.conf /etc/apache2/sites-available/000-default.conf

# Crear grupo e usuario durante a construción
RUN groupadd -g 1000 webgroup && \
    useradd -u 1000 -g 1000 webuser && \
    chown -R 1000:1000 /var/www/html
