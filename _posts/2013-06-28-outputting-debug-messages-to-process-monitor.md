---
title: Outputting Debug Messages to Process Monitor
categories:
- windows_development
- debugging
category_names:
- Windows Development
- Debugging
---
I have been using Process Monitor a lot recently to help solve customer support issues. Process Monitor is a great tool for looking at what files, registry keys, and network resources that my products are using. Earlier today, I discovered a new technique to make my Process Monitor logs better.

<!--more-->

Since taking the lead on [Neuron ESB](http://www.neuronesb.com), I have had to spend a lot of time refining my customer support skills. Customer support is hard for a product like Neuron, especially when I can't physically see the environment that Neuron is running in or poke around on the server to understand where Neuron might be having a problem. One of the tools that I have found to be extremely useful for my customer support activities is a free utility from Microsoft that is part of their wonderful [Sysinternals](http://www.sysinternals.com) suite: [Process Monitor](http://technet.microsoft.com/en-us/sysinternals/bb896645.aspx).

Process Monitor is a fantastic tool. Users can start Process Monitor on their computer or server and Process Monitor immediately begins capturing events that occur on the computer. Process monitor captures process and thread activity, file activity, registry activity, network activity, and other profiling events on the computer. At the end of a capture session, users can save the Process Monitor log to a file, and that file can be viewed or replayed by other people. For example, when looking at some difficult-to-solve problems, I can have my customers email me their Process Monitor log so that I can replay their session and look at what Neuron was doing at the time that a problem occurred.

Some cool features of using Process Monitor for production debugging is that Process Monitor collects a lot of information about the computer and each event that gets logged. Looking at a user's Process Monitor log, I can get the computer name, see the operating system version, whether the computer is a 32-bit or 64-bit machine, and get additional information about the runtime environment. Looking at each event, I can see what modules or assemblies are loaded into each process, where each module or assembly was loaded from, and the call stack for the process and thread that an event originated from. If I have my PDB symbol files for native code, I can get detailed information and see the source code around events. Unfortunately, this does not work with managed code, but the information is still valuable.

While Process Monitor is a great tool, one of the problems with looking at the output is trying to determine what events are relevant to a particular problem. Often I need to know the steps that a user executed to try to match events to parts of my program. What would be great is to be able to combine my trace logs with the Process Monitor output.

One of my greatest shortcomings is that I usually learn tools by diving in and exploring. I spend very little time looking at the help documentation for products. Usually, if I can't figure out a tool easily and find value right away, I may not come back to that tool or may not use it that often. However, this morning Ihit the online help for Process Monitor and came across an interesting topic at the bottom of the help contents. Apparently, I am not alone in wanting trace output. Other people have wanted this as well. Fortunately, the author of Process Monitor was listening and gave us a way of sending trace messages to Process Monitor to be included as events in the log. The sample code in the online help shows using the Win32 API and C to output the trace output. I translated that code into .NET.

The main class, **ProcessMonitor**, exposes two methods named **WriteMessage** to write a trace message to the Process Monitor log. The first method writes a string to the Process Monitor log. The second method can be used to format a string and then write the formatted message to the log. Here's the code:

{% gist 5890044 ProcessMonitor.cs %}

The **NativeMethods** class defines the P/Invoke methods for the Win32 API calls that are needed to send the trace message to Process Monitor:

{% gist 5890044 NativeMethods.cs %}

To use this code, simply instantiate the **ProcessMonitor** class in a program and send messages to Process Monitor:

{% highlight c# %}
internal class Program
{
    private void Main()
    {
        using (var procmon = new ProcessMonitor())
        {
            procmon.WriteMessage("The program is starting.");
            Thread.Sleep(5000);
            procmon.WriteMessage("The program is running.");
            Thread.Sleep(5000);
            procmon.WriteMessage("The program is ending.");
        }
    }
}
{% endhighlight %}

Now, when running Process Monitor, you will see your trace messages in the log and you can correlate the process events with the source code to track down problems.

Note that you must enable profiling events to see trace messages. Process Monitor creates trace events in the log as profiling events, and by default profiling events are filtered out of the events that Process Monitor displays. If you enable profiling events, your trace messages will appear in the Process Monitor log.
