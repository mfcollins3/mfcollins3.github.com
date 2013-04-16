---
layout: post
title: Introduction to Command-Line Programming
description: We live in a GUI dominated world and we have since
    Windows 3.1 appeared in the early 1990s. For many of us, writing
    console mode programs went out of fashion long ago to be replaced by
    graphical shells and web applications. However, the value of programs
    without user interfaces, that run in console windows or terminals, and
    that accept a variety of command-line options has not diminished. In
    this post, I return to take a look at the world of command-line
    development to see if a former command-line developer can return from
    the world of the web and Windows.
disqus_identifier: 2012-09-21-introduction-to-command-line-programming
author: Michael F. Collins, III
author_first_name: Michael
author_last_name: Collins
author_gender: male
twitter_creator: mfcollins3
modified_time: 2013-04-16
---
I will be presenting at the upcoming Desert Code Camp in November, 2012, at the Chandler-Gilbert Community College campus. I love presenting at Code Camp. Attending it is one of the highlights of my year. I love being around others like me that are enthusiastic about being technologists and computer scientists, and being with people that want to learn from people who want to teach. I love doing both and am very grateful when I get the opportunity to do so.

One of my presentations this year is going to be a bit different from the past. I am not really going to cover new technology, but will instead take a step back to look at the state of command-line development and why command-line programs are too powerful of a tool to be dismissed. Most of this dates back to my career change late in 2011.

If you know me, or follow my Linked-In profile, or talk to other Neudesic folks in the area, then you probably know already that I am no longer the Custom App Dev Practice Director for the Phoenix region anymore. (Nathan Smith now is, by the way, and he will be wonderful at it.) I decided to make a change and leave consulting in my past. I never felt that I was a good consultant. I was proficient at it and consulting did carry me through a good period of my career here in Arizona, but I finally found an opportunity to return to product development and being a product developer. I left consulting and took over the Neuron Enterprise Service Bus product that Neudesic sells.

Making the switch from being a consultant to being a product developer was not an overnight switch, and honestly, it's a continual evolution back. Not having a stable product to work on for the past few years has made me forget some of the tricks-of-the-trade that I could not easily do when I was a consultant because it was outside the scope of the job that I was paid to do. One of the most important tricks is having a good set of administrative or utility programs that I can run to do important tasks for me.

    "What do utilities have to do with command-line programming? You can create utilities with GUIs."*

Yes, that is very true, but GUIs are often too much of an investment and their slow and hard to automate. Utility programs are fast and interactive, they can be scripted, and most importantly they can be combined. Utility programs can be one-offs that require little effort just to get something simple done. They can also be very powerful data processing systems that can crank through a lot of work with little fanfare.

