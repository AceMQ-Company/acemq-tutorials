# Learn AceMQ, in any language

AceMQ is a family of messaging libraries for RabbitMQ — for Java, Python, Ruby,
.NET and Go — that teach the same ideas in the same order: publish with a
confirm, retry without blocking, dead-letter and replay, never process twice,
call and reply, keep a log, and see what happened.

This is the one place to start. It is a path of seven steps; each step runs in
all five languages, with one command and nothing installed but Docker:

```bash
docker run --rm -p 15672:15672 ghcr.io/acemq-company/acemq-tutorials-python:0.7.17 step 1
```

The image carries the toolchain, the library at a released version, the
tutorial code and a RabbitMQ broker. While a step runs, the broker's management
UI is at <http://localhost:15672> (guest/guest). Swap `python` for `java`,
`ruby`, `dotnet` or `go`; [the images](images.md) lists every tag.

## The path

<!-- path -->

Each step page shows the five languages side by side, links each example at the
exact commit the image was built from, and points to that library's own
tutorial and guide. Nothing here is a second copy of either: the examples live
in each library's examples repository, where CI runs every one of them against a
real broker, and the prose lives in each library's documentation.

## Inside an image

```bash
docker run --rm ghcr.io/acemq-company/acemq-tutorials-go:0.9.14                 # list the steps
docker run --rm -p 15672:15672 ghcr.io/acemq-company/acemq-tutorials-go:0.9.14 step 3 --keep
docker run --rm -it ghcr.io/acemq-company/acemq-tutorials-go:0.9.14 shell       # a shell, broker running
docker run --rm -p 5672:5672 -p 15672:15672 ghcr.io/acemq-company/acemq-tutorials-go:0.9.14 broker
```

`shell` opens a shell in the examples checkout with the toolchain on the `PATH`
and the broker running, so you can change an example and run it again.
`broker` is the broker alone, for pointing your own code at.

## Where to go next

Every library has a site of its own, with the full guide and a set of tutorials
that go further than the path does:
[Java](https://acemq.org/acemq-java-amqp/),
[Python](https://acemq.org/acemq-python-amqp/),
[Ruby](https://acemq.org/acemq-ruby-amqp/),
[.NET](https://acemq.org/acemq-dotnet-amqp/) and
[Go](https://acemq.org/acemq-go-amqp/).
The examples repositories have many more examples than the path uses — topology
as data, codecs, encryption, claim checks, consumer groups, graceful shutdown —
and three small applications each.
