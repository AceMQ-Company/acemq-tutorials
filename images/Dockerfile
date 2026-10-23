# syntax=docker/dockerfile:1.7
#
# One Dockerfile, one target per language:
#
#   docker build -f images/Dockerfile --target python \
#     --build-arg ACEMQ_VERSION=0.7.12 --build-arg EXAMPLES_COMMIT=<sha> \
#     --build-arg INTEGRATION_VERSION=0.1.10 \
#     -t acemq-tutorials-python .
#
# etc/build-image.sh fills the arguments in from pins.env, which is the only
# place versions are written down.
#
# Every image is the RabbitMQ image with a language runtime added, rather than a
# language image with RabbitMQ added. The broker is the harder of the two to
# install well -- Erlang, OpenSSL and the server are built together upstream --
# while every runtime here is either a package or a self-contained directory
# that can be copied out of its own official image.
#
# Each language is two stages: a build stage with the whole toolchain, and the
# image, which gets what the build produced and the runtime that runs it and
# nothing else. No compiler, SDK, package cache or build tree is in an image.
# The base is the Alpine variant of the RabbitMQ image (musl), so every runtime
# copied in is its Alpine build. Measured sizes are in docs/images.md.
#
# The tutorial code is not in this repository, except step 8's. It is fetched
# from the examples repository at the pinned commit, at build time, so what the
# image runs is exactly what that repository's CI ran. Step 8 is the framework
# integrations, which have no examples repository; their examples are in
# integrations/ here and land in the image at /tutorials/examples/integrations,
# so every directory in path/examples.tsv is relative to the same place.

ARG RABBITMQ_IMAGE=rabbitmq:4.3.6-management-alpine

# The toolchains, for the build stages only.
FROM maven:3.9-eclipse-temurin-21-noble AS maven
FROM mcr.microsoft.com/dotnet/sdk:8.0-noble AS dotnet-sdk
FROM golang:1.25 AS go-sdk
# The runtimes, copied into the images.
FROM eclipse-temurin:21-jre-alpine AS jre
FROM mcr.microsoft.com/dotnet/runtime:8.0-alpine AS dotnet-runtime

FROM ${RABBITMQ_IMAGE} AS base
# bash for the entrypoint; the Alpine image has only busybox sh.
RUN apk add --no-cache bash
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

# Each language below has the same shape. The build stage: toolchain, then the
# examples at the pinned commit, then step 8's integration example beside them,
# then the path files, then a build of exactly the examples the path uses,
# ending in a test that the library resolved is the pinned release. The image:
# the runtime, then the built examples, then the path files and the entrypoint.
# ARG values are scoped to the stage that declares them, so each stage
# redeclares the ones it uses.

