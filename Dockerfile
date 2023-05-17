# syntax=docker/dockerfile:1

ARG PYTHON_VERSION


# ==============================================
# ~~~~~~~~ Stage 0: Task ~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


FROM golang:bullseye@sha256:a0b51fe882f269828b63e7f69e6925f85afc548cf7cf967ecbfbcce6afe6f235 AS build-task
ENV GOBIN=/app/bin
WORKDIR /app
RUN go install github.com/go-task/task/v3/cmd/task@latest


# ==============================================
# ~~~~~~~~ Stage 1: webapp ~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


FROM --platform=linux/amd64 python:${PYTHON_VERSION}-slim
LABEL description="example.django-mssql-docker"
LABEL org.opencontainers.image.authors="Alexander Sidorov <alexander@sidorov.dev>"

# ~~~~~~~~ System packages ~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

COPY --from=build-task /app/bin/task /usr/bin/task

RUN apt update \
    && apt install --no-install-recommends --yes \
    bash \
    curl \
    g++ \
    gnupg2 \
    libffi-dev \
    libpq-dev \
    netcat \
    python3-dev


RUN (curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -) \
    && (curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list) \
    && apt-get update

ENV ACCEPT_EULA=Y

RUN apt-get install --yes \
    libgssapi-krb5-2 \
    msodbcsql18 \
    mssql-tools18 \
    unixodbc \
    unixodbc-dev


# ~~~~~~~~ Poetry & Python dependencies ~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ARG PIP_VERSION
RUN pip install "pip==${PIP_VERSION}"

ARG POETRY_VERSION
RUN pip install "poetry==${POETRY_VERSION}"


# ~~~~~~~~ User & App directories ~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ARG GROUP_ID=9999
ARG USER_ID=9999
ARG USERNAME=mercury

ARG DIR_APP="/app"
ARG DIR_CACHE="/var/cache/app"

RUN addgroup --system --gid ${GROUP_ID} ${USERNAME} \
    && useradd \
        --create-home \
        --no-log-init \
        --system \
        --home-dir="/home/${USERNAME}" \
        --gid=${GROUP_ID} \
        --uid=${USER_ID} \
        ${USERNAME} \
    && install --owner ${USERNAME} --group ${USERNAME} --directory "${DIR_APP}" \
    && install --owner ${USERNAME} --group ${USERNAME} --directory "${DIR_CACHE}"

WORKDIR "${DIR_APP}"

USER ${USERNAME}


# ~~~~~~~~ Virtualenv ~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

COPY ./pyproject.toml ./poetry.lock ./

ENV POETRY_VIRTUALENVS_ALWAYS_COPY=false
ENV POETRY_VIRTUALENVS_CREATE=true
ENV POETRY_VIRTUALENVS_IN_PROJECT=false
ENV POETRY_VIRTUALENVS_PATH="${DIR_CACHE}"
ENV PYTHONPYCACHEPREFIX="${DIR_APP}/.local/docker/pycache"
ENV PYTHONUNBUFFERED=1
ENV PYTHONUTF8=1

RUN poetry env use "${PYTHON_VERSION}" \
    && poetry env info > "${DIR_CACHE}/.poetry-env-info.txt"
RUN poetry install --with dev --sync


COPY . .

RUN task collect-static

EXPOSE 80
