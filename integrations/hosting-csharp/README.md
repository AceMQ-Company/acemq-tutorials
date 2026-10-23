# .NET hosting, in C#

The step 1 program as a .NET Generic Host worker with AceMq.Amqp.Hosting:
`AddAceMq` binds the connection and the topology from `appsettings.json`,
`AddConsumer<Order, OrderHandler>` registers a handler resolved from the
container for every message, and stopping the host drains it.

A real worker ends with `host.RunAsync()`. This one starts the host, publishes
three orders, waits for the handler to see them and stops it, so that it ends
with a status. [`hosting-vbnet`](../hosting-vbnet) is the same program in VB.NET.