# ---------------------------------------------------------------- Java
FROM maven AS java-build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV TUTORIAL_LANG=java
ARG ACEMQ_VERSION
ARG EXAMPLES_COMMIT
ARG INTEGRATION_VERSION
ADD https://github.com/AceMQ-Company/acemq-java-amqp-examples.git#${EXAMPLES_COMMIT} /tutorials/examples
COPY integrations/spring-boot /tutorials/examples/integrations/spring-boot
COPY path /tutorials/path
COPY images/tutorial /usr/local/bin/tutorial
# Compiled, with each module's runtime classpath copied beside it, so a step
# starts a JVM rather than Maven. The main class comes from the module's own
# exec-maven-plugin configuration -- the one `mvn exec:java` would use. The
# Spring Boot example is a project of its own, not a module of the examples'.
# The modules' classpaths share most of their jars (281 copies of 55), so each
# jar is kept once in /tutorials/lib and every classpath links to it.
RUN cd /tutorials/examples \
 && mods="$(tutorial dirs | grep -v '^integrations/' | paste -sd, -)" \
 && mvn -B -q --no-transfer-progress -Dacemq.version="$ACEMQ_VERSION" -DskipTests \
        -pl "$mods" -am package dependency:copy-dependencies -DincludeScope=runtime \
 && (cd integrations/spring-boot \
     && mvn -B -q --no-transfer-progress -Dacemq.version="$ACEMQ_VERSION" -Dstarter.version="$INTEGRATION_VERSION" \
            package dependency:copy-dependencies -DincludeScope=runtime \
     && test -f "target/dependency/acemq-spring-boot-autoconfigure-$INTEGRATION_VERSION.jar") \
 && for m in $(tutorial dirs); do \
      sed -n 's:.*<mainClass>\(.*\)</mainClass>.*:\1:p' "$m/pom.xml" > "$m/target/main-class"; \
      test -s "$m/target/main-class"; \
      test -f "$m/target/dependency/acemq-amqp-core-$ACEMQ_VERSION.jar"; \
    done \
 && mkdir /tutorials/lib \
 && for j in */*/target/dependency/*.jar; do \
      [ -f "/tutorials/lib/${j##*/}" ] || mv "$j" /tutorials/lib/; \
      ln -sf "/tutorials/lib/${j##*/}" "$j"; \
    done \
 && echo "$ACEMQ_VERSION" > /tutorials/LIBRARY_VERSION && echo "$EXAMPLES_COMMIT" > /tutorials/EXAMPLES_COMMIT \
 && echo "acemq-spring-boot-starter $INTEGRATION_VERSION" > /tutorials/INTEGRATION_VERSION

FROM base AS java
COPY --from=jre /opt/java/openjdk /opt/java/openjdk
ENV JAVA_HOME=/opt/java/openjdk \
    PATH=/opt/java/openjdk/bin:$PATH \
    TUTORIAL_LANG=java
COPY --from=java-build /tutorials /tutorials
COPY images/tutorial /usr/local/bin/tutorial
ARG ACEMQ_VERSION
LABEL org.opencontainers.image.source=https://github.com/AceMQ-Company/acemq-tutorials \
      org.opencontainers.image.description="AceMQ for Java tutorials, with RabbitMQ inside" \
      org.opencontainers.image.licenses=Apache-2.0 \
      org.opencontainers.image.version=${ACEMQ_VERSION}

# ---------------------------------------------------------------- Python
# The virtual environment is built on the same base it runs on, so the
# interpreter it links to is at the same path; the compilers a wheel without a
# musl build would need stay in this stage.
FROM base AS python-build
RUN apk add --no-cache python3 build-base python3-dev libffi-dev
ENV PATH=/opt/venv/bin:$PATH TUTORIAL_LANG=python PIP_DISABLE_PIP_VERSION_CHECK=1
ARG ACEMQ_VERSION
ARG EXAMPLES_COMMIT
ARG INTEGRATION_VERSION
ADD https://github.com/AceMQ-Company/acemq-python-amqp-examples.git#${EXAMPLES_COMMIT} /tutorials/examples
COPY integrations/fastapi /tutorials/examples/integrations/fastapi
# requirements.txt pins the release itself; the test is what notices a pin
# that says otherwise. The integration goes into the same environment, held to
# the same library release.
RUN python3 -m venv /opt/venv \
 && pip install --no-cache-dir -r /tutorials/examples/requirements.txt \
 && pip install --no-cache-dir -r /tutorials/examples/integrations/fastapi/requirements.txt \
        "acemq-amqp-fastapi==$INTEGRATION_VERSION" "acemq-amqp==$ACEMQ_VERSION" \
 && pip uninstall -y -q pip \
 && test "$(python -c 'import importlib.metadata as m; print(m.version("acemq-amqp"))')" = "$ACEMQ_VERSION" \
 && test "$(python -c 'import importlib.metadata as m; print(m.version("acemq-amqp-fastapi"))')" = "$INTEGRATION_VERSION" \
 && echo "$ACEMQ_VERSION" > /tutorials/LIBRARY_VERSION && echo "$EXAMPLES_COMMIT" > /tutorials/EXAMPLES_COMMIT \
 && echo "acemq-amqp-fastapi $INTEGRATION_VERSION" > /tutorials/INTEGRATION_VERSION

FROM base AS python
RUN apk add --no-cache python3
ENV PATH=/opt/venv/bin:$PATH TUTORIAL_LANG=python
COPY --from=python-build /opt/venv /opt/venv
COPY --from=python-build /tutorials /tutorials
COPY path /tutorials/path
COPY images/tutorial /usr/local/bin/tutorial
ARG ACEMQ_VERSION
LABEL org.opencontainers.image.source=https://github.com/AceMQ-Company/acemq-tutorials \
      org.opencontainers.image.description="AceMQ for Python tutorials, with RabbitMQ inside" \
      org.opencontainers.image.licenses=Apache-2.0 \
      org.opencontainers.image.version=${ACEMQ_VERSION}

# ---------------------------------------------------------------- Ruby
# Gems are installed on the same base they run on, into BUNDLE_PATH, which the
# image copies; the compilers native extensions need stay in this stage.
FROM base AS ruby-build
RUN apk add --no-cache ruby ruby-dev ruby-bundler build-base yaml-dev openssl-dev libffi-dev
ENV TUTORIAL_LANG=ruby BUNDLE_SILENCE_ROOT_WARNING=1 BUNDLE_PATH=/usr/local/bundle
ARG ACEMQ_VERSION
ARG EXAMPLES_COMMIT
ARG INTEGRATION_VERSION
ADD https://github.com/AceMQ-Company/acemq-ruby-amqp-examples.git#${EXAMPLES_COMMIT} /tutorials/examples
COPY integrations/rails /tutorials/examples/integrations/rails
# The Gemfile asks for "~> 0.7" and no lock is committed, by that repository's
# choice; the lock written here is this image's, and the test holds it to the
# pinned release. The Rails example has a Gemfile of its own, resolved here with
# both versions named exactly.
RUN cd /tutorials/examples && rm -f Gemfile.lock \
 && bundle install --jobs 4 --quiet \
 && test "$(bundle exec ruby -e 'print Gem.loaded_specs["acemq-amqp"].version')" = "$ACEMQ_VERSION" \
 && cd integrations/rails \
 && ACEMQ_VERSION="$ACEMQ_VERSION" ACEMQ_RAILS_VERSION="$INTEGRATION_VERSION" bundle install --jobs 4 --quiet \
 && test "$(bundle exec ruby -e 'print Gem.loaded_specs["acemq-amqp"].version')" = "$ACEMQ_VERSION" \
 && test "$(bundle exec ruby -e 'print Gem.loaded_specs["acemq-amqp-rails"].version')" = "$INTEGRATION_VERSION" \
 && rm -rf "$BUNDLE_PATH"/ruby/*/cache && find "$BUNDLE_PATH" -name "*.o" -delete \
 && echo "$ACEMQ_VERSION" > /tutorials/LIBRARY_VERSION && echo "$EXAMPLES_COMMIT" > /tutorials/EXAMPLES_COMMIT \
 && echo "acemq-amqp-rails $INTEGRATION_VERSION" > /tutorials/INTEGRATION_VERSION

FROM base AS ruby
RUN apk add --no-cache ruby ruby-bundler yaml libffi libstdc++
ENV TUTORIAL_LANG=ruby BUNDLE_SILENCE_ROOT_WARNING=1 BUNDLE_PATH=/usr/local/bundle
COPY --from=ruby-build /usr/local/bundle /usr/local/bundle
COPY --from=ruby-build /tutorials /tutorials
COPY path /tutorials/path
COPY images/tutorial /usr/local/bin/tutorial
ARG ACEMQ_VERSION
LABEL org.opencontainers.image.source=https://github.com/AceMQ-Company/acemq-tutorials \
      org.opencontainers.image.description="AceMQ for Ruby tutorials, with RabbitMQ inside" \
      org.opencontainers.image.licenses=Apache-2.0 \
      org.opencontainers.image.version=${ACEMQ_VERSION}

# ---------------------------------------------------------------- .NET
FROM dotnet-sdk AS dotnet-build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1 TUTORIAL_LANG=dotnet
ARG ACEMQ_VERSION
ARG EXAMPLES_COMMIT
ARG INTEGRATION_VERSION
ADD https://github.com/AceMQ-Company/acemq-dotnet-amqp-examples.git#${EXAMPLES_COMMIT} /tutorials/examples
COPY integrations/Directory.Build.props integrations/nuget.config integrations/hosting-appsettings.json /tutorials/examples/integrations/
COPY integrations/hosting-csharp /tutorials/examples/integrations/hosting-csharp
COPY integrations/hosting-vbnet /tutorials/examples/integrations/hosting-vbnet
COPY path /tutorials/path
COPY images/tutorial /usr/local/bin/tutorial
# Published framework-dependent, so the image needs the .NET runtime and not the
# SDK. Every C# example the path uses and its VB.NET twin (TUTORIAL_VARIANT=vbnet
# runs those), each into /tutorials/bin/<directory with / as _>.
RUN cd /tutorials/examples \
 && for d in $(tutorial dirs); do \
      for p in "$d" "${d%-csharp}-vbnet"; do \
        [ -d "$p" ] || continue; \
        dotnet publish -c Release -v quiet -p:AceMqVersion="$ACEMQ_VERSION" -p:HostingVersion="$INTEGRATION_VERSION" \
          -o "/tutorials/bin/${p//\//_}" "$p" \
        && grep -q "\"AceMq.Amqp/$ACEMQ_VERSION\"" "$p/obj/project.assets.json" || exit 1; \
        case "$p" in integrations/*) grep -q "\"AceMq.Amqp.Hosting/$INTEGRATION_VERSION\"" "$p/obj/project.assets.json" || exit 1;; esac; \
      done; \
    done \
 && find . -depth -type d \( -name bin -o -name obj \) -exec rm -rf {} + \
 && echo "$ACEMQ_VERSION" > /tutorials/LIBRARY_VERSION && echo "$EXAMPLES_COMMIT" > /tutorials/EXAMPLES_COMMIT \
 && echo "AceMq.Amqp.Hosting $INTEGRATION_VERSION" > /tutorials/INTEGRATION_VERSION

FROM base AS dotnet
# What the .NET runtime needs on Alpine: the C++ runtime, ICU for globalization,
# and Kerberos, TLS and zlib, which the runtime loads by name.
RUN apk add --no-cache libgcc libstdc++ icu-libs icu-data-full krb5-libs libssl3 zlib
COPY --from=dotnet-runtime /usr/share/dotnet /usr/share/dotnet
ENV DOTNET_ROOT=/usr/share/dotnet PATH=/usr/share/dotnet:$PATH \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1 TUTORIAL_LANG=dotnet
COPY --from=dotnet-build /tutorials /tutorials
COPY images/tutorial /usr/local/bin/tutorial
ARG ACEMQ_VERSION
LABEL org.opencontainers.image.source=https://github.com/AceMQ-Company/acemq-tutorials \
      org.opencontainers.image.description="AceMQ for .NET tutorials, with RabbitMQ inside" \
      org.opencontainers.image.licenses=Apache-2.0 \
      org.opencontainers.image.version=${ACEMQ_VERSION}

# ---------------------------------------------------------------- Go
FROM go-sdk AS go-build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV CGO_ENABLED=0 TUTORIAL_LANG=go
ARG ACEMQ_VERSION
ARG EXAMPLES_COMMIT
ADD https://github.com/AceMQ-Company/acemq-go-amqp-examples.git#${EXAMPLES_COMMIT} /tutorials/examples
COPY path /tutorials/path
COPY images/tutorial /usr/local/bin/tutorial
# Built in each example's own directory, so the nested modules (advanced/06
# is one) resolve their own go.mod. The binary is named after the directory,
# static, so the image needs no Go at all.
RUN cd /tutorials/examples \
 && for d in $(tutorial dirs); do \
      (cd "$d" && go build -trimpath -ldflags='-s -w' -o "/tutorials/bin/${d//\//_}" . \
        && test "$(go list -m -f '{{.Version}}' github.com/AceMQ-Company/acemq-go-amqp)" = "v$ACEMQ_VERSION") || exit 1; \
    done \
 && echo "$ACEMQ_VERSION" > /tutorials/LIBRARY_VERSION && echo "$EXAMPLES_COMMIT" > /tutorials/EXAMPLES_COMMIT

FROM base AS go
ENV TUTORIAL_LANG=go
COPY --from=go-build /tutorials /tutorials
COPY images/tutorial /usr/local/bin/tutorial
ARG ACEMQ_VERSION
LABEL org.opencontainers.image.source=https://github.com/AceMQ-Company/acemq-tutorials \
      org.opencontainers.image.description="AceMQ for Go tutorials, with RabbitMQ inside" \
      org.opencontainers.image.licenses=Apache-2.0 \
      org.opencontainers.image.version=${ACEMQ_VERSION}
