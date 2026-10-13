# Roadmap

What is left, roughly in order.

## Gaps in the examples repositories

These are not this repository's to fix; each is the examples repository's.

- **No standalone confirms example outside Java.** Only
  `acemq-java-amqp-examples/basic/01-publish-and-confirm` is about confirms.
  The path folds confirms into step 1 because every library confirms by
  default, but a step of its own on what a nack, a timeout and `mandatory` look
  like would need an example in the other four.

## Here

- **A release after every bump is cut by hand.** `bump-pins` lands new pins on
  main by itself, but the images for them are published only by the next
  tutorials release ([RELEASING.md](RELEASING.md)), so for a while the README
  names an image tag that is not pushed yet. Releasing automatically is a
  workflow away; it is held back only because a version is tagged when
  somebody decides to.
- **The integrations.** The Spring Boot starter, .NET hosting, FastAPI and Rails
  integrations each have their own docs and examples; a step 8, "in your
  framework", would link them. Go has no integration.
- **Visual Basic.** .NET runs the C# example of each pair. A `TUTORIAL_VARIANT=vbnet`
  switch could run the VB twin instead, from the same image.
- **The broker version is not checked.** `RABBITMQ_IMAGE` in `pins.env` is moved
  by hand. The libraries support 3.13 and 4.x; the images carry 4.3.6.
- **Image size.** Each image is the broker plus a full toolchain (0.55–1.4
  GB). A slimmer runtime-only variant is possible for Java, .NET and Go, at the
  cost of `shell` no longer being able to rebuild an example.
- **A link from the landing page** at acemq.org to this site — the landing page
  is maintained separately.
