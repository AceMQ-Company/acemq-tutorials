// Step 8 for .NET: the same publish and consume as step 1, written the way a
// .NET Generic Host application writes it. AceMq.Amqp.Hosting opens the
// connection, declares the topology in appsettings.json, and resolves the
// handler from the container for every message; stopping the host drains it.
//
// A real worker ends with `await host.RunAsync()` and stops on Ctrl-C or
// SIGTERM. This one starts the host, publishes three orders, waits for them,
// and stops it, so that it ends with a status.

using AceMq.Amqp;
using AceMq.Amqp.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Tutorial;

// appsettings.json is read from beside the program, wherever it is run from.
var builder = Host.CreateApplicationBuilder(
    new HostApplicationBuilderSettings { Args = args, ContentRootPath = AppContext.BaseDirectory });

// The tutorial image sets ACEMQ_URL; appsettings.json has the local default.
if (Environment.GetEnvironmentVariable("ACEMQ_URL") is { Length: > 0 } url)
{
    builder.Configuration["acemq:url"] = url;
}

builder.Services
    .AddAceMq(builder.Configuration.GetSection("acemq"))
    .AddConsumer<Order, OrderHandler>("tutorial.orders.new");
builder.Services.AddSingleton<Received>();

using var host = builder.Build();
await host.StartAsync();

// The provider rather than AceMqConnection: it awaits the connection instead of
// blocking on it.
var mq = await host.Services.GetRequiredService<IAceMqConnectionProvider>().GetAsync();
var orders = mq.Publisher<Order>("tutorial.orders", "order.created");
for (var n = 1; n <= 3; n++)
{
    // Returns once the broker has confirmed it: confirms are on by default.
    await orders.SendAsync(new Order($"o-{n}", n));
    Console.WriteLine($"published o-{n}");
}

var ok = await host.Services.GetRequiredService<Received>().AllThree(TimeSpan.FromSeconds(15));

// What Ctrl-C does to a worker: the consumer stops taking deliveries, finishes
// the ones it has, and the connection closes.
await host.StopAsync();

if (!ok)
{
    Console.Error.WriteLine("the handler did not receive all three orders within 15s");
    return 1;
}
Console.WriteLine("three published, three received, drained on stop");
return 0;

namespace Tutorial
{
    /// <summary>What travels on the queue, encoded as JSON by default.</summary>
    public sealed record Order(string Id, int Quantity);

    /// <summary>
    /// An ordinary service: constructor injection, a fresh scope per message.
    /// Returning Accept acknowledges; throwing rejects.
    /// </summary>
    public sealed class OrderHandler : IMessageHandler<Order>
    {
        private readonly Received _received;

        public OrderHandler(Received received) => _received = received;

        public Task<Ack> HandleAsync(IMessage<Order> message, CancellationToken cancellationToken)
        {
            Console.WriteLine($"received {message.Payload.Id} for {message.Payload.Quantity} unit(s)");
            _received.One();
            return Task.FromResult(Ack.Accept());
        }
    }

    /// <summary>Counts what the handler saw, so the program can wait for it.</summary>
    public sealed class Received
    {
        private readonly TaskCompletionSource _all = new(TaskCreationOptions.RunContinuationsAsynchronously);
        private int _count;

        public void One()
        {
            if (Interlocked.Increment(ref _count) == 3) _all.TrySetResult();
        }

        public async Task<bool> AllThree(TimeSpan timeout)
        {
            try
            {
                await _all.Task.WaitAsync(timeout);
                return true;
            }
            catch (TimeoutException)
            {
                return false;
            }
        }
    }
}
