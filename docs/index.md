# Learn AceMQ, in any language

AceMQ is a family of messaging libraries for RabbitMQ — for Java, Python, Ruby,
.NET and Go — that teach the same ideas in the same order: publish with a
confirm, retry without blocking, dead-letter and replay, never process twice,
call and reply, keep a log, see what happened, and do all of it from inside the
framework you already use.

This is the one place to start. It is a path of eight steps; each step runs in
all five languages, with one command and nothing installed but Docker:

```bash
docker run --rm -p 15672:15672 ghcr.io/acemq-company/acemq-tutorials-python:0.7.17 step 1
```

The image carries the library at a released version, the tutorial code, built,
the runtime that runs it and a RabbitMQ broker. While a step runs, the broker's management
UI is at <http://localhost:15672> (guest/guest). Swap `python` for `java`,
`ruby`, `dotnet` or `go`; [the images](images.md) lists every tag. For .NET in
Visual Basic rather than C#, add `-e TUTORIAL_VARIANT=vbnet`:

```bash
docker run --rm -p 15672:15672 -e TUTORIAL_VARIANT=vbnet ghcr.io/acemq-company/acemq-tutorials-dotnet:0.7.18 step 1
```

## The path

<!-- path -->

Each step page shows the five languages side by side, links each example at the
exact commit the image was built from, and points to that library's own
tutorial and guide. Nothing here is a second copy of either: the examples live
in each library's examples repository, where CI runs every one of them against a
real broker, and the prose lives in each library's documentation. Step 8 is the
exception: the framework integrations have no examples repository, so its four
examples live in this one, in
[`integrations/`](https://github.com/AceMQ-Company/acemq-tutorials/tree/main/integrations).

## Inside an image

```bash
docker run --rm ghcr.io/acemq-company/acemq-tutorials-go:0.9.14                 # list the steps
docker run --rm -p 15672:15672 ghcr.io/acemq-company/acemq-tutorials-go:0.9.14 step 3 --keep
docker run --rm -it ghcr.io/acemq-company/acemq-tutorials-go:0.9.14 shell       # a shell, broker running
docker run --rm -p 5672:5672 -p 15672:15672 ghcr.io/acemq-company/acemq-tutorials-go:0.9.14 broker
```

`shell` opens a shell in the examples checkout with the broker running. In the
Python and Ruby images an example runs from its source, so you can change one
and run it again. The Java, .NET and Go images carry the examples built and a
runtime, not a compiler — that is what keeps them small — so to change one of
those, clone its examples repository.
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
