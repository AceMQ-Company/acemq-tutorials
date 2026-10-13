# syntax=docker/dockerfile:1.7
#
# One Dockerfile, one target per language:
#
#   docker build -f images/Dockerfile --target python \
#     --build-arg ACEMQ_VERSION=0.7.12 --build-arg EXAMPLES_COMMIT=<sha> \
#     -t acemq-tutorials-python .
#
# etc/build-image.sh fills the arguments in from pins.env, which is the only
# place versions are written down.
#
# Every image is the RabbitMQ image with a language toolchain added, rather than
# a language image with RabbitMQ added. The broker is the harder of the two to
# install well -- Erlang, OpenSSL and the server are built together upstream --
# while every toolchain here is either a package or a self-contained directory
# that can be copied out of its own official image.
#
# The tutorial code is not in this repository. It is fetched from the examples
# repository at the pinned commit, at build time, so what the image runs is
# exactly what that repository's CI ran.

ARG RABBITMQ_IMAGE=rabbitmq:4.3.6-management

FROM eclipse-temurin:21-jdk-noble AS jdk
FROM maven:3.9-eclipse-temurin-21-noble AS maven
FROM mcr.microsoft.com/dotnet/sdk:8.0-noble AS dotnet-sdk
FROM golang:1.25 AS go-sdk

FROM ${RABBITMQ_IMAGE} AS base
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# The Erlang cookie on the command line, for the server and for every CLI tool.
# See start_broker in images/tutorial for why not a file.
ENV RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="-setcookie acemq-tutorials" \
    RABBITMQ_CTL_ERL_ARGS="-setcookie acemq-tutorials" \
    ACEMQ_URL=amqp://guest:guest@localhost:5672 \
    AMQP_URL=amqp://guest:guest@localhost:5672
EXPOSE 5672 15672
ENTRYPOINT ["tutorial"]
CMD ["list"]

# Each language stage below has the same shape: toolchain, then the examples at
# the pinned commit, then the path files, then a build of exactly the examples
# the path uses, ending in a test that the library resolved is the pinned
# release. The toolchain comes first so that editing the path rebuilds the
# examples and nothing before them. ARG values are scoped to the stage that
# declares them, so each stage redeclares the two it uses.

# ---------------------------------------------------------------- Java
FROM base AS java
COPY --from=jdk /opt/java/openjdk /opt/java/openjdk
COPY --from=maven /usr/share/maven /usr/share/maven
ENV JAVA_HOME=/opt/java/openjdk \
    PATH=/opt/java/openjdk/bin:/usr/share/maven/bin:$PATH \
    TUTORIAL_LANG=java
ARG ACEMQ_VERSION
ARG EXAMPLES_COMMIT
ADD https://github.com/AceMQ-Company/acemq-java-amqp-examples.git#${EXAMPLES_COMMIT} /tutorials/examples
COPY path /tutorials/path
COPY images/tutorial /usr/local/bin/tutorial
# Compiled, with each module's runtime classpath copied beside it, so a step
# starts a JVM rather than Maven. The main class comes from the module's own
# exec-maven-plugin configuration -- the one `mvn exec:java` would use.
RUN cd /tutorials/examples \
 && mods="$(tutorial dirs | paste -sd, -)" \
 && mvn -B -q --no-transfer-progress -Dacemq.version="$ACEMQ_VERSION" -DskipTests \
        -pl "$mods" -am package dependency:copy-dependencies -DincludeScope=runtime \
 && for m in $(tutorial dirs); do \
      sed -n 's:.*<mainClass>\(.*\)</mainClass>.*:\1:p' "$m/pom.xml" > "$m/target/main-class"; \
      test -s "$m/target/main-class"; \
      test -f "$m/target/dependency/acemq-amqp-core-$ACEMQ_VERSION.jar"; \
    done \
 && echo "$ACEMQ_VERSION" > /tutorials/LIBRARY_VERSION && echo "$EXAMPLES_COMMIT" > /tutorials/EXAMPLES_COMMIT
LABEL org.opencontainers.image.source=https://github.com/AceMQ-Company/acemq-tutorials \
      org.opencontainers.image.description="AceMQ for Java tutorials, with RabbitMQ inside" \
      org.opencontainers.image.licenses=Apache-2.0 \
      org.opencontainers.image.version=${ACEMQ_VERSION}

