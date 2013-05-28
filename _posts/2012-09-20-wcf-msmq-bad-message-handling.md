---
layout: post
title: Poison Message and Dead Letter Handling for WCF and MSMQ
description: Since I started working on Neudesic's Neuron product, I have found myself doing a lot more with WCF and gaining a better understanding of that technology plus related technologies such as MSMQ. In this post, I will discuss how to handle problem situations where WCF messages sent over MSMQ have errors or expire and are sent to the dead letter queue.
disqus_identifier: 2012-09-20-wcf-msmq-bad-message-handling
author: Michael F. Collins, III
author_first_name: Michael
author_last_name: Collins
author_gender: male
twitter_creator: mfcollins3
modified_time: 2013-04-16
categories:
- dotnet_development
- Windows_Communication_Foundation
category_names:
- .NET Development
- Windows Communication Foundation
tags:
- wcf
- msmq
---
Yes, it has been a while since I have blogged. It's been a mix of writer's block, lack of time, working on a product, and being a father and husband. None of those are easy obstacles to overcome. But just because I have not been writing does not mean that I have not been doing anything. Quite the contrary, I have been working on a lot of things and learning many new things to share with anyone out there that cares to learn. In this post, I am going to look at the integration between Windows Communication Foundation and MSMQ, and specificially how to handle problem situations such as poison messages in the queue or when messages expire in the queue and are moved to the dead letter queue.

Prior to joining Neudesic's product team and taking over Neuron development, my experience with WCF was pretty basic. I created basic web services for my applications, but I did not have a need to delve into many of the internals. Also, since most of my applications uses HTTP, I did not have to deal with alternative transports such as TCP or MSMQ. But since taking over Neuron development, I have had to go through a "trial-by-fire" so to speak in order to learn pretty much everything about WCF that is possibly out there.

About WCF and MSMQ
------------------
<div class="alert alert-info alert-block">
  <strong>Note:</strong>
  This post is going to focus on WCF integration with MSMQ 4.0, which was released starting with Windows Vista. Some of this will not work with MSMQ 3.0 that is present on Windows XP or Server 2003 and below.
</div>

In case you are not familiar with MSMQ or why you would want to use it with WCF, here's the short summary. MSMQ is Microsoft's built-in messaging technology for Microsoft Windows. MSMQ comes with most versions of Windows, both desktop and server SKUS. Most messaging systems come in two options for developers: point-to-point queues or publish-subscribe topics. A point-to-point message queue is your typical FIFO queue. Senders enqueue messages onto the message queue, and one or more receivers will dequeue the message on the other end. A message is guaranteed to be delivered to at most one receiver. A publish-subscribe topic also allows multiple receivers on the other end of the queue, but follows more of a broadcast pattern. Every message sent to the topic is delivered to message queues for each of the receivers. MSMQ only offers the point-to-point option for now, but that may change in the future.

The advantage to using MSMQ with WCF over alternative channels is reliability and guaranteed delivery. MSMQ queues can be made durable, so messages that are sent to the queue are written to disk. If the system comes crashing down, the messages are not lost. If the receivers are not running, the senders can still post messages to the queue so that they will be available when the receivers come back online. MSMQ also supports transactions, so senders or receivers can publish or receive messages in the context of a transaction. If the transaction fails, sent messages are removed from the queue, or received messages are placed back on the queue to be processed by another receiver. Messages are also guaranteed to be  received in the order in which they are sent to the message queue. These kinds of features just are not available with TCP, HTTP, or named pipes.

When dealing with messaging, there are two problem scenarios that you have to consider:

1. A message is sent to a receiver that is malformed or causes some kind of exception and cannot be processed by a receiver.
2. A message has a time-to-live that expires before the message is processed.

The first problem is what we call a **poison message**. Poison messages are problematic given the FIFO nature of a message queue. If a message causes an exception or is unable to be processed by a receiver, and was delivered in the context of a transaction, then the message will be returned to the queue by MSMQ to be delivered to another receiver. The problem here is that while the message is in the queue and causing problems, no other messages can get processed, so in essence the poison message clogs up the queue. Now, not every message that is returned to the queue is a poisoned message. A message might be received and then the entire computer crashes, but the message is correct and eventually can be processed by another receiver. This scenario happens quite often and is why MSMQ offers the retry logic. But if a message is malformed, or if there is a validation error of sorts, then it becomes problematic.