I was honestly having some idea problems for how to present command-line programming at the code camp, but a co-worker posted a link to an article that caught my attention and re-energized my original idea behind this topic. In the online-book [The Art of Unit Programming](http://www.faqs.org/docs/artu/index.html) by Eric Raymond, Mr. Raymond presents the ideals of what differentiates Unix software from the rest of the world. Some of the rules and ideas about Unix software make the great case for what has always been wrong with modern monolithic software development and how the Unix programmers have avoided the same problems. For example:

* **Write programs that do one thing and do it well.** *In the modern application world, I have written very large monolithic applications that did many things, and some of them have not gone so well.*
* **Design and build software to be tried within weeks.** *Some of my applications have gone months without being seen by end users, not necessarily by my choice. But this could also be an indication that some of my products have become too massive too early, leading to an upward battle through quality issues.*
* **Expect the output of every program to become the input to another, as yet unknown program.** *This is a critical idea that we often forget about when writing GUI programs. We put too much logic into these large, monolithic programs, and scale out into distributed systems to push more complex logic server-side. But more often than not, we forget about programs calling other programs, a parent feeding data to a child program, and the parent processing the output of the child. Too often we use threads to do multi-processing and we end up with brittle, inefficient, hard-to-maintain code.*

Features of Command-Line Programs
---------------------------------
Notice that the title of this sections is "features of" and not "advantages of". I feel that it is important to understand that command-line programs are just another option, but are not necessarily better than GUI programs. Command-line programs, if not managed correctly, can become large and monolithic over time as well. It's important that they be managed correctly. In my opinion, these are the features and benefits of good command-line programs:

* **Fast to develop**: If done correctly, command-line programs follow the Single Responsibility Principle. They do one thing and do it well. For example, one command-line program could read a file, or execute a SELECT statement against a database. Because they do one thing, they don't take months to develop. A good command-line program should yield results extremely quickly.
* **Easy to test**: Command-line programs should be extremely easy to test in isolation. Command-line programs should not have dependencies on other parts of your system. When I write about how streams work in a minute, you will understand why. Good command-line programs are easy to test using an automated acceptance testing suite. Good command-line programs can be tested and verified using nothing more than a test editor.
* **Composable**: Command-line programs should be designed to be composable with other command-line programs. This will also be illustrated more when I write about streams below. Basically, the inputs an outputs of multiple command-line programs should be capable of being chained together so that one program can feed another in order to produce a desired result.

As we get deeper into this subject, you will see that command-line programs very nicely fit into the model of object-oriented or component-based software development.

Command-Line Program User Experience
------------------------------------
Command-line programs do have a user experience that needs to be carefully designed, but it is not like a graphical user interface or web user interface. The command-line program user experience can be divided into the following components:

* Command line
* Streams
* Exit code

###Command Line

The command line is the initial user interface to a command-line program. The command line allows the user to control how the command-line program runs and what the command-line program will do. A typical command-line program will follow this syntax for execution:

    > command-name [options] [arguments] [redirection options]

Command-line parameters are broken into the following categories

* **Options**: These parameters enable or disable features, or specify values that control how the command-line program executes. Options usually have a default value that is used if not overridden by the command line.
* **Arguments**: Arguments are objects that the command-line program will operate on. Usually, the order or position of the arguments is important. Arguments will usually be objects such as files or directories, but may also be URLs, strings or text, or other objects.
* **Redirection Options**: These options are used by the operating system or command shell that your program is being called by and will be important when we look at streams down below. For example, you might redirect the program's output to a file so that you can use that file later or view it in a text editor, or you might redirect a file to the input stream for your command-line program.

Options come in two flavors:

* **Short form**: A short form option is usually prefixed by a single dash (-) and has one letter or is a short acronym. For example, '-q' may make a program run silently, or '-v' may output verbose output. '-o=output.txt' may cause the program to output the results of an operation to a file named output.txt.
* **Long form**: Many short form options also have a more verbose long form. Long form options are usually specified with two dashes (--). For example '--quiet' or '--verbose' or '--output=output.txt'.

The obvious advantage for advanced users is that the options are short and sweet. But longer options do have great value as well in documenting specifically what purpose an option may have. Not all short options are required to have long forms, but most typically do. Not every long option needs to have a short option. This makes sense because you probably want to save the short options for those options that will be used more often by advanced users in order to shorten the text that they are required to type.

Arguments come after options in the command line and the position of the arguments is important for some commands. A command that reads and processes files will typically accept a list of files as arguments and will process the files in the order that they appear. But other commands like **copy** on Windows or **cp** on Unix will copy the file identified by the first argument to the file identified by the second argument. Arguments do not need to be limited to just files or directories. They could be search filters, such as "*.dll" or "*.txt", or they could be URLs. For example, if I wanted to execute an HTTP request to download the content from [NBCNews.com](http://www.nbcnews.com), I may specify "http://www.nbcnews.com" as an argument.

I will discuss redirection in the next section.

### Streams

When planning for command-line programming, streams are probably the most important part of the program's interface and the one that requires the most planning. Streams are how users will interact with your program while it is running, and how other programs will be composed with your command line program to create a working system.

Composability is a big requirement for command-line programs. You must design your application with the assumption that it will be used both by human users and other programs. Other programs may not necessarily be command-line programs. Graphical user interfaces or web applications also consume command-line programs. For example, do you use a GUI interface or the [GitHub](http://www.github.com) client for Windows or Mac when interacting with your GitHib repositories? In this case, you are using GUIs that are executing Git's command-line programs and interacting with Git through streams.

What are streams? Streams are basically a one-way pipe that flows data in some direction. You probably have used streams to write text to the console, read or write data to files, or read or write data to the network. Most streams are binary in nature, but can carry textual data as a stream of bytes.

Every application, whether a command-line application or a GUI, is automatically given three streams by the operating system:

* **Standard input**: Standard input is a one-way stream that sends data to the program. By default, standard input will be associated with the keyboard or other primary input device for the computer. Standard input is usually abbreviated as **stdin**.
* **Standard output**: Standard output is a one-way stream that carries data from the program to an output device. By default, standard output will be associated with a text-based console or terminal such as the Command Prompt on Windows or a shell such as Bash on Unix. Standard output is usually abbreviated as **stdout**.
* **Standard error**: Standard error is also a one-way stream that carries diagnostic information from the program to an output device. Standard error is also usually mapped to the console or terminal that the program was run from. Standard error is usually abbreviated as **stderr**.

Why are there two output streams? The reasoning behind it goes back to the days before modern compiler tools, but is still very applicable today: tracing and logging. Programs need to output diagnostic information both at development time and runtime, and good programmers put lots of logging information into their code. If you have not noticed by now, development environments are much different than production environments and software that works well on one computer may not work well on another. By having two output streams, developers can use **stdout** to write the output that will be consumed by the user or other programs, and can write diagnostic information to **stderr**.

Do not let stderr or the name *standard error* fool you. The stderr stream can be used for more than writing out errors. Any tracing or logging that you output from your command-line program, or basically any output such as a copyright statement that should not be consumed by other programs should be written to stderr instead of stdout. Most consoles or terminals will consume from both streams and will output the content to the console in the order it is received from either stream.

Earlier when I was introducing the streams, I also told you by default what the streams were attached to. This is important because streams can be redirected to other sources or targets. For example, if you were to give me a file containing names, addresses, and telephone numbers, I would still probably write the command-line program to read the records from that file using stdin. The reason for doing that is that during development I can test by typing random records directly into the program from my keyboard and I can probably have a reasonable expectation that if my program works against manually-entered records, it will work equally well against a file that contains the same format. In order to get my program to process the records in the file that you have given me, I will redirect stdin from the keyboard to the file:

    > readrecs < records.txt

I might write a program that will read a file containing a set of unsorted records, sort the records by name, and then output the records to a new file. Again, I would still write the command-line program to read from stdin and write to stdout, but I will redirect stdin to be from the source file, and redirect stdout to write to the destination file:

    > sortrecs < records.txt > sortedrecords.txt

The above command, when it executes, will overwrite sortedrecords.txt if that file already exists. Instead maybe the problem is that I want to filter records instead of sort them. If you give me 100 files of records containing sales leads that you want me to filter and you only want one file in return containing all of the filtered records, I can run my program on each source file and append the filtered records to an existing file (the file will obviously be created when the program runs for the first time):

    > filterrecs < records001.txt >> filteredrecords.txt

In the above command, input will come from records001.txt, output will go to filteredrecords.txt, and errors/tracing/log messages will still be written to the console. What happens if I want to save the stderr output to analyze later after the program runs? I can redirect stderr as well using a different syntax:

    > myprogram 2> log.txt

This will write any output that is written to stderr to a file named log.txt.

Why is the redirection "2>"? The answer is that the number is the file descriptor or file handle for the standard streams. I could redirect stdin, stdout, or stderr to any stream or file handle if I know the identifier. Typically you won't do this directly on the command line, but your programs will use this if they spawn other programs and want to intercept the input, output, or error output of the child program. The identifiers for the standard streams are:

<table class="table table-bordered">
	<thead>
		<tr>
			<th>Identifier/Handle</th>
			<th>Stream</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td>0</td>
			<td>Standard input (stdin)</td>
		</tr>
		<tr>
			<td>1</td>
			<td>Standard output (stdout)</td>
		</tr>
		<tr>
			<td>2</td>
			<td>Standard error (stderr)</td>
		</tr>
	</tbody>
</table>

Using the stream identifier, I can also redirect stderr to write out to the same location that stdout does:

    > myprogram 2>&1

This redirection will redirect any output written to stderr to stdout.

The order of where the redirections are specified is also important. Look at the following command line and tell me what you think where the outputs will appear when the program runs:

    > myprogram 2>&1 > output.txt

Where will the data written to stderr appear?

If you guessed that stderr will write to output.txt, you are incorrect. The data written to stderr will be written to stdout and will appear on the console. The data written to stdout will be sent to output.txt. Why is this?

The answer is that the redirection applies to the value of the streams at the time that the redirection occurs. Because we redirected stderr to stdout first, the operating system or shell looked at what the value of stdout was at the time the redirection was evaluated. In this case, stdout was pointing to the console. After stderr was redirected, stdout was then redirected to output.txt.

What happens if we run this command?

    > myprogram > output.txt 2>&1

In this case, stdout gets redirected first to output.txt, and then stderr will also get redirected so that output written to stderr will be written to output.txt as well. This happens because when the stderr redirection is evaluated, stdout has already been redirected.

Another redirection that you will commonly see is what is called a pipe and is typically represented using the pipe symbol (|). A pipe is used to redirect the output of one program to the input of another.  For example, if I wanted to filter a set of records and then sort the filtered records by name to produce my final list of records, I can *pipe* the output of my **filterrecs** program to the input of my **sortrecs** program to get back the list of sorted, filtered records:

    > filterrecs < rawleads.txt | sortrecs > qualifiedleads.txt

In this command, I am using both a pipe and redirects. I am redirecting stdin to read from rawleads.txt. The input records are read by **filterrecs** and the filtered records are written to stdout. The stdout stream for **filterrecs** is *piped* to the stdin stream for **sortrecs**. The **sortrecs** program will read the filtered records and will write the sorted records to the stdout stream for **sortrecs**. The stdout stream has been redirected to write to the qualifiedleads.txt file.

For a real-world example of piping output of one program to the input of another, try this command in a large directory in a Windows console window:

    > dir C:\Windows | more

In this example, I am redirecting the output of running the **dir C:\Windows** command to the **more** command so that I can page through the output of the **dir** command.

Streams, redirection, and pipes are fundamental to command-line programming because they allow composition. Steams and pipes allow the outputs of one program to be used as the inputs of another. Redirection is important when you get to batch programming because the outputs of one program can be written to a temporary file that will be used later in a batch script to run another program. That is a topic that we will look at in a later post.

###Exit Codes

The final user experience aspect of a command-line program is what we call the **exit code**. The exit code is typically an 8-bit value between 0 and 255 that indicates if the program completed successfully. Usually, if the program ran successfully, the exit code will be 0. If an error occurred, the exit code will be a value between 0 and 255.

When running a command-line program from a console window manually, exit codes will not be so important. But when you combine multiple command-line programs into a batch script, exit codes are how you will determine if an error occurs during batch processing.

When composing command-line programs with other programs, the exit code is also critical in alerting the parent program that a problem occurred. For example, if a GUI shell executes a command-line program to perform an administrative function such as creating a user account, the command-line program can return a non-zero exit code to alert the GUI shell that the user cound not be created and the GUI shell should display an alert of message box. Exit codes are how command-line programs report exceptional conditions to their parents.

Exit codes are program-specific. There is no standard table of error codes and what they represent. It is up to each developer to design and document that as part of their interface. For example, with the administrative program that I just used as an example above, the exit codes might look like this:

<table class="table table-bordered">
	<thead>
		<tr>
			<td>Exit Code</td>
			<td>Description</td>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td>0</td>
			<td>The user was created.</td>
		</tr>
		<tr>
			<td>1</td>
			<td>Unable to connect to the database.</td>
		</tr>
		<tr>
			<td>2</td>
			<td>A user already exists with that name.</td>
		</tr>
		<tr>
			<td>3</td>
			<td>The user name contains invalid characters.</td>
		</tr>
		<tr>
			<td>4</td>
			<td>The password is not strong enough.</td>
		</tr>
		<tr>
			<td>5</td>
			<td>The email is already in use by another user.</td>
		</tr>
		<tr>
			<td>6</td>
			<td>The user was created, but will have to change his password when he logs in for the first time.</td>
		</tr>
		<tr>
			<td>7</td>
			<td>The user was created, but will have to be approved before he can log in.</td>
		</tr>
	</tbody>
</table>

As you can see with exit code 6 and 7, a non-zero exit code does not always have to indicate an error. This is why it is important to document the exit codes for anyone who will consume your command-line program.

Testing Command-Line Programs
-----------------------------
Earlier in this post, I mentioned three features of command-line development. I showed you using pipes and redirection how command-line programs can be composed with other applications, and in future posts I will demonstrate more of that by showing you actual command-line applications. I will also show you how fast they can be to develop. But what I have not covered significantly yet is how easy they are to test. I will discuss testing strategy more for each command-line program that I demonstrate in future posts, but I will just mention a little bit about testing now.

Command-line programs should be designed so that they are easy to test. This should be possible even for programs that are not meant to be run by themselves but are instead designed to be composed with other programs. For example, the **more** command-line program is designed to accept input from another program. It does not make sense to be used without an input source. But just as **more** needs an input source, it can be easy to test when used standalone.

Because command-line programs make use of the standard streams for input and output, command-line programs should be testable just by entering information manually by typing on the keyboard and seeing the results visually appear in the console window. Command-line programs can also be tested by redirecting stdin to a test input file and redirecting stdout to a test output file, and then comparing the test output file against a file containing the expected results.

Command-line programs should be testable individually without needing to be composed with other programs. Command-line programs may need other infrastructure such as a web service or database to communicate with, however.

Most importantly, command-line programs should as much as possible be designed around a text protocol. Input to a command-line program should be something that a developer, tester, or user could type by hand if necessary. If possible and unless absolutely necessary, do not design a command-line program to expect or require binary input or output in order to succeed. If you need to pass binary objects into our out of a command-line program, create options or use arguments to pass the file name of a binary input file or the file name of a binary output file to the command-line program.

Design for Extensibility
------------------------
One parting thought on command-line programs that you should always keep in mind. Design command-line programs to be composed into or used by other programs. Do not expect that only human users will be using your program. Document the input and output formats and design in a way that creating inputs for your program or consuming outputs is easy. (Standard error is treated differently, and you can assume that output written to stderr is intended for human consumption, although the output from stderr can be processed further or displayed in a GUI shell, for example.)

You should also make no assumptions about how your program will be used in the future. This is why it's important to observe the [Single Responsibility Principle](http://en.wikipedia.org/wiki/Single_responsibility_principle) when designing your program: *do one thing and do it well*. Don't design your program to do two things. If you need to do two things, write two programs and pipe the output of one to the input of the other. Design your program specific enough to do its job, but generic enough so that the job that your program does do can be composed into a greater workflow or easily re-used for another purpose.

Also do not expect that your command-line program will be used by any specific technology. For example, I will demonstrate in a later post calling a command-line program that I wrote in C# and .NET being called by a JavaScript application running in [Node.js](http://nodejs.org). Expect that your program will be usable by many different technologies. Note that this does not mean that your program needs to be portable to different operating systems. Indeed, some of the demonstrations that I will show in later posts are written in .NET and intended to be run on Windows, even though the command-line programs are consumed by more "portable languages" such as JavaScript/Node.js, Ruby, or Python. Composing systems from programs written in different languages or using different technologies is also why a text-based protocol for stdin and stdout is important, because nothing is more portable or easily consumable as raw text.

Conclusion
----------
We came a long way in this post, and hopefully I have set you up with the basics for where I intend to go with this subject matter. In later posts that will be coming over the next few days, I will show off real examples of command-line programs that make use of much of the information that I introduced to you here.

What we learned are that command-line programs still have a valuable place in the modern web/GUI world. But just like web or GUI applications, command-line programs require design and planning. Command-line programs have a standardized interface using options and arguments. Command-line programs make use of three standard streams: standard input (stdin), standard output (stdout), and (stderr). Command-line programs can also report errors, warnings, or other informative status through exit codes. Finally, command-line programs should be designed so that they can be composed into other applications, batch scripts, or used by GUI or web applications.

If you live in the Phoenix region, or will be visiting for Desert Code Camp on November 17, 2012, please join me for this presentation and bring your questions. I hope to see you there.