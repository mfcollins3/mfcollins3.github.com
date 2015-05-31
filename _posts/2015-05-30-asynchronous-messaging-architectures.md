---
title: Asynchronous Messaging Architectures
cover_photo: messaging_architecture.jpg
disqus_identifier: 2015-05-30-asynchronous-messaging-architectures
---
Software architectures are full of opinions. They are usually the
result of one person's bias towards a specific technology, or a
specific approach to developing software. Sometimes software
architectures are the result of reading something in a book or seeing
something in a video and believing that it's the answer to the world's
problems. In this post, I'll share my opinion, and my desired
architecture for my own softare.

<!--more-->

Being the lead developer on the [Neuron ESB](http://www.neuronesb.com)
product for the last 3-and-a-half years, I've definitely learned a lot
about modern enterprise architectures. Before working on Neuron as a
consultant, I definitely built some very complex monolithic systems. I
never really thought about message queuing or aynchronous tasks.
Everything was implemented to happen right away. All work happened
within the lifetime of a single request on the server.

So after my experience (or during, as that experience is still
ongoing), I've definitely become more appreciative of messsage-based
architectures. In these architectures, you make use of a queuing system
and queuing patterns to distribute work across multiple components.
Message-based architectures are also very useful for just sending event
notifications between different systems. But my favorite aspect of
message-based architectures is how they open up a system to better
handle extension and evolution over time. Different pieces of the
solution can be changed and removed or added just by connecting to the
message bus. New events can be created. New work can be composed with
existing work. Basically, good things can happen.

If I were ever to leave Neuron ESB to work on another product or
project, or when I develop my own applications moving forward, I am
definitely going to include a message bus in them. With microservices
finally catching on and systems becoming much more distributed in the
Amazon and Azure clouds, a message bus is necessary for building
scalable and efficient applications.

Let's look at a message-based architecture for a public website, which
I actually am building. This website will actually be live and will be
for a real company; a small software development company that I am
starting Naked Coders. Naked Coders website will be hosted at
[https://nakedcoders.io](https://nakedcoders.io), and will be hosted
using [Amazon Web Services](aws.amazon.com) and
[Heroku](https://heroku.com). Heroku will host the application
components, but since Heroku exists inside Amazon's cloud,
applications running on Heroku can take advantage of Amazon's cloud
services as well.

<image class="img-responsive center-block" src="/images/website-architecture.png" alt="Naked Coders website architecture">

The initial architecture for the Naked Coders website has three
components. The website itself will be mostly static content or dynamic
content driven by JavaScript. The website will be pre-generated using
Jekyll. The website will be hosted as a static website using Amazon Web
Services's S3 service. S3 is a cheap service that supports being used
as a web server for static websites that are publicly accessible.
However, when people browse the website, they won't actually be going
directly to S3. What I am instead is using AWS's CloudFront service to
serve the actual content. CloudFront is a content delivery network that
is operated by Amazon Web Services. CloudFront operates edge servers
all around the world and will cache my website's content local to where
users are accessing the Internet in order to speed up the website
experience. CloudFront also allows me to associate a custom domain name
and an SSL certificate for the website.

For dynamic functionality or behavior that needs to run on the server
and not in the web browser, I'm implementing an application server with
a web API that JavaScript in my website will call to perform actions.
The API server will be written in Go and will be hosted on Heroku.

Finally, I am going to introduce a RabbitMQ broker into the
architecture. The API server will generate events that will be
published to the RabbitMQ broker. At the moment, there's not gong to be
anything listening to events, but that will change as I build out the
website. But as I'm implementing features, I'll identify what those
events are and might implement something to actually process the
events. For the time being, I'll publish events and those events will
be quietly discarded by the RabbitMQ broker. In the future, I'll add
something to RabbitMQ so that messages are not discarded, but moved to
an error queue that I can monitor and review for errors.

RabbitMQ defines two entities for messaging: exchanges and queues.
Messages are published to exchanges, and then exchanges route the
messages to queues. Subscribers or receivers will read messages from
queues, and messages are stored in queues in the order in which the
messages are received from exchanges.

RabbitMQ has four types of exchanges:

* **direct**: messages are routed to queues based on a routing key. The
  routing key on the message must match the routing key that was used
  to bind the queue to the exchange. The default exchange uses the name
  of the queue to route messages to a single queue.
* **fanout**: fanout exchanges implement a typical publish-subscribe
  pattern. When a message is published to a fanout exchange, the
  message is routed to all queues that are bound to the exchange. This
  is also known as a broadcast pattern.
* **topic**: topic exchanges implement the fanout pattern but use the
  routing key to determine which queues should receive the message.
  When queues are bound to exchanges, rules are added to the binding to
  indicate what messages the queue is interested in receiving from the
  exchange based on the routing key of the message. When a message is
  published to the exchange, the routing key is compared to the binding
  rules to determine if the message is delivered to the queue or not.
* **headers**: header exchanges are similar to topics, but instead of
  delivering messages based on the routing key, messages are delivered
  based on the values of one or more headers in the message.

For the website, I'm going to start off using one exchange that is a
topic exchange. I will specify the kind of message being published to
the exchange as the routing key, and I will subscribe queues to the
exchange to receive different kinds of events.

<img class="img-responsive center-block" src="/images/website_exchange_queue.png" alt="Website exchange and queues">

In my next post, I'll build out my first feature, user registration,
and I will demonstrate publishing my first events to my RabbitMQ
server.

<div class="cover-photo-credit">
Photo credit: <a href="https://www.flickr.com/photos/smithsonian/2550229291/">Smithsonian Institution</a> / <a href="http://foter.com/">Foter</a> / <a href="http://flickr.com/commons/usage/">No known copyright restrictions</a>
</div>