The second problem is what we call **dead letters**. Dead letters are messages that are sent to the queue that have a maximum lifetime associated with them. Let's use the example of a B2B exchange containing sellers and buyers. As a seller, I may have an excess of inventory that I want to get rid of, so I decide to mark down the product for a short period of time. I send a message to the exchange telling all of the buyers that this sale is valid until 5:00pm. It is currently 9:00am. When I send out my message to the exchange, I give the message a lifetime of 8 hours. Given that this is a message-based exchange, there is no guarantee that the buyers will be listening. A buyer might be closed or have gone offline. It does not do anyone any good for them to get the message after 5:00pm, because my inventory will hopefully be gone. From the buyer's side, if the message sits in their queue for more than 8 hours, the message becomes invalid. Rather than continue the message's journey to the buyer, the exchange decides to move the message out of the buyer's message queue. The message should not be completely lost though. If the message were lost, the seller would never know that the message did not arrive at its intended recipient. Instead, the exchange will move the message out of the buyer's queue and move the message into another special queue called a **dead letter queue**. The seller can look in his dead letter queue to determine which messages could not be delivered to buyers.

The question before us is how does WCF support poison messages or dead letters? We will not look at how to extend the WCF/MSMQ integration to support processing poison messages and messages in a dead-letter queue.

A Basic WCF Service Using MSMQ
------------------------------
The sample that we will use to build our MSMQ-based WCF service is a "Hello" application. The client will send names to the service, and the service will "say hello" to every name that it receives. Here's our basic service contract:

