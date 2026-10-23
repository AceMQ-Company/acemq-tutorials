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
| the base image | the official `rabbitmq` management image, on Alpine Linux |
| the runtime | the Temurin 21 JRE, Python 3.12, Ruby 3.4 and Bundler, or the .NET 8 runtime; Go needs none |
| `/tutorials/examples` | the language's examples repository at the pinned commit, built, with step 8's example in `integrations/` |
| `/tutorials/path` | the path: which steps there are and which examples each runs |
| `/usr/local/bin/tutorial` | the entrypoint: `list`, `step <n> [--keep]`, `all`, `shell`, `broker`, `version` |

There is no compiler, SDK or build tool in an image: every example is built in a
separate stage and only its output is copied in. In the Python and Ruby images
an example runs from its source, so `shell` lets you change one and run it
again; in the Java, .NET and Go images it is compiled, and changing one means
its examples repository, or building the image yourself (below).

`tutorial version` prints the library release, the examples commit and, for the
four languages that have one, the framework integration step 8 runs.

## Visual Basic

The .NET image carries the VB.NET twin of every example the path uses, built.
`TUTORIAL_VARIANT=vbnet` runs those instead of the C# ones:

```bash
docker run --rm -p 15672:15672 -e TUTORIAL_VARIANT=vbnet ghcr.io/acemq-company/acemq-tutorials-dotnet:0.7.18 step 8
```

## Size

Measured on `linux/arm64` as `docker image inspect` reports it, for the same
pins (Java 0.7.20, Python 0.7.17, Ruby 0.7.19, .NET 0.7.18, Go 0.9.14), before
and after the images moved to Alpine and a build stage per language
(2026-10-23). *After* also carries step 8, and for .NET the VB.NET twins.

| Image | Before | After | |
|---|---|---|---|
| Java | 1.19 GB | 0.53 GB | −55% |
| Python | 0.55 GB | 0.41 GB | −25% |
| Ruby | 0.99 GB | 0.42 GB | −58% |
| .NET | 1.42 GB | 0.47 GB | −67% |
| Go | 1.08 GB | 0.36 GB | −67% |

About 0.27 GB of each is the broker image. What came out: the JDK and Maven
(Java keeps a JRE, and one copy of each jar its examples share instead of one
per example), the .NET SDK (the runtime stays), the Go toolchain (the binaries
are static), and the compilers and headers Ruby and Python's native packages
are built with.

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
docker run --rm ghcr.io/acemq-company/acemq-tutorials-python:0.7.17 all
```

`pins.env` holds every version an image is built from.
