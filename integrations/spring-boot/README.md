# Spring Boot

The step 1 program as a Spring Boot application with the AceMQ starter: the
starter opens the connection and declares the exchange, queue and binding in
`application.yml`, an `@AceListener` method consumes, a service with `AceMq`
injected publishes, and closing the context drains the listener.

`OrdersApplication.main` starts the application, places three orders, waits for
the listener to see them, and closes the context, so that it ends with a status.
A real service would leave the context running until it is told to stop.