{% highlight c# %}
[ServiceContract]
public interface ISayHelloService
{
  [OperationContract(IsOneWay = true)]
  void SayHello(string to);
}
{% endhighlight %}

If you have not used MSMQ before, or MSMQ with WCF, you have to remember that unlike TCP/IP, HTTP, or named-pipes, MSMQ is a half-duplex protocol. Messages can only move in one direction across the channel. If you need to implement a request/reply pattern with MSMQ, then you will need two queues and a client and service on each end. In this scenario, I'm not going to return a response to the client, so I will use only one queue.

My service implementation receives the name of an individual and writes a hello message to *stdout*:

{% highlight c# %}
internal class SayHelloService : ISayHelloService
{
  [OperationContract(TransactionRequired = true, TransactionAutoComplete = true)]
  public void SayHello(string to)
  {
    Console.Out.WriteLine("Hello {0}", to);
  }
}
{% endhighlight %}

Notice in the service implementation that I defined the **OperationContractAttribute** attribute and set the **TransactionScope** property to required and set **TransactionAutoComplete** to true. Because we are using MSMQ, I want the messages to be retrieved from the queue in the context of a transaction. If a problem occurs while processing the message, then the message goes back onto the queue. The underlying MSMQ queue should also be created as a transactional queue.

The host program will create the MSMQ binding and will host the SayHelloService class:

{% highlight c# %}
internal class Program
{
  internal static void Main()
  {
    ServiceHost serviceHost = null;
    try
    {
      var baseAddress = new Uri("net.msmq://localhost/private");
      serviceHost = new ServiceHost(
        typeof(SayHelloService),
        baseAddress);
      var netMsmqBinding = new NetMsmqBinding(NetMsmqSecurityMode.None);
      serviceHost.AddServiceEndpoint(
        typeof(ISayHelloService),
        netMsmqBinding,
        "/hello");
      serviceHost.Open();

      Console.Error.WriteLine("The service is listening for requests. Press Enter to exit.");
      Console.In.ReadLine();
    }
    catch (Exception ex)
    {
      Console.Error.WriteLine("\nERROR: {0}\n\nPress Enter to exit.");
      Console.In.ReadLine();
    }
    finally
    {
      if (null != serviceHost &&
      	  CommunicationState.Opened == serviceHost.State)
      {
        serviceHost.Close();
      }
    }
  }
}
{% endhighlight %}

Finally, here's the client program:

{% highlight c# %}
internal class Program
{
  internal static void Main()
  {
    ChannelFactory<ISayHelloService> channelFactory = null;
    ISayHelloService service = null;
    try
    {
      var netMsmqBinding = new NetMsmqBinding(NetMsmqSecurityMode.None);
      var remoteAddress = 
        new EndpointAddress("net.msmq://localhost/private/hello");
      channelFactory = new ChannelFactory<ISayHelloService>(
        netMsmqBinding,
        remoteAddress);
      channelFactory.Open();

      service = channelFactory.CreateChannel();
      var clientChannel = service as IClientChannel;
      if (null != clientChannel)
      {
      	clientChannel.Open();
      }

      Console.Error.WriteLine("Enter a name to send. Enter a blank line to exit.");
      while (true)
      {
      	var name = Console.In.ReadLine();
      	if (string.IsNullOrWhiteSpace(name))
      	{
      	  break;
      	}

        service.SayHello(name);
      }
    }
    finally
    {
      var clientChannel = service as IClientChannel;
      if (null != clientChannel &&
      	  CommunicationState.Opened == clientChannel.State)
      {
        clientChannel.Close();
        clientChannel.Dispose();
      }

      if (null != channelFactory &&
          CommunicationState.Opened == channelFactory.State)
      {
      	channelFactory.Close();
      }
    }
  }
}
{% endhighlight %}

When I compiled and ran this code, I entered in my name plus several others. In the MSMQ console, I watched the message queue get populated with messages, and then in the other console window, I say the correct hello messages. Now that the basic WCF service and client are implemented, let's turn our attention first to handling dead letters.

Dead Letter Processing
----------------------
In WCF and MSMQ, dead letter processing is controlled by the client-side of the WCF conversation. The client, or sender, specifies the time-to-live for the message and also specifies where the dead letter message is sent to. When creating the WCF binding to an MSMQ queue, the client program can specify also what queue to write the dead letter messages to. MSMQ also provides a global system dead letter queue, but it's better practice to use an application-specific dead letter queue, as multiple applications can send dead letter messages to the global queue.

To start, I am going to modify the client program from above to set a two-minute time-to-live and also specify the queue to use for dead letters:

{% highlight c# %}
internal class Program
{
  internal static void Main()
  {
    ChannelFactory<ISayHelloService> channelFactory = null;
    ISayHelloService service = null;
    try
    {
      // BEGIN NEW CODE
      var netMsmqBinding = new NetMsmqBinding(NetMsmqSecurityMode.None)
      {
        DeadLetterQueue = DeadLetterQueue.Custom,
        CustomDeadLetterQueue = new Uri("net.msmq://localhost/private/hellodeadletter"),
        TimeToLive = TimeSpan.FromMinutes(2.0)
      };
      // END NEW CODE

      .
      .
      .
{% endhighlight %}

These new properties for the **NetMsmqBinding** class specify that MSMQ should move expired messages to a custom queue located at *.\Private$\hellodeadletter* if the messages are not received within two minutes from when they are sent. To test this, run the client program but not the service program. Wait for two minutes and use the MSMQ console to verify that the messages from the client get moved to the custom dead letter queue.

Now that the messages are in the queue, how can we report errors on the messages? This is also done at the client side by creating a custom WCF service that implements the same service contract as the original service and will receive the messages in the dead letter queue in order to output an error to the console. Here's the dead letter service:

{% highlight c# %}
[ServiceBehavior(AddressFilterMode = AddressFilterMode.Any)]
internal class SayHelloDeadLetterService : ISayHelloService
{
  public void SayHello(string to)
  {
    Console.Error.WriteLine("DEAD LETTER: {0}", to);
  }
}
{% endhighlight %}

This is a pretty simple service. The dead letter service implements the same service contract as the main WCF service. WCF will read the message off of the dead letter queue and will call the matching operation passing all of the data that was included in the message. The dead letter service is annotated with a **ServiceBehaviorAttribute** with the **AddressFilterMode** property set to **Any**. This is needed because WCF checks the **To** header during dispatching and will fail if the **To** header does not match the address of the receiving service. By setting the **AddressFilterMode** property, we can bypass that check so that the dead letter service can receive messages sent to any address.

Because the dead letter queue is specific to the sender, we will add the dead letter host to the client program. Here is the updated client program:

{% highlight c# %}
internal class Program
{
  internal static void Main()
  {
    ChannelFactory<ISayHelloService> channelFactory = null;
    ISayHelloService service = null;
    ServiceHost deadLetterServiceHost = null;
    try
    {
      var netMsmqBinding = new NetMsmqBinding(NetMsmqSecurityMode.None)
      {
        DeadLetterQueue = DeadLetterQueue.Custom,
        CustomDeadLetterQueue = 
          new Uri("net.msmq://localhost/private/hellodeadletter"),
        TimeToLive = TimeSpan.FromMinutes(2.0)
      };
      var remoteAddress = 
        new EndpointAddress("net.msmq://localhost/private/hello");
      channelFactory = new ChannelFactory<ISayHelloService>(
        netMsmqBinding,
        remoteAddress);
      channelFactory.Open();

      var baseAddress = new Uri("net.msmq://localhost/private");
      deadLetterServiceHost = new ServiceHost(
        typeof(ISayHelloService),
        baseAddress);
      netMsmqBinding = new NetMsmqBinding(NetMsmqSecurityMode.None);
      deadLetterServiceHost.AddServiceEndpoint(
        typeof(SayHelloDeadLetterService),
        netMsmqBinding,
        "/hellodeadletter");
      deadLetterServiceHost.Open();

      service = channelFactory.CreateChannel();
      var clientChannel = service as IClientChannel;
      if (null != clientChannel)
      {
      	clientChannel.Open();
      }

      Console.Error.WriteLine("Enter a name to send. Enter a blank line to exit.");
      while (true)
      {
      	var name = Console.In.ReadLine();
      	if (string.IsNullOrWhiteSpace(name))
      	{
      	  break;
      	}

        service.SayHello(name);
      }
    }
    finally
    {
      var clientChannel = service as IClientChannel;
      if (null != clientChannel &&
      	  CommunicationState.Opened == clientChannel.State)
      {
        clientChannel.Close();
        clientChannel.Dispose();
      }

      if (null != channelFactory &&
          CommunicationState.Opened == channelFactory.State)
      {
      	channelFactory.Close();
      }

      if (null != deadLetterServiceHost &&
          CommunicationState.Opened == channelFactory.State)
      {
        deadLetterService.Close();
      }
    }
  }
}
{% endhighlight %}

Once the changes are made to the client program, when it runs, it will host the **SayHelloDeadLetterService** to the dead letter queue. When messages expire, MSMQ will move the messages from the main queue to the dead letter queue, and then our client program will receive the message back from the dead letter queue in order to output an error.

Poison Message Processing
-------------------------
In MSMQ 4.0, poison message processing is very similar to dead letter processing. As with dead letter processing, we will create a WCF service that will receive messages that are written to a poison message queue. When a poison message is received by the receiver, the receiver will typically fail and throw an exception or otherwise cause the transaction that the message is being processed under to be rolled back. When the transaction is rolled back, the message is placed back on the MSMQ queue for another receiver to try. This retry logic has constraints that can be customized on the WCF binding for MSMQ. After a couple of retries that fail, MSMQ may move the message off of the main queue and place the message in a retry queue to be held for a certain period of time. This is similar to a cooling off period where the message is not lost, but if the system is being monitored, the administrators can look at the system to see why the message is not being processed successfully. Maybe there is a database that is unreachable? Maybe the Internet is down?

Once the retry delay expires, the message will be moved back into the main queue to be processed. This workflow repeats itself as many times as specified in the WCF MSMQ binding. After all of the retry attempts have been exhausted, MSMQ will next move the message from the main queue and store it in a special queue for poison messages.

<div class="alert alert-info alert-block">
  <strong>Note:</strong>
  This workflow is different than with MSMQ 3.0. If you are using MSMQ 3.0, the poison message is not moved. You have to write a special WCF error handler to move the message out of the main queue and either handle the poison message or move the poison message to a custom queue that is acting as a poison message queue.
</div>

Unlike dead letter messages, poison messages are handled at the service side, so I will extend my WCF service program to handle the poison messages. First, I need a new WCF service that will receive the messages that are sent to the poison message queue:

{% highlight c# %}
[ServiceBehavior(AddressFilterMode = AddressFilterMode.Any)]
internal class SayHelloPoisonMessageService : ISayHelloService
{
  [OperationBehavior(TransactionScopeRequired = true, TransactionAutoComplete = true)]
  public void SayHello(string to)
  {
    Console.Error.WriteLine("POISON MESSAGE: {0}", to);
  }
}
{% endhighlight %}

Note that I annotated the **SayHelloPoisonMessageService** class with the **AddressFilterMode** service behavior property set to **Any**. The poison message service has the same problem with the **To** header as the dead letter service, so the poison message service needs to be able to receive any message posted to the poison message queue.

I have to update my WCF service program to also host the poison message service:

{% highlight c# %}
internal class Program
{
  internal static void Main()
  {
    ServiceHost serviceHost = null;
    ServiceHost poisonMessageServiceHost = null;
    try
    {
      var baseAddress = new Uri("net.msmq://localhost/private");
      serviceHost = new ServiceHost(
        typeof(SayHelloService),
        baseAddress);

      // CHANGED CODE
      var netMsmqBinding = new NetMsmqBinding(NetMsmqSecurityMode.None)
      {
        ReceiveRetryCount = 1,
        ReceiveErrorHandling = ReceiveErrorHandling.Move,
        MaxRetryCycles = 1,
        RetryCycleDelay = TimeSpan.FromSeconds(10.0)
      };
      // END CHANGED CODE

      serviceHost.AddServiceEndpoint(
        typeof(ISayHelloService),
        netMsmqBinding,
        "/hello");
      serviceHost.Open();

      // NEW CODE
      poisonMessageServiceHost = new ServiceHost(
        typeof(SayHelloPoisonMessageService),
        baseAddress);
      var netMsmqBinding = new NetMsmqBinding(NetMsmqSecurityMode.None);
      poisonMessageServiceHost.AddServiceEndpoint(
        typeof(ISayHelloService),
        netMsmqBinding,
        "/hello;poison");
      poisonMessageServiceHost.Open();
      // END NEW CODE

      Console.Error.WriteLine("The service is listening for requests. Press Enter to exit.");
      Console.In.ReadLine();
    }
    catch (Exception ex)
    {
      Console.Error.WriteLine("\nERROR: {0}\n\nPress Enter to exit.");
      Console.In.ReadLine();
    }
    finally
    {
      if (null != serviceHost &&
      	  CommunicationState.Opened == serviceHost.State)
      {
        serviceHost.Close();
      }

      // NEW CODE
      if (null != poisonMessageServiceHost &&
          CommunicationState.Opened == serviceHost.State)
      {
        poisonMessageServiceHost.Close();
      }
      // END NEW CODE
    }
  }
}
{% endhighlight %}

In the code above, you will also notice the additional properties that I defined for the **NetMsmqBinding** for the main WCF service. I set values for the **ReceiveRetryCount**, **ReceiveErrorHandling**, **MaxRetryCycles**, and **RetryCycleDelay** properties for testing. The **ReceiveErrorHandling** property is very important because it defines the behavior for poison messages. By setting it to **Move**, MSMQ will move the poison message out of the main queue automatically and put it in the poison message queue. If I did not use that value, then I would have to clear the message before other messages could be processed.

The last thing that I have to do is go back and modify my primary WCF service to throw an exception and cause the transaction to roll back. In order to do that, I will throw an exception if the client sends the name "John" to the service, because, after all, who wants a "John" around (except for my Uncle John; he's always welcome!)?

{% highlight c# %}
internal class SayHelloService : ISayHelloService
{
  [OperationContract(TransactionRequired = true, TransactionAutoComplete = true)]
  public void SayHello(string to)
  {
    if (to.Equals("john", StringComparison.OrdinalIgnoreCase))
    {
      Console.Error.WriteLine("ERROR: John is not welcome.");
      throw new Exception("John is not welcome.");
    }

    Console.Out.WriteLine("Hello {0}", to);
  }
}
{% endhighlight %}

Conclusion
----------
In this post, I explained what dead letters and poison messages are and how they affect a WCF/MSMQ solution. I also presented a solution for creating WCF services to receive and handle the messages that are written to the dead letter queue or poison message queues. Hopefully this will help you with your own programs.

The source code presented in this post has been posted as a Gist on GitHub. You can <a href="https://gist.github.com/3757366">download it from here</a> or clone the repository using Git from here: git://gist.github.com/3757366.git.