# Desplegar compritas

Esta carpeta incluye todo lo necesario para desplegar compritas, a excepción de Postgres y el servidor de correo electrónico.

## Requerimientos

  * [Docker](https://www.docker.com/)
  * [Postgres](https://www.postgresql.org/)
  * Servidor de correo SMPT

Ejemplo de como desplegar en un servidor linux

Crear una carpeta `compritas`

    mkdir ~/compritas

Copiar los archivos de la carpeta `deploy` a la carpeta `compritas` creada.

    cp deploy/* ~/compritas

Ingresar a la carpeta `compritas`
		
    cd ~/compritas
		
Renombrar el archivo `env.sample` a `.env` y personalizar según corresponda

    mv env.sample .env

Levantar los servicios

    docker compose up -d

## Descripción de los archivos de la carpeta `deploy`

**Archivos importantes**

|Archivo|Descripción|
|--|--|
|Caddyfile  | [Caddy](https://caddyserver.com/) es un servidor proxy; se usa como balanceador de carga para la aplicación y soportar SSL a través de [Letsencrypt](https://letsencrypt.org). |
|docker-compose.yml|Archivo [Docker Compose](https://docs.docker.com/compose/) para desplegar los servicios.|
|env.sample|Un archivo .env de ejemplo que contiene las variables del sistema requeridas.|


**Otros archivos**

|Archivo|Descripción|
|--|--|
|deploy.sh|Se usa para desplegar una nueva versión de la aplicación.|
|setup-swap.sh|Script para incrementar el tamaño de la memoria SWAP, Solo si los recursos del servidor son muy limitados. |


