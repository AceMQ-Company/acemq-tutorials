# AceMQ tutorials

[![ci](https://github.com/AceMQ-Company/acemq-tutorials/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/AceMQ-Company/acemq-tutorials/actions/workflows/ci.yml)
[![authorship guard](https://github.com/AceMQ-Company/acemq-tutorials/actions/workflows/attribution-guard.yml/badge.svg?branch=main)](https://github.com/AceMQ-Company/acemq-tutorials/actions/workflows/attribution-guard.yml)
[![license](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)

Learn AceMQ in any of its five languages — Java, Python, Ruby, .NET and Go — on
one path of eight steps, each runnable with one command and nothing installed but
Docker:

```bash
docker run --rm -p 15672:15672 ghcr.io/acemq-company/acemq-tutorials-python:0.7.17 step 1
```

**The site is at <https://acemq.org/acemq-tutorials/>.**

| Step | | |
|---|---|---|
| 1 | Your first message | connect, declare, publish with a confirm, consume |
| 2 | Never processing twice | the idempotent consumer |
| 3 | Surviving failure | the retry ladder, dead letters, replay |
| 4 | Request and reply | correlation, reply queue, timeout |
| 5 | Streams | a log you can read from any offset |
| 6 | Outbox, saga and scheduler | the patterns built from the above |
| 7 | Seeing what happens | metrics, health and traces |
| 8 | In your framework | Spring Boot, .NET hosting, FastAPI, Rails (Go has none) |

## The images

| Language | Image |
|---|---|
| Java | `ghcr.io/acemq-company/acemq-tutorials-java:0.7.20` |
| Python | `ghcr.io/acemq-company/acemq-tutorials-python:0.7.17` |
| Ruby | `ghcr.io/acemq-company/acemq-tutorials-ruby:0.7.19` |
| .NET | `ghcr.io/acemq-company/acemq-tutorials-dotnet:0.7.18` |
| Go | `ghcr.io/acemq-company/acemq-tutorials-go:0.9.14` |

Each is tagged with the version of the library it carries, plus `latest` and an
immutable `<library version>-t<tutorials version>`. Each contains the library,
the tutorial code built, the runtime that runs it and a RabbitMQ broker, on
Alpine, for `linux/amd64` and `linux/arm64`: 0.36 to 0.53 GB. `docker run --rm <image>` lists the steps; `step <n> --keep`
holds the broker open for the management UI afterwards; `shell` gives you a
shell in the examples with the broker running; `broker` is the broker alone.
[`compose.yaml`](compose.yaml) runs one broker and points any image at it
instead. The .NET image runs the VB.NET twin of each example with
`-e TUTORIAL_VARIANT=vbnet`.

## What is in this repository, and what is not

This repository owns the **order**, not the content. The code each step runs is
in the language's examples repository —
[Java](https://github.com/AceMQ-Company/acemq-java-amqp-examples),
[Python](https://github.com/AceMQ-Company/acemq-python-amqp-examples),
[Ruby](https://github.com/AceMQ-Company/acemq-ruby-amqp-examples),
[.NET](https://github.com/AceMQ-Company/acemq-dotnet-amqp-examples),
[Go](https://github.com/AceMQ-Company/acemq-go-amqp-examples) —
fetched at a pinned tag when an image is built. The prose is each library's
own documentation, linked from every step. Nothing is copied. The one
exception is step 8: the framework integrations have no examples repository,
so their examples are in [`integrations/`](integrations).

| File | |
|---|---|
| [`pins.env`](pins.env) | every version: library and integration releases, examples tags, broker |
| [`path/`](path) | the steps, and which examples each step runs per language |
| [`integrations/`](integrations) | step 8's examples: Spring Boot, .NET hosting (C# and VB.NET), FastAPI, Rails |
| [`images/`](images) | the Dockerfile (a target per language) and the `tutorial` entrypoint |
| [`docs/`](docs) | the site's pages; [`docs/design.md`](docs/design.md) is the design |
| [`etc/`](etc) | build an image, build the site, check the pins |

```bash
./etc/build-image.sh go                      # build one image from pins.env
docker run --rm ghcr.io/acemq-company/acemq-tutorials-go:0.9.14 all
./etc/check-pins.sh                          # the pins are the newest releases
./etc/build-site.sh                          # render the site into site/
```

CI builds every image and runs every step against its bundled broker, and checks
that the pins are the newest releases — on every push and every Monday. Every
day, `bump-pins` moves the pins to any newer release whose examples repository
has tagged it, after running every step. A `vX.Y.Z` tag publishes the images:
see [RELEASING.md](RELEASING.md). What is left is in [ROADMAP.md](ROADMAP.md).

## Licence

Apache-2.0 — see [LICENSE](LICENSE). The images contain RabbitMQ and other
software under their own licences.
