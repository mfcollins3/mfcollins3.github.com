---
title: Understanding OutputDebugString
categories:
- windows_development
- debugging
category_names:
- Windows Development
- Debugging
---
In this post, I want to discuss a basic debugging technique on Windows by outputting trace information through the debugger. I will explain to you how you can use OutputDebugString from native or .NET code and how to write tools that can you can install with your production software to capture this trace information at runtime.

<!--more-->

Introduction
------------
Debugging is a skill that I am constantly working on. The problem is that like most of computer science, debugging is an extremely large topic. For many software developers, debugging may be thought of as using a tool such as Visual Studio to walk through your code. Unfortunately for them, only a small fraction of bugs happen in this controlled environment during testing. Users will undoubtedly use your software in ways that you had never imagined that they would, and all kinds of conditions are bound to pop up in foreign environments where debuggers are not allowed.

One of my favorite techniques for debugging is instrumenting my programs with debugger trace statements. These statements get output while my program is running so that I can later review the transcript of the program's execution to look for where my program might have failed. Trace statements are more efficient than breakpoints because they don't require my program to stop so that I can walk through the code. I also do not need to take notes while the program is running because anything that I want to record I can write to the trace output.

The Microsoft Windows API includes a function named [OutputDebugString](http://bit.ly/KEQNZh) that simply takes a string and sends the string to the debugger. This is the primary mechanism for outputting debugger trace information at runtime, and it's only available normally in native code. .NET applications don't program directly against **OutputDebugString**, but in .NET we have the [DefaultTraceListener](http://msdn.microsoft.com/en-us/library/system.diagnostics.defaulttracelistener.aspx) class that is attached automatically to the **Trace** class or **TraceSource** objects as event listeners. **DefaultTraceListener** will output the trace messages that are written to a trace source to the debugger using the **OutputDebugString** function.

When not running in a development environment, Microsoft makes a wonderful tool available that can be used in production or QA environments to capture the trace log. It is named [DebugView](http://technet.microsoft.com/en-us/sysinternals/bb896647) and it is a free download from the [Microsoft Sysinternals website](http://technet.microsoft.com/en-us/sysinternals). **DebugView** is a simple little tool, but it will capture and display the messages written to **OutputDebugString** that are running on the local computer. In addition, there's a great feature where you can have **DebugView** connect to an instance of **DebugView** that is running on a remote server, and you can pipe all of the debug output to your development computer.

**DebugView** is a great tool, but even though it is free, the license provided by Microsoft prevents me from distributing **DebugView** with my own software. Microsoft prefers that customers download the latest version from Microsoft's servers. This can be problematic if my users are in a locked-down production environment and need to go through a change control process in order to install any new software on their servers just so that I can diagnose a problem for a customer support issue.

Having an inquisitive mind, I wanted to understand how **DebugView** works so that I could look at writing my own utility that I can install with my software products and allow my customers to capture the trace output without having to install **DebugView**. In the rest of this post, I am going to explain to you how **OutputDebugString** works internally, and how to write your own program that can capture the debug trace information for your own use.

OutputDebugString Internals
---------------------------
**OutputDebugString** works by using an interprocess communication protocol that is based on shared memory to exchange messages between processes and Win32 event objects that are used to synchronize access to the shared memory and alert the debugger and the process being debugged of when to act. The debugger will created the shared memory object and will use a Win32 event to notify processes that the shared memory buffer is available to receive a debug message. A process waiting to send a message via **OutputDebugString** will wait until the event is triggered and will obtain exclusive access to the shared memory buffer in order to store the message that will be output by the debugger. Once the message has been stored in the shared memory buffer, the process being debugged will trigger a second event that will notify the debugger that a message has been staged in the shared memory buffer and that the debugger can now safely read the contents of the shared memory buffer. This process repeats continuously so that debug messages are witten to the debugger from the processes running on the user's computer.

The shared memory object is named **DBWIN_BUFFER** and is created by the debugger. **DBWIN_BUFFER** is 4096 bytes in length. The first four bytes of the buffer is the process identifier for the process that stored the debug message in the shared memory buffer. The other 4092 bytes contain the characters for the message. Looking at the MSDN documentation, you will notice that there is both an ANSI (**OutputDebugStringA**) and a Unicode (**OutputDebugStringW**) version of **OutputDebugString**. Unlike most of the modern Win32 APIs, **OutputDebugStringW** will attempt to convert the debug message to the ANSI character set before storing the message in the shared memory buffer. Given this, you can expect that the shared memory buffer will contain 8-bit ANSI characters that will need to be converted to Unicode before you can use them in a modern Windows application or a .NET application.

The two events used to synchronize access to the shared memory buffer are named **DBWIN_BUFFER_READY** and **DBWIN_DATA_READY**. Both of these events are auto-reset events that are created by the debugger process. A process that is trying to use **OutputDebugString** will wait for the **DBWIN_BUFFER_READY** event to be set before writing to the shared memory buffer. After setting the **DBWIN_BUFFER_READY** event, the debugger will wait for the **DBWIN_DATA_READY** event to be set by the process being debugged. When the **DBWIN_DATA_READY** event is set, the debugger will know that a message has been stored in the **DBWIN_BUFFER** shared memory object and the debugger can safely read the message from the shared memory.

Basic Capture Program
---------------------
Using .NET, it is extremely simple to write a program that will act like a debugger to capture and output the debugger trace messages. Below is a simple console program that implements the protocol and will write the debug trace messages to standard output:

{% gist 5695056 OutputDebugStringWriter.cs %}

This program demonstrates the simple process of creating a RAM-based memory-mapped file for the shared memory object and creating the **DBWIN_BUFFER_READY** and **DBWIN_DATA_READY** events. The program then runs a loop where it continues to receive and output messages sent from **OutputDebugString** until the user presses the **CTRL+C** key.

This program is cool, but if you run it on your computer and leave it running, you are bound to see messages written to the screen from multiple processes. What would be even better is if we could limit the output to only a specific process that we are interested in debugging.

Enhanced OutputDebugString Capture
----------------------------------
This second program offers a slight modification of the first. Using this program, you can specify the path of a program and any command line arguments. The capture program will run the specified program as a child process and will filter out any debug trace messages that do not originate from the child process:

{% gist 5695056 CaptureProgramDebugOutput.cs %}

Conclusion
----------
If you understand the internal protocol behind the **OutputDebugString** API, it is pretty simple to write a custom tool that you can distribute with your software to capture and report the debug trace information from production environments. In this blog post, I have shown through source code samples how to capture **OutputDebugString** messages from either native Windows applications, Windows services, or .NET applications. Hopefully this will help you to build your own tool that you can use to support your own programs in production environments.
