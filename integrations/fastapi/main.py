"""Step 8 for Python: the same publish and consume as step 1, written the way a
FastAPI application writes it.

acemq-amqp-fastapi's lifespan opens the connection and starts the consumers when
the application starts, and drains them when it stops; a route publishes through
a dependency. Served for real, this is ``uvicorn main:app``. Run as a script, it
drives the same application through FastAPI's TestClient -- which runs the real
lifespan against the real broker -- posts three orders, waits for the consumer to
see them, and leaves, so that it ends with a status.
"""

import asyncio
import sys
from typing import Annotated

from acemq_amqp import Ack, Message, Publisher, accept
from acemq_fastapi import AceMQ, AceMQSettings, publishes
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient

QUEUE = "tutorial.orders.new"

# Settings come from ACEMQ_* environment variables -- the tutorial image sets
# ACEMQ_URL -- and anything written here. The topology is declared when the
# lifespan opens, before the consumers start; nothing declared means nothing is.
acemq = AceMQ(
    AceMQSettings(
        topology={
            "exchanges": [{"name": "tutorial.orders", "kind": "topic"}],
            "queues": [{"name": QUEUE}],
            "bindings": [
                {"queue": QUEUE, "exchange": "tutorial.orders", "routing_key": "order.created"}
            ],
        }
    )
)
received: list[dict] = []
all_three = asyncio.Event()


@acemq.consumer(QUEUE)
async def on_order(message: Message) -> Ack:
    """Started on the application's own event loop. accept() acknowledges."""
    order = message.payload
    print(f"received {order['id']} for {order['quantity']} unit(s)")
    received.append(order)
    if len(received) == 3:
        all_three.set()
    return accept()


app = FastAPI(lifespan=acemq.lifespan)
app.include_router(acemq.health_router())  # GET /health/acemq

# A publisher for one destination, injected into the route.
Orders = Annotated[Publisher, Depends(publishes("order.created", exchange="tutorial.orders"))]


@app.post("/orders/{order_id}")
async def place(order_id: str, quantity: int, orders: Orders) -> dict[str, str]:
    # Returns once the broker has confirmed it: the library always confirms.
    result = await orders.send({"id": order_id, "quantity": quantity})
    return {"id": order_id, "message_id": result.message_id}


def main() -> int:
    # Entering the block runs the lifespan; leaving it is the ASGI shutdown, and
    # the drain.
    with TestClient(app) as client:
        print("health:", client.get("/health/acemq").json()["status"])
        for n in (1, 2, 3):
            client.post(f"/orders/o-{n}", params={"quantity": n}).raise_for_status()
            print(f"published o-{n}")
        try:
            # The handlers run on the application's loop, not this thread's.
            client.portal.call(lambda: asyncio.wait_for(all_three.wait(), 15))
        except TimeoutError:
            print("the consumer did not receive all three orders within 15s", file=sys.stderr)
            return 1
    print("three published, three received, drained on shutdown")
    return 0


if __name__ == "__main__":
    sys.exit(main())
