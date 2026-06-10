FROM python:3.11-slim

# System deps: compilers for verification gates
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    rustc \
    cargo \
    golang-go \
    gfortran \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY pyproject.toml ./
COPY src/ ./src/

RUN pip install --no-cache-dir -e ".[api]"

# Warm the LLM cache dir
RUN mkdir -p /root/.cache/transpilers/llm

ENV HOST=0.0.0.0
ENV PORT=8000

EXPOSE 8000

CMD ["python", "-m", "transpilers.api.server"]
