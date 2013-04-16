---
layout: post
title: Building Neuron ESB 3.0 Subscribers the Reactive Way
description: Neuron ESB 3.0 is out, and if you're a Neuron user or using .NET-based ESBs, then you should be interested, because there's a lot of stuff there. Now rocking on the .NET 4 platform, there are some pretty cool things that you can do with Neuron that you could not do with the previous releases. In this post, I will show you a new way to create custom subscribers using Neuron's Party class and using Reactive Extensions to asynchronously receive and filter incoming messages sent to a subscriber.
disqus_identifier: 2013-03-06-neuron-esb-subscribers-the-reactive-way
categories:
- Neuron_ESB
tags:
- neuron
- neudesic
- esb
author: Michael F. Collins, III
author_first_name: Michael
author_last_name: Collins
author_gender: male
twitter_creator: mfcollins3
modified_time: 2013-04-16
---
[Neuron ESB 3.0](http://products.neudesic.com/latest) recently hit the proverbial store shelves last week. This was a big release for me as it was my first major release since I joined the Neuron team. Moving Neuron to .NET 4 and a major release has been a big accomplishment. While I hoped to have Neuron out late last year, the extra time that we took releasing it now gave us a chance to fix a lot of quality and stability issues in the code, and I honestly believe that Neuron is in a great position in terms of quality and potential for future investment.

Moving to .NET 4 was a big move for Neuron. What this means is that we're investing for Neuron to be a viable solution moving forward. We want to give you Neuron users the latest and greatest tools and techniques, and as product developers, we want to build you the best product possible. Over the next year we'll be adding more functionality based on .NET 4 technologies and doing more things like parallel processing and taking better advantage of multiple-core environments in order to maximize the performance of the product.

Moving to .NET 4 also opens us up to looking at some alternative ways of processing messages, which is the subject of this post. In this post, I will build the same program twice. The first version of the program will use the **Party** class to connect to the ESB service as a subscriber role and will use the **OnReceive** event to receive and process messages. The second version of the program will use the [Reactive Extensions](http://bit.ly/K9r0Cu) and LINQ to create subscriptions to messages filtered by the topic that the message was published to.

##Event-based Subscription

When using the Neuron ESB client API, we use the **Party** class or one of its subclasses to implement publishers and subscribers. The **Party** class handles the task of connecting to an ESB service, assuming a role of a publisher or a subscriber, and sending or receiving messages from the ESB service. Messages sent from the ESB service for the party are received by the client program through the **OnReceive** event.

In this sample program, I have created two topics in my sample ESB configuration:

* **Offers**: has subtopics **Bread**, **Milk**, **Pepper**, and **Salt**.
* **Orders**: has subtopics **Arizona**, **California**, **Hawaii**, **Nevada**, and **Oregon**.

I am not using any ESB filtering, so all messages published to these topics will be received by my subscriber application. Inside my event handler for **Party.OnReceive**, I will use the topic to determine how to process the received message.

The main program for my subscriber will connect to my Neuron ESB service and assume the role of *EventSubscriber*. Then the program will attach to the **OnReceive** event to receive messages.

{% highlight c# %}
private static void Main()
{
	using (var program = new Program())
	{
		program.Run();
	}
}

private void Run()
{
	var clientConfig = new SubscriberConfiguration(
		"EventSubscriber",
		"Enterprise",
		"http://localhost:50000",
		WindowsIdentity.GetCurrent().Name);
	this.party = new Party(clientConfig);
	this.party.OnReceive += ProcessMessage;
	try
	{
		this.party.Connect();
		Console.Error.WriteLine(
			"Listening for messages. Press Enter to exit.");
		Console.In.ReadLine();
	}
	finally 
	{
		this.party.OnReceive -= ProcessMessage;
	}
}
{% endhighlight %}

Inside of my **ProcessMessage** method, I will look at the topic that the message was published to and will determine what action to take based on the topic:

{% highlight c# %}
private static void ProcessMessage(object o, MessageEventArgs messageEventArgs)
{
    var message = messageEventArgs.Message;
    switch (message.Header.Topic)
    {
        case "Offers":
            Trace.TraceInformation(
            	"Received offer: {0}", message.ToString());
            break;

        case "Offers.Salt":
            Trace.TraceInformation(
            	"Received offer for salt: {0}", message.ToString());
            break;

        case "Offers.Pepper":
            Trace.TraceInformation(
            	"Received offer for pepper: {0}", message.ToString());
            break;

        case "Offers.Bread":
            Trace.TraceInformation(
            	"Received offer for bread: {0}", message.ToString());
            break;

        case "Orders":
            Trace.TraceInformation(
            	"Received order: {0}", message.ToString());
            break;

        case "Orders.California":
            Trace.TraceInformation(
            	"Received order from California: {0}", 
            	message.ToString());
            break;

        case "Orders.Arizona":
            Trace.TraceInformation(
            	"Received order from Arizona: {0}", 
            	message.ToString());
            break;

        case "Orders.Hawaii":
            Trace.TraceInformation(
            	"Received order from Hawaii: {0}", 
            	message.ToString());
            break;

        case "Orders.Oregon":
            Trace.TraceInformation(
            	"Received order from Oregon: {0}", 
            	message.ToString());
            break;

        case "Orders.Nevada":
            Trace.TraceInformation(
            	"Received order from Nevada: {0}", 
            	message.ToString());
            break;

        default:
            Trace.TraceError(
            	"Don't know how to process message for topic \"{0}\".", 
            	message.Header.Topic);
            break;
    }
}
{% endhighlight %}

What's wrong with this approach? Nothing in general, but there's a lot of logic in there to filter out the message. The biggest maintenance problem with this code is that it violates the [Single Responsibility Principle](http://en.wikipedia.org/wiki/Single_responsibility_principle) in massive fashion. My **switch** statement has 11 responsibilities, and if I add more topics or remove topics that are no-longer necessary, I have to go back in and change this code. If I were a smart developer, I would use the **case** statements to dispatch out to other methods, but that doesn't make maintenance of this massive **switch** statement any easier.

##Reactive-based Subscription

With .NET 4, Microsoft introduced a new framework that is distributed externally from the .NET 4 core framework named Reactive Extensions. The Reactive Extensions extend a new set of interfaces that were added to the .NET 4 core in order to support push-based asynchronous processing of potentially infinite information sources. These new interfaces are named [System.IObservable&lt;T&gt;](http://msdn.microsoft.com/en-us/library/dd990377.aspx) and [System.IObserver&lt;T&gt;](http://msdn.microsoft.com/en-us/library/dd783449.aspx). The **IObservable&lt;T&gt;** interface is fairly similar in concept to the **IEnumerable&lt;T&gt;** interface, except that **IEnumerable&lt;T&gt;** requires programs to *pull* data from the collection, and **IObservable&lt;T&gt;** pushes information to the program. **IEnumerable&lt;T&gt;** is also typically used on a data source whose size is known and cannot change while the program is enumerating through its elements, where **IObservable&lt;T&gt;** does not have to be predefined and can represent an infinite data source. For example, we can use **IObservable&gt;T&lt;** with Neuron messages because we don't know how many messages our subscriber will receive. Neuron ESB is an infinite data source.

The other really cool thing about using Reactive Extensions is that we have full LINQ support for message processing. We can get rid of the **switch** logic that I showed in the earlier event-based example and use LINQ to filter the messages for us. Also, unlike the event-based example, we can have more than one *subscsriber* or *receiver* that receives messages. We are not limited to one method for one event handler. Basically, we can implement a subscriber while still observing the **Single Responsibility Principle** as you'll see in a moment.

The main program code for this sample is mostly identical to the earlier event-based sample:

{% highlight c# %}
private static void Main()
{
	using (var program = new Program())
	{
		program.Run();
	}
}

private void Run()
{
	var clientConfig = new SubscriberConfiguration(
		"ReactiveSubscriber",
		"Enterprise",
		"http://localhost:50000",
		WindowsIdentity.GetCurrent().Name);
	this.party = new Party(clientConfig);

	var receiveSource = Observable.FromEventPattern<MessageEventArgs>(
		this.party,
		"OnReceive")
		.Select(e => Tuple.Create(
			e.EventArgs.Message.Header.Topic,
			e.EventArgs.Message));
	this.CreateOfferSubscriptions(receiveSource);
	this.CreateOrderSubscriptions(receiveSource);

	this.party.Connect();
	Console.Error.ReadLine(
		"Listening for messages. Press Enter to exit.");
	Console.In.ReadLine();
}
{% endhighlight %}

The important piece of code to look at from this code sample is here:

{% highlight c# %}
var receiveSource = Observable.FromEventPattern<MessageEventArgs>(
	this.party,
	"OnReceive");
	.Select(e => Tuple.Create(
		e.EventArgs.Message.Header.Topic,
		e.EventArgs.Message));
{% endhighlight %}

What this code is doing is using Reactive Extensions to turn the **Party.OnReceive** event into an observable event source. The output of the **Observable.FromEventPattern&lt;T&gt;** method is an **IObservable&lt;T&gt;** object that we can subscribe to. Internally, Reactive Extensions is attaching an event handler to the **OnReceive** event and will dispatch the message to any subscribers that we attach to the event source.

The next thing that is happening in this statement is that I am pre-processing the received messages. The data that is pushed to my program by the Reactive Extensions event source is of type **EventPattern&lt;MessageEventArgs&gt;**, but I want to convert the event information into a format that is easier for me to process. Since I am planning on filtering by topic, I am using the .NET [Tuple](http://msdn.microsoft.com/en-us/library/system.tuple.aspx) class to create a tuple with two terms: the topic and the message. I am using LINQ to create the tuple that will then be output by my observable sequence for my subscribers.

Let's first look at creating subscribers for the **Offer** messages:

{% highlight c# %}
private void CreateOfferSubscriptions(
	IObservable<Tuple<string, ESBMessage>> receiveSource)
{
	this.offerSubscription = receiveSource
		.Where(t => t.Item1 == "Offers")
		.Subscribe(t => ProcessGenericOffer(t.Item2.Text));
	this.breadOfferSubscription = receiveSource
		.Where(t => t.Item1 == "Offers.Bread")
		.Subscribe(t => ProcessBreadOffer(t.Item2.Text));
	this.milkOfferSubscription = receiveSource
		.Where(t => t.Item2 == "Offers.Milk")
		.Subscribe(t => ProcessMilkOffer(t.Item2.Text));
	this.pepperOfferSubscription = receiveSource
		.Where(t => t.Item2 == "Offers.Pepper")
		.Subscribe(t => ProcessPepperOffer(t.Item2.Text));
	this.saltofferSubscription = receiveSource
		.Where(t => t.Item2 == "Offers.Salt")
		.Subscribe(t => ProcessSaltOffer(t.Item2.Text));
}
{% endhighlight %}

In the **CreateOfferSubscriptions** method, I can use LINQ against the **receiveSource** observable sequence that I created earlier to further filter the messages based on the topic. After completing my filtering specification, I can then subscribe the message by specifying a lambda expression that will be executed when a message satisfies the filter.

With Reactive Extensions, it is very easy to create multiple levels of filters. Here's an example of how I created the subscribers for the **Orders** topics:

{% highlight c# %}
private void CreateOrderSubscriptions(
	IObservable<Tuple<strng, ESBMessage>> receiveSource)
{
	var orderSource = receiveSource
		.Where(t => t.Item1 == "Orders" || 
			t.Item1.StartsWith("Orders."));
	this.californiaOrderSubscription = orderSource
		.Where(t => t.Item1.EndsWith(".California"))
		.Subscribe(t => ProcessCaliforniaOrder(t.Item2.Text));
	this.orderSubscription = orderSource
		.Where(t => !t.Item1.EndsWith(".California"))
		.Subscribe(t => ProcessOrder(t.Item2.Text));
}
{% endhighlight %}

In this example, I am pretending that my program will process orders from anyplace, but there is special handling that needs to happen for orders from California. Using LINQ, I can filter the messages from California to execute the special logic, while orders from everyplace else go to the generic event handler.

##Why is Reactive Better?

Using Reactive Extensions and observable sequences are a better way of building custom subscriber applications using Neuron ESB's client API. Reactive Extensions treat Neuron ESB as an asynchronous data source which it really is. Using Reactive Extensions, it's easier to use LINQ to perform complex filtering and manipulation of messages before they hit your message processing logic. It's also easier to build subscribers that are maintainable and follow the Single Responsibility Principle.

The other reason that I have not covered is schedulers. Reactive Extensions does a better job at letting you process received messages asychronously. With the event-based approach, the **OnReceive** event is fired on the thread in which the message is received from the Neuron ESB service. This blocks the receiving thread so that no other messages can be processed until the active message completes processing. This can also be a problem if your subscriber is a desktop UI program because you are responsible for marshaling the message from the event thread to the UI thread.

Reactive Extensions has the concept of **[schedulers](http://bit.ly/10gnFiq)**. A scheduler indicates where the received message will be processed. Using Reactive Extensions, you can easily redirect all of your messages to the UI thread or you can asynchronously dispatch the messages to be processed on background worker threads in the thread pool. For long-running message processes, you can instruct Reactive Extensions to create a new thread dedicated to processing that single message. Reactive Extension's schedulers are also extensible, so you can create custom schedulers to store messages in a persistent data queue, for example.

##Summary

In this post, I had three goals. First, I wanted to introduce you to the Reactive Extensions for .NET. Second, I wanted to show you how you could use Reactive Extensions to turn your Neuron ESB into an asynchronous data source. Third, I wanted to make an argument why you should be using Reactive Extensions to implement your message processing in your custom applications that use Neuron for publishing or subscribing. Reactive Extensions is a wonderful framework and it adds a lot of value to implementing custom solutions using Neuron ESB's client API.

##Get the Source Code

<div class="alert alert-info alert-block">
	<strong>Note:</strong>
	The source code has not yet been published. This post will be updated with the link to the GitHub repository after it has been posted.
</div>