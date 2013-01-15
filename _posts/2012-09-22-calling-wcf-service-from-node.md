---
layout: post
title: Calling a WCF Service from Node.js
description: In this post, I will demonstrate writing a command-line program that will allow other programs to call WCF-based web services. This will demonstrate some of the important aspects of command-line programming that I touched on in the introduction post.
disqus_identifier: 2012-09-22-calling-wcf-service-from-node
---
In my [previous post](http://www.michaelfcollins3.me/blog/Desert%20Code%20Camp/2012/Command-Line%20Programming/2012/09/21/introduction-to-command-line-programming.html), I introduced command-line programming in general. In this post, I will actually create a command-line program to demonstrate some of the important aspects of command-line programming, and then I will create another program using Node.js that will consume my command-line program. The command-line program that I am going to create is a generic WCF client that can be used to invoke remote WCF services. I will then use this command-line program to send a request to a WCF service from a [Node.js](http://nodejs.org) application and process the reply.

<div class="alert alert-info alert-block">
	<strong>Note:</strong> For brevity, I removed some of the details such as XML namespaces that I am using in the XML and WCF contracts. I will post the full code for the sample, along with a correct input file so that you can run this on your own computer.
</div>

Scenario
--------
Just so that you do not think that this is a contrived sample, let's look at how this could be used in a real production environment before we start looking at the code. For all intents and purposes, .NET has been a pretty dominant language over the past 12 years. There has been a lot of innovation happening in the Microsoft Windows space around .NET. Also, many programming systems have been able to do web services, but WCF has been pretty successful in gaining a foothold in the SOAP and WS-* world. Many companies have invested quite a lot of money, time, and other resources in building SOAP web services for the business systems, and just because the winds are changing a little, that does not mean that companies are going to be anxious to replace their entire stack anytime soon.

As a new kid on the block, Node.js is really very cool and is gaining more and more exposure every day. It's risen so quickly that even Microsoft has thrown their support being using Node.js with IIS instead of ASP.NET and creating Node.js applications that run in Microsoft's Azure cloud computing environment. Node.js keeps growing and it is not going to go anywhere other than up and out in its quest for market share.

Put these two technologies together in the same space and there's quite a bit of a chasm to deal with. It's pretty simple to call basic web services with Node.js, and it's very easy to call the newer-style REST web APIs, but as I already wrote, many enterprises have invested a lot in their SOAP stack and they like features such as distributed transactions and the advanced security capabilities that WCF provides. They may eventually change to use REST-based services, but that's not a change that's going to happen overnight, if at all.

However, many companies are also aware of the promise of newer systems such as Node.js. Node.js is proving itself to be a very capable development platform, and in some cases may be easier and more cost effective than using ASP.NET MVC. Also, companies want to attract the best talent, and right now there's a lot of talent focused on Node.js, especially from younger developers. Over the next couple of years, more companies may be open to using a technology like Node.js for their new business systems, but the problem remains that it's likely that they will not be able to rewrite or re-platform their existing web services.

This sample will demonstrate how a command-line program written as a child process will help to bridge that chasm between a newer technology and an older technology. By using a .NET program as a child process to a Node.js application, you can have the best of both worlds. You can build new business and application logic with Node.js, but still have the full support of the WCF stack for web services.

The WCF Service
---------------
I will start by creating a simple WCF request/reply service using C# and .NET. The WCF service will take the name of a person and will respond with a welcome message. Here are the contracts for the service:

{% highlight c# %}
[DataContract]
public class Person
{
  [DataMember(IsRequired = true, Order = 1)]
  public string Name { get; set;}
}

[DataContract]
public class WelcomeMessage
{
  [DataMember(IsRequired = true, Order = 1)]
  public string Message { get; set; }
}

[ServiceContract]
public interface IHelloService
{
  [OperationContract]
  WelcomeMessage SayHello(Person to);
}
{% endhighlight %}

The WCF service is pretty simple. The **SayHello** operation just returns a formatted message saying hello to the person that is sent to the operation:

{% highlight c# %}
internal class HelloService : IHelloService
{
  public WelcomeMessage SayHello(Person to)
  {
    return new WelcomeMessage
      {
        Message = string.Format("Welcome {0}", to.Name);
      };
  }
}
{% endhighlight %}

For the purpose of this demonstration, I am going to host the service using the **NetTcpBinding** and hosting it at **net.tcp://localhost:9010/hello**. Here is the service host program:

{% highlight c# %}
internal class Program
{
  internal static void Main()
  {
    ServiceHost serviceHost = null;
    try
    {
      var baseAddress = new Uri("net.tcp://localhost:9010");
      serviceHost = new ServiceHost(typeof(HelloService), baseAddress);
      serviceHost.AddServiceEndpoint(
        typeof(IHelloService),
        new NetTcpBinding(),
        "/hello");
      serviceHost.Open();

      Console.Error.WriteLine("Listening. Press Enter to exit.");
      Console.In.ReadLine();
    }
    catch (Exception ex)
    {
      Console.Error.WriteLine("ERROR: {0}\n\nPress Enter to exit.", ex);
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

Generic WCF Client Command-Line Program
---------------------------------------
With the WCF service hosted, I can now write the command-line program that my Node.js application can use to send requests to the WCF service and return responses. I could write this command-line program to be specific to the hello service, but in this scenario I am going to create the command-line program to be generic and support any WCF service operation that uses the WCF request-reply pattern. In order to do this, I will make use of the generic WCF request-reply service contract and will create the SOAP message manually.

Here's the generic WCF interface for the request-reply pattern:

{% highlight c# %}
[ServiceContract]
internal interface IWcfRequestReplyPattern
{
  [OperationContract(AsyncPattern = true, Action = "*", ReplyAction = "*")]
  IAsyncResult BeginProcessRequest(
    Message request,
    AsyncCallback callback,
    object state);

  Message EndProcessRequest(IAsyncResult result);
}
{% endhighlight %}

Here I am going to use the asynchronous pattern for invoking WCF operations. This will allow my command-line program to continue to accept requests from the standard input (stdin) stream while waiting for the replies to be returned from the remote WCF service. When the replies are returned, I will receive each reply and write the reply out to standard output (stdout).

###Input/Output Protocol Design

The first thing that I need to do when designing my command-line program is design the protocol for the requests read from stdin and the replies that are written to stdout. I also have to consider that I may be processing multiple requests concurrently, so in the output I need to indicate which request a reply correlates to.

Also, being a generic WCF client, requests may be intended for any implemented operation on the WCF service. In WCF and SOAP, operations are identified by a SOAP Action header which is typically a URI of some sort. On input, the parent process needs to tell the command-line program which WCF operation to invoke by passing the value of the Action header with the request.

Given this information, the input protocol for my command-line program is that each request will be on a single line of the stdin stream. This will make it easy to process requests because I just read one line of input and then execute the request that is included on that line of input. I also need to determine how to delimit each field in the input record from the next, so I will use a tab-delimited format for the records. The format for each record will be:

    request-id \t action-uri \t request-xml

The output format will be the same:

    request-id \t reply-action-uri \t reply-xml

The request identifier specified in the input will be included in the output as a correlation identifier. In SOAP messaging, a request-reply operation returns a URI that indicates the reply type. Finally, the reply XML will be output at the end of the output line.

Here is my command-line program:

{% highlight c# %}
internal class Program
{
  private IWcfRequestReplyPattern service;

  internal static int Main()
  {
    var program = new Program();
    return program.Run();
  }

  private int Run()
  {
    ChannelFactory<IWcfRequestResponsePattern> channelFactory = null;
    IClientChannel clientChannel = null;
    try
    {
      var binding = new NetTcpBinding();
      var remoteAddress = new EndpointAddress("http://localhost:9010/hello");
      channelFactory = new ChannelFactory<IWcfRequestReplyPattern>(
        binding,
        remoteAddress);
      channelFactory.Open();

      this.service = channelFactory.CreateChannel();
      clientChannel = this.service as IClientChannel();
      if (null != clientChannel)
      {
      	clientChannel.Open();
      }

      var line = Console.In.ReadLine();
      while (null != line)
      {
        var parts = line.Split('\t');
        var requestId = parts[0];
        var action = parts[1];
        var xml = parts[2];

        var xmlElement = XElement.Parse(xml);
        var requestMessage = Message.Create(
          MessageVersion.Soap12WSAddressing10,
          action,
          xmlElement.CreateReader());
        this.service.BeginProcessRequest(
          requestMessage,
          this.OutputResponse,
          requestId);

        line = Console.In.ReadLine();
      }
    }
    catch (Exception ex)
    {
      Console.Error.WriteLine("ERROR: {0}", ex);
      return -1;
    }
    finally
    {
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

  private void OutputResponse(IAsyncResult ar)
  {
    var requestId = ar.AsyncState as string;

    Message replyMessage = null;
    try
    {
      replyMessage = this.service.EndProcessRequest(ar);
    }
    catch (Exception ex)
    {
      Console.Error.WriteLine("ERROR: An error occurred while processing a reply for request {0}: {1}", requestId, ex);
      return;
    }

    XElement xml;
    using (var xmlReader = replyMessage.GetReaderAtBodyContents())
    {
      try
      {
        xml = XElement.Load(xmlReader.ReadSubtree());
      }
      catch (Exception ex)
      {
        Console.Error.WriteLine("ERROR: An error occurred while parsing the reply for request {0}: {1}", requestId, ex);
        return;
      }
    }

    Console.Out.WriteLine(
      "{0}\t{1}\t{2}",
      requestId,
      replyMessage.Headers.Action,
      xml.ToString(SaveOptions.DisableFormatting));
  }
}
{% endhighlight %}

This program will connect to the remote WCF service. The program will then start a loop to read each line of input. The loop will break with the end of the input stream is reached (the parent program closes the input stream, the end of the input file is read, or an end-of-file marker is reached on the input stream from the user typing CTRL+Z on Windows or CTRL+D on Unix).

The program will parse each input line into its parts. The program will then manually construct the SOAP envelope to be sent to the remote WCF service and will send the SOAP request.

When the response is received, WCF will invoke the **OutputResponse** method. The OutputResponse method will obtain the reply from the WCF service and then will create the output record that will be written to stdout. The request identifer is included in the response that is written to stdout so that the parent program can correlate the reply with the request.

I can test this command-line program pretty easily from a console window on Windows. Given the input:

    > WcfRequestReplyClient.exe
    TestCall[<tab>]http://www.michaelfcollins3.me/desertcodecamp/2012/11/commandline/IHelloService/SayHello[<tab>]<SayHello><to><Name>Michael</Name></to></SayHello>

I should receive the response written to stdout:

    TestCall[<tab>]http://www.michaelfcollins3.me/desertcodecamp/2012/11/commandline/IHelloService/SayHelloResponse[<tab>]<SayHelloResponse><SayHelloResult><Message>Welcome Michael</Message></SayHelloResult></SayHelloResponse>

The Node.js Application
-----------------------
For the Node.js application, I'm just going to show the basic approach of running the WCF client command-line program as a child process, sending the request, and reading back the response. I will output the XML for the SOAP response message, but for brevity in this post, I will not show parsing the XML message to get the welcome message out. I will leave that as an exercise for you, or you can look at the full posted sample code.

Here is the Node.js application:

{% highlight javascript %}
var childProcess = reqire('child_process');

var wcfClient = childProcess.spawn('WcfClient.exe');

wcfClient.stdout.on('data', function (data) {
  var parts = new String(data).split('\t');
  console.log(parts[2]);

  /* After receiving the reply, close the input stream
   * to terminate the child process.
   */
  wcfClient.stdin.end();
});

wcfClient.on('exit', function (code) {
	console.log('The WCF client program terminated with exit code ' + code);
});

wcfclient.stdin.write('TestCall\thttp://www.michaelfcollins3.me/desertcodecamp/2012/11/commandline/IHelloService/SayHello\t<SayHello><to><Name>Michael</Name></to></SayHello>\n');
{% endhighlight %}

The Node.js application uses the **child_process** module to spawn the .NET WCF client command-line program. The child_process module automatically redirects the stdin, stdout, and stderr streams so that they are accessible through the **stdin**, **stdout**, and **stderr** properties on the **wcfClient** object. When a new line is output to **childProcess.stdout**, the **data** event is raised and the Node.js program receives the line that was written to stdout in the callback function. In this sample program, since only one record is being written to the child process's stdin stream, I am closing the child process's stdin stream when I get the reply record. Closing the stdin stream for the child process results in the EOF marker being sent to the WCF client program, which will cause the child program to terminate. At the end, you should see the message "The WCF client program terminated with exit code 0".

Conclusion
----------
In this post, I expanded upon my previous post introducing (or re-introducing) you to command-line programming by giving you my first example of the power of command-line programming. While this was not a complete sample in that I only used default WCF settings without security or other features, it's a starting point that either you or I can expand on to provide support for more WCF features such as alternative bindings. I hope to keep developing this sample to demonstrate additional features.

Source Code
-----------
*The source code for this sample will be posted soon. Please check back for a link to the source code on GitHub.*