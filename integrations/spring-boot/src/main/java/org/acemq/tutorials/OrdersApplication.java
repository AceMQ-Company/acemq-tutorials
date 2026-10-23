package org.acemq.tutorials;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import org.acemq.amqp.core.AceMq;
import org.acemq.spring.boot.AceListener;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Service;

/**
 * Step 8 for Java: the same publish and consume as step 1, written the way a Spring Boot
 * application writes it. The starter opens the connection, declares the topology in
 * application.yml, and runs the {@code @AceListener} method; the application injects
 * {@link AceMq} and publishes. Closing the context drains the listener.
 */
@SpringBootApplication
public class OrdersApplication {

    /** What travels on the queue, encoded as JSON by the starter's default codec. */
    public record Order(String id, int quantity) {}

    /** Sends: an ordinary service with {@link AceMq} injected. */
    @Service
    static class OrderService {
        private final AceMq mq;

        OrderService(AceMq mq) {
            this.mq = mq;
        }

        void place(Order order) {
            // Returns once the broker has confirmed it: confirms are on by default.
            mq.publisher("tutorial.orders", "order.created", Order.class).send(order);
            System.out.println("published " + order.id());
        }
    }

    /** Receives: returning normally acknowledges, throwing rejects. */
    @Component
    static class OrderListener {
        final CountDownLatch received = new CountDownLatch(3);

        @AceListener(queue = "tutorial.orders.new")
        void onOrder(Order order) {
            System.out.println("received " + order.id() + " for " + order.quantity() + " unit(s)");
            received.countDown();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        ConfigurableApplicationContext context = SpringApplication.run(OrdersApplication.class, args);
        boolean ok;
        try {
            OrderService orders = context.getBean(OrderService.class);
            for (int n = 1; n <= 3; n++) {
                orders.place(new Order("o-" + n, n));
            }
            ok = context.getBean(OrderListener.class).received.await(15, TimeUnit.SECONDS);
        } finally {
            // What a SIGTERM does to a Boot application: the listener stops taking
            // deliveries, finishes the ones it has, and the connection closes.
            context.close();
        }
        if (!ok) {
            System.err.println("the listener did not receive all three orders within 15s");
            System.exit(1);
        }
        System.out.println("three published, three received, drained on close");
    }
}
