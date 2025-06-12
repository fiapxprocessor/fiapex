# Dockerfile
FROM elixir:1.15

# Instala o FFmpeg e dependências
RUN apt-get update && \
    apt-get install -y git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Instala ferramentas Elixir
RUN mix local.hex --force && \
    mix local.rebar --force

WORKDIR /app

COPY . .

# Instala dependências Elixir
RUN apt-get update && apt-get install -y ffmpeg
RUN apt-get update && apt-get install -y unzip zip zlib1g-dev
RUN mix deps.get
RUN mix compile

# Expondo a porta padrão do Phoenix
EXPOSE 4000

CMD ["mix", "phx.server"]
