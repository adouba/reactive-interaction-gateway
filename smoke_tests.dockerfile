FROM elixir:1.9

# Install Elixir & Erlang environment dependencies
RUN mix local.hex --force
RUN mix local.rebar --force

WORKDIR /opt/sites/rig

# Copy release config
COPY version /opt/sites/rig/

# Copy necessary files for dependencies
COPY mix.exs /opt/sites/rig/
COPY mix.lock /opt/sites/rig/

# Install project dependencies
RUN mix deps.get

# Copy application files

COPY config /opt/sites/rig/config
COPY lib /opt/sites/rig/lib

# Proxy
EXPOSE 4000
# Internal APIs
EXPOSE 4010

# Precompile
RUN MIX_ENV=test mix compile

CMD ["mix", "test", "--only", "smoke"]
