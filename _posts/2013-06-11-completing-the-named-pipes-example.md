---
layout: post
title: Completing the Named Pipes Example
description: In this post, I will complete my named pipes example from the previous post in preparation for my next post where I will build out a complete IPC-based system for managing work queues.
categories:
- windows_development
category_names:
- Windows Development
author: Michael F. Collins, III
author_first_name: Michael
author_last_name: Collins
author_gender: male
twitter_creator: mfcollins3
---
In this post, I will complete my named pipes example from the previous post in preparation for my next post where I will build out a complete IPC-based system for managing work queues.

<!--more-->

In my last post, I started to develop a solution that used named pipes for interprocess communication in order to manage work queues in a work queue server. Using named pipes, a client administation program could send text-based messages to the server program to create a work queue. In this post, I will complete that demonstration and expand on it before I take my named pipe solution and build out the next phase of the project.

In the previous post, I only implemented a single scenario for creating a work queue. In this post, I will implement these additional scenarios:

* list work queues
* delete a work queue
* start a work queue
* stop a work queue

Here's the updated SpecFlow feature and scenarios that will be implemented:

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

The first scenario, **Create a work queue**, was completed in the [last post]({% post_url 2013-06-10-windows-ipc-using-named-pipes %}). For reference, here are the step definitions that I ended up with:

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

[Binding]
public class StepDefinitions
{
    private const int BufferSize = 32768;

    private readonly Dictionary<string, WorkQueue> workQueues =
        new Dictionary<string, WorkQueue>();

    [Given(@"the work queue does not exist")]
    public void GivenTheWorkQueueDoesNotExist()
    {
        if (this.workQueues.ContainsKey("MyWorkQueue"))
        {
            this.workQueues.Remove("MyWorkQueue");
        }
    }

    [When(@"I create the work queue")]
    public void WhenICreateTheWorkQueue()
    {
        this.RunNamedPipeServer();
        CreateWorkerQueue();
    }

    [Then(@"the work queue will exist")]
    public void ThenTheWorkQueueWillExist()
    {
        Assert.True(this.workQueues.ContainsKey("MyWorkQueue"));
    }

    [Then(@"the work queue will be stopped")]
    public void ThenTheWorkQueueWillBeStopped()
    {
        Assert.Equal(
            WorkQueueState.Stopped,
            this.workQueues["MyWorkQueue"].State);
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
                            var workQueue = new WorkQueue(name);
                            this.workQueues.Add(name, workQueue);
                            var reply = Encoding.Unicode.GetBytes("OK");
                            pipeStream.Write(reply, 0, reply.Length);
                            pipeStream.WaitForPipeDrain();
                            pipeStream.Disconnect();
                            pipeStream.Dispose();
                        });
                });
    }

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
        var clientTask = ReadMessageAsync(pipeStream);
        clientTask.Wait();
        pipeStream.Dispose();
    }
}
{% endhighlight %}

In the rest of this post, I will continue to refactor these step definitions and the implementation code as I complete the additional four scenarios.

Listing Work Queues
-------------------
Let us start by revisiting the steps for the **List Work Queues** scenario:

{% highlight gherkin %}
Given there are work queues defined
When I list the work queues
Then all of the work queues will be returned
{% endhighlight %}

Implementing the first step will be pretty simple. I just need to populate the **workQueues** dictionary with some sample work queues:

