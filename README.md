# Compritas

[![Compritas](https://github.com/joselo/compritas/workflows/Elixir%20CI/badge.svg)](https://github.com/joselo/compritas/actions)

Compritas es una aplicación web de comercio electrónico y facturación electrónica para Ecuador;  Use [Phoenix](https://phoenixframework.org/) un framework web escrito en el lenguaje [Elixir](https://elixir-lang.org/). 

> IMPORTANTE: El desarrollo de la aplicación está en proceso, aún no se libera el primer reléase.


Algunas secciones del desarrollo las he estado desarrollando en vivo transmitiendo en [YouTube](https://www.youtube.com/watch?v=73sglmNSK5A&list=PLS3D8lZZio6oKttRZfuytjSgh1RGNTit7).

## Requerimientos

  * [Elixir](https://elixir-lang.org/)
  * [Erlang](https://www.erlang.org/)
  * [Postgresql](https://www.postgresql.org/)

## Levantar el proyecto en el entorno local

> Si ya estás familiarizado con Elixir y Phoenix y cuentas con todo instalado, puedes seguir los siguientes pasos; de lo contrario, mira los [Requerimientos para desarrollo](#requerimientos-para-desarrollo).

Clonar el repositorio localmente e ingresar a la carpeta del proyecto

    git clone https://github.com/joselo/compritas
    cd compritas

Instalar las dependencias del proyecto y crear la base de datos

    mix setup

Iniciar el servidor de la aplicación

    mix phx.server

Si todo ha ido correctamente visita: http://localhost:4000/

# Funcionalidades

 - [x] Carrito de compras
 - [x] Procesamiento de órdenes
 - [x] Cotizaciones
 - [x] Facturación electrónica
 - [x] Catálogo de productos
 - [x] Gestión de clientes
 - [x] Gestión de empresas
 - [x] Gestión de firmas electrónicas
 - [ ] Asistente IA
 - [ ] Temas para la tienda
 - [ ] Notas de credito
 - [ ] Notas de debito
 - [ ] Guías de remisión
 - [ ] Plataforma de pago
 - [ ] Gestión de envios

# Requerimientos para desarrollo

Se recomienda usar [Hombrew](https://brew.sh):

Crear un archivo llamado `Brewfile` con las siguientes formulas:

```
brew "erlang"
brew "elixir"
brew "inotify-tools"
brew "postgresql@14", restart_service: :changed
brew "watchman"
```

Una vez creado el archivo `Brewfile` por ejemplo en `/tmp/Brewfile`, ejecutar el siguiente comando para instalar las formulas:

    brew bundle --file=/tmp/Brewfile

Realizada la instalacion se debe crear un super usuario en postgres:

    createuser --superuser postgres

Comprobar si podemos conectarnos a postgres:

    psql -Upostgres

### Dependencias para Debian/Ubuntu

Se recomienda tambien instalar las siguientes dependencias:

    sudo apt-get install build-essential libncurses5-dev libncursesw5-dev libssl-dev


# Notas de desarrollo

## Actualiar traducciones

    mix gettext.extract --merge

## IA Tidewave

El proyecto incluye una librería para realizar cambios usando inteligencia artificial:

 - [Tidewave](https://tidewave.ai/)

Para realizar cambios en la aplicación usando IA abrir la siguiente dirección http://localhost:4000/tidewave

## Licencia

Este proyecto está bajo la Licencia MIT.
Consulta el archivo [LICENSE](./LICENSE.md) para más detalles.


