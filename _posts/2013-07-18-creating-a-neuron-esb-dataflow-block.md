---
title: Creating a Neuron ESB Dataflow Block
categories:
- neuron_esb
category_names:
- Neuron ESB
---
In my last post, I introduced you to the TPL Dataflow library that was added out-of-band to .NET 4.5. In this post, I will show my first example of a custom dataflow block when I create a block to support building Neuron ESB-based dataflow pipelines that send or receive messages to a Neuron ESB topic.

<!--more-->

In my [last post]({% post_url 2013-07-18-introduction-to-the-tpl-dataflow-framework %}), I introduced you to the TPL Dataflow Library. To recap, the Dataflow Library was produced by the .NET Base Class Library team and was released out-of-band via [NuGet](http://www.nuget.org). Using the Dataflow Library, it's easy to create individual blocks that perform a behavior and compose them into a parallel processing pipeline. While most of the internals of a pipeline can be handled with standard blocks, lamdba expressions, and anonymous methods, getting data into the pipeline or sending data produced to the pipeline to somewhere else is left up to the developer to figure out. In this post, I will show how easy it is to create a block by tying my Dataflow Library research with my day job and creating a block that can be used to send messages to or receive messages from a Neuron ESB service.

Dataflow Block Design Basics
----------------------------
Building a dataflow block is extremely easy. Every dataflow block falls within one of these three categories:

1. Source block
2. Target block
3. Propagator block

A **source block** is a data source that provides messages. Source blocks are typically used as the first block in a dataflow pipeline because the source block will feed the source data to the pipeline. On the other side of a pipeline, a **target block** is typically a destination block that is used at the end of a dataflow pipeline. Messages sent to a target block are delivered to a destination, and then processing of that message and pipeline terminates at that point. Between source blocks and target blocks are **propagator blocks**.

Propagator blocks act as both source blocks and target blocks. Propagator blocks typically fall into two further subcategories:

1. Transformer block
2. Bi-directional block

A transformer block will transform each record that is provided to it as input and will output one or more records that are produced from the source record. In my previous post, I used transformer blocks to convert a string to an **XDocument** object, for example.

A bi-directional block is simply a dataflow block that can be used as either a source block or a target block, and messages sent to the block are not necessarily related to the messages that are received from the block. A socket or pipe, for example, could be represented by a bi-directional block because you can both write to or read from a socket or pipe.

In this post, the dataflow block that I will create will be a bi-directional propagator block, so it will allow being used either as a publisher or subscriber to a Neuron ESB topic.

Creating a Dataflow Block
-------------------------
Dataflow blocks conform to a contract that is specified by the following .NET interfaces:

* [ISourceBlock<TOutput>](http://msdn.microsoft.com/en-us/library/hh160369.aspx)
* [ITargetBlock<TInput>](http://msdn.microsoft.com/en-us/library/hh194833.aspx)
* [IPropagatorBlock<TInput, TOutput>](http://msdn.microsoft.com/en-us/library/hh194827.aspx)
* [IReceivableSourceBlock<TOutput>](http://msdn.microsoft.com/en-us/library/hh194860.aspx)

The difference between **ISourceBlock<T>** and **IReceivableSourceBlock<T>** is that messages received by a normal source block can only be received by linked target or propagator blocks. Using the **IReceivableSourceBlock<T>** interface, consumers can query the block for available messages and the source block does not need to be connected to any other target or propagator blocks.

Looking at the online documentation for the above interfaces, you'll notice that there's a bit of lack of documentation on how to implement each method defined in the interfaces. I could spend a good portion of this post describing each method, but the good news is that we really don't need to have a good understanding of that right now. The reason for this is that, when creating custom dataflow blocks, it's usually unlikely that you will be building a dataflow block from scratch. A better approach to creating custom dataflow blocks is to compose a new dataflow block from others. So the custom block that I will create will make use of standard blocks for the internal implementation and message handling protocols between blocks. Instead, I will only focus on the core functionality of sending messages to Neuron, or handling messages that are received from Neuron.

NeuronEsbBlock
--------------
I am going to call my custom propagator block **NeuronEsbBlock**. As I said, this will be a bi-directional block, so it can be used either as a source block or a target block. Messages that are sent to the block will be published to a Neuron topic. Messages that are received by the block will be output to any connected blocks, or will be queued to be read by the block's owner.

To handle the first case of sending a message, I simply need to take every message that is sent to my custom block and publish it to the ESB. Looking at the standard dataflow blocks, this looks like a perfect fit for the **ActionBlock<T>** class. The **ActionBlock<T>** class executes an **Action<T>** delegate for every message that is sent to it, and that's exactly what I need to do. So if I have a Neuron ESB **Party** object, I can write the publishing action as:

{% highlight c# %}
var party = new Party(...);
var actionBlock = new ActionBlock<ESBMessage>(
	message => party.SendMessage(message));
{% endhighlight %}

For messages that are received, I simply want to output them from my block. However, there are three design considerations that I need to think about:

1. Messages should be forwarded to linked blocks.
2. If no blocks are linked to the Neuron ESB block, then the message should be queued until it can be read by the owner of the block.
3. Messages should be read FIFO. No more than one linked party should receive the same message.

To implement the subscriber role of my dataflow block, I will use the standard **BufferBlock<T>** dataflow block. A **BufferBlock<T>** object implements a FIFO queue and also ensures that only one linked party will receive each message. Using the **BufferBlock<T>** class, I can also achieve goals #1 and #2 without any additional code.

Now that I have an **ActionBlock<T>** block as an internal message target block and a **BufferBlock<T>** as the internal message source block, all that I have to do is write a wrapper class that composes these two blocks into a new block, and maps the source and target methods to the appropriate block. The only code that I have to write is the code to propagate completion from the target block to the source block, as well as the code to manage the Neuron ESB **Party** object that establishes the connection between my dataflow block and the Neuron ESB server.

Below is the code for the custom dataflow block:

{% gist 6031590 NeuronEsbBlock.cs %}

Using the NeuronEsbBlock class
------------------------------
Now that the NeuronEsbBlock is implemented, using it is quite easy in a program. In the program below, I am creating one block for a publisher role and another block for a subscriber role. The publisher and subscriber are associated with the same topic. The program will read a line of text from standard input and will turn the line of text into an **ESBMessage** object and publish it to the enterprise service bus. The subscriber block will receive the message that is published to the topic and will then output the message that was received to standard output:

{% gist 6031590 Program.cs %}

Conclusion
----------
In this post, my goal was to show you how to create a custom dataflow block, and more specifically, how to link Neuron ESB into your dataflow pipelines. Using the source code presented in this article, you can build powerful dataflow pipelines that publish messages to the enterprise service bus, or that process messages that are received from the enterprise service bus. Using Neuron ESB and the TPL Dataflow Library for .NET 4.5, you can build easily maintainable and powerful integrations for your business systems and applications.