{% highlight c# %}
[Given(@"there are work queues defined")]
public void GivenThereAreWorkQueuesDefined()
{
    this.workQueues.Clear();
    this.workQueues.Add("WorkQueue1", new WorkQueue("WorkQueue1"));
    this.workQueues.Add("WorkQueue2", new WorkQueue("WorkQueue2"));
    this.workQueues.Add("WorkQueue3", new WorkQueue("WorkQueue3"));
}
{% endhighlight %}

Implementing the next step gives us the opportunity to stop, revisit the current implementation, and make some changes to make the solution better. Looking at the implementation for **CreateWorkerQueue**, the method sends a string containing a command to the named pipe server. That worked out well when I had a single command to send, but now I have both a **CREATE** command and a **LIST** command. It would be better if I could genericize that code to send a command that I specify and return the reply from the named pipe server:

{% highlight c# %}
private const string TestServiceName = "WorkQueueService";

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
{% endhighlight %}

I made a second refactoring in the above code. I extracted the name of the named pipe into a constant field. I then renamed **CreateWorkerQueue** into **SendCommandToServer**. The new method takes a command, creates a named pipe client, sends the message to the named pipe server, then waits for the reply to be received. Normally, I wouldn't wait for the reply to be received, but I need to do this in order to guarantee that the **Then** validation steps do not run until this step completes.

I can refactor the **WhenICreateTheWorkQueue** step and implement the new step to use the **SendCommandToServer** method:

{% highlight c# %}
private Table serviceTable;

[When(@"I create the work queue")]
public void WhenICreateTheWorkQueue()
{
    this.RunNamedPipeServer();
    var reply = SendCommandToServer("CREATE MyWorkQueue");
    Assert.Equal("OK", reply);
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
{% endhighlight %}

In the new step definition, I am sending a **LIST** command to the named pipe server. My expectation is that the named pipe server will send me a response in this format:

    OK
    name<tab>state
    name<tab>state
    ...

I am reading the response and building a SpecFlow **Table** object that I will use to validate that the expected result was returned when I implement the **Then** step below.

To implement the server-side logic so that this step passes, I need to refactor the **RunNamedPipeServer** method a little to handle a new command and to improve the efficiency of the named pipe server implementation:

{% highlight c# %}
private static readonly Regex CreateCommandRegex = new Regex(
    @"CREATE (?<name>\w+)$",
    RegexOptions.Compiled | RegexOptions.Singleline);

private static readonly Regex ListCommandRegex = new Regex(
    @"^LIST$",
    RegexOptions.Compiled | RegexOptions.Singleline);

private void RunNamedPipeServer()
{
    var serverPipe = new NamedPipeServerStream(
        TestServiceName,
        PipeDirection.InOut,
        NamedPipeServerStream.MaxAllowedServerInstances,
        PipeTransmissionMode.Message,
        PipeOptions.Asynchronous);
    Task.Factory.FromAsync(
        serverPipe.BeginWaitForConnection,
        serverPipe.EndWaitForConnection,
        null)
        .ContinueWith(t =>
            {
                ReadMessageAsync(serverPipe).ContinueWith(rt =>
                    {
                        var command = rt.Result;
                        var match = CreateCommandRegex.Match(command);
                        if (match.Success)
                        {
                            var queueName =
                                match.Groups["name"].Value;
                            this.CreateWorkQueue(queueName, serverPipe);
                        }
                        else
                        {
                            this.ListWorkQueues(serverPipe);
                        }
                    });
            });
}

private void CreateWorkQueue(
    string queueName,
    NamedPipeServerStream serverPipe)
{
    var workQueue = new WorkQueue(queueName);
    this.workQueues.Add(queueName, workQueue);
    SendOkReply(serverPipe);
}

private static void SendOkReply(NamedPipeServerStream serverPipe)
{
    var response = Encoding.Unicode.GetBytes("OK");
    serverPipe.Write(response, 0, response.Length);
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
{% endhighlight %}

I started off by creating **Regex** fields for both the **CREATE** and **LIST** command. I'm not using the **List** **Regex** object yet, but I will soon. I then refactored the **RunNamedPipeServer** method to process the command and dispatch the command to an action method that implements the command. I implemented the **ListWorkQueues** method to send back the list of defined work queues from the **workQueues** dictionary. There are more refactorings that I can do to both the test code and the executable code, but for the moment this is working, so I will leave it as is and will move onto the next scenario.

Deleting Work Queues
--------------------
{% highlight gherkin %}
Given the work queue exists
When I delete the work queue
Then the work queue will be deleted
{% endhighlight %}

I will start off with the **Given** step:

{% highlight c# %}
private const string TestWorkQueueName = "MyWorkQueue";

[Given(@"the work queue does not exist")]
public void GivenTheWorkQueueDoesNotExist()
{
    if (this.workQueues.ContainsKey(TestWorkQueueName))
    {
        this.workQueues.Remove(TestWorkQueueName);
    }
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
{% endhighlight %}

Here I refactored the **GivenTheWorkQueueDoesNotExist** method to store the name of the test work queue in a constant field. I then implemented the **GivenTheWorkQueueExists** method to create the work queue if it does not exist.

Now that the work queue exists, I can implement the logic for deleting it:

{% highlight c# %}
[When(@"I delete the work queue")]
public void WhenIDeleteTheWorkQueue()
{
    this.RunNamedPipeServer();
    var reply = SendCommandToServer("DELETE MyWorkQueue");
    Assert.Equal("OK", reply);
}
{% endhighlight %}

I will add a new command regular expression for the DELETE command and do a little bit of modification to my command processor code on the server-side:

{% highlight c# %}
private static readonly Regex DeleteCommandRegex = new Regex(
    @"^DELETE (?<name>\w+)$",
    RegexOptions.Compiled | RegexOptions.Singleline);

private void RunNamedPipeServer()
{
    ...

    // Replace the ReadMessageAsync(...).ContinueWith(...)
    // delegate with this code:
    try
    {
        var command = x.Result;
        var match = CreateCommandRegex.Match(command);
        if (match.Success)
        {
            var queueName = match.Groups["name"].Value;
            this.CreateWorkQueue(queueName, serverPipe);
            goto end;
        }

        match = DeleteCommandRegex.Match(command);
        if (match.Success)
        {
            var queueName = match.Groups["name"].Value;
            this.DeleteWorkQueue(queueName, serverPipe);
            goto end;
        }

        match = ListCommandRegex.Match(command);
        if (match.Success)
        {
            this.ListServices(serverPipe);
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
        var messageBytes = Encoding.Unicode.GetBytes(message);
        serverPipe.Write(messageBytes, 0, messageBytes.Length);
    }

end:
    serverPipe.WaitForPipeDrain();
    serverPipe.Disconnect();
    serverPipe.Dispose();

    ...
}

private void DeleteWorkQueue(
    string queueName,
    NamedPipeServerStream serverPipe)
{
    this.workQueues.Remove(queueName);
    SendOkReply(serverPipe);
}
{% endhighlight %}

I added a couple of things to this implementation. First, I wrapped the command processor in a **try/catch** block to handle exceptions if they occur. When an exception does occur, I added the new **ERROR** response that will send back an error message to the client. I then added an error case where a command is sent that is not recognized. I don't have an explicit test defined that will test this code, but I will add one later so that there is a scenario specification for the case. This is more of just something to do for the moment for completeness.

I defined the new regular expression for the **DELETE** command, and now I am matching the regular expression for the **LIST** command. In the command processor, I decided to go against all of my professional being and use the **goto** statement to jump out of the command processor code. I've honestly never used a **goto** statement since leaving BASIC back in the day, but it honestly made sense here. Because I am using regular expressions to evaluate the commands, I cannot use a **switch** statement. If I just did one big **if/else if/else**, the nesting level would get too deep and the code would look atrocius. I broke down in the best interest of readability and maintainability and used the **goto**. I support the decision.

Now that the server implementation works, I'll implement the verification code:

{% highlight c# %}
[Then("the work queue will exist")]
public void ThenTheWorkQueueWillExist()
{
    Assert.True(this.workQueues.ContainsKey(TestWorkQueueName));
}

[Then("the work queue will be stopped")]
public void ThenTheWorkQueueWillBeStopped()
{
    Assert.Equal(
        WorkQueueState.Stopped,
        this.workQueues[TestWorkQueueName]);
}

[Then("the work queue will be deleted")]
public void ThenTheWorkQueueWillBeDeleted()
{
    Assert.False(this.workQueues.ContainsKey(TestWorkQueueName));
}
{% endhighlight %}

I refactored the **ThenTheWorkQueueWillExist** and **ThenTheWorkQueueWillBeStopped** methods to use the constant field that I created containing the name of the test work queue. I then implemented the opposite check for the **ThenTheWorkQueueWillBeDeleted** method that ensures that the **DELETE** comamnd did delete the work queue.

Starting the Work Queue
-----------------------
{% highlight gherkin %}
Given the work queue exists
And the work queue is stopped
When I start the work queue
Then the work queue will be running
{% endhighlight %}

In my example world, a work queue is a service that can be independently started or stopped relative to other work queues. It does not always have to be running and accessible. In this scenario, we are going to add the ability to start a work queue so that it can start accepting and processing messages.

The first step has already been implemented in a previous scenario, so we can reuse the existing implementation. The second step is pretty easy to implement since the work queues default to the stopped state.

{% highlight c# %}
[Given(@"the work queue is stopped")]
public void GivenTheWorkQueueIsStopped()
{
    Assert.Equal(
        WorkQueueState.Stopped,
        this.workQueues[TestWorkQueueName].State);
}
{% endhighlight %}

The third step will send a new **START** command to the named pipe server:

{% highlight c# %}
[When(@"I start the work queue")]
public void WhenIStartTheWorkQueue()
{
    this.RunNamedPipeServer();
    var reply = SendCommandToServer("START MyWorkQueue");
    Assert.Equal("OK", reply);
}
{% endhighlight %}

The named pipe server is then enhanced to handle the new command:

{% highlight c# %}
private static readonly Regex StartCommandRegex = new Regex(
    @"^START (?<name>\w+)$",
    RegexOptions.Compiled | RegexOptions.Singleline);

private void RunNamedPipeServer()
{
    ...

    try
    {
        ...

        match = StartCommandRegex.Match(command);
        if (match.Success)
        {
            var queueName = match.Groups["name"].Value;
            var workQueue = this.workQueues[queueName];
            workQueue.Start();
            SendOkReply(pipeServer);
            goto end;
        }

        ...
    }

    ...
}
{% endhighlight %}

In order to complete this step, I have to enhance my **WorkQueue** class and add the **Start** method to start the work queue. The implementation will simply perform a state change from stopped to running:

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
}
{% endhighlight %}

Finally, we just need to verify that the work queue is running:

{% highlight c# %}
[Then(@"the work queue will be running")]
public void ThenTheWorkQueueWillBeRunning()
{
    Assert.Equal(
        WorkQueueState.Running,
        this.workQueues[TestWorkQueueName].State);
}
{% endhighlight %}

Stopping the Work Queue
-----------------------
The final scenario is stopping the work queue:

{% highlight gherkin %}
Given the work queue exists
And the work queue is running
When I stop the work queue
Then the work queue will be stopped
{% endhighlight %}

The first and last steps have already been implemented, so we can reuse work that we have already completed. The second step is easy to implement given the work done in the previous scenario:

{% highlight c# %}
private static readonly Regex StopCommandRegex = new Regex(
    @"^STOP (?<name>\w+)$",
    RegexOptions.Compiled | RegexOptions.Singleline);

[Given(@"the work queue is running")]
public void GivenTheWorkQueueIsRunning()
{
  this.workQueues[TestWorkQueueName].Start();
}
{% endhighlight %}

The third step involves sending a new **STOP** command to the named pipe server and updating that implementation:

{% highlight c# %}
[When("I stop the work queue")]
public void WhenIStopTheWorkQueue()
{
    this.RunNamedPipeServer();
    var reply = SendCommandToServer("STOP MyWorkQueue");
    Assert.Equal("OK", reply);
}

private void RunNamedPipeServer()
{
    ...

    try
    {
        ...

        match = StopCommandRegex.Match(command);
        if (match.Success)
        {
            var queueName = match.Groups["name"].Value;
            var workQueue = this.workQueues[queueName];
            workQueue.Stop();
            SendOkReply(serverPipe);
            goto end;
        }

        ...
    }

    ...
}
{% endhighlight %}

Finally, I just need to add the **Stop** method to the **WorkQueue** class:

{% highlight c# %}
public void Stop()
{
    this.State = WorkQueueState.Stopped;
}
{% endhighlight %}

There it is, the complete work queue management solution.

Conclusion
----------
In this post, I continued developing the topic and example code for a management interface for a work queue system. The management interface was exposed by sending commands from a management client program to a named pipe server. I also used SpecFlow to drive the implementation of the solution. I did not use unit testing, and I will eventually bring it in when I turn the code into a production solution, but for the moment everything is being tested and I can demonstrate that my approach to sending commands over named pipes does work.

In the next post, I will take what I have learned about messaging using named pipes and I will turn this prototype into an actual management interface that I can use from PowerShell or other management tools to create, delete, list, start, or stop work queues.
