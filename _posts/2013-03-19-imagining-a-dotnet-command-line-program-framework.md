---
layout: post
title: Imagining a .NET Command Line Program Framework
description: In an earlier post, I introduced you to the properties of developing command line programs. In this post, I will revive that topic and will start looking at how to create a framework for building command line programs using the .NET Framework on Microsoft Windows computers.
disqus_identifier: 2013-03-19-imagining-a-dotnet-command-line-program-framework
categories:
- Command_Line_Programming
---
At the [November 2012 Desert Code Camp](http://nov2012.desertcodecamp.com/session/473), I presented a session on command line development. The focus of the presentation was why, in this world of web-based applications and graphical windowing environments, the command line still matters. And yes, it does still matter. Command line programs are quick to develop, provide demonstrable results faster when you do not necessarily need to have a GUI or web interface developed, are great for POCs and testing new ideas, and are also a great idea for providing a scriptable or expert interface for administering and managing your applications. 

In this post, I am going to expand on my presentation and my previous blog post and start writing a framework for creating .NET-based command line programs that run on the Microsoft Windows platform.

Framework Design
----------------
The first thing that I will do is look at my usage model for this framework. How will users (including myself) use this framework in everyday life to create command line programs? I think that the first thing to do is to understand that there are more than one type of command line program. There are in fact three types that I can think of initially:

* **Command line program**: This is a typical command line program that performs a single task and outputs a result. On Windows, commands like **dir**, **copy**, or **more** would qualify for this type of command.
* **Command suite program**: This is a more complex program that is run from the command line but allows you to execute commands. [Git](http://git-scm.org) would be considered a command suite program.
* **Windows service**: Some programs that you can run from the command line you may also want to run in the background and service processes. Windows services should be able to run either in the foreground or in the background as a service. Windows services are a pain to debug when they are running in the background, but it's fairly easy to launch the service in the foreground through Visual Studio and attach a debugger. You might choose to run a Windows service in the foreground for development, debugging or demonstrations, and run it as a Windows service in the background in production environments. A Windows service, if it can run in the foreground, may also be launched as a child process of another program or service.

Regardless of the type of command line program that you are writing, I want the experience to be the same so that we do not need to remember different techniques for each type of program. For example, I think that this might be an ideal approach for starting a command line program:

{% highlight c# linenos %}
internal class Program : CommandLineProgram
{
    private static int Main(string[] args)
    {
        return (new Program()).Run(args);
    }
}
{% endhighlight %}

This program implementation is simple, but not complete. The **Main** method accepts the arguments that were passed on the command line and returns an integer exit code that indicates if an error occurred. Recall that a **0** exit code indicates that the program completed successfully, otherwise an error code between 0 and 255 indicates what kind of error occurred.

The **Run** method should implement the standard logic for parsing the command line arguments, setting up the execution environment, and then calling the heart of the program that performs the actual task. I could see the interface for **CommandLineProgram** looking like this:

{% highlight c# linenos %}
public abstract class CommandLineProgram
{
    public int Run(params string[] args);

    protected abstract int Execute(string[] args);
}
{% endhighlight %}

In this interface, the **Run** method implements the parsing and pre-execution logic that is standard for every command line program. Once the command line arguments have been processed, the **Run** method will call the **Execute** method to perform the actual business logic for the program.

A couple of things to note here. First, notice the use of **params** for the **args** parameter to the **Run** method. I am doing this for unit testing, because the program should be unit testable. This will save a few keystrokes and make the API a little friendlier for testing:

{% highlight c# linenos %}
public class MyProgramTests
{
    [Fact]
    public void TestProgramRunsSuccessfully()
    {
        var program = new Program();
        var result = program.Run("-l", "somefile.txt", "output.txt");
        Assert.Equal(0, result);
    }
}
{% endhighlight %}

If I did not use the **params** keyword, the test scenario would look like this:

{% highlight c# linenos %}
public class MyProgramTests
{
    [Fact]
    public void TestProgramRunsSuccessfully()
    {
        var program = new Program();
        var result = program.Run(
            new[] { "-l", "somefile.txt", "output.txt" });
        Assert.Equal(0, result);
    }
}
{% endhighlight %}

In my opinion, the first usage makes the test case a little more readable.

Thinking about my future command line programs a bit further, many of the programs that I write may process data in some form. I may take a file as input, filter the data or compress or encrypt the file, and output the result. I may not deal directly with files either. I may redirect a file to standard input or send the output to a file with a redirection. I may combine multiple command line programs using the pipe symbol (**|**) so that the output of the first program will go to the standard input of the second program (firstprog.exe | secondprog.exe).

My command line program might do something that requires multiple input files. I may, for example, take a list of input files, combine them into a single package, and then output the combined result. Or take multiple input files and output all of their records to the same output stream.

In these use cases, I could see an alternative interface for the **CommandLineProgram** class that looks like this:

{% highlight c# linenos %}
public abstract class CommandLineProgram
{
    public int Run(params string[] args);

    protected virtual int Execute(string[] args);

    protected abstract int Execute(
        TextReader input,
        TextWriter output,
        TextWriter error);
}
{% endhighlight %}

In this interface, I added a new **Execute** overload method that takes three parameters and I revised the other **Execute** method that was previously abstract to give it a default implementation. The new overloaded method has a parameter for the input, output, and error streams. By default, all three parameters would be mapped to standard input, standard output, and standard error if there were no parameters specified on the command line. But if you pass a list of files as command line arguments (myprog.exe file1.txt file2.txt file3.txt), then the first **Execute** method will call the second **Execute** method once for each command line argument. The first time the second **Execute** method is invoked, the **input** parameter will have a **TextReader** object for file1.txt. The second call will have **input** mapped to file2.txt, and the third call will map **input** to file3.txt.

With this interface, I make the assumption that command line programs will operate on inputs and produce outputs, but I give you the option of overriding the first **Execute** method if that is not the case and your program does something like add a user to a database table or something else that does not require file operations. This is still not perfect. Thinking a little further, this revised interface for **CommandLineProgram** will only let me deal with text inputs and outputs. What happens if I am dealing with binary files? I could be writing a compression or encryption program that accepts text files as input and outputs a binary stream, or a decompression program that acceps a binary stream and outputs text data. Using **TextReaders** will not work for every scenario. The interface needs to be more flexible. I could envision the following possible forms of the second **Execute** method:

{% highlight c# linenos %}
protected abstract int Execute(
    TextReader input, TextWriter output, TextWriter error);
protected abstract int Execute(
    Stream input, Stream output, TextWriter error);
protected abstract int Execute(
    TextReader input, Stream output, TextWriter error);
protected abstract int Execute(
    Stream input, TextWriter output, TextWriter error);
{% endhighlight %}

It does not make sense, at least right now, to use anything but a **TextWriter** for the error stream. The error stream is always going to be text based.

Let's throw in another wrinkle. What if my input or output is not a file and is something like the name of a database? Or if there is special logic or handling that I need to do when opening a file? In these cases, it might be better to just get the original argument as a string. This would expand my **Execute** forms:

{% highlight c# linenos %}
int Execute(TextReader input, TextWriter output, TextWriter error);
int Execute(Stream input, Stream output, TextWriter error);
int Execute(TextReader input, Stream output, TextWriter error);
int Execute(Stream input, TextWriter output, TextWriter error);
int Execute(string input, TextWriter output, TextWriter error);
int Execute(string input, Stream output, TextWriter error);
int Execute(TextReader input, string output, TextWriter error);
int Execute(Stream input, string output, TextWriter error);
int Execute(string input, string output, TextWriter error);
{% endhighlight %}

Given all of these forms, I don't want to define abstract methods for them and then figure out which one to call. I basically see two options:

1. Create a class hierarchy with a base class for each form of **Execute**.
2. Create a generic class and use reflection to look at the generic type parameters to determine how to execute **Execute**.
3. Use reflection to find the **Execute** method in the object instance based on the signature.

The problem that I see with the first approach is that I will have 10 different base classes for command line programs:

{% highlight c# linenos %}
public abstract class CommandLineProgram { ... }
public abstract class CommandLineProgram_ReaderWriter :
    CommandLineProgram { ... }
public abstract class CommandLineProgram_StreamWriter :
    CommandLineProgram { ... }
public abstract class CommandLineProgram_ReaderStream :
    CommandLineProgram { ... }
public abstract class CommandLineProgram_StreamStream :
    CommandLineProgram { ... }
public abstract class CommandLineProgram_StringWriter :
    CommandLineProgram { ... }
public abstract class CommandLineProgram_StringStream :
    CommandLineProgram { ... }
public abstract class CommandLineProgram_WriterString :
    CommandLineProgram { ... }
public abstract class CommandLineProgram_StreamString :
    CommandLineProgram { ... }
public abstract class CommandLineProgram_StringString :
    CommandLineProgram { ... }
{% endhighlight %}

I'm not sure that I like this idea. The second approach is better. I can reduce the number of base classes to two:

{% highlight c# linenos %}
public abstract class CommandLineProgram { ... }
public abstract class CommandLineProgram<TInput, TOutput>
    : CommandLineProgram
{
    protected override int Execute(string[] args) { ... }

    protected abstract int Execute(
        TInput input, TOutput output, TextWriter error);
}
{% endhighlight %}

I can hide all of the reflection code in the base class implementation and the interface is easy for another developer to understand. Plus there is compile time error checking to ensure that the correct form of the second **Execute** method is implemented.

The third option works as well, but is not as friendly as the second:

{% highlight c# linenos %}
public class Program : CommandLineProgram
{
    private int Execute(
        TextReader input, Stream output, TextWriter error);
}
{% endhighlight %}

The third option is still friendlier than the first, but might be confusing for other developers since the second form of the **Execute** method is not declared by the base class.

I don't think that the first option is acceptable, so I'm not going to pursue that. Initially in my head, I was thinking I would do the third option, but as I am writing this post, the second option has some interesting aspects that I would like to explore later, so I am going to proceed with this approach and see where it leads me. I may have to drop it later and go with the third approach, but I should not lose any work because the code should be similar for both approaches.

So here's where I have ended up with for my command line program design:

{% highlight c# linenos %}
public abstract class CommandLineProgram
{
    public int Run(params string[] args) { ... }

    protected abstract int Execute(string[] args);
}

public abstract class CommandLineProgram<TInput, TOutput> :
    CommandLineProgram
{
    protected override int Execute(string[] args) { ... }

    protected abstract int Execute(
        TInput input,
        TOutput output,
        TextWriter error);
}
{% endhighlight %}

This is good for command line programs, but what about command suites and Windows services? Let us take a look at those now.

Command Suite Program
---------------------
Let us first recognize that a command suite program is just a specialized form of a command line program. A command suite program may have global arguments and options that precede the command on the command line, and commands may have their own arguments and options that follow them on the command line. My initial view of a command suite program looks like this:

{% highlight c# linenos %}
public abstract class CommandSuiteProgram : CommandLineProgram
{
    protected override int Execute(string[] args) { ... }
}
{% endhighlight %}

The **CommandSuiteProgram.Execute** method will be called by **CommandLineProgram.Run** after the global arguments and options have been processed. The first item in the **args** array could be the command, or I could define a positional argument to be used for the command:

{% highlight c# linenos %}
public abstract class CommandSuiteProgram : CommandLineProgram
{
    [Argument(1)]
    public string CommandName { get; set; }

    protected override int Execute(string[] args) { ... }
}
{% endhighlight %}

In this case, the **args** array would be the command line arguments that immediately follow the command name on the command line. The **CommandName** property would be set to the name of the command to execute by the **CommandLineProgram.Run**'s command line processing algorithm.

The command suite needs to execute a command. I'll employ the **Command** pattern here:

{% highlight c# linenos %}
public interface ICommand
{
    int Execute(string[] args);
}

public abstract class Command : ICommand
{
    public abstract int Execute(string[] args);
}

public abstract class Command<TInput, TOutput> : Command
{
    public override int Execute(string[] args) { ... }

    protected abstract int Execute(
        TInput input, TOutput output, TextWriter error);
}
{% endhighlight %}

Here I defined a generic interface named **ICommand** that classes can implement in order to be used as commands. I also created two **Command** classes based on my discussion in the previous section. The first **Command** abstract class is a generic command that processes its own arguments. The second **Command** generic class specifically performs some kind of file processing and takes the types for the input and output parameters. I should be able to share logic between the **CommandLineProgram&lt;TInput, TOutput&gt; class and the **Command&lt;TInput, TOutput&gt; class for argument processing.

When thinking of command suite programs, I am using Git as a model because it is the program that I use the most with commands. One of the great features of Git is that it is extensible. You can add commands to Git. For example, [gitflow](https://github.com/nvie/gitflow) adds the **flow** command hierarchy to the **git** command. There are probably others that do the same. What would be great is if I could ship a command suite and allow others to expand on my program with their own commands. I can envision using one of my favorite .NET technologies called [Managed Extensibility Framework](http://msdn.microsoft.com/en-us/library/dd460648.aspx) or (MEF) to do this.

If I use the **ICommand** interface as the contract interface for commands, then I can use MEF to discover and import the commands. I will create a custom export attribute for MEF that includes the name of the command so that I can locate it later:

{% highlight c# linenos %}
[AttributeUsage(AttributeTargets.Class, AllowMultiple = true)]
[MetadataAttribute]
public sealed class CommandAttribute : ExportAttribute
{
    public CommandAttribute(string name) :
        base(typeof(ICommand))
    {
        this.Name = name;
    }

    public string Name { get; private set; }
}

public interface ICommandMetadata
{
    string Name { get; }
}
{% endhighlight %}

Because I am importing the **ICommand** interface, I can use either form of the **Command** base class, or I can use a custom class that implements and exports **ICommand**:

{% highlight c# linenos %}
[Command("add")]
public class AddCommand : Command { ... }

[Command("compress")]
public class CompressCommand : Command<TextReader, Stream> { ... }
{% endhighlight %}

Before closing out the design of command suites, let's look quickly at the **git** and **gitflow** example in a little more detail. **Gitflow** makes use of command categories or groups and has support for subcommands. For example:

    > git flow init
    > git flow feature start my-feature
    > git flow feature finish my-feature
    > git flow release start 1.0.0
    > git flow release finish 1.0.0

My current design for command suite programs cannot handle this type of scenario yet. I could expand the metadata in the **CommandAttribute** attribute class to include a category name:

{% highlight c# linenos %}
[AttributeUsage(AttributeTargets.Class)]
[MetadataAttribute]
public sealed class CommandAttribute : ExportAttribute
{
    public CommandAttribute(string name)
    {
        this.Name = name;
    }

    public CommandAttribute(string category, string name)
    {
        this.Category = category;
        this.Name = name;
    }

    public string Category { get; private set; }

    public string Name { get; private set; }
}
{% endhighlight %}

If I do this, then I can filter my imports and implement a command category class:

{% highlight c# linenos %}
public interface ICommandMetadata
{
    [DefaultValue(null)]
    string Category { get; }

    string Name { get; }
}

public abstract class CommandCategory : Command
{
    protected CommandCategory(
        string category,
        ICommand<Lazy<ICommand, ICommandMetadata> commands)
    {
        this.Commands =
            commands.Where(x => category == x.Metadata.Category);
    }

    [Argument(1)]
    public string CommandName { get; set; }

    protected IEnumerable<Lazy<ICommand, ICommandMetadata>> Commands
    {
        get;
        private set;
    }

    public override int Execute(string[] args)
    {
        var command = 
            this.Commands.Single(
                x => this.CommandName == x.Metadata.Name);
        return command.Execute(args);
    }
}
{% endhighlight %}

Windows Services
----------------
Windows services are typically implemented in .NET by subclassing and implementing the [ServiceBase](http://msdn.microsoft.com/en-us/library/system.serviceprocess.servicebase.aspx) class. However, if I do that, my program will only run as a Windows service. That's not what I want to do. I want to be able to run my Windows services either from the command line, as a child process of another program, in the debugger, or as a Windows service. So I will not subclass **ServiceBase** directly. I will do that in my framework. Instead, I will implement another base class that I will extend to implement my service program logic, and the framework's implementation of **ServiceBase** will wrap my program class when running as a Windows service.

When I defined the command suite framework in the pevious section, I built it on top of the command line program framework. For a Windows service, I will build the Windows service framework on top of the command suite framework. Why am I doing this? I am thinking of how I will use a Windows service from a command line or how I will run the Windows service in the background.

By default, I think that the my service program should expect to run in the foreground like it's being run from the command line, in the debugger, or as a child process. Executing something like this should just run the service in the foreground:

    > myservice.exe

In this case, the service would have interactivity with the console and would be able to read from standard input and write to either standard output or standard error.

If I were to run the program as a service, I could pass an option to alert the program that it should start as a Windows service:

    > myservice.exe --service

For diagnostic reasons, I will probably want to support administrative functions in my service program such as being able to start or stop the service:

    > myservice.exe service start
    > myservice.exe service stop
    > myservice.exe service pause
    > myservice.exe service continue

I may also want to be able to xcopy deploy my service without an installer and be able to install it onto a computer from the command line:

    > myservice.exe service install
    > myservice.exe service uninstall

Given this, I can see my service being used as a command suite. Here's my first design for the Windows service framework:

{% highlight c# linenos %}
public abstract class WindowsServiceProgram : CommandSuiteProgram
{
    [Option("service")]
    public bool RunAsService { get; set; }

    protected override int Execute(string[] args);
}

public abstract class WindowsService
{
    public int Run(string[] args) { ... }

    protected abstract int Execute(string[] args);
}

internal class WindowsServiceHost : ServiceBase
{
    private readonly WindowsService windowsService;

    internal WindowsServiceHost(WindowsService windowsService)
    {
        this.windowsService = windowsService;
    }

    protected override void OnContinue() { ... }

    protected override void OnCustomCommand(int command) { ... }

    protected override void OnPause() { ... }

    protected override void OnStart(string[] args) { ... }

    protected override void OnStop() { ... }
}

[Command("service", "start")]
internal class StartServiceCommand : Command
{
    protected override int Execute(string[] args) { ... }
}

[Command("service", "stop")]
internal class StopServiceCommand : Command
{
    protected override int Execute(string[] args) { ... }
}

[Command("service", "pause")]
internal class PauseServiceCommand : Command
{
    protected override int Execute(string[] args) { ... }
}

[Command("service", "continue")]
internal class ContinueServiceCommand : Command
{
    protected override int Execute(string[] args) { ... }
}
{% endhighlight %}

Here I defined the base class for the program that hosts the Windows service, the base class for the actual program code that will be executed, and my **ServiceBase** subclass that I can use to host the program when the program is being run in the background as a Windows service.

Summary
-------
In this post, I introduced you to my ideas and initial design for a framework for creating .NET applications that process the command line and run in a console window or as a Windows service. I walked you through the three types of programs (command line program, command suite program, and Windows service). I then started designing the class framework that I will be developing to implement command line programs. In my next post, I will start down the path of processing options and arguments from the command line and will show you the framework for building simple command line programs.