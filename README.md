# Example: Django + MS SQL + Docker

## Description

This is a bootstrap setup for a single service (webapp). The service is shipped as Docker image. The service will provide a Django/DRF webapp, which displays the tables within the given DB.

Includes:
1. [Task](https://taskfile.dev).
2. [Poetry](https://python-poetry.org/).
3. DB drivers: [ODBC](https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server) and [PostgreSQL](https://www.psycopg.org/docs/).
4. [Non-root user](https://betterprogramming.pub/running-a-container-with-a-non-root-user-e35830d1f42a)
5. [Caches](https://docs.docker.com/build/cache/)

Current size: ~230 MB

## Usage

The service utilizes a given MS SQL.
Unfortunately MS SQL does not respect URLs, so you have to configure each aspect
of credentials explicitly. See `.env.sample` for examples. `WEBAPP_` is a prefix for env vars.

After successful build & run,
you can open [http://localhost:8000/](http://localhost:8000/)
and observe list of tables in your MS SQL database.

## Installation

Before doing something, make sure that you have

1. copied `.env.sample` to `.env`
2. modified values in `.env` according to your realm

### Docker

First, hit `docker compose build`.

Next, hit `task docker-up` OR `docker compose up -d`.

### Bare metal

#### Mac OS

If you have [brew](https://brew.sh/), [pyenv](https://github.com/pyenv/pyenv) and [Task](https://taskfile.dev/) installed, this would be enough:

`task setup-toolchain`

#### Linux

First, be sure you're installed Microsoft ODBC drivers. [Here are](https://github.com/mkleehammer/pyodbc/wiki/Install) some key points.

Next, if you have [pyenv](https://github.com/pyenv/pyenv) and [Task](https://taskfile.dev/) installed, this might be enough:

`task setup-toolchain`

I haven't checked yet this way, please send me a feedback in case of any bug.

#### Other

1. be sure you have Microsoft ODBC drivers installed. [Here are](https://github.com/mkleehammer/pyodbc/wiki/Install) some key points.
2. install [Python 3.11.3](https://www.python.org/downloads/release/python-3113/)
3. install [Poetry 1.4.2](https://python-poetry.org/docs/#installation)
4. bind Python 3.11.3 to the cloned directory (this project)
5. create venv and install dependencies: `poetry install --with dev --sync`
6. double-check your `.env`
7. start webapp with `poetry run python manage.py runserver 0.0.0.0:8000`
