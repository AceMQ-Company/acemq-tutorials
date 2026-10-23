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
- **The broker version is not checked.** `RABBITMQ_IMAGE` in `pins.env` is moved
  by hand. The libraries support 3.13 and 4.x; the images carry 4.3.6.
- **The Java runtime is a whole JRE** (0.16 GB of the 0.53 GB image). A
  `jlink`ed runtime of just the modules the examples use would be smaller, at
  the cost of a module list to keep right as the examples change.
- **A link from the landing page** at acemq.org to this site — the landing page
  is maintained separately.
