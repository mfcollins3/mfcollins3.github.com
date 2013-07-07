---
layout: post
title: Implementing the CIM Provider
description: In the previous three posts in this series, I have been creating a work queue service that can be controlled through messages sent to the service using named pipes. In this article, I will complete the series by implementing a working CIM provider and showing how PowerShell can be used to administer work queues.
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
Where I Left Off
----------------
If you recall from the previous three articles in this series, I have demonstrated the following:

1. [Creating a named pipe server and client]({% post_url 2013-06-10-windows-ipc-using-named-pipes %})
2. [Adding commands for listing, deleting, starting, and stopping work queues]({% post_url 2013-06-11-completing-the-named-pipes-example %})
3. [Extracting the work queue service into an external program and updating the feature tests to communicate with the service]({% post_url 2013-06-16-extracting-the-named-pipe-server %})

In this fourth article, I will finally get to the point of this series which is creating a CIM provider so that we can use PowerShell and other management tools to create, delete, list, start, or stop work queues.

Get the Code!
-------------
In the last post, I promised that I would make this source code available on GitHub so that you can download and run it. My mistake as I was writing the earlier posts was that I originally built them outside of version control (bad, bad, bad). I managed to rectify the issue and I used the blog posts to recreate the source code. You can find the source code in my [GitHub repository](https://github.com/mfcollins3/cimprovider). I have created tags that correlate to the state of the source code at the end of each article in this series. Please feel free to fork the repository and enhance the sample to suit your needs and interests.

A Little Background on CIM Providers
------------------------------------
As long as there has been a Windows Server architecture, there has been a management framework named Windows Management Instrumentation (WMI). WMI presents a hierarchical object model that administrators can use to monitor and manage applications, devices, and other services on the server. Developers can extend WMI by creating additional objects and events that administators can use to manage installed applications on their servers.

From an end-user point of view, WMI is very nice. WMI presents a standard interface that you can query objects on the server, invoke operations or set properties on those objects, and receive events or notifications when things happen. From a developer point of view, things are not so rosy. WMI providers have been difficult and unfriendly to write, and for .NET developers, the WMI provider support has not been wonderful.

Along came Windows 8 and Windows Server 2012. People within Microsoft decided to take more of a standardized approach to WMI and management and formally adopted an industry standard called the Common Information Model, or CIM. CIM provides a standard object model for management that is supported across platforms and operating systems. In addition to the CIM support, Microsoft developed an easier framework for developing providers that solved a lot of the problems that existed with creating WMI providers. Microsoft also included a code generator with the Windows 8 SDK that made it easy to generate the skeleton code, so that developers only need to worry about building the business logic for the provider.

The provider programming interface is still in C and there is not a published .NET equivalent, but the C interface is not that hard to deal with. In this article, I will walk through my first attempt at building a CIM provider that will use the named pipes interface that I have already implemented in feature tests to communicate with the external work queue service.

Disclaimer
----------
<div class="alert alert-block alert-error">
	<h4>I Apologize in Advance</h4>
	<p>
		I pride myself on being a professional software developer and trying to present the best code possible in my blog posts. However, I will not claim that this C/C++ code is the best quality code that I could write, or that the CIM provider that is produced is the best quality. The sample will work, that's all that I will promise. There are probably plenty of mistakes and things that I would not normally do in production code. Please remember that this code was developed as a learning exercise. While in review some of the code will make me cringe, it works, so I left it like that.
	</p>
	<p>
		I considered re-writing the provider to make it more <em>polished</em> and production ready. However, in the end I thought that seeing the code as it was developed using my exporatory approach was going to lead to a better example. In a future blog post or source code update to the GitHub repository, I will update the source code for the CIM provider with a more polished version. I do believe that this version of the code is better for learning and works better for this blog post.
	</p>
</div>

Before Getting Started...
-------------------------
Before getting started with this post, if you are new to CIM providers, WMI, and management in general, you might want to take a look at a wonderful video presentation from the 2012 [Build Windows](http://www.buildwindows.com) titled [Making Your Applications Manageable](http://channel9.msdn.com/Events/Build/2012/2-027). This was the first presentation that I reviewed where I learned about CIM providers. The sample code for their presentation is located in the MSDN code repository [here](http://code.msdn.microsoft.com/Management-Infrastructure-79fb414f).

The new management infrastructure documentation is on MSDN [here](http://bit.ly/13DBOYl). For the client-side of the management problem space, Microsoft provides both managed and native APIs for interacting with CIM providers. The managed APIs are also exposed through PowerShell 3 as cmdlets.

Let's Begin!
------------
I'm not going to go into anymore basics about what CIM is and the significance of providers. If you want to know that before jumping into the code, check out the [Channel 9 video](http://channel9.msdn.com/Events/Build/2012/2-027).

The first thing that we need to do when creating a new CIM provider is to describe our new object model for work queues. The object model is pretty simple as I'm only going to expose a **WorkQueue** object type in this initial example. To define the object model, I'm going to use a specification written in a language called **Management Object Format**, or **MOF**. Here is the object definition below:

{% highlight text %}
#pragma include ("cim_schema_2.26.0.mof")

class Sample_WorkQueue : CIM_Service
{
    uint32 StartService();
    uint32 StopService();
}
{% endhighlight %}

This specification defines a new object type named **Sample_WorkQueue** that is derived from the **CIM_Service** class. Microsoft's CIM support is based on version 2.26.0 of the CIM standard. The MOF files for this release and the documentation for the standard CIM classes can be downloaded from [here](http://dmtf.org/standards/cim/cim_schema_v2260).

Given the standard CIM schema and my MOF class, I can use the **Convert-MofToProvider.exe** program that is provided by the Windows 8 SDK to generate the skeleton source code for my CIM provider:

	> Convert-MofToProvider.exe -MofFile WorkQueue.mof
		-ClassList Sample_WorkQueue
		-IncludePath cim
		-OutPath CimProvider

**Convert-MofToProvider** will read my MOF specification in **WorkQueue.mof** and will generate skeleton code for the **Sample_WorkQueue** class, its superclasses, and any dependency classes. **Convert-MofToProvider** will search for the standard CIM definitions in the **.\cim** directory, and will output the skeleton C code to **.\CimProvider**.

What **Convert-MofToProvider** will actually do is to read the MOF definition and generate the source code for a complete DLL that implements a CIM provider. The CIM provider can be compiled using Visual C++ and registered with WMI and will work, although it will not do anything yet and all of the calls to it will return errors. I will fill in the implementation details to the point where all of my feature tests are using the CIM provider to communicate with the work queue service and are passing.

Looking at the Skeleton
-----------------------
The source code for the work queue CIM object is going to be generated into the **Sample_WorkQueue.c** file by the **Convert-MofToProvider** program. The generated code looks like this:

{% highlight c %}
/* @migen@ */
#include <MI.h>
#include "Sample_WorkQueue.h"

void MI_CALL Sample_WorkQueue_Load(
    _Outptr_result_maybenull_ Sample_WorkQueue_Self** self,
    _In_opt_ MI_Module_Self* selfModule,
    _In_ MI_Context* context)
{
    MI_UNREFERENCED_PARAMETER(selfModule);

    *self = NULL;
    MI_Context_PostResult(context, MI_RESULT_OK);
}

void MI_CALL Sample_WorkQueue_Unload(
    _In_opt_ Sample_WorkQueue_Self* self,
    _In_ MI_Context* context)
{
    MI_UNREFERENCED_PARAMETER(self);

    MI_Context_PostResult(context, MI_RESULT_OK);
}

void MI_CALL Sample_WorkQueue_EnumerateInstances(
    _In_opt_ Sample_WorkQueue_Self* self,
    _In_ MI_Context* context,
    _In_opt_z_ const MI_Char* nameSpace,
    _In_opt_z_ const MI_Char* className,
    _In_opt_ const MI_PropertySet* propertySet,
    _In_ MI_Boolean keysOnly,
    _In_opt_ const MI_Filter* filter)
{
    MI_UNREFERENCED_PARAMETER(self);
    MI_UNREFERENCED_PARAMETER(nameSpace);
    MI_UNREFERENCED_PARAMETER(className);
    MI_UNREFERENCED_PARAMETER(propertySet);
    MI_UNREFERENCED_PARAMETER(keysOnly);
    MI_UNREFERENCED_PARAMETER(filter);

    MI_Context_PostResult(context, MI_RESULT_NOT_SUPPORTED);
}

void MI_CALL Sample_WorkQueue_GetInstance(
    _In_opt_ Sample_WorkQueue_Self* self,
    _In_ MI_Context* context,
    _In_opt_z_ const MI_Char* nameSpace,
    _In_opt_z_ const MI_Char* className,
    _In_ const Sample_WorkQueue* instanceName,
    _In_opt_ const MI_PropertySet* propertySet)
{
    MI_UNREFERENCED_PARAMETER(self);
    MI_UNREFERENCED_PARAMETER(nameSpace);
    MI_UNREFERENCED_PARAMETER(className);
    MI_UNREFERENCED_PARAMETER(instanceName);
    MI_UNREFERENCED_PARAMETER(propertySet);

    MI_Context_PostResult(context, MI_RESULT_NOT_SUPPORTED);
}

void MI_CALL Sample_WorkQueue_CreateInstance(
    _In_opt_ Sample_WorkQueue_Self* self,
    _In_ MI_Context* context,
    _In_opt_z_ const MI_Char* nameSpace,
    _In_opt_z_ const MI_Char* className,
    _In_ const Sample_WorkQueue* newInstance)
{
    MI_UNREFERENCED_PARAMETER(self);
    MI_UNREFERENCED_PARAMETER(nameSpace);
    MI_UNREFERENCED_PARAMETER(className);
    MI_UNREFERENCED_PARAMETER(newInstance);

    MI_Context_PostResult(context, MI_RESULT_NOT_SUPPORTED);
}

void MI_CALL Sample_WorkQueue_ModifyInstance(
    _In_opt_ Sample_WorkQueue_Self* self,
    _In_ MI_Context* context,
    _In_opt_z_ const MI_Char* nameSpace,
    _In_opt_z_ const MI_Char* className,
    _In_ const Sample_WorkQueue* modifiedInstance,
    _In_opt_ const MI_PropertySet* propertySet)
{
    MI_UNREFERENCED_PARAMETER(self);
    MI_UNREFERENCED_PARAMETER(nameSpace);
    MI_UNREFERENCED_PARAMETER(className);
    MI_UNREFERENCED_PARAMETER(modifiedInstance);
    MI_UNREFERENCED_PARAMETER(propertySet);

    MI_Context_PostResult(context, MI_RESULT_NOT_SUPPORTED);
}

void MI_CALL Sample_WorkQueue_DeleteInstance(
    _In_opt_ Sample_WorkQueue_Self* self,
    _In_ MI_Context* context,
    _In_opt_z_ const MI_Char* nameSpace,
    _In_opt_z_ const MI_Char* className,
    _In_ const Sample_WorkQueue* instanceName)
{
    MI_UNREFERENCED_PARAMETER(self);
    MI_UNREFERENCED_PARAMETER(nameSpace);
    MI_UNREFERENCED_PARAMETER(className);
    MI_UNREFERENCED_PARAMETER(instanceName);

    MI_Context_PostResult(context, MI_RESULT_NOT_SUPPORTED);
}

void MI_CALL Sample_WorkQueue_Invoke_RequestStateChange(
    _In_opt_ Sample_WorkQueue_Self* self,
    _In_ MI_Context* context,
    _In_opt_z_ const MI_Char* nameSpace,
    _In_opt_z_ const MI_Char* className,
    _In_opt_z_ const MI_Char* methodName,
    _In_ const Sample_WorkQueue* instanceName,
    _In_opt_ const Sample_WorkQueue_RequestStateChange* in)
{
    MI_UNREFERENCED_PARAMETER(self);
    MI_UNREFERENCED_PARAMETER(nameSpace);
    MI_UNREFERENCED_PARAMETER(className);
    MI_UNREFERENCED_PARAMETER(methodName);
    MI_UNREFERENCED_PARAMETER(instanceName);
    MI_UNREFERENCED_PARAMETER(in);

    MI_Context_PostResult(context, MI_RESULT_NOT_SUPPORTED);
}

void MI_CALL Sample_WorkQueue_Invoke_StartService(
    _In_opt_ Sample_WorkQueue_Self* self,
    _In_ MI_Context* context,
    _In_opt_z_ const MI_Char* nameSpace,
    _In_opt_z_ const MI_Char* className,
    _In_opt_z_ const MI_Char* methodName,
    _In_ const Sample_WorkQueue* instanceName,
    _In_opt_ const Sample_WorkQueue_StartService* in)
{
    MI_UNREFERENCED_PARAMETER(self);
    MI_UNREFERENCED_PARAMETER(nameSpace);
    MI_UNREFERENCED_PARAMETER(className);
    MI_UNREFERENCED_PARAMETER(methodName);
    MI_UNREFERENCED_PARAMETER(instanceName);
    MI_UNREFERENCED_PARAMETER(in);

    MI_Context_PostResult(context, MI_RESULT_NOT_SUPPORTED);
}

void MI_CALL Sample_WorkQueue_Invoke_StopService(
    _In_opt_ Sample_WorkQueue_Self* self,
    _In_ MI_Context* context,
    _In_opt_z_ const MI_Char* nameSpace,
    _In_opt_z_ const MI_Char* className,
    _In_opt_z_ const MI_Char* methodName,
    _In_ const Sample_WorkQueue* instanceName,
    _In_opt_ const Sample_WorkQueue_StopService* in)
{
    MI_UNREFERENCED_PARAMETER(self);
    MI_UNREFERENCED_PARAMETER(nameSpace);
    MI_UNREFERENCED_PARAMETER(className);
    MI_UNREFERENCED_PARAMETER(methodName);
    MI_UNREFERENCED_PARAMETER(instanceName);
    MI_UNREFERENCED_PARAMETER(in);

    MI_Context_PostResult(context, MI_RESULT_NOT_SUPPORTED);
}
{% endhighlight %}

Because this file was produced through code generation and may get regenerated at a later time, I'm not going to put the implementation of my work queue client into this skeleton code. I'm going to create a C++ module to implement the actual business logic of the CIM provider, and I'll modify the skeleton code to call the business logic.

I'm now going to walk back through the feature tests and will implement the code necessary to make each scenario and step pass.

Creating a Work Queue
---------------------
I'm going to start at the first scenario that I implemented in the first article: creating a work queue. In the first article, I created a named pipe server and client. The client sent a CREATE command to the server, and the server created the work queue. In the third post, I extracted the server-side of the implementation into a separate service program. The feature tests still use named pipes to communicate with the service to create a work queue.

In this article, I want to change that implementation. With Windows 8, PowerShell 3.0, and the Windows Management Framework 3.0, Microsoft introduced the new management infrastructure API with both managed and native APIs. I want to use the managed APIs in my feature tests to invoke the operations in my CIM provider, and have the CIM provider use the named pipes interface for my work queue service program to manage work queues.

The managed API for working with CIM providers is implemented in the **Microsoft.Management.Infrastructure.dll** assembly that is located in the **C:\Program Files (x86)\Reference Assemblies\Microsoft\WMI\v1.0** directory. I'm going to add a reference to this assembly to my **FeatureTests** project.

To review, here's the scenario:

{% highlight gherkin %}
Given the work queue does not exist
When I create the work queue
Then the work queue will be created
And the work queue will be stopped
{% endhighlight %}

The steps for this test look like this after the third article:

{% highlight c# %}
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

[When(@"I create the work queue")]
public void WhenICreateTheWorkQueue()
{
    this.CreateTestWorkQueue();
}

[Then(@"the work queue will be created")]
public void ThenTheWorkQueueWillBeCreated()
{
    this.GetWorkQueues();
    Assert.IsTrue(this.workQueues.ContainsKey(TestWorkQueueName));
}

[Then(@"the work queue will be stopped")]
public void ThenTheWorkQueueWillBeStopped()
{
    this.GetWorkQueues();
    Assert.AreEqual("Stopped", this.workQueues[TestWorkQueueName]);
}
{% endhighlight %}

The good news looking at this code is that I've already moved all of the named pipe logic out of the step definitions and put them into helper methods. So I only need to change my helper methods to invoke CIM operations using the Microsoft Management API instead of sending messages to the work queue service using named pipes.

First, I will re-implement the **GetWorkQueues** method to query WMI for the list of defined work queues. Previously, this method sent the **LIST** command over the named pipe to the work queue service. Now, I'll query WMI for the list of work queues:

{% highlight c# %}
private CimSession session;

[BeforeScenario]
public void CreateCimSession()
{
    var sessionOptions = new CimSessionOptions
        {
            Culture = Thread.CurrentThread.CurrentCulture,
            Timeout = TimeSpan.FromMinutes(2.0),
            UICulture = Thread.CurrentThread.CurrentUICulture
        };
    this.session = CimSession.Create(null, sessionOptions);
    Assert.IsTrue(this.session.TestConnection());
}

[AfterScenario]
public void DisposeCimSession()
{
    this.session.Dispose();
}

private void GetWorkQueues()
{
    this.workQueues = new Dictionary<string, string>();
    var operationOptions = new CimOperationOptions
        {
            WriteError = error =>
                {
                    Console.Error.WriteLine(
                        "ERROR: {0}", error.ToString());
                    return CimResponseType.None;
                },
            WriteMessage = (channel, message) =>
                Console.Error.WriteLine(message)
        };
    var instances = this.session.EnumerateInstances(
        @"root/standardcimv2/sample",
        "Sample_WorkQueue",
        operationOptions);
    for (var instance in instances)
    {
        var enabledState = (ushort)
            instance.CimInstanceProperties["EnabledState"].Value;
        this.workQueues.Add(
            (string)instance.CimInstanceProperties["Name"].Value,
            2 == enabledState ? "Running" : "Stopped");
    }
}
{% endhighlight %}

The **GetWorkQueues** method will retrieve all of the **Sample_WorkQueue** objects that exist in the **root/standardcimv2/sample** WMI namespace. It will then use the properties of the retrieved objects (if there are any) to populate the **workQueues** collection used by the steps.

Notice the **operationOptions** object that I am initializing. When the CIM provider runs, even though the CIM provider is a DLL, it will not be running in the client program's process space. By default, the CIM provider will be running in a WMI host process. You can debug this code by finding and attaching the Visual Studio debugger to the WMI host process, but to make it easier, I am using the old-style logging approach. The log messages that I output from my CIM provider will be sent to the client process. I am capturing these output events and outputting the messages that are sent to the test output so that I can monitor how the CIM provider is executing while a test is running. When I run the CIM provider through PowerShell later, I can also enable these messages to appear in PowerShell for diagnostic reasons.

Iterating the instances of work queues will cause WMI to invoke the **Sample_WorkQueue_EnumerateInstances** function in my CIM provider. I updated the skeleton code to call a **ListWorkQueues** function where I implemented the real business logic. Notice the call to the **MI_WriteDebug** function. I am using this to out the debug messages that I just discussed. These debug messages are being captured and output by my event handlers in the above code fragment:

{% highlight c %}
void MI_CALL Sample_WorkQueue_EnumerateInstances(
  _In_opt_ Sample_WorkQueue_Self* self,
  _In_ MI_Context* context,
  _In_opt_z_ const MI_Char* nameSpace,
  _In_opt_z_ const MI_Char* className,
  _In_opt_ const MI_PropertySet* propertySet,
  _In_ MI_Boolean keysOnly,
  _In_opt_ const MI_Filter* filter)
{
  MI_UNREFERENCED_PARAMETER(self);
  MI_UNREFERENCED_PARAMETER(nameSpace);
  MI_UNREFERENCED_PARAMETER(className);
  MI_UNREFERENCED_PARAMETER(propertySet);
  MI_UNREFERENCED_PARAMETER(keysOnly);
  MI_UNREFERENCED_PARAMETER(filter);
  MI_WriteDebug(context, L"Sample_WorkQueue_EnumerateInstances called");
  ListWorkQueues(context);
}
{% endhighlight %}

While the CIM provider interface is using C, my internal implementation is actually written in C++. I could have achieved what I was trying to do in C, but I like C++ and its standard library better, so I did it that way. The **ListWorkQueues** function will create the named pipe connection to the work queue service and will sent the **LIST** command. The **ListWorkQueues** function will then take the results and will output **Sample_WorkQueue** objects back to WMI for each defined work queue:

{% highlight c++ %}
namespace {
  HANDLE CreateClientPipe(MI_Context *context) {
    MI_Context_WriteDebug(context, L"Connecting to the server");
    Handle pipe_handle = CreateFile(
      _T("\\\\.\\pipe\\WorkQueueService"),
      GENERIC_READ | GENERIC_WRITE,
      0,
      NULL,
      OPEN_EXISTING,
      0,
      NULL);
    if (INVALID_HANDLE_VALUE == pipe_handle) {
      throw std::exception("CreateFile failed.");
    }

    MI_Context_WriteDebug(context, L"Connected to the server");
    DWORD mode = PIPE_READMODE_MESSAGE;
    BOOL success = SetNamedPipeHandleState(pipe_handle, &mode, NULL, NULL);
    if (!success) {
      CloseHandle(pipe_handle);
      throw std::exception("SetNamedPipeHandleState failed");
    }

    return pipe_handle;
  }

  std::wstring ReadMessageFromPipe(HANDLE pipe_handle) {
    std::wostringstream os;
    wchar_t buffer[16384];
    DWORD bytes_read;
    BOOL success;
    do {
      success =
        ReadFile(pipe_handle, buffer, sizeof(buffer), &bytes_read, NULL);
      if (!success && ERROR_MORE_DATA != GetLastError()) {
        break;
      }

      os.write(buffer, bytes_read / sizeof(wchar_t));
    } while (!success);

    if (!success) {
      throw std::exception("An error occurred reading from the pipe");
    }

    return os.str();
  }

  std::wstring SendMessageAndReceiveReply(
    HANDLE pipe_handle, std::wstring message) {
    const wchar_t *buffer = message.c_str();
    size_t number_of_bytes;
    StringCbLength(buffer, 256, &number_of_bytes);
    BOOL success = 
      WriteFile(pipe_handle, buffer, number_of_bytes, NULL, NULL);
    if (!success) {
      throw std::exception("WriteFile failed");
    }

    return ReadMessageFromPipe(pipe_handle);
  }

  void EndClientSession(
    MI_Context *context,
    HANDLE pipe_handle,
    MI_RESULT result = MI_RESULT_OK) {
    std::wstring reply;
    MI_Context_WriteDebug(context, L"Sending GOODBYE command");
    try {
      reply = SendMessageAndReceiveReply(pipe_handle, L"GOODBYE");
    } catch (std::exception ex) {
      MI_Context_WriteDebug(context, L"GOODBYE command failed");
      CloseHandle(pipe_handle);
      MI_Context_PostResult(context, MI_RESULT_FAILED);
      return;
    }

    MI_Context_WriteDebug(context, reply.c_str());
    CloseHandle(pipe_handle);
    MI_Context_PostResult(context, result);
  }
}

void ListWorkQueues(MI_Context *context) {
  HANDLE pipe_handle;
  try {
    pipe_handle = CreateClientPipe(context);
  } catch (std::exception ex) {
    MI_Context_WriteDebug(context, L"CreateClientPipe failed");
    MI_Context_PostResult(context, MI_RESULT_FAILED);
    return;
  }

  MI_Context_WriteDebug(context, L"Sending LIST command");
  std::wstring reply;
  try {
    reply = SendMessageAndReceiveReply(pipe_handle, L"LIST");
  } catch (std::exception ex) {
    MI_Context_WriteDebug(context, L"LIST command failed");
    CloseHandle(pipe_handle);
    MI_Context_PostResult(context, MI_RESULT_FAILED);
    return;
  }

  MI_Context_WriteDebug(context, reply.c_str());
  std::wistringstream is(reply);
  std::wstring result;
  is >> result;
  if (result == L"OK") {
    std::wstring name;
    std::wstring state;
    while (!is.eof()) {
      is >> name >> state;
      MI_Context_WriteDebug(context, name.c_str());
      MI_Context_WriteDebug(context, state.c_str());
      Sample_WorkQueue work_queue;
      ZeroMemory(&work_queue, sizeof(work_queue));
      Sample_WorkQueue_Construct(&work_queue, context);
      Sample_WorkQueue_Set_Name(&work_queue, name.c_str());
      Sample_WorkQueue_Set_Caption(&work_queue, name.c_str());
      Sample_WorkQueue_Set_CreationClassName(
        &work_queue,
        L"Sample_WorkQueue");
      Sample_WorkQueue_Set_SystemCreationClassName(
        &work_queue,
        L"CIM_Service");
      Sample_WorkQueue_Set_SystemName(&work_queue, name.c_str());
      Sample_WorkQueue_Set_EnabledState(
        &work_queue,
        L"Running" == state ? 2 : 3);
      Sample_WorkQueue_Post(&work_queue, context);
      Sample_WorkQueue_Destruct(&work_queue);
    }
  }

  EndClientSession(context, pipe_handle);
}
{% endhighlight %}

The **ListWorkQueues** function will open a named pipe to the work queue service and will send the **LIST** command. It will then parse the response into a set of name and status values. The interesting section is inside the loop. To send results back to the WMI user, I actually need to create and send **Sample_WorkQueue** objects. The **Sample_WorkQueue** objects are really just binary structures, but they represent a snapshot of a real work queue object that is managed by my service. If you look at the schema for the **CIM_Service** CIM class, you'll see that there are a lot of properties that I can set, but I'm only going to return the values that I need at the moment. In order to have the call to **Sample_WorkQueue_Post** succeed in returning a **Sample_WorkQueue** object to the client program, I need to populate a set of required fields that are identified as keys. For the **Sample_WorkQueue** object, the keys are **Name**, **Caption**, **CreationClassName**, **SystemCreationClassName**, and **SystemName**. Besides those, I also return the **EnabledState** field to indicate whether the work queue is running or is stopped.

I have two more methods that I need to implement in my test code to get the test to pass: **CreateTestWorkQueue** and **DeleteTestWorkQueue**. The updated implementations are below:

{% highlight c# %}
private void CreateWorkQueue(string workQueueName)
{
    var operationOptions = new CimOperationOptions
        {
            WriteMessage = (channel, message) => 
                Console.Error.WriteLine(message)
        };
        var workQueueClass = this.session.GetClass(
            "root/standardcimv2/sample",
            "Sample_WorkQueue",
            operationOptions);
        var workQueueInstance = new CimInstance(workQueueClass);
        workQueueInstance.CimInstanceProperties["Name"].Value =
            workQueueName;
        var newWorkQueue = this.session.CreateInstance(
            "root/standardcimv2/sample",
            workQueueInstance,
            operationOptions);
        Assert.NotNull(newWorkQueue);
        Assert.AreEqual(
            workQueueName,
            newWorkQueue.CimInstanceProperties["Name"].Value);
}

private void DeleteTestService()
{
    var operationOptions = new CimOperationOptions
        {
            WriteMessage = (channel, message) =>
                Console.Error.WriteLine(message)
        };
    var workQueues = this.session.QueryInstances(
        "root/standardcimv2/sample",
        "WQL",
        "SELECT * FROM Sample_WorkQueue WHERE Name = 'MyWorkQueue'",
        opertionOptions);
    var workQueue = workQueues.First();
    this.session.DeleteInstance(
        "root/standardcimv2/sample",
        workQueue,
        operationOptions);
}
{% endhighlight %}

Creating a work queue object will invoke the **Sample_WorkQueue_CreateInstance** function in the skeleton code, and deleting a work queue object will invoke the **SampleWorkQueue_DeleteInstance** function. Like the earlier examples, these function defer to the following implementation functions that are shown below:

{% highlight c++ %}
void CreateWorkQueue(
    MI_Context *context, const SampleWorkQueue *work_queue) {
  HANDLE pipe_handle;
  try {
    pipe_handle = CreateClientPipe(context);
  } catch (std::exception ex) {
    MI_Context_WriteDebug(context, L"CreateClientPipe failed");
    MI_Context_PostResult(context, MI_RESULT_FAILED);
    return;
  }

  std::wostringstream os;
  os << L"CREATE " << work_queue->Name.value;
  std::wstring reply;
  try {
    reply = SendMessageAndReceiveReply(pipe_handle, os.str());
  } catch (std::exception ex) {
    MI_Context_WriteDebug(context, L"SendMessageAndReceiveReply failed");
    CloseHandle(pipe_handle);
    MI_Context_PostResult(context, MI_RESULT_FAILED);
    return;
  }

  MI_Context_WriteDebug(context, reply.c_str());
  MI_RESULT result;
  if (L"OK" == reply) {
    Sample_WorkQueue new_work_queue;
    ZeroMemory(&new_work_queue, sizeof(new_work_queue));
    Sample_WorkQueue_Construct(&new_work_queue, context);
    Sample_WorkQueue_Set_Name(&new_work_queue, work_queue->Name.value);
    Sample_WorkQueue_Set_Caption(&new_work_queue, work_queue->Name.Value);
    Sample_WorkQueue_SetCreationClassName(
        &new_work_queue, L"Sample_WorkQueue");
    Sample_WorkQueue_SetSystemCreationClassName(
        &new_work_queue, L"CIM_Service");
    Sample_WorkQueue_SetSystemName(
        *new_work_queue, work_queue->Name.value);
    result = Sample_WorkQueue_Post(&new_work_queue, context);
    if (MI_RESULT_OK != result) {
      wchar_t message[256];
      StringCchPrintf(
          message, 256, L"Sample_WorkQueue_Post failed: %d", result);
      MI_Context_WriteDebug(context, message);
    }

    Sample_WorkQueue_Destruct(&new_work_queue);
  }

  EndClientSession(context, pipe_handle, result);
}

void DeleteWorkQueue(
    MI_Context *context, const Sample_WorkQueue *work_queue) {
  HANDLE pipe_handle;
  try {
    pipe_handle = CreateClientPipe(context);
  } catch (std::exception ex) {
    MI_Context_WriteDebug(context, L"CreateClientPipe failed");
    MI_Context_PostResult(context, MI_RESULT_FAILED);
    return;
  }

  wchar_t command[256];
  ::StringCchPrintf(command, 256, L"DELETE %s", work_queue->Name.Value);
  std::wstring reply;
  try {
    reply = SendMessageAndReceiveReply(pipe_handle, command);
  } catch (std::exception ex) {
    MI_Context_WriteDebug(context, L"SendMessageAndReceiveReply failed");
    CloseHandle(pipe_handle);
    MI_Context_PostResult(context, MI_RESULT_FAILED);
    return;
  }

  MI_Context_WriteDebug(context, reply.c_str());
  MI_Result result = L"OK" == reply ? MI_RESULT_OK : MI_RESULT_FAILED;
  EndClientSession(context, pipe_handle, result);
}
{% endhighlight %}

Now that these operations are implemented, I can test my CIM provider. In order to test, I need to register my provider with the WMI subsystem on my computer using a tool named **Register-CimProvider.exe** that is installed in the **C:\Windows\System32** directory. The syntax is:

    > Register-CimProvider.exe -Namespace root/standardcimv2/sample
        -ProviderName "Work Queue Service"
        -Path CimProvider.dll
        -GenerateUnregistration

This command line program will register my CIM provider DLL with WMI. The DLL will be configured to execute from the path that I specified in the call to **Register-CimProvider.exe**, so you can install the CIM drivers with your software and register them as part of the installer. You can also replace the DLLs with updated when available. The **-GenerateUnregistration** flag is good for testing. This option will generate a MOF file that you can run to remove your CIM provider. This is very helpful to enable for testing when you may need to register or unregister development versions of the CIM provider.

After registering my CIM provider, running the creation scenario should succeed. In the test output, you should see each of the calls that were made to the work queue servie in the test output. In addition to the create scenario, the list and delete scenarios should run also. This is because we moved all of the communication logic with the service out of the step implementations and instead moved that logic into helper methods, whose logic was just replaced. The start and stop operations should be fairly easy to get using by just changing their implementations to use the new CIM provider and implementing the corresponding functions in the CIM provider:

{% highlight c# %}
private void StartService()
{
    var operationOptions = new CimOperationOptions
        {
            WriteMessage = (channel, message) =>
                Console.Error.WriteLine(message);
        };
    var workQueue = this.session.QueryInstances(
        "root/standardcimv2/sample",
        "WQL",
        "SELECT * FROM Sample_WorkQueue WHERE Name = 'MyWorkQueue'",
        operationOptions).First();
    var result = this.session.InvokeMethod(
        "root/standardcimv2/sample",
        workQueue,
        "StartService",
        new CimMethodParametersCollection(),
        operationOptions);
    Assert.NotNull(result);
}

private void StopService()
{
    var operationOptions = new CimOperationOptions
        {
            WriteMessage = (channel, message) =>
                Console.Error.WriteLine(message);
        };
    var workQueue = this.session.QueryInstances(
        "root/standardcimv2/sample",
        "WQL",
        "SELECT * FROM Sample_WorkQueue WHERE Name = 'MyWorkQueue'",
        operationOptions).First();
    var result = this.session.InvokeMethod(
        "root/standardcimv2/sample",
        workQueue,
        "StartService",
        new CimMethodParametersCollection(),
        operationOptions);
    Assert.NotNull(result);
}
{% endhighlight %}

The CIM provider implementation is below:

{% highlight c++ %}
void StartWorkQueue(MI_Context *context, const Sample_WorkQueue *work_queue)
{
  HANDLE pipe_handle;
  try {
    pipe_handle = CreateClientPipe(context);
  } catch (std::exception ex) {
    MI_Context_WriteDebug(context, L"CreateClientPipe failed");
    MI_Context_PostResult(context, MI_RESULT_FAILED);
    return;
  }

  wchar_t command[256];
  ::StringCchPrintf(command, 256, L"START %s", work_queue->Name.value);
  MI_Context_WriteDebug(context, command);
  std::wstring reply;
  try {
    reply = SendMessageAndReceiveReply(pipe_handle, command);
  } catch (std::exception ex) {
    MI_Context_WriteDebug(context, L"SendMessageAndReceiveReply failed.");
    ::CloseHandle(pipe_handle);
    MI_Context_PostResult(context, MI_RESULT_FAILED);
    return;
  }

  MI_Context_WriteDebug(context, reply.c_str());
  MI_Result result = L"OK" == reply ? MI_RESULT_OK : MI_RESULT_FAILED;
  EndClientSession(context, pipe_handle, result);
}

void StopWorkQueue(MI_Context *context, const Sample_WorkQueue *work_queue)
{
  HANDLE pipe_handle;
  try {
    pipe_handle = CreateClientPipe(context);
  } catch (std::exception ex) {
    MI_Context_WriteDebug(context, L"CreateClientPipe failed");
    MI_Context_PostResult(context, MI_RESULT_FAILED);
    return;
  }

  wchar_t command[256];
  ::StringCchPrintf(command, 256, L"STOP %s", work_queue->Name.value);
  MI_Context_WriteDebug(context, command);
  std::wstring reply;
  try {
    reply = SendMessageAndReceiveReply(pipe_handle, command);
  } catch (std::exception ex) {
    MI_Context_WriteDebug(context, L"SendMessageAndReceiveReply failed.");
    ::CloseHandle(pipe_handle);
    MI_Context_PostResult(context, MI_RESULT_FAILED);
    return;
  }

  MI_Context_WriteDebug(context, reply.c_str());
  MI_Result result = L"OK" == reply ? MI_RESULT_OK : MI_RESULT_FAILED;
  EndClientSession(context, pipe_handle, result);
}
{% endhighlight %}

After compiling in these updates, re-registering the CIM provider, and running the tests, I should see all of my tests pass.

Working with the CIM Provider in PowerShell
-------------------------------------------
So the tests are running, but what can we really do with CIM providers? Why have I been working on this sample and what is my end goal? My end goal is really to build software applications that run on servers and can be managed by administrators using PowerShell or Microsoft SCOM. I also want to be able to ship after-market solutions in the form of PowerShell scripts or other components that can do things such as create work queues if necessary. So the next logical step now that the CIM provider appears to be working is to try it in a production simulation using PowerShell.

My tests launched an instance of the work queue service automatically to test their behavior, but PowerShell's going to expect my work queue server to be running, so I will start and run it in the background and will then start a PowerShell session.

Let's start by looking at the classes that exist in the **root/standardcimv2/sample** namespace:

{% highlight powershell %}
Get-CimClass -Namespace root/standardcimv2/sample
{% endhighlight %}

Running this command should show you a list of all of the WMI and CIM objects in the namespace. At the bottom of the list, you should see the **Sample_WorkQueue** class that we defined.

Next, let's try listing the work queues:

{% highlight powershell %}
# This command is split over 2 lines for clarity. Enter it all on
# a single line
Get-CimInstance -Namespace root/standardcimv2/sample
    -ClassName Sample_WorkQueue
{% endhighlight %}

This command should not have any output, and that's to be expected because we have not created any work queues. Let's fix that:

{% highlight powershell %}
New-CimInstance -ClassName Sample_WorkQueue
    -Namespace root/standardcimv2/sample
    -Property @{Name="MyWorkQueue"}
Get-CimInstance -Namespace root/standardcimv2/sample
    -ClassName Sample_WorkQueue
{% endhighlight %}

In the output, you should now see a work queue object named **MyWorkQueue**. The **EnabledState** property should have a value of **3** indicating that the work queue is stopped. Let's start it:

{% highlight powershell %}
$workQueue = Get-CimInstance 
    -Query "SELECT * FROM Sample_WorkQueue WHERE Name = 'MyWorkQueue'"
    -Namespace root/standardcimv2/sample
Invoke-CimMethod $workQueue -MethodName StartService
$workQueue = Get-CimInstance 
    -Query "SELECT * FROM Sample_WorkQueue WHERE Name = 'MyWorkQueue'"
    -Namespace root/standardcimv2/sample
$workQueue
{% endhighlight %}

The first command will query WMI for the work queue object that we created previously. The **Invoke-CimMethod** cmdlet will invoke the **StartService** method on the work queue object to start the work queue. Again, I query WMI for the work queue object. I do this because **$workQueue** is a snapshot of the state of the work queue object when I queried it. **$workQueue** is not updated as the state of the object changes, so I have to requery it. Running the fourth command will dump the **$workQueue** object to the screen. You should see the **EnabledState** property with a value of **2**, indicating that the work queue is running.

For the final test, let's delete the work queue:

{% highlight powershell %}
Remove-CimInstance $workQueue
Get-CimInstance -Namespace root/standardcimv2/sample
    -ClassName Sample_WorkQueue
{% endhighlight %}

The first command will delete the work queue instance from the server. The second command will list the active work queues. Since I deleted my only work queue, there should be no output from the **Get-CimInstance** cmdlet.

Where We Are At and Where Do We Have To Go?
-------------------------------------------
In the first four articles of this series, I defined a set of scenarios that I wanted to achieve, I built a named pipe protocol, created a service for managing work queues, and then created a CIM provider that will allow me to add that management behavior to management tools such as PowerShell or Microsoft SCOM. There's more places where we can take this implementation. In the next post in this series, I will explore the concept of CIM indications. CIM indications are equivalent of WMI events. We can create subscribers that monitor our objects for events in the form of indications, and can operate on those events. In later posts, we can look to build out a more complete object model and add associations between CIM objects.