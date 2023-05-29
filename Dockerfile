# syntax=docker/dockerfile:1

ARG PYTHON_VERSION


# ==============================================
# ~~~~~~~~ Stage 0: Task ~~~~~~~~~~~~~~~~~~~~~~~


FROM --platform=linux/amd64 golang:1.20.4-alpine3.18 AS build-task
ENV GOBIN=/app/bin
WORKDIR /app
RUN go install github.com/go-task/task/v3/cmd/task@latest


# ==============================================
# ~~~~~~~~ Stage 1: webapp ~~~~~~~~~~~~~~~~~~~~~


FROM --platform=linux/amd64 python:${PYTHON_VERSION}-alpine3.18 AS staging
LABEL description="example-django-mssql-docker"
LABEL org.opencontainers.image.authors="Alexander Sidorov <alexander@sidorov.dev>"


# ~~~~~~~~ System packages ~~~~~~~~~~~~~~~~~~~~~

# COPY --from=build-task /app/bin/task /usr/bin/task

RUN --mount=type=cache,target=/var/cache/apt/archives \
    apk update && apk add --no-interactive --upgrade \
    bash \
    curl \
    g++ \
    unixodbc-dev \
    && curl -O https://download.microsoft.com/download/1/f/f/1fffb537-26ab-4947-a46a-7a45c27f6f77/msodbcsql18_18.2.1.1-1_amd64.apk \
    && curl -O https://download.microsoft.com/download/1/f/f/1fffb537-26ab-4947-a46a-7a45c27f6f77/mssql-tools18_18.2.1.1-1_amd64.apk \
    && apk add --allow-untrusted --no-cache --no-interactive --purge --upgrade msodbcsql18_18.2.1.1-1_amd64.apk \
    && apk add --allow-untrusted --no-cache --no-interactive --purge --upgrade mssql-tools18_18.2.1.1-1_amd64.apk


# ~~~~~~~~ Poetry & Python dependencies ~~~~~~~~

ARG PIP_VERSION
RUN pip install "pip==${PIP_VERSION}"

ARG POETRY_VERSION
RUN pip install "poetry==${POETRY_VERSION}"


# ~~~~~~~~ User & App directories ~~~~~~~~~~~~~~

ARG GROUP_ID=9999
ARG USER_ID=9999
ARG USERNAME=mercury

ARG DIR_APP="/app"
ARG DIR_CACHE="/var/cache/app"

RUN addgroup --gid ${GROUP_ID} --system ${USERNAME} \
    && adduser \
        --disabled-password \
        --home="/home/${USERNAME}" \
        --ingroup=${USERNAME} \
        --shell=/bin/bash \
        --system \
        --uid=${USER_ID} \
        ${USERNAME} \
    && install --owner ${USERNAME} --group ${USERNAME} --directory "${DIR_APP}" \
    && install --owner ${USERNAME} --group ${USERNAME} --directory "${DIR_APP}/dist" \
    && install --owner ${USERNAME} --group ${USERNAME} --directory "${DIR_CACHE}"

WORKDIR "${DIR_APP}"

USER ${USERNAME}


# ~~~~~~~~ Virtualenv ~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

COPY ./pyproject.toml ./poetry.lock ./

ENV POETRY_NO_INTERACTION=1
ENV POETRY_VIRTUALENVS_ALWAYS_COPY=false
ENV POETRY_VIRTUALENVS_CREATE=true
ENV POETRY_VIRTUALENVS_IN_PROJECT=false
ENV POETRY_VIRTUALENVS_PATH="${DIR_CACHE}"
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONUTF8=1

RUN --mount=type=cache,target="${DIR_CACHE}",uid="${USER_ID}",gid="${GROUP_ID}" \
    poetry env use "${PYTHON_VERSION}" \
    && poetry env info > "${DIR_CACHE}/.poetry-env-info.txt" \
    && poetry install --without dev --no-root

COPY . .

RUN --mount=type=cache,target="${DIR_CACHE}",uid="${USER_ID}",gid="${GROUP_ID}" \
    poetry build --format wheel \
    && poetry export --format constraints.txt --output constraints.txt --without-hashes

# =================================================================================================


FROM --platform=linux/amd64 python:${PYTHON_VERSION}-alpine3.18 AS production

ARG DIR_APP="/app"
ARG DIR_CACHE="/var/cache/app"

WORKDIR "${DIR_APP}"

USER ${USERNAME}

#COPY --from=build-task /usr/bin/task /usr/bin/task
COPY --from=staging "${DIR_APP}/dist/example_django_mssql_docker-2023.6.1-py3-none-any.whl" ./
COPY --from=staging "${DIR_APP}/constraints.txt" ./
RUN pip install "${DIR_APP}/example_django_mssql_docker-2023.6.1-py3-none-any.whl" --constraint constraints.txt
# COPY . .

# RUN task collect-static

EXPOSE 80
