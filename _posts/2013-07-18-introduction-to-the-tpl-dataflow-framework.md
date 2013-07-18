---
layout: post
title: Introduction to the TPL Dataflow Framework
description: The .NET 4.0 Framework introduced the new Task Parallel Framework which has made background and parallel processing extremely easy for .NET developers. With .NET 4.5, Microsoft released a new enhancement for the TPL library out of band. Called the TPL Dataflow framework, this new framework makes it extremely easy to create batch-processing pipelines in your applications. In this post, I will introduce you to the background concepts of the TPL Dataflow framework and set up further posts where I will show you how to use and build on the TPL Dataflow framework.
categories:
- windows_development
- dotnet_development
category_names:
- Windows Development
- .NET Development
author: Michael F. Collins, III
author_first_name: Michael
author_last_name: Collins
author_gender: male
twitter_creator: mfcollins3
---
Probably one of the most significant improvements over the past few years in my software development ecosystem has been the rise of package managers. I have always built software using third-party software libraries, and over the years most of these libraries have come from the open source community. I don't know the history of package management and who came up with it first, but it seems that the Ruby Gem tool is the origin of many of the current implementations. Along with Gem, Node.js has NPM, and fortunately, .NET has NuGet.

What has been truly great with NuGet is that over the past two years, it has not only been used by community folks to redistribute their libraries, but it is also being used by Microsoft to push out out-of-band releases and improvements to the .NET Framework. The first releases that I really noticed were the Azure SDKs, but I have just started to notice other frameworks that also improve the base class library. One of those frameworks is the topic of today's post.

