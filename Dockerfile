FROM elixir:1.15

# Instala dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    ffmpeg \
    unzip \
    zip \
    zlib1g-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Cria diretório do app
WORKDIR /app

# Copia os arquivos do projeto
COPY . .

# Instala dependências do Elixir (opcional, dependendo do seu projeto)
RUN mix local.hex --force && mix local.rebar --force && mix deps.get

# Você pode adicionar aqui o build do seu app, se necessário
# RUN mix deps.get
# RUN mix compile

CMD ["mix", "phx.server"]
