---
layout: post
title: Introduction to ZeroMQ
description: I will be presenting to the Phoenix Connected Systems User Group on November 7th, 2012. The topic will be an introduction to ZeroMQ. In this post, I will describe a little about ZeroMQ and tell you what you will be seeing in my presentation.
disqus_identifier: 2012-10-22-introduction-to-zeromq
categories:
- ZeroMQ
tags:
- zeromq
- zmq
author: Michael F. Collins, III
author_first_name: Michael
author_last_name: Collins
author_gender: male
twitter_creator: mfcollins3
modified_time: 2013-04-16
---
Messaging is big on my research list right now, and that probably has to do a lot with my day job. Spending my days and weeks and months (and almost one year!) in the guts of Neuron has brought me back into the world of message-oriented middleware pretty heavily. From dealing with MSMQ to now dealing with AMQP, I have been reminded why messaging is an important technology and sorry that I have not used it as much on past projects.

I have not done a lot of community service this year. I did one presentation to the [Northwest Valley .NET User Group](http://nwvdnug.org) on Orchard, but beyond that I have been pretty quiet on the presenting and public speaking front. I have a lot planned for November, starting with the [Phoenix Connected Systems User Group](http://www.pcsug.org) on November 7th, 2012, followed by [Desert Code Camp](http://www.desertcodecamp.com) on November 17th, 2012.

My upcoming presentation to the PCSUG is titled **Introduction to ZeroMQ**. [ZeroMQ](http://www.zeromq.org) is an extremely interesting technology that was created by [iMatix Corporation](http://www.imatix.com). I believe that iMatix was one of the original participants in the AMQP specification, but became disenchanted with the process, and splintered off. The end result of their leaving the AMQP working group was the creation of ZeroMQ.

Unlike other messaging software that I have used, ZeroMQ is not a server. It is a library. It is also a highly portable library that has been adapted to most major programming languages in use today. For example, using ZeroMQ, I can send messages between .NET, C, node.js, Python, Ruby, C++, Erlang, Java, and programs written in many other languages. ZeroMQ is also very flexible. I can use ZeroMQ to exchange messages within different parts of a single program, send messages between processes, or even send messages between computers.

ZeroMQ also supports several different message exchange patterns. ZeroMQ has built-in support for request-reply messaging or can perform unidirectional messaging using the point-to-point or publish-subscribe patterns. It is also very easy to create more advanced messaging systems by combining the socket types and message exchange patterns supported by ZeroMQ. For more information on what you can do with ZeroMQ, check out their [wonderful guide](http://zguide.zeromq.org/page:all).

I have started to post my samples for the upcoming presentation. If you are interested now and do not want to wait until November 7th, please feel free to start checking them out. They are posted on GitHub [here](https://github.com/mfcollins3/PCSUG-Nov2012), and there is also a GitHub Pages website where I will be posting my slides and other supplementary material [here](http://www.michaelfcollins3.me/PCSUG-Nov2012).

I hope to see you on November 7th if you are able to attend.