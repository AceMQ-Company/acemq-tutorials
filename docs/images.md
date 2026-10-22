# The images

One image per language, on the GitHub Container Registry, each tagged with the
version of the library it carries:

<!-- images -->

Every image also has a `latest` tag, and a `<library version>-t<tutorials
version>` tag that never moves — `0.7.12-t0.1.0`, say — for anybody who needs to
know that what they pull tomorrow is what they pulled today. The library-version
tag moves when this repository releases again for the same library version, to
pick up a fix to the path or to the images.

Images are built for `linux/amd64` and `linux/arm64`, so they run natively on
Apple silicon as well as on x86.

## What is in one

| Path | What |
|---|---|
| the base image | the official `rabbitmq` management image, on Ubuntu 24.04 |
| the toolchain | Temurin 21 and Maven, Python 3.12, Ruby 3.2 and Bundler, the .NET 8 SDK, or Go 1.25 |
| `/tutorials/examples` | the language's examples repository at the pinned commit, built |
| `/tutorials/path` | the path: which steps there are and which examples each runs |
| `/usr/local/bin/tutorial` | the entrypoint: `list`, `step <n> [--keep]`, `all`, `shell`, `broker`, `version` |

The broker starts when a command needs it, as the `rabbitmq` user, with its log
in `/var/log/rabbitmq/tutorial-broker.log` rather than on your terminal.
`ACEMQ_URL` (and `AMQP_URL`, which the Java examples read) point every example
at it.

## Or with Compose

The broker inside the image is the point — one command, nothing else to start —
but if you would rather run the broker separately, or point several languages at
one broker, [`compose.yaml`](https://github.com/AceMQ-Company/acemq-tutorials/blob/main/compose.yaml)
in the repository does that. Each language runs the same `step` command, against
a broker of its own service instead of its own process:

```bash
docker compose up -d broker
docker compose run --rm python step 3
docker compose run --rm go step 3
```

## Building one yourself

```bash
git clone https://github.com/AceMQ-Company/acemq-tutorials && cd acemq-tutorials
./etc/build-image.sh python
docker run --rm ghcr.io/acemq-company/acemq-tutorials-python:0.7.15 all
```

`pins.env` holds every version an image is built from.