Actors
------
About eighteen months ago, Mickey Williams ([LinkedIn](http://www.linkedin.com/pub/mickey-williams/0/858/5a2) or [Twitter](https://twitter.com/mickeyw)), the vice-president of [Neudesic](http://www.neudesic.com)'s Technology Platform Group, turned me onto [Erlang](http://www.erlang.org). Erlang is a VM-based language and framework used heavily in the telecommunications industry. It's designed for scalability and availability and it was really my first foray into actor-based frameworks.

In an actor framework, an actor is a completely isolated component that runs in its own thread. An actor doesn't have more than one thread and there's no concurrency to worry about as there's no shared state between actors. Each actor has its own copy of the data that it needs. Multiple actors can be composed together in a system and can talk to each other by passing messages between them. This message passing framework is critical in the actor architecture because it also allows actors to be distributed over multiple physical nodes. The Erlang runtime knows where actors physically located and handles routing the messages between actors. The actors only know that they can send messages to other actors or receive messages sent to them.

Since my awakening into the world of actors, I have seen other uses of actor-based frameworks pop up. Java and Scala have the [Akka](http://akka.io) framework. [PostSharp](http://www.postsharp.net) recently introduced an actor-style framework in their latest release. Visual C++ 2010 introduced the [Asynchronous Agents Library](http://msdn.microsoft.com/en-us/library/dd492627.aspx). Now, the .NET Base Class Library team has gotten into the game with the [TPL Dataflow](http://msdn.microsoft.com/en-us/library/hh228603.aspx) framework.

About the TPL Dataflow Framework
--------------------------------
The Dataflow framework is an extension of the Task Parallel Library framework that was introduced in .NET 4.0 for use in writing background and asynchronous processing. Instead of using the older components for queueing delegates to be run in a background thread pool, Microsoft introduced the **Task** and **Task&lt;T&gt;** classes that could be used to encapsulate background tasks, queue the work to the background thread pool, and allow the application to monitor the progress and get the end result or exception that occurred in the asynchronous task. The **Task** classes made it extremely easy and efficient to implement asynchronous processing and have quickly improved the efficiency of coding asynchronous tasks as well thanks to the new **async** and **await** keywords added in the latest version of the C# language.

The Dataflow library is a natural extension of the TPL library that allows developers to create data-processing pipelines in their applications. The Dataflow library provides a framework for creating *blocks* that perform a specific function asynchronously. These blocks can be composed together to form a *pipeline* where data flows into one end of the pipeline and some result or results come out from the other end. This is great when data can be processed at different rates or when parallel processing can efficiently spread work out across multiple CPU cores. For example, consider the following pipeline:

![Example dataflow pipeline](/images/2013-07-18-dataflow-pipeline.png "Example dataflow pipeline")

In this example, consider that a streaming data source is being used to obtain the input data for the pipeline. The data source may be a file of records that are being downloaded over the Internet, or a series of records being read from a database or disk file. The data source could also be messages being received from a message queue such as RabbitMQ or the Azure Service Bus. 

As the messages are received, they first go through a block where they are transformed into a format that's easier for the pipline to use. The source data may be XML for example, so the transform block could be parsing the XML and turning the data into objects that are easier to query and manipulate.

The next step is that the data goes through some sort of processing step. If these are financial records for example, the process step may be some sort of calculation or some kind of analytic operation takes place. For this example, let's assume that the calculation is not simple. The calculation could involve things such as database lookups, calls to external web services to obtain additional information that is merged with the input data, or there could be a lot of in-memory processing that needs to take place on the record. Whatever it is, let's just assume that this processing step is a block in our pipeline and that records can be received and transformed faster than they can be processed. Fortunately, this pipeline is running on a modern quad-core server, or maybe the server has multiple cores and CPUs, we can take advantage of this fact by spinning up multiple processing blocks that can each handle a record concurrently. So instead of processing one record at a time, we have decided that we can optimally handle three records at a time. We could spin up more, but let's just assume for this example that more than three would be inefficient and less than three would cause an unwanted backlog of messages waiting to be processed.

After the processing block, there's a block that collects and aggregates the results of the processing. If we're dealing with financial information, for example, this block may be calculating statistical values such as mean, mode, or standard deviation. The block could also choose to sample records that are output instead of looking at the entire population. From there, the calculated values are then transformed into another output format, or possibly turned into data for a report, and then finally the final result of the pipeline is output.

This is the kind of structure that the TPL Dataflow library helps us to build in .NET applications. Beyond asynchronous tasks and parallel processing, TPL introduces a framework that provides the concepts of *block* and *pipeline* to .NET programs and provides a mechanism where blocks can be composed into a pipeline, and messages can be efficiently moved between blocks as a pipeline executes.

Below is an example pipeline that is similar to the illustration above. I n this pipeline, I have an input block that reads records from an input source, which in this case is an array of strings, but it could just as easily be a text file or standard input. I have a block that transforms the line of text into an **XDocument** object. I have a block that extracts a name and age from the **XDocument** object and outputs a **Tuple** object containing the extracted values. I have another transform block that converts the **Tuple** object into a formatted string. Finally, there is a block that will write the formatted string to standard output.

{% gist 6030475 %}

These blocks that I am using contain standard blocks that are provided by the Dataflow library. There are not that many pre-defined blocks (only nine standard blocks), but the ones that are there are very powerful and useful later when I explore creating custom Dataflow blocks.

Rules for Building Pipelines
----------------------------
The Dataflow library provides an easy to use and powerful framework for building asynchronous data processing pipelines for your programs. But like all frameworks, there are rules that you have to understand in order to be successful. These are not earth shattering rules and in fact have been cited frequently for object-oriented development or command line development on Unix (and Windows to some extent, but definitely more so for Unix).

###Do One Thing

To be successful in building Dataflow pipelines, this rule is critical:

**Do one thing, and do it well**

This is more a rule for Unix command line programs, but is also a principal of modern object-oriented development called the [Single Responsibility Principle](http://en.wikipedia.org/wiki/Single_responsibility_principle). The central idea is that your block should only perform one action and should only have one reason to change. 

Return to the code example above. Each block had no more than one responsibility. The input block provided the input records to the pipeline. The transformer blocks all performed a single transform: converting a string into an XML object, parsing the XML and generating an object containing the record's data, and creating a formatted message from the object. The output block simply took the data that was provided to it and wrote it to the standard output stream.

Most blocks that you are going to use are going to use the standard **ActionBlock**, **TransformBlock**, or **TransformManyBlock** blocks. Each of these blocks are based on a delegate, lamdba expression, or anonymous method that does work. Keep these lamdba expressions or anonymous methods small and easy to follow and maintain.

###Design for Composition

From the Unix programming world, this rule says that you should design your command line programs so that the output of one program can be used as the input to another program. In the object-oriented programming world, we call this the [Open/Closed Principle](http://en.wikipedia.org/wiki/Open/closed_principle) where we preach to design your classes so that they are **open to extension, but closed to modification**.

What this means in relation to the Dataflow library is build blocks so that they can be composed with other blocks. Assume that in the majority of cases, the blocks and pipelines that you build could be composed with other blocks or pipelines to produce new blocks or pipelines. Using the example above, don't build a pipeline that could be possibly reused with the final two blocks that produce the output message and output the message to standard output unless that is the intent of the pipeline. If you are building a reusable pipeline, stop at the point where the pipeline outputs a **Tuple** object containing the person's name and age. Let the ultimate consumer of your pipeline or custom block implement the final formatting and output logic.

Conclusion
----------
The TPL Dataflow Library is an exciting addition to the .NET Framework 4.5. This framework is going to provide additional power and utility to the Task Parallel Framework. Using Dataflows, developers will be able to do more than build asynchronous tasks. They will be able to build fully asynchronous data processing pipelines that will encourage reuse and composition and that will maximize the use of multi-core architectures for concurrent and parallel processing.

In my next post, I will start to show how I have created custom blocks to create dataflows that support distributed processing and integration with external systems.