# ---------------------------------------------------------------- Python
FROM base AS python
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-venv \
 && rm -rf /var/lib/apt/lists/*
ENV PATH=/opt/venv/bin:$PATH TUTORIAL_LANG=python PIP_DISABLE_PIP_VERSION_CHECK=1
ARG ACEMQ_VERSION
ARG EXAMPLES_COMMIT
ADD https://github.com/AceMQ-Company/acemq-python-amqp-examples.git#${EXAMPLES_COMMIT} /tutorials/examples
COPY path /tutorials/path
COPY images/tutorial /usr/local/bin/tutorial
# requirements.txt pins the release itself; the test is what notices a pin
# that says otherwise.
RUN python3 -m venv /opt/venv \
 && pip install --no-cache-dir -r /tutorials/examples/requirements.txt \
 && test "$(python -c 'import importlib.metadata as m; print(m.version("acemq-amqp"))')" = "$ACEMQ_VERSION" \
 && echo "$ACEMQ_VERSION" > /tutorials/LIBRARY_VERSION && echo "$EXAMPLES_COMMIT" > /tutorials/EXAMPLES_COMMIT
LABEL org.opencontainers.image.source=https://github.com/AceMQ-Company/acemq-tutorials \
      org.opencontainers.image.description="AceMQ for Python tutorials, with RabbitMQ inside" \
      org.opencontainers.image.licenses=Apache-2.0 \
      org.opencontainers.image.version=${ACEMQ_VERSION}

# ---------------------------------------------------------------- Ruby
FROM base AS ruby
RUN apt-get update && apt-get install -y --no-install-recommends ruby ruby-dev ruby-bundler build-essential libyaml-dev libssl-dev \
 && rm -rf /var/lib/apt/lists/*
ENV TUTORIAL_LANG=ruby BUNDLE_SILENCE_ROOT_WARNING=1
ARG ACEMQ_VERSION
ARG EXAMPLES_COMMIT
ADD https://github.com/AceMQ-Company/acemq-ruby-amqp-examples.git#${EXAMPLES_COMMIT} /tutorials/examples
COPY path /tutorials/path
COPY images/tutorial /usr/local/bin/tutorial
# The Gemfile asks for "~> 0.7" and no lock is committed, by that repository's
# choice; the lock written here is this image's, and the test holds it to the
# pinned release.
RUN cd /tutorials/examples && rm -f Gemfile.lock \
 && bundle install --jobs 4 --quiet \
 && test "$(bundle exec ruby -e 'print Gem.loaded_specs["acemq-amqp"].version')" = "$ACEMQ_VERSION" \
 && echo "$ACEMQ_VERSION" > /tutorials/LIBRARY_VERSION && echo "$EXAMPLES_COMMIT" > /tutorials/EXAMPLES_COMMIT
LABEL org.opencontainers.image.source=https://github.com/AceMQ-Company/acemq-tutorials \
      org.opencontainers.image.description="AceMQ for Ruby tutorials, with RabbitMQ inside" \
      org.opencontainers.image.licenses=Apache-2.0 \
      org.opencontainers.image.version=${ACEMQ_VERSION}

# ---------------------------------------------------------------- .NET
FROM base AS dotnet
RUN apt-get update && apt-get install -y --no-install-recommends libicu74 \
 && rm -rf /var/lib/apt/lists/*
COPY --from=dotnet-sdk /usr/share/dotnet /usr/share/dotnet
ENV DOTNET_ROOT=/usr/share/dotnet PATH=/usr/share/dotnet:$PATH \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1 TUTORIAL_LANG=dotnet
ARG ACEMQ_VERSION
ARG EXAMPLES_COMMIT
ADD https://github.com/AceMQ-Company/acemq-dotnet-amqp-examples.git#${EXAMPLES_COMMIT} /tutorials/examples
COPY path /tutorials/path
COPY images/tutorial /usr/local/bin/tutorial
RUN cd /tutorials/examples \
 && for d in $(tutorial dirs); do \
      dotnet build -c Release -v quiet -p:AceMqVersion="$ACEMQ_VERSION" "$d" \
      && grep -q "\"AceMq.Amqp/$ACEMQ_VERSION\"" "$d/obj/project.assets.json" || exit 1; \
    done \
 && echo "$ACEMQ_VERSION" > /tutorials/LIBRARY_VERSION && echo "$EXAMPLES_COMMIT" > /tutorials/EXAMPLES_COMMIT
LABEL org.opencontainers.image.source=https://github.com/AceMQ-Company/acemq-tutorials \
      org.opencontainers.image.description="AceMQ for .NET tutorials, with RabbitMQ inside" \
      org.opencontainers.image.licenses=Apache-2.0 \
      org.opencontainers.image.version=${ACEMQ_VERSION}

# ---------------------------------------------------------------- Go
FROM base AS go
COPY --from=go-sdk /usr/local/go /usr/local/go
ENV PATH=/usr/local/go/bin:/root/go/bin:$PATH CGO_ENABLED=0 TUTORIAL_LANG=go
ARG ACEMQ_VERSION
ARG EXAMPLES_COMMIT
ADD https://github.com/AceMQ-Company/acemq-go-amqp-examples.git#${EXAMPLES_COMMIT} /tutorials/examples
COPY path /tutorials/path
COPY images/tutorial /usr/local/bin/tutorial
# Built in each example's own directory, so the nested modules (advanced/06
# is one) resolve their own go.mod. The binary is named after the directory.
RUN cd /tutorials/examples \
 && for d in $(tutorial dirs); do \
      (cd "$d" && go build -o "/tutorials/bin/${d//\//_}" . \
        && test "$(go list -m -f '{{.Version}}' github.com/AceMQ-Company/acemq-go-amqp)" = "v$ACEMQ_VERSION") || exit 1; \
    done \
 && echo "$ACEMQ_VERSION" > /tutorials/LIBRARY_VERSION && echo "$EXAMPLES_COMMIT" > /tutorials/EXAMPLES_COMMIT
LABEL org.opencontainers.image.source=https://github.com/AceMQ-Company/acemq-tutorials \
      org.opencontainers.image.description="AceMQ for Go tutorials, with RabbitMQ inside" \
      org.opencontainers.image.licenses=Apache-2.0 \
      org.opencontainers.image.version=${ACEMQ_VERSION}
