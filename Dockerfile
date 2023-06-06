# syntax=docker/dockerfile:1

ARG PYTHON_VERSION

ARG DIR_APP="/app"
ARG DIR_CACHE="/var/cache/app"
ARG GROUP_ID=9999
ARG USER_ID=9999
ARG USERNAME=ex


# ~~~~ Target: build-task ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# purpose: to build `task` app: see https://taskfile.dev

FROM --platform=linux/amd64 golang:1.20.4-alpine3.18 AS build-task
ENV GOBIN=/app/bin
WORKDIR /app
RUN go install github.com/go-task/task/v3/cmd/task@latest


# ~~~~ Target: base ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# purpose: build system packages, Python packages, venv


FROM --platform=linux/amd64 python:${PYTHON_VERSION}-alpine3.18 AS base
LABEL description="example-django-mssql-docker"
LABEL org.opencontainers.image.authors="Alexander Sidorov <alexander@sidorov.dev>"

# install system packages

RUN --mount=type=cache,target=/var/cache/apk \
    apk update && apk add --no-interactive --upgrade \
    bash \
    curl \
    g++ \
    libffi-dev \
    unixodbc-dev \
    && curl -O https://download.microsoft.com/download/1/f/f/1fffb537-26ab-4947-a46a-7a45c27f6f77/msodbcsql18_18.2.1.1-1_amd64.apk \
    && curl -O https://download.microsoft.com/download/1/f/f/1fffb537-26ab-4947-a46a-7a45c27f6f77/mssql-tools18_18.2.1.1-1_amd64.apk \
    && apk add --allow-untrusted --no-interactive --upgrade msodbcsql18_18.2.1.1-1_amd64.apk \
    && apk add --allow-untrusted --no-interactive --upgrade mssql-tools18_18.2.1.1-1_amd64.apk


# install system Python apps

ARG PIP_VERSION
RUN pip install "pip==${PIP_VERSION}"

ARG POETRY_VERSION
RUN pip install "poetry==${POETRY_VERSION}"


# create non-root user and its dirs

ARG DIR_APP
ARG DIR_CACHE
ARG GROUP_ID
ARG USER_ID
ARG USERNAME

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
    && install --owner ${USERNAME} --group ${USERNAME} --directory "${DIR_CACHE}"

WORKDIR "${DIR_APP}"

USER ${USERNAME}

# create virtual env using Poetry

COPY ./pyproject.toml ./poetry.lock ./

ENV POETRY_NO_INTERACTION=1
ENV POETRY_VIRTUALENVS_ALWAYS_COPY=false
ENV POETRY_VIRTUALENVS_CREATE=true
ENV POETRY_VIRTUALENVS_IN_PROJECT=false
ENV POETRY_VIRTUALENVS_PATH="${DIR_CACHE}"
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONUTF8=1

RUN poetry env use "${PYTHON_VERSION}" \
    && poetry env info > "${DIR_CACHE}/.poetry-env-info.txt" \
    && poetry install --without dev --no-root


# ~~~~ Target: production ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# purpose: the image itself

FROM --platform=linux/amd64 python:${PYTHON_VERSION}-alpine3.18 AS production

ARG DIR_APP
ARG DIR_CACHE
ARG GROUP_ID
ARG USER_ID
ARG USERNAME

# create non-root user and its dirs

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
    && install --owner ${USERNAME} --group ${USERNAME} --directory "${DIR_CACHE}"

# copy stuff from previous stages

COPY --from=base "${DIR_CACHE}" "${DIR_CACHE}"
COPY --from=base "/usr/lib/libstdc++.so*" /usr/lib/
COPY --from=base /bin/bash /bin/bash
COPY --from=base /etc/*odbc* /etc/
COPY --from=base /opt/microsoft/ /opt/microsoft/
COPY --from=base /opt/mssql-tools18/ /opt/mssql-tools18/
COPY --from=base /usr/bin/*odbc* /usr/bin/
COPY --from=base /usr/lib/*odbc* /usr/lib/
COPY --from=base /usr/lib/libgcc_s.so* /usr/lib/
COPY --from=base /usr/local/bin/poetry /usr/local/bin/poetry
# fixme: the path depends on python version. The project uses 3.11.3 so it's safe for a while
COPY --from=base /usr/local/lib/python3.11/site-packages/ /usr/local/lib/python3.11/site-packages/
COPY --from=build-task /app/bin/task /usr/bin/task

RUN chown ${USER_ID}:${GROUP_ID} /opt/microsoft/ /opt/mssql-tools18/ 

WORKDIR "${DIR_APP}"

USER ${USERNAME}

COPY . .

# let Poetry know about previously built venv

ENV POETRY_NO_INTERACTION=1
ENV POETRY_VIRTUALENVS_ALWAYS_COPY=false
ENV POETRY_VIRTUALENVS_CREATE=true
ENV POETRY_VIRTUALENVS_IN_PROJECT=false
ENV POETRY_VIRTUALENVS_PATH="${DIR_CACHE}"
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONUTF8=1

# integrate static stuff into this image

RUN task collect-static

# fixme: depends on Gunicorn settings, but I don't care
EXPOSE 80
