---
title: Extracting the Named Pipe Server
categories:
- windows_development
category_names:
- Windows Development
---
In this post, I will expand on my previous two posts and will extract a working named pipe server program from my feature tests. I will then update the feature tests to perform acceptance testing against the named pipe server.

<!--more-->

In my last two posts, I have been using SpecFlow to build an interprocess communication solution using Windows named pipes. My solution has been to manage work queues that can be used to ship units of work to background processes. In the first two posts on this subject, I built out the SpecFlow feature, the IPC protocol, the named pipe server, and the named pipe client. However, all of this code was embedded inside of the feature tests and the named pipe service did not exist as a separate executable component. In this post, I will extract the named pipe server into an executable program and will revise my feature tests to use the new server program.

In my opinion, refactoring working code works best when there is a working suite of unit or feature tests available. The reason why this works best is that refactoring code with working tests adds the pressure to return the tests to working status as quickly as possible in order to validate that the refactoring was performed correctly.

To summarize where I left off in my last post and to give us a starting point for this refactoring, here's the feature test and step implementations that I ended up with at the end of the last post:

{% highlight gherkin %}
Feature: Manage work queues

  Scenario: Create a work queue
    Given the work queue does not exist
    When I create the work queue
    Then the work queue will exist
    And the work queue will be stopped

  Scenario: List work queues
    Given there are work queues defined
    When I list the work queues
    Then all of the work queus will be returned

  Scenario: Delete a work queue
    Given the work queue exists
    When I delete the work queue
    Then the work queue will be deleted

  Scenario: Start a work queue
    Given the work queue exists
    And the work queue is stopped
    When I start the work queue
    Then the work queue will be running

  Scenario: Stop a work queue
    Given the work queue exists
    And the work queue is running
    When I stop the work queue
    Then the work queue will be stopped
{% endhighlight %}

Here is the source code for the step definitions:

