ARG PYTHON_VERSION=3.12
ARG NODE_VERSION=20
ARG USER=pn

FROM nikolaik/python-nodejs:python${PYTHON_VERSION}-nodejs${NODE_VERSION}-slim as poetry
ARG USER
ENV PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    POETRY_VIRTUALENVS_CREATE=true \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_CACHE_DIR="/home/${USER}/poetry-cache"
RUN poetry self add poetry-plugin-up \
    && poetry config virtualenvs.create ${POETRY_VIRTUALENVS_CREATE} \
    && poetry config virtualenvs.in-project ${POETRY_VIRTUALENVS_IN_PROJECT} \
    && poetry config cache-dir ${POETRY_CACHE_DIR} \
    && chown -R ${USER}:${USER} ${POETRY_CACHE_DIR} \
    && poetry --version
COPY pyproject.toml poetry.lock* ./
RUN poetry export --without-hashes --only main -f requirements.txt > requirements.txt \
    && rm pyproject.toml poetry.lock*

FROM poetry as dev
ARG USER
ENV NODE_ENV=development \
    PYTHONPYCACHEPREFIX="/home/${USER}/.cache/cpython/"
RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
    git \
    openssh-client \
    sudo \
    vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
WORKDIR "/home/${USER}/app"
# Install Python dependencies
COPY --chown=${USER}:${USER} pyproject.toml poetry.lock* ./
RUN poetry install --no-root --no-interaction --no-ansi
# Install frontend dependencies
RUN mkdir frontend
COPY --chown=${USER}:${USER} frontend/package*.json frontend/
RUN cd frontend \
    && npm install
# Copy project files
COPY --chown=${USER}:${USER} . .

FROM node:${NODE_VERSION}-alpine as frontend-build
ENV NODE_ENV=development
WORKDIR /frontend
COPY frontend .
RUN npm install
RUN npm run build

FROM python:${PYTHON_VERSION}-slim as prod
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DEFAULT_TIMEOUT=100 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_IGNORE_INSTALLED=1 \
    PIP_NO_CACHE_DIR=1
COPY --from=poetry /requirements.txt ./
RUN pip install --upgrade --quiet pip \
    && pip install --upgrade --quiet -r requirements.txt \
    && rm -rf requirements.txt
COPY . .
COPY --from=frontend-build /frontend/dist ./frontend/dist
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0"]
