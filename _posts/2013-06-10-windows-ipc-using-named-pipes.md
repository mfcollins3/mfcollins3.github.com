---
title: Interprocess Communication on Windows using Named Pipes
categories:
- windows_development
category_names:
- Windows Development
---
Writing collaborating programs is common in the modern age. Many programs make use of web services to distribute work between a client application and a server. But not all applications are distributed over a network. It is also common for two programs on the same computer to collaborate by exchanging messages. In this post, we will look at building a request-reply exchange pattern between two Windows programs using named pipes.

<!--more-->

Introduction
------------
In my day job maintaining and enhancing [Neuron ESB](http://www.neuronesb.com), I deal a lot with web services and distributed applications. Being an enterprise service bus, Neuron has integrations with web service technologies such as WCF and HTTP, and it also has an expanding series of adapters that connect to other applications or technologies. Typically when you think of application distribution, you think of deploying programs on different computers over the Internet or an intranet and exchanging messages between them.

However, most distributed systems do not start distributed over a network. Most distributed systems start in development all running on the same developer workstation and passing messages between each other locally on the computer. Many programs are also never distributed over the network. Some programs are designed to exist on the same computer and to exchange messages with each other using a set of technologies called Interprocess Communication, or **IPC**. There are several ways that programs can perform IPC:

* A parent process can spawn a child process and the two programs can exchange messages using the standard input, output, and error streams of the child process.
* Most operating systems have a *pipe* concept which one process can write to and another can read from.
* Desktop applications can interact with each other using the clipboard to transfer data from one application to another via user interaction.
* A program running on the same computer as its clients can expose a web service tied to the computer's loopback adapter. Clients will call the web service like they do other web services, but the message never hits the network.
* Many operating systems have an internal message queue or mailbox system that processes can use to send messages to other processes.

In this post, we're going to take a look at the pipe mechanism for exchanging messages between two programs running on the Microsoft Windows operating system. I will prototype out a protocol that two programs will use to exchange messages using a request-reply message exchange pattern. In the next post, I will use this protocol to implement a management provider that can be used to configure and control a program running on Windows using PowerShell or other management tools like Microsoft's System Center Operations Manager.

About Windows Pipes
-------------------
If you have never used pipes before on Windows, there's nothing magical to worry about. Working with pipes is nearly identical to working with files. You start by creating or opening the pipe that you are going to work with, and then you can read or write to the pipe. There are a couple of minor difference though to keep in mind:

* Depending on your role, a pipe server will create a server pipe object and will have to implement connection management. A pipe client will open a pipe object and will connect to the pipe server.
* Pipes can operate in either byte stream mode or message mode. In byte stream mode, all of the data that is written to the pipe is delivered as a continuous stream of data until the pipe is closed. In message mode, data is delivered in message blocks, so the program reading from the pipe will read one complete message before the data for the next message can be received.

The Windows API supports two kinds of pipes: anonymous and named. Anonymous pipes are useful in parent-child relationships where a parent process spawns a child process and the two processes use pipes to exchange messages. Named pipes are more useful for two processes that run separately and collaborate. A server process will create a named pipe server and the client process will be able to access the pipe using its given name.

In this post, I am going to look specifically at using named pipes.

Getting Started
-----
Following up on my [last post]({% post_url 2013-06-02-minimum-viable-products %}), I am going to use SpecFlow to drive the examples in this post and help me to develop the protocol and a working prototype of the named pipe server and client. To begin with, I will define the first scenario that I want to implement:

{% highlight gherkin %}
Feature: Manage work queues
  In order to maintain responsive clients, long-running activities are
  dispatched to background worker components. The client applications
  will publish messages to work queues that worker components will
  retrieve. The work queue service exposes a management interface that
  management tools can use to list current work queues, and create,
  delete, start, or stop work queues managed by the service.

  Scenario: Create a work queue
    In order to pass work to background workers, a queue needs to exist.
    A management program can send a message to the service to create a
    work queue. The queue will initially be created in the stopped state
    so that the management program can perform additional configuration
    of the work queue before starting it.

    Given the work queue does not exist
    When I create the work queue
    Then the work queue will be created
    And the work queue will be stopped
{% endhighlight %}

If I run this feature through SpecFlow, the scenario is going to fail because the step definitions are missing. I can resolve that by creating the StepDefinitions class and adding the boilerplate code for the step definitions:

{% highlight c# linenos %}
[Binding]
public class StepDefinitions
{
    [Given(@"the work queue does not exist")]
    public void GivenTheWorkQueueDoesNotExist()
    {
       ScenaroContext.Current.Pending();
    }

    [When(@"I create the work queue")]
    public void WhenICreateTheWorkQueue()
    {
        ScenarioContext.Current.Pending();
    }

    [Then(@"the work queue will be created")]
    public void ThenTheWorkQueueWillBeCreated()
    {
        ScenarioContext.Current.Pending();
    }

    [Then(@"the work queue will be stopped")]
    public void ThenTheWorkQueueWillBeStopped()
    {
        ScenarioContext.Current.Pending();
    }
}
{% endhighlight %}

Running the feature again will give me a different result. The test goes from red to yellow. It's not failing, but SpecFlow does report that the test is not fully implemented either because all of the step definitions are in the pending state.

Let us look at the first step:

{% highlight gherkin %}
Given the work queue does not exist
{% endhighlight %}

My goal is to do the minimum possible to make the step succeed. Since I have not implemented anything yet, I have no way to verify whether any work queue exists or not. I can come back to this step later, but for now, I'm going to clear the step's implementation so that this first step succeeds:

{% highlight c# %}
[Given(@"the work queue does not exist")]
public void GivenTheWorkQueueDoesNotExist()
{
    // TODO: come back later to implement
}
{% endhighlight %}

If I run the scenario again, the first step succeeds, but the second step is now stopping the scenario because the second step is also in the pending state. Let's look at the implementation of this step:

{% highlight gherkin %}
When I create the work queue
{% endhighlight %}

For this step, I need to actually do something that is going to create the work queue. Given that my goal is to show how to exchange messages between processes using named pipes, I don't necessarily need to implement two processes, but I should probably pass a message using named pipes to demonstrate how the communication will eventually occur between the work queue service and its clients. To begin with, let us define the message and the protocol that will be used.

###Protocol Design

When designing an IPC protocol, we need to think primarily of two key details:

* the message exchange pattern
* the message format

The message exchange pattern is basically going to fall into one of these categories:

* request-reply
* one-way, client to server
* one-way, server to client

In a request-reply pattern, the client will send a message to the service containing a request or command to be evaluated. After completing the request, the service will respond with a reply message containing any output results or error messages. In the one-way patterns, messages are written from one end of the pipe and consumed by the other, but messages do not flow in the opposite direction. For this example, I am going to implement the request-reply pattern.

For message format, we have to consider what the messages are going to look like. WCF, for example, uses XML SOAP messages to send requests over the wire and return replies. There are also binary formats such as [protocol buffers](http://code.google.com/p/protobuf/) or proprietary data structures that can be used.

For the message formats that I am going to be exchanging over named pipes, I have decided on simple text commands exchanged over the pipes as Unicode strings. I have chosen text because it's simple to implement, simple to test, and I do not need to use any third-party libraries to encode or decode the messages for me.

###Exchanging Messages

My plan for implementing this step is to do the following:

1. Implement the named pipe server to receive a command and return a successful reply.
2. Implement the named pipe client to send a request to the server and receive the reply.
3. Implement the actual work behind creating the work queue.

The request and reply will be pretty simple. The request will look like this:

    CREATE work-queue-name

On success, the reply will look like this:

    OK

If an error occurs, the reply will look like this:

    ERROR error-code error-message

No errors will occur in the initial implementation, but I'll add those in at a later point. For this initial implementation, the server will disconnect the client after processing a single reply. I will change that behavior later.

To implement the named pipe server, I will be using the [NamedPipeServerStream](http://msdn.microsoft.com/en-us/library/system.io.pipes.namedpipeserverstream.aspx) class in the .NET Framework. I will also be making use of the asynchronous operations instead of the synchronous operations so that my client or service does not block except where necessary. I could get by in this initial example by running synchronous operations, but let's be honest, it's an asynchronous world now and it's a good habit to do things asynchronously whenever it makes sense to.

Here's my initial named pipe server implementation:

{% highlight c# linenos %}
const int BufferSize = 32768;
var namedPipeServerStream = new NamedPipeServerStream(
    "WorkQueueService",
    PipeDirection.InOut,
    NamedPipeServerStream.MaxAllowedServerInstances,
    PipeTransmissionMode.Message,
    PipeOptions.Asynchronous,
    BufferSize,
    BufferSize);
var task = Task.Factory.FromAsync(
    namedPipeServerStream.BeginWaitForConnection,
    namedPipeServerStream.EndWaitForConnection,
    null)
    .ContinueWith(t =>
        {
            var commandBuilder = new StringBuilder();
            var commandBuffer = new byte[BufferSize];
                namedPipeServerStream.ReadAsync(
                commandBuffer,
                0,
                commandBuffer.Length)
                .ContinueWith(rt =>
                    {
                        commandBuilder.Append(
                        Encoding.Unicode.GetString(
                            commandBuffer, 0, rt.Result));
                        while (!namedPipeServerStream.IsMessageComplete)
                        {
                            var length = namedPipeServerStream.Read(
                                commandBuffer,
                                0,
                                commandBuffer.Length);
                            commandBuilder.Append(
                                Encoding.Unicode.GetString(
                                    commandBuffer, 0, length));
                        }

                        // TODO: process request

                        var reply = Encoding.Unicode.GetBytes("OK");
                        namedPipeServerStream.Write(
                            reply, 0, reply.Length);
                        namedPipeServerStream.WaitForPipeDrain();
                        namedPipeServerStream.Disconnect();
                    });
        });
{% endhighlight %}

The above code will create a pipe named **WorkQueueService**. After the pipe is created, it will asynchronously wait for a connection to occur. When a connection is established with a name pipe client, the service will asynchronously read the message from the pipe. Because my named pipe server is using message mode, I have to account for the fact that some messages in the future may be larger than the buffer that I have available to receive the message contents. I am using a while look while monitoring the **NamedPipeServerStream.IsMessageComplete** property to determine if the previous **Read** or the **ReadAsync** operation read the complete message. If not, I will read the net message block off of the pipe. When reading messages off of the pipe, I am only doing the initial read asynchronously. I am making the assumption that I want to read asynchronously for the initial message block because I could be waiting a while for the client to send it. Once I have read the first block of a large message, I am making the assumption that the remaining bytes are going to be read quickly without significant blocking, so I am reading the subsequent blocks of the message synchronously. This is ok because the message is being read and processed on a background thread anyways, so the main thread will not block. Finally, after reading and processing the request, I am sending the reply, waiting for the full reply message to be sent to the client, and then I am disconnecting the client from the service.

The client implementation is flow is similar to the server flow:

{% highlight c# linenos %}
var namedPipeClientStream = new NamedPipeClientStream(
    ".",
    "WorkQueueService",
    PipeDirection.InOut,
    PipeOptions.Asynchronous);
namedPipeClientStream.Connect();
namedPipeClientStream.ReadMode = PipeTransmissionMode.Message;
var command = Encoding.Unicode.GetBytes("CREATE MyWorkQueue");
namedPipeClientStream.Write(command, 0, command.Length);
var replyBuilder = new StringBuilder();
var replyBuffer = new byte[BufferSize];
namedPipeClientStream.ReadAsync(replyBuffer, 0, replyBuffer.Length)
    .ContinueWith(t =>
        {
            replyBuilder.Append(Encoding.Unicode.GetString(
                replyBuffer,
                0,
                t.Result));
            while (!namedPipeClientStream.IsMessageComplete)
            {
                var length = namedPipeClientStream.Read(
                    replyBuffer,
                    0,
                    replyBuffer.Length);
                replyBuilder.Append(Encoding.Unicode.GetString(
                    replyBuffer,
                    0,
                    length));
            }

            // TODO: process reply
        });
{% endhighlight %}

The above code will use the [NamedPipeClientStream](http://msdn.microsoft.com/en-us/library/system.io.pipes.namedpipeclientstream.aspx) class to open a connection to the named pipe server. Once the connection is established, the client will send the command to the server and will wait for the reply. I am not doing anything with the reply at the moment, but I will later.

In order to get the step to complete, I am going to combine this code in the step implementation for the moment. At a later point, I will refactor it out. Here's the completed step definition:

{% highlight c# linenos %}
[When(@"I create the work queue")]
public void WhenICreateTheWorkQueue()
{
    const int BufferSize = 32768;
    var namedPipeServerStream = new NamedPipeServerStream(
        "WorkQueueService",
        PipeDirection.InOut,
        NamedPipeServerStream.MaxAllowedServerInstances,
        PipeTransmissionMode.Message,
        PipeOptions.Asynchronous,
        BufferSize,
        BufferSize);
    Task.Factory.FromAsync(
        namedPipeServerStream.BeginWaitForConnection,
        namedPipeServerStream.EndWaitForConnection,
        null)
        .ContinueWith(t =>
        {
            var commandBuilder = new StringBuilder();
            var commandBuffer = new byte[BufferSize];
            namedPipeServerStream.ReadAsync(
                commandBuffer,
                0,
                commandBuffer.Length)
                .ContinueWith(rt =>
                {
                    commandBuilder.Append(
                        Encoding.Unicode.GetString(
                            commandBuffer, 0, rt.Result));
                    while (!namedPipeServerStream.IsMessageComplete)
                    {
                      var length = namedPipeServerStream.Read(
                          commandBuffer,
                          0,
                          commandBuffer.Length);
                      commandBuilder.Append(
                          Encoding.Unicode.GetString(
                          commandBuffer, 0, length));
                    }

                    // TODO: process request

                    var reply = Encoding.Unicode.GetBytes("OK");
                    namedPipeServerStream.Write(reply, 0, reply.Length);
                    namedPipeServerStream.WaitForPipeDrain();
                    namedPipeServerStream.Disconnect();
                });  
        });
    var namedPipeClientStream = new NamedPipeClientStream(
        ".",
        "WorkQueueService",
        PipeDirection.InOut,
        PipeOptions.Asynchronous);
    namedPipeClientStream.Connect();
    namedPipeClientStream.ReadMode = PipeTransmissionMode.Message;
    var command = Encoding.Unicode.GetBytes("CREATE MyWorkQueue");
    namedPipeClientStream.Write(command, 0, command.Length);
    var replyBuilder = new StringBuilder();
    var replyBuffer = new byte[BufferSize];
    var clientTask = namedPipeClientStream.ReadAsync(
        replyBuffer,
        0,
        replyBuffer.Length)
        .ContinueWith(t =>
            {
                replyBuilder.Append(Encoding.Unicode.GetString(
                    replyBuffer,
                    0,
                    t.Result));
                while (!namedPipeClientStream.IsMessageComplete)
                {
                    var length = namedPipeClientStream.Read(
                        replyBuffer,
                        0,
                        replyBuffer.Length);
                    replyBuilder.Append(Encoding.Unicode.GetString(
                        replyBuffer,
                        0,
                        length));
                }

                // TODO: process reply
            });
    clientTask.Wait();
    namedPipeClientStream.Dispose();
    namedPipeServerStream.Close();
}
{% endhighlight %}

I will refactor and clean the code for this step soon, but for now it should work. If I run this in the debugger, I should see the messages get passed between the client and the server and the step should succeed. Now even though I am sending a **CREATE** message to create a work queue and I am returning an **OK** reply indicating that the operation is succeeding, I have not actually created anything yet as evidenced by the next step:

{% highlight gherkin %}
Then the work queue will be created
{% endhighlight %}

First, I'm going to create a class representing a work queue:

{% highlight c# %}
public class WorkQueue
{
    public string Name { get; set; }
}
{% endhighlight %}

Next, I will enhance my **StepDefinitions** class to store the work queues. I will use a dictionary keyed by the name of the work queue:

{% highlight c# %}
[Binding]
public class StepDefinitions
{
    private readonly Dictionary<string, WorkQueue> workQueues =
        new Dictionary<string, WorkQueue>();

    ...
}
{% endhighlight %}

Now I can implement the test:

{% highlight c# %}
[Then(@"the work queue will be created")]
public void ThenTheWorkQueueWillBeCreated()
{
    Assert.True(this.workQueues.ContainsKey("MyWorkQueue"));
}
{% endhighlight %}

If I run this test, it will not pass because in the previous step I did not actually process the request and create the work queue. I am going to go back, refactor the previous method, and then implement the code to create the work queue:

The first refactoring that I did was to take into consideration that both **NamedPipeServerStream** and **NamedPipeClientStream** derived from **PipeStream**. Since the logic for reading a message from a pipe is identical for both the client and the server, I can extract that logic into a method:

{% highlight c# %}
private static Task<string> ReadMessageAsync(PipeStream pipeStream)
{
    var message = new StringBuilder();
    var buffer = new byte[BufferSize];
    return pipeStream.ReadAsync(buffer, 0, buffer.Length)
        .ContinueWith(t =>
            {
                message.Append(Encoding.Unicode.GetString(
                    buffer, 0, t.Result));
                while (!pipeStream.IsMessageComplete)
                {
                    var length = pipeStream.Read(
                        buffer, 0, buffer.Length);
                    message.Append(Encoding.Unicode.GetString(
                        buffer, 0, length));
                }

                return message.ToString();
            });
}
{% endhighlight %}

I can also move the named pipe server logic into its own method. I will also add the code to create the work queue.

{% highlight c# linenos %}
private void RunNamedPipeServer()
{
    var pipeStream = new NamedPipeServerStream(
        "WorkQueueService",
        PipeDirection.InOut,
        NamedPipeServerStream.MaxAllowedServerInstances,
        PipeTransmissionMode.Message,
        PipeOptions.Asynchronous,
        BufferSize,
        BufferSize);
    Task.Factory.FromAsync(
        pipeStream.BeginWaitForConnection,
        pipeStream.EndWaitForConnection,
        null)
        .ContinueWith(t =>
            {
                ReadMessageAsync(pipeStream).ContinueWith(rt =>
                    {
                        var commandRegex = new Regex(
                            @"^CREATE (?<name>\w+)$",
                            RegexOptions.Singleline);
                        var match = commandRegex.Match(rt.Result);
                        var name = match.Groups["name"].Value;
                        var workQueue = new WorkQueue
                        {
                            Name = name
                        };
                        this.workQueues.Add(name, workQueue);
                        var reply = Encoding.Unicode.GetBytes("OK");
                        pipeStream.Write(reply, 0, reply.Length);
                        pipeStream.WaitForPipeDrain();
                        pipeStream.Disconnect();
                        pipeStream.Dispose();
                    });
            });
}
{% endhighlight %}

The new code is shown on lines 19 through 28. Finally, I will extract the named pipe client code into its own method:

{% highlight c# linenos %}
private static void CreateWorkerQueue()
{
    var pipeStream = new NamedPipeClientStream(
        ".",
        "WorkQueueService",
        PipeDirection.InOut,
        PipeOptions.Asynchronous);
    pipeStream.Connect();
    pipeStream.ReadMode = PipeTransmissionMode.Message;
    var command = Encoding.Unicode.GetBytes("CREATE MyWorkQueue");
    var namedPipeClientStream.Write(command, 0, command.Length);
    var clientTask = this.ReadMessageAsync(namedPipeClientStream);
    clientTask.Wait();
    pipeStream.Dispose()
}
{% endhighlight %}

My revised step definition now looks like this:

{% highlight c# %}
[When(@"I create the work queue")]
public void WhenICreateTheWorkQueue()
{
    this.RunNamedPipeServer();
    CreateWorkerQueue();
}
{% endhighlight %}

Running the feature test again should succeed through the third step. At this point, we can also go back and implement the first step to ensure that the work queue does not exist before the work queue is created:

{% highlight c# %}
[Given(@"the work queue does not exist")]
public void GivenTheWorkQueueDoesNotExist()
{
    if (this.workQueues.ContainsKey("MyWorkQueue"))
    {
        this.workQueues.Remove("MyWorkQueue");
    }
}
{% endhighlight %}

###Finishing the Scenario

There is one last step that needs to be implemented for the scenario to be complete:

{% highlight gherkin %}
Then the work queue will be stopped
{% endhighlight %}

I will expand the definition of the **WorkQueue** class to include a state field. Since I have only one state that I care about (*stopped*), I will only define that state initially.

{% highlight c# %}
public enum WorkQueueState
{
    Stopped
}

public class WorkQueue
{
    public WorkQueue(string name)
    {
        this.Name = name;
        this.State = WorkQueueState.Stopped;
    }

    public string Name { get; private set; }
    public WorkQueueState State { get; private set; }
}
{% endhighlight %}

Now I can implement the final step:

{% highlight c# %}
[Then(@"the work queue will be stopped")]
public void ThenTheWorkQueueWillBeStopped()
{
    Assert.Equal(
        WorkQueueState.Stopped,
        this.workQueues["MyWorkQueue"].State);
}
{% endhighlight %}

When I run the test, the whole scenario completes successfully.

Conclusion
----------
In this post, I had one explicit goal and one implicit goal. My explicit goal was that I wanted to demonstrate how I can use a named pipe to allow a client program to pass a command to a server program to achieve a result. I succeeded in implementing both the client and the server sides of the named pipe, passed a command from the client to the server, and returned a response. My implicit goal, based off of my [last post]({% post_url 2013-06-02-minimum-viable-products %}) was to use SpecFlow to drive the implementation of this feature. While both my client and server are implemented in the same process, I didn't actually build a full client/server solution, but thanks to the guidance that my SpecFlow scenario provided to me, I was able to build a minimum version that demonstrates the most important part of the client-server communication using a named pipe.

I will be developing other scenarios that are part of this feature which will lead in a future post to using the named pipe client and server in a real solution for managing work queues.