{% highlight c# %}
public enum WorkQueueState
{
    Running,
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

    public void Start()
    {
        this.State = WorkQueueState.Running;
    }

    publi void Stop()
    {
        this.State = WorkQueueState.Stopped;
    }
}

[Binding]
public class StepDefinitions
{
    private const int BufferSize = 32768;

    private const string TestServiceName = "WorkQueueService";

    private const string TestWorkQueueName = "MyWorkQueue";

    private static readonly Regex CreateCommandRegex = new Regex(
        @"^CREATE (?<name>\w+)$",
        RegexOptions.Compiled | RegexOptions.Singleline);

    private static readonly Regex DeleteCommandRegex = new Regex(
        @"^DELETE (?<name>\w+)$",
        RegexOptions.Compiled | RegexOptions.Singleline);

    private static readonly Regex ListCommandRegex = new Regex(
        @"^LIST$",
        RegexOptions.Compiled | RegexOptions.Singleline);

    private static readonly Regex StartCommandRegex = new Regex(
        @"^START (?<name>\w+)$",
        RegexOptions.Compiled | RegexOptions.Singleline);

    private static readonly Regex StopCommandRegex = new Regex(
        @"^STOP (?<name>\w+)$",
        RegexOptions.Compiled | RegexOptions.Singleline);

    private readonly Dictionary<string, WorkQueue> workQueues =
        new Dictionary<string, WorkQueue>();

    private Table serviceTable;

    [Given(@"the work queue does not exist")]
    public void GivenTheWorkQueueDoesNotExist()
    {
        if (this.workQueues.ContainsKey(TestWorkQueueName))
        {
            this.workQueues.Remove(TestWorkQueueName);
        }
    }

    [When(@"I create the work queue")]
    public void WhenICreateTheWorkQueue()
    {
        this.RunNamedPipeServer();
        var reply = SendCommandToServer("CREATE MyWorkQueue");
        Assert.Equal("OK", reply);
    }

    [Then(@"the work queue will exist")]
    public void ThenTheWorkQueueWillExist()
    {
        Assert.True(this.workQueues.ContainsKey(TestWorkQueueName));
    }

    [Then(@"the work queue will be stopped")]
    public void ThenTheWorkQueueWillBeStopped()
    {
        Assert.Equal(
            WorkQueueState.Stopped,
            this.workQueues[TestWorkQueueName].State);
    }

    [Given(@"there are work queues defined")]
    public void GivenThereAreWorkQueuesDefined()
    {
        this.workQueues.Clear();
        this.workQueues.Add("WorkQueue1", new WorkQueue("WorkQueue1"));
        this.workQueues.Add("WorkQueue2", new WorkQueue("WorkQueue2"));
        this.workQueues.Add("WorkQueue3", new WorkQueue("WorkQueue3"));
    }

    [When(@"I list the work queues")]
    public void WhenIListTheWorkQueues()
    {
        this.RunNamedPipeServer();
        var reply = SendCommandToServer("LIST");
        using (var reader = new StringReader(reply))
        {
            var line = reader.ReadLine();
            Assert.Equal("OK", line);
            line = reader.ReadLine();
            var table = new Table("Name", "State");
            while (null != line)
            {
                var fields = line.Split('\t');
                table.AddRow(fields);
                line = reader.ReadLine();
            }

            this.serviceTable = table;
        }
    }

    [Then(@"all of the work queues will be returned")]
    public void ThenAllOfTheWorkQueuesWillBeReturned()
    {
        var expected = new Table("Name", "State");
        expected.AddRow("WorkQueue1", "Stopped");
        expected.AddRow("WorkQueue2", "Stopped");
        expected.AddRow("WorkQueue3", "Stopped");
        Assert.Equal(expected.ToString(), this.serviceTable.ToString());
    }

    [Given(@"the work queue exists")]
    public void GivenTheWorkQueueExists()
    {
        if (!this.workQueues.ContainsKey(TestWorkQueueName))
        {
            this.workQueues.Add(
                TestWorkQueueName,
                new WorkQueue(TestWorkQueueName));
        }
    }

    [When(@"I delete the work queue")]
    public void WhenIDeleteTheWorkQueue()
    {
        this.RunNamedPipeServer();
        var reply = SendCommandToServer("DELETE MyWorkQueue");
        Assert.Equal("OK", reply);
    }

    [Then(@"the work queue will be deleted")]
    public void ThenTheWorkQueueWillBeDeleted()
    {
        Assert.False(this.workQueues.ContainsKey(TestWorkQueueName));
    }

    [Given(@"the work queue is stopped")]
    public void GivenTheWorkQueueIsStopped()
    {
        Assert.Equal(
            WorkQueueState.Stopped,
            this.workQueues[TestWorkQueueName].State);
    }

    [When(@"I start the work queue")]
    public void WhenIStartTheWorkQueue()
    {
        this.RunNamedPipeServer();
        var reply = SendCommandToServer("START MyWorkQueue");
        Assert.Equal("OK", reply);
    }

    [Then(@"the work queue will be running")]
    public void ThenTheWorkQueueWillBeRunning()
    {
        Assert.Equal(
            WorkQueueState.Running,
            this.workQueues[TestWorkQueueName].State);
    }

    [Given(@"the work queue is running")]
    public void GivenTheWorkQueueIsRunning()
    {
        this.workQueues[TestWorkQueueName].Start();
    }

    [When(@"I stop the work queue")]
    public void WhenIStopTheWorkQueue()
    {
        this.RunNamedPipeServer();
        var reply = SendCommandToServer("STOP MyWorkQueue");
        Assert.Equal("OK", reply);
    }

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

    private static string SendCommandToServer(string command)
    {
        var clientPipe = new NamedPipeClientStream(
            ".",
            TestServiceName,
            PipeDirection.InOut,
            PipeOptions.Asynchronous);
        using (clientPipe)
        {
            clientPipe.Connect();
            clientPipe.ReadMode = PipeTransmissionMode.Message;
            var buffer = Encoding.Unicode.GetBytes(command);
            clientPipe.Write(buffer, 0, buffer.Length);
            var task = ReadMessageAsync(clientPipe);
            task.Wait();
            return task.Result;
        }
    }

    private static string SendOkReply(NamedPipeServerStream serverPipe)
    {
        var response = Encoding.Unicode.GetBytes("OK");
        serverPipe.Write(response, 0, response.Length);
    }

    private void CreateWorkQueue(
        string queueName,
        NamedPipeServerStream serverPipe)
    {
        var workQueue = new WorkQueue(queueName);
        this.WorkQueues.Add(queueName, workQueue);
        SendOkReply(serverPipe);
    }

    private void DeleteWorkQueue(
        string queueName,
        NamedPipeServerStream serverPipe)
    {
        this.workQueues.Remove(queueName);
        SendOkReply(serverPipe);
    }

    private void ListWorkQueues(NamedPipeServerStream serverPipe)
    {
        var replyBuilder = new StringBuilder();
        replyBuilder.AppendLine("OK");
        foreach (var kvp in this.workQueues)
        {
            replyBuilder.AppendFormat(
                "{0}\t{1}",
                kvp.Value.Name,
                kvp.Value.State);
            replyBuilder.AppendLine();
        }

        var replyBytes = Encoding.Unicode.GetBytes(
            replyBuilder.ToString());
        serverPipe.Write(replyBytes, 0, replyBytes.Length);
    }

    private void RunNamedPipeServer()
    {
        var serverPipe = new NamedPipeServerStream(
            TestServiceName,
            PipeDirection.InOut,
            NamedPipeServerStream.maxAllowedServerInstances,
            PipeTransmissionMode.Message,
            PipeOptions.Asynchronous
            BufferSize,
            BufferSize);
        Task.Factory.FromAsync(
            serverPipe.BeginWaitForConnecton,
            serverPipe.EndWaitForConnection,
            null)
            .ContinueWith(t =>
                {
                    ReadMessageAsync(pipeStream).ContinueWith(rt =>
                        {
                            try
                            {
                                var command = rt.Result;
                                var match = CreateCommandRegex.Match(command);
                                if (match.Success)
                                {
                                    var queueName = match.Groups["name"].Value;
                                    this.CreateWorkQueue(
                                        queueName,
                                        serverPipe);
                                        goto end;
                                }

                                match = DeleteCommandRegex.Match(command);
                                if (match.Success)
                                {
                                    var queueName = match.Groups["name"].Value;
                                    this.DeleteWorkQueue(
                                        queueName,
                                        serverPipe);
                                    goto end;
                                }

                                match = ListCommandRegex.Match(command);
                                if (match.Success)
                                {
                                    this.ListServices(serverPipe);
                                    goto end;
                                }

                                match = StartCommandRegex.Match(command);
                                if (match.Success)
                                {
                                    var queueName = match.Groups["name"].Value;
                                    var workQueue = this.workQueues[queueName];
                                    workQueue.Start();
                                    SendOkReply(serverPipe);
                                    goto end;
                                }

                                match = StopCommandRegex.Match(command);
                                if (match.Success)
                                {
                                    var queueName = match.Groups["name"].Value;
                                    var workQueue = this.workQueues[queueName];
                                    workQueue.Stop();
                                    SendOkReply(serverPipe);
                                    goto end;
                                }

                                var message = string.Format(
                                    CultureInfo.CurrentCulture,
                                    "The command \"{0}\" is not supported.",
                                    command);
                                throw new InvalidOperationException(message);
                            }
                            catch (Exception ex)
                            {
                                var message = string.Format(
                                    CultureInfo.CurrentCulture,
                                    "ERROR {0}",
                                    ex.Message);
                                var messageBytes =
                                    Encoding.Unicode.GetBytes(message);
                                serverPipe.Write(
                                    messageBytes,
                                    0,
                                    messageBytes.Length);
                            }

end:
                            serverPipe.WaitForPipeDrain();
                            serverPipe.Disconnect();
                            serverPipe.Dispose();
                        });
                });
    }
}
{% endhighlight %}

Extracting the Named Pipe Server
--------------------------------
The first thing that I am going to do is to extract the named pipe server code from the **StepDefinitions** class. This will break my tests and step definitions, so I will have to go back later and fix that code. I also need to make a change to the named pipe server to allow a single connection to execute multiple requests from a client. I have to do this because the work queue state is going to be moved to the server process and the step definitions will not have access to that. The step definitions will instead have to send commands to the named pipe server to query or configure the state of the work queues.

Because the revised named pipe server will be capable of processing multiple commands from clients, I added a new message called **GOODBYE**. The client will send the **GOODBYE** message to terminate the session, and the named pipe server will disconnect the server side of the named pipe after replying with an **OK** response.

Here is the revised code for the named pipe server program:

{% highlight c# %}
internal class Program
{
    private const int BufferSize = 32768;

    private static readonly Regex CreateCommandRegex = new Regex(
        @"^CREATE (?<name>\w+)$",
        RegexOptions.Compiled | RegexOptions.Singleline);

    private static readonly Regex DeleteCommandRegex = new Regex(
        @"^DELETE (?<name>\w+)$",
        RegexOptions.Compiled | RegexOptions.Singleline);

    private static readonly Regex GoodbyeCommandRegex = new Regex(
        @"^GOODBYE$",
        RegexOptions.Compiled | RegexOptions.Singleline);

    private static readonly Regex ListCommandRegex = new Regex(
        @"^LIST$",
        RegexOptions.Compiled | RegexOptions.Singleline);

    private static readonly byte[] OkResponse =
        Encoding.Unicode.GetBytes("OK");

    private static readonly Regex StartCommandRegex = new Regex(
        @"^START (?<name>\w+)$",
        RegexOptions.Compiled | RegexOptions.Singleline);

    private static readonly Regex StopCommandRegex = new Regex(
        @"^STOP (?<name>\w+)$",
        RegexOptions.Compiled | RegexOptions.Singleline);

    private static readonly Dictionary<string, WorkQueue> workQueues =
        new Dictionary<string, WorkQueue>();

    private static void Main()
    {
        ListenForConnection();
        while (null != Console.In.ReadLine())
        {
        }
    }

    private static void ListenForConnection()
    {
        var serverPipe = new NamedPipeServerStream(
            "WorkQueueService",
            PipeDirection.InOut,
            NamedPipeServerStream.MaxAllowedServerInstances,
            PipeTransmissionMode.Message,
            PipeOptions.Asynchronous,
            BufferSize,
            BufferSize);
        Task.Factory.FromAsync(
            serverPipe.BeginWaitForConnection,
            serverPipe.EndWaitForConnection,
            null)
            .ContinueWith(t =>
                {
                    ListenForConnection();
                    ProcessCommand(serverPipe);
                });
    }

    private static void ProcessCommand(NamedPipeServerStream serverPipe)
    {
        var messageBuilder = new StringBuilder();
        var buffer = new byte[BufferSize];
        serverPipe.ReadAsync(buffer, 0, buffer.Length).ContinueWith(rt =
            {
                messageBuilder.Append(Encoding.Unicode.GetString(
                    buffer, 0, rt.Result));
                while (!serverPipe.IsMessageComplete)
                {
                    var bytesRead = serverPipe.Read(buffer, 0, buffer.Length);
                    messageBuilder.Append(Encoding.Unicode.GetString(
                        buffer, 0, bytesRead));
                }

                var command = messageBuilder.ToString();
                try
                {
                    var match = CreateCommandRegex.Match(command);
                    if (match.Success)
                    {
                        var queueName = match.Groups["name"].Value;
                        CreateWorkQueue(queueName, serverPipe);
                        ProcessCommand(serverPipe);
                        return;
                    }

                    match = DeleteCommandRegex.Match(command);
                    if (match.Success)
                    {
                        var queueName = match.Groups["name"].Value;
                        DeleteWorkQueue(queueName, serverPipe);
                        ProcessCommand(serverPipe);
                        return;
                    }

                    match = ListCommandRegex.Match(command);
                    if (match.Success)
                    {
                        ListWorkQueues(serverPipe);
                        ProcessCommand(serverPipe);
                        return;
                    }

                    match = StartCommandRegex.Match(command);
                    if (match.Success)
                    {
                        var queueName = match.Groups["name"].Value;
                        var workQueue = workQueues[queueName];
                        workQueue.Start();
                        SendOkReply(serverPipe);
                        ProcessCommand(serverPipe);
                        return;
                    }

                    match = StopCommandRegex.Match(command);
                    if (match.Success)
                    {
                        var queueName = match.Groups["name"].Value;
                        var workQueue = workQueues[queueName];
                        workQueue.Stop();
                        SendOkReply(serverPipe);
                        ProcessCommand(serverPipe);
                        return;
                    }

                    match = GoodbyeCommandRegex.Match(command);
                    if (match.Success)
                    {
                        SendOkReply(serverPipe);
                        serverPipe.WaitForPipeDrain();
                        serverPipe.Disconnect();
                        serverPipe.Dispose();
                        return;
                    }

                    var message = string.Format(
                        CultureInfo.CurrentCulture,
                        "The command \"{0}\" is not supported.",
                        command);
                    throw new InvalidOperationException(message);
                }
                catch (Exception ex)
                {
                    var message = string.Format(
                        CultureInfo.CurrentCulture,
                        "ERROR {0}",
                        ex.Message);
                    var messageBytes = Encoding.Unicode.GetBytes(message);
                    serverPipe.Write(messageBytes, 0, messageBytes.Length);
                }
            });
    }

    private static void SendOkReply(PipeStream pipeStream)
    {
        pipeStream.Write(OkResponse, 0, OkResponse.Length);
    }

    private static void ListWorkQueues(PipeStream pipeStream)
    {
        var replyBuilder = new StringBuilder();
        replyBuilder.AppendLine("OK");
        foreach (var kvp in workQueues)
        {
            replyBuilder.AppendFormat(
                "{0}\t{1}",
                kvp.Value.Name,
                kvp.Value.State);
            replyBuilder.AppendLine();
        }

        var replyBytes = Encoding.Unicode.GetBytes(replyBuilder.ToString());
        pipeStream.Write(replyBytes, 0, replyBytes.Length);
    }

    private static void DeleteWorkQueue(
        string queueName,
        PipeStream pipeStream)
    {
        workQueues.Remove(queueName);
        SendOkReply(pipeStream);
    }

    private static void CreateWorkQueue(
        string queueName,
        PipeStream pipeStream)
    {
        var workQueue = new WorkQueue(queueName);
        workQueues.Add(queueName, workQueue);
        SendOkReply(pipeStream);
    }
}
{% endhighlight %}

The main changes to this code from the baseline version are:

1. I added the **GOODBYE** command
2. I moved the named pipe server connection logic into the **ListenForConnection** method
3. After a connection is established, I am immediately calling **ListenForConnection** again to create another server pipe and wait for a connection. This is ok because the waiting for a connection logic is run asynchronously on another background thread, so the call will not block.
4. The command processing code is in the **ProcessCommand** method.
5. After executing a command, I am calling **ProcessCommand**. Like the call back to **ListenForConnection**, the **ProcessCommand** method will asynchronously wait for a command to be received on another background thread, so the call will not block.

The server program runs until the standard input stream is closed. I will use this in the revised test code to terminate the server program at the end of a test scenario.

Revising the Step Definitions
-----------------------------
With the named pipe server now extracted into a separate program, the step definitions no longer work. They need to be revised to deal with the fact that they no longer have access to the server state, and running the named pipe server means executing the server as a child process. To start and stop the server, I am going to add hooks to the test code to run before each scenario executes and after each scenario finishes:

{% highlight c# %}
private Process workQueueService;

private NamedPipeClientStream clientPipe;

[BeforeScenario]
public void StartWorkQueueService()
{
    var startInfo = new ProcessStartInfo("WorkQueueService.exe", string.Empty)
    {
        CreateNoWindow = true,
        RedirectStandardError = true,
        RedirectStandardInput = true,
        RedirectStandardOutput = true,
        UseShellExecute = false
    };
    this.workQueueService = Process.Start(startInfo);
    this.workQueueService.EnableRaisingEvents = true;
    this.workQueueService.OutputDataReceived += (sender, e) =>
        Console.Error.WriteLine("STDOUT: {0}", e.Data);
    this.workQueueService.ErrorDataReceived += (sender, e) =>
        Console.Error.WriteLine("STDERR: {0}", e.Data);
    this.workQueueService.BeginErrorReadLine();
    this.workQueueService.BeginOutputReadLine();
    this.clientPipe = new NamedPipeClientStream(
        ".",
        TestServiceName,
        PipeDirection.InOut,
        PipeOptions.Asynchronous);
    this.clientPipe.Connect();
    this.clientPipe.ReadMode = PipeTransmissionMode.Message;
}

[AfterScenario]
public void StopWorkQueueService()
{
    var reply = SendCommandToServer("GOODBYE");
    this.clientPipe.Dispose();
    this.workQueueService.StandardInput.Close();
    Assert.True(this.workQueueService.WaitForExit(5000));
    Assert.Equal("OK", reply);
}
{% endhighlight %}

The **StartWorkQueueService** method will be called before each scenario executes and will launch the work queue service program as a child process. The **StartWorkQueueService** method will redirect the standard error, input, and output streams. Output written by the service program to standard output or error will be written to the standard error stream for the test runner. This is helpful to debug the service program because I can output trace statements to STDERR for example and see what happened in the server program for each scenario.

After each scenario completes, the **StopWorkQueueService** method is called. This method will send the new **GOODBYE** message to the server and then will close the server's standard input stream. Closing the input stream will send an EOF to the main program code for the server that will cause the main program to terminate.

The other change that I made is that the client end of the named pipe is now an instance method of the **StepDefinitions** class. The connection is established when the server process is launched and is terminated after the scenario completes. All of the test code needs to be changed to use the new client pipe.

Let us revisit the first scenario for creating a work queue:

{% highlight gherkin %}
Given the work queue does not exist
When I create the work queue
Then the work queue will exist
And the work queue will be stopped
{% endhighlight %}

The first big change is that since we no longer share state with the named pipe server, we need to query the server to see if a work queue exists or not. Fortunately, we have already defined the LIST command and we can just send that and process the results:

{% highlight c# %}
private Dictionary<string, string> workQueues;

[Given(@"the work queue does not exist")]
public void GivenTheWorkQueueDoesNotExist()
{
    this.GetWorkQueues();
    if (!this.workQueues.ContainsKey(TestWorkQueueName))
    {
        return;
    }

    this.DeleteTestWorkQueue();
}

private void GetWorkQueues()
{
    var reply = this.SendCommandToServer("LIST");
    this.workQueues = new Dictionary<string, string>();
    using (var reader = new StringReader(reply))
    {
        var line = reader.ReadLine();
        Assert.Equal("OK", line);
        line = reader.ReadLine();
        while (!string.IsNullOrEmpty(line))
        {
            var fields = line.Split('\t');
            this.workQueues.Add(fields[0], fields[1]);
            line = reader.ReadLine();
        }
    }
}

private void DeleteTestWorkQueue()
{
    var reply = this.SendCommandToServer("DELETE MyWorkQueue");
    Assert.Equal("OK", reply);
}
{% endhighlight %}

As you can see, instead of querying shared state, we now have to send commands to the server to retrieve the state and set preconditions for the scenario being tested. However, this is fairly easy to do thanks to the work that we have already done earlier in this post and the previous posts. We already implemented the **LIST** command to return the list of work queues that have been defined, and if the work queue exists, we have already implemented the **DELETE** command. Plus, we have a great understanding of how to send commands to our server, so there's no struggle to get this step definition passing. Here are the other step definitions in this scenario:

{% highlight c# %}
[When("I create the work queue")]
public void WhenICreateTheWorkQueue()
{
    this.CreateTestWorkQueue();
}

[Then(@"the work queue will exist")]
public void ThenTheWorkQueueWillExist()
{
    this.GetWorkQueues();
    Assert.True(this.workQueues.ContainsKey(TestWorkQueueName));
}

[Then(@"the work queue will be stopped")]
public void ThenTheWorkQueueWillBeStopped()
{
    this.GetWorkQueues();
    Assert.Equal("Stopped", this.workQueues[TestWorkQueueName]);
}

private void CreateTestWorkQueue()
{
    this.CreateWorkQueue(TestWorkQueueName);
}

private void CreateWorkQueue(string workQueueName)
{
  var command = string.Format(
      CultureInfo.InvariantCulture,
      "CREATE {0}",
      workQueueName);
  var reply = this.SendCommandToServer(command);
  Assert.Equal("OK", reply);
}
{% endhighlight %}

If we run the create scenario, the scenario should pass. The remaining step definitions are listed below:

{% highlight c# %}
[Given("the work queue exists")]
public void GivenTheWorkQueueExists()
{
    this.GetWorkQueues();
    if (!this.workQueues.ContainsKey(TestWorkQueueName))
    {
        this.CreateTestWorkQueue();
    }
}

[When(@"I delete the work queue")]
public void WhenIDeleteTheWorkQueue()
{
    this.DeleteTestWorkQueue();
}

[Then(@"the work queue will be deleted")]
public void ThenTheWorkQueueWillBeDeleted()
{
    this.GetWorkQueues();
    Assert.False(this.workQueues.ContainsKey(TestWorkQueueName));
}

[Given(@"there are work queues defined")]
public void GivenThereAreWorkQueuesDefined()
{
    this.CreateWorkQueue("WorkQueue1");
    this.CreateWorkQueue("WorkQueue2");
    this.CreateWorkQueue("WorkQueue3");
}

[When(@"I list the work queues")]
public void WhenIListTheWorkQueues()
{
    this.GetWorkQueues();
    this.workQueueTable = new Table("Name", "State");
    foreach (var kvp in this.workQueues)
    {
        this.workQueueTable.AddRow(kvp.Key, kvp.Value);
    }
}

[Then(@"all of the work queues will be returned")]
public void ThenAllOfTheWorkQueuesWillBeReturned()
{
    var expected = ne Table("Name", "State");
    expected.AddRow("WorkQueue1", "Stopped");
    expected.AddRow("WorkQueue2", "Stopped");
    expected.AddRow("WorkQueue3", "Stopped");
    Assert.Equal(expected.ToString(), this.workQueueTable.ToString());
}

[Given(@"the work queue is stopped")]
public void GivenTheWorkQueueIsStopped()
{
    this.GetWorkQueues();
    Assert.Equal("Stopped", this.workQueues[TestWorkQueueName]);
}

[When(@"I start the work queue")]
public void WhenIStartTheWorkQueue()
{
    var reply = this.SendCommandToServer("START MyWorkQueue");
    Assert.Equal("OK", reply);
}

[Then(@"the work queue will be running")]
public void ThenTheWorkQueueWillBeRunning()
{
    this.GetWorkQueues();
    Assert.Equal("Running", this.workQueues[TestWorKQueueName]);
}
{% endhighlight %}

Where Are We At?
----------------
In the first post and second posts, I showed how to use SpecFlow to define a minimum viable product. I created a specification for a protocol between a client and server program and used named pipes to send commands from the client to the server to perform actions and return responses. In this third post, I took my prototype product and started to build out the production code. I extracted the working server prototype that I created and turned it into an actual executable service. Along with that, I revised my feature tests to use and test the executable named pipe server for managing work queues.

All of this work has not been for a random journey. There is an actual destination that I am trying to get to. In the next post, I will begin to look at the new CIM provider model supported by PowerShell 3.0 and Microsoft's Windows Management Framework that was introduced with Windows 8 and Windows Server 2012. Now that we have a working named pipe server, I will look at creating a CIM provider that uses the named pipe protocol to provide a management interface for creating, deleting, starting, and stopping work queues.

Getting the Source Code
-----------------------
I realize that having the code samples in the blog are good, but having actual code to run are better. For the next post in this series, I will move the code into a [GitHub](https://github.io) repository and will provide a link to it so that you can get the code and follow along. I will go through and tag each of the revisions in the Git repository that match the end products of each of the blog posts so that you can run the code at each stage.
