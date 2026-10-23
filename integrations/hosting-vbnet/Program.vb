' Step 8 for .NET, in VB.NET: the same program as its C# twin. The Generic Host
' and AceMq.Amqp.Hosting are called the same way from either language.
'
' A real worker ends with host.RunAsync() and stops on Ctrl-C or SIGTERM. This
' one starts the host, publishes three orders, waits for them, and stops it, so
' that it ends with a status.

Imports System.Threading
Imports System.Threading.Tasks

Imports AceMq.Amqp
Imports AceMq.Amqp.Hosting
Imports Microsoft.Extensions.DependencyInjection
Imports Microsoft.Extensions.Hosting

''' <summary>What travels on the queue, encoded as JSON by default.</summary>
Public Class Order
    Public Property Id As String = ""
    Public Property Quantity As Integer
End Class

''' <summary>
''' An ordinary service: constructor injection, a fresh scope per message.
''' Returning Accept acknowledges; throwing rejects.
''' </summary>
Public NotInheritable Class OrderHandler
    Implements IMessageHandler(Of Order)

    Private ReadOnly _received As Received

    Public Sub New(received As Received)
        _received = received
    End Sub

    Public Function HandleAsync(message As IMessage(Of Order), cancellationToken As CancellationToken) As Task(Of Ack) _
        Implements IMessageHandler(Of Order).HandleAsync
        Console.WriteLine($"received {message.Payload.Id} for {message.Payload.Quantity} unit(s)")
        _received.One()
        Return Task.FromResult(Ack.Accept())
    End Function
End Class

''' <summary>Counts what the handler saw, so the program can wait for it.</summary>
Public NotInheritable Class Received
    Private ReadOnly _all As New TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)
    Private _count As Integer

    Public Sub One()
        If Interlocked.Increment(_count) = 3 Then _all.TrySetResult()
    End Sub

    Public Async Function AllThree(timeout As TimeSpan) As Task(Of Boolean)
        Try
            Await _all.Task.WaitAsync(timeout)
            Return True
        Catch ex As TimeoutException
            Return False
        End Try
    End Function
End Class

Module Program

    Function Main(args As String()) As Integer
        Return RunAsync(args).GetAwaiter().GetResult()
    End Function

    Private Async Function RunAsync(args As String()) As Task(Of Integer)
        ' appsettings.json is read from beside the program, wherever it is run from.
        Dim builder = Host.CreateApplicationBuilder(
            New HostApplicationBuilderSettings With {.Args = args, .ContentRootPath = AppContext.BaseDirectory})

        ' The tutorial image sets ACEMQ_URL; appsettings.json has the local default.
        Dim url = Environment.GetEnvironmentVariable("ACEMQ_URL")
        If Not String.IsNullOrEmpty(url) Then builder.Configuration("acemq:url") = url

        builder.Services _
            .AddAceMq(builder.Configuration.GetSection("acemq")) _
            .AddConsumer(Of Order, OrderHandler)("tutorial.orders.new")
        builder.Services.AddSingleton(Of Received)()

        Using app = builder.Build()
            Await app.StartAsync()

            ' The provider rather than AceMqConnection: it awaits the connection
            ' instead of blocking on it.
            Dim mq = Await app.Services.GetRequiredService(Of IAceMqConnectionProvider)().GetAsync()
            Dim orders = mq.Publisher(Of Order)("tutorial.orders", "order.created")
            For n = 1 To 3
                ' Returns once the broker has confirmed it: confirms are on by default.
                Await orders.SendAsync(New Order With {.Id = $"o-{n}", .Quantity = n})
                Console.WriteLine($"published o-{n}")
            Next

            Dim ok = Await app.Services.GetRequiredService(Of Received)().AllThree(TimeSpan.FromSeconds(15))

            ' What Ctrl-C does to a worker: the consumer stops taking deliveries,
            ' finishes the ones it has, and the connection closes.
            Await app.StopAsync()

            If Not ok Then
                Console.Error.WriteLine("the handler did not receive all three orders within 15s")
                Return 1
            End If
        End Using
        Console.WriteLine("three published, three received, drained on stop")
        Return 0
    End Function

End Module
