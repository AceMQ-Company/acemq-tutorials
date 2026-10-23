# FastAPI

The step 1 program as a FastAPI application with acemq-amqp-fastapi: its lifespan
opens the connection, declares the topology and starts the `@acemq.consumer`
handler when the application starts, a route publishes through an injected
`Publisher`, and the lifespan drains on the way out.

Served for real it is `uvicorn main:app`. Run as a script, `main.py` drives the
same application through FastAPI's `TestClient`, which runs the real lifespan
against the real broker: it posts three orders, waits for the consumer and
leaves, so that it ends with a status.
