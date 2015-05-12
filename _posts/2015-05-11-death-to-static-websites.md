---
title: Death to Static Websites
cover_photo: landfill.jpg
javascript: staticapp
disqus_identifier: 2015-05-11-death-to-static-websites
---
All too often, web developers start a web application or website with
a framework like Express, Rails, or ASP.NET MVC. For a time, they were
necessary, but their time and usefulness is quickly expiring. In this
post, I will make the argument for why you should not use these
frameworks for the next great web application and instead use simpler
websites based on a mix of static and dynamic HTML and web APIs.

<!--more-->

This isn't my first blog. This blog has been my home since 2012 when I
learned about GitHub Pages and decided to give it a try. Previously,
I have tried [WordPress](https://wordpress.com),
[BlogEngine.NET](http://www.dotnetblogengine.com), and others. They
worked fairly well, I blogged happily for a while, then I eventually
stopped using them. While they were great as blogging engines and I
was a successful blogger, I determined that being a successful blogger
was not all that I wanted.

The problem, I determined, was that the blog engines were all
successfully built on various web technology. WordPress is a lot of
PHP, a language that I don't know that well. I could probably learn it
if I put the effort in, but to date I haven't had much of a need to
learn PHP. BlogEngine.NET was built on .NET, which pays my bills on a
daily basis. But my problem with BlogEngine.NET was that I had a hard
time diving into the code to learn how it works and I didn't want to
put in the effort to make changes that I wanted to make to fill the
holes that I perceived that the blog engine had.

I also tried big content management systems like [Umbraco](http://umbraco.com).
I was very successful with Umbraco and I liked the flexibility that it
gave me, but in the end, changing or getting into the mindset of
contributing to the core development, I decided that I just didn't have
the time. I wrote a few extensions, but I just didn't want to build
older-style ASP.NET applications. I was more into MVC at the time.

What I liked about GitHub Pages was the framework. [Jekyll](http://jekyllrb.com)
is a Ruby application that produces static websites given basic
content. The static website is then uploaded and hosted on GitHub's
web servers. At first, the *static website* feature worried me, but
I found freedom and satisfation creatively in my blog because there
was not much there except for generating static content. It was easy
to produce blog posts using Markdown, which I appreciated. I no longer
needed a special editor like Windows Live Writer to write my posts and
upload them to the blog site. A simple text editor will do.

Creatively, I liked that although I was still using Jekyll, the entire
website was my creation. I defined the HTML structure. I defined the
CSS. I didn't have to fit into the constraints of an existing
framework. I could choose to use other frameworks like
[Bootstrap](http://getbootstrap.com) if I wanted to. I could use tools
like [Less](http://lesscss.org). I could tinker and play with the
website and make it an invention of what I wanted it to be, which was
very exciting for myself creatively.

The part that worried me was the *static* part of static websites on
GitHub Pages. I worried that I was going to miss things that I could
do in a server-side application that I couldn't do in a static website.
I worried that I would feel limited by the client-side only approach
to developing. But fortunately, technology caught up in the form of
newer web browser features and those concerns became less of an issue
over time.

The modern web is in a wonderful place. We have excellent web browsers
that are constantly pushing the envelope in making web applications
more feature rich by the day. The Internet speeds are very fast and
getting faster as cable providers are introducing gigabit Internet
speeds to homes and businesses. Mobile browsers are exceptional. There
are modern frameworks that make creating responsive applications so
incredibly easy. It's no longer necessary to run a separate mobile
website to accommodate devices such as iPhones or iPads.

Another great technology that I feel is just starting to see its
potential is something call [Cross-Origin Resource Sharing](http://en.wikipedia.org/wiki/Cross-origin_resource_sharing)
or CORS. If you're not familiar with CORS, it's a mechanism for client
side code from a website to safely invoke web service APIs from another
service accessible over the Internet. It is meant to obsolete and
replace technologies such as JSONP that allowed JavaScript code to be
injected into web pages dynamically at runtime.

CORS is an extension to the HTTP protocol that allows a web service to
indicate if a client appliation is authenticated and allowed to make
HTTP requests to the web service's APIs. Most importantly, CORS is
supported by all major web browsers.

The great thing about CORS is that CORS makes static websites not so
much static anymore. Using simple cloud technologies, static websites
are just as capable as their server-generated peers, but might just be
a bit easier and more flexible to develop.

An Example
----------
With a little bit of CORS magic, I am going to accomplish a first for
me: I am going to turn a blog post into an actual web application. This
blog post is hosted by [GitHub Pages](http://pages.github.com) and the
page that you are reading now was generated using Jekyll. The original
content was written in Markdown with a few HTML elements thrown in. You
can see the code for the post in my public repository at
https://github.com/mfcollins3/mfcollins3.github.com.

The web application that I am going to build is just going to be a
simple form that accepts your name. When you enter your name and press
the submit button to submit the form, client-side JavaScript will
execute in your web browser that will invoke a CORS-enabled web API
that will simply return a welcome message to you. The welcome message
will then be displayed in the form. For full disclosure, I am going to
use [jQuery](http://jquery.com) to implement the client-side form
application. I will also be using [CoffeeScript](http://coffeescript.org)
to write the source code for the web application. I use
[Grunt](http://gruntjs.com) to build the website before I publish it to
my GitHub repository, and I will use Grunt to transform the
CoffeeScript source code into JavaScript.

Here's the web application:

<form id="example-app">
  <div class="form-group">
    <label for="firstName">First name</label>
    <input type="text" class="form-control" id="firstName" name="firstName" placeholder="Enter your first name" required>
  </div>
  <div class="form-group">
    <label for="lastName">Last name</label>
    <input type="text" class="form-control" id="lastName" name="lastName" placeholder="Enter your last name" required>
  </div>
  <button type="submit" class="btn btn-default">Submit</button>
</form>
<div class="alert alert-success hidden">
  <p id="welcomeMessage"></p>
</div>

The source code for the form is below:

```html
<form id="example-app">
  <div class="form-group">
    <label for="firstName">First name</label>
    <input type="text"
           class="form-control"
           id="firstName"
           name="firstName"
           placeholder="Enter your first name"
           required>
  </div>
  <div class="form-group">
    <label for="lastName">Last name</label>
    <input type="text"
           class="form-control"
           id="lastName"
           name="lastName"
           placeholder="Enter your last name"
           required>
  </div>
  <button type="submit" class="btn btn-default">Submit</button>
</form>
<div class="alert alert-success hidden">
  <p id="welcomeMessage"></p>
</div>
```

The application is simple. The user will enter a first name and a last
name into the form, then press the Submit button. This will execute the
JavaScript (or CoffeeScript) code that is behind the form to submit the
user's name to the web service, and the welcome message will be
returned. When the welcome message is returned, the message will be
output to the `welcomeMessage` paragraph element.

Here is the CoffeeScript code that reacts to the form and calls the
remote web service:

```coffeescript
$(document).ready ->
  $('#example-app').submit (event) ->
    event.preventDefault()
    userData =
      firstName: $('#example-app input[name=firstname]').val()
      lastName: $('#example-app input[name=lastname]').val()
    $.ajax
      url: "https://michaelfcollins3.herokuapp.com/sayhello"
      type: "POST"
      data: JSON.stringify userData
      contentType: "application/json"
    .done (data) ->
      console.log data
      response = JSON.parse(data)
      $('#welcomeMessage').text response.greeting
      $('#welcomeMessage').parent().removeClass "hidden"
    .fail (xhr, status, err) ->
      console.log err
```

When the form is submitted, the code will intercept the submit event
for the form. The event handler will capture the first name and the
last name that were entered into the form and will create a new
JavaScript object containing those values. The event handler will then
use jQuery to send an HTTP POST request to the web service that is
hosted at https://mfcollins3.herokuapp.com/sayhello, passing the
JavaScript object as a JSON object. When the call is successfully
handled, the `done` handler will be invoked which will store the
welcome message in the `welcomeMessage` HTML element.

To complete this solution, I need a web service. For this example, I
am going to build the web service in [Go](http://golang.org) and will
host the web service in a Heroku application.

Here is the source code for the web service:

```go
package main

import (
  "bytes"
  "encoding/json"
  "fmt"
  "io/ioutil"
  "log"
  "net/http"
  "os"
  "strings"

  "gitub.com/rs/cors"  
)

func main() {
  port := os.Getenv("PORT")
  log.Println("Listening on port ", port)

  http.Handle("/sayhello",
    cors.Default().Handler(http.HandlerFunc(sayHello))
  log.Fatal(http.ListenAndServe(":"+port, nil))
}

type welcomeRequest struct {
  FirstName string `json:"firstName"`
  LastName  string `json:"lastName"`
}

type welcomeResponse struct {
  Greeting string `json:"greeting"`
}

func sayHello(w http.ResponseWriter, r *http.Request) {
  body, err := ioutil.ReadAll(r.Body)
  if nil != err {
    log.Println("ERROR: ", err)
    http.Error(w, err.Error(), http.StatusInternalServerError)
    return
  }

  var request welcomeRequest
  err = json.Unmarshal(body, &request)
  if nil != err {
    log.Println("ERROR: ", err)
    http.Error(w, err.Error(), http.StatusInternalServerError)
    return
  }

  var response welcomeResponse
  response.Greeting = fmt.Sprintf("Welcome %s %s!", request.FirstName,
    request.LastName)
  data, err := json.Marshal(request)
  if nil != err {
    log.Println("ERROR: ", err)
    http.Error(w, err.Error(), http.StatusInternalServerError)
    return
  }

  _, err := w.Write(data)
  if nil != err {
    log.Println("ERROR: ", err)
    http.Error(w, err.Error(), http.StatusInternalServerError)
  }
}
```

Now give it a try. Go back to the form and enter your name or someone
else's name. When you click on the submit button, the reqeust will be
sent to the web server running in Heroku and a response will be
returned. If you are using Google Chrome, open the Developer Console
and watch the web request be sent. My static website now has the
ability to display dynamic content, and no server-side framework such
as ASP.NET MVC or Rails was used. Everything was rendered in the web
browser, and a web API on a remote server performed data manipulation
for my website.

Why I Like Static Websites
--------------------------
I demonstrated that using CORS, JavaScript, and a web API, I could add
a bit of dynamic functionality and processing to an otherwise static
website. Why is this important? Why would I still not use something
like ASP.NET, Express, or Rails to build a website or web application?

The answer is that you can, but it's not fully necessary in a lot of
circumstances. If you have a mostly static website, say a corporate
website, that has a few interactive features such as a contact form
or a career application that is part of your website, you don't need
to use a complex framework like ASP.NET MVC that relies on server-side
rendering. All of this can be achieved on the client.

When you utilize client side features using JavaScript and HTML, you
effectively have a static website. The advantages of a website built
with client technologies and supported by a web API is some very cool
deployment options.

For example, if you have mostly static content with dynamic content
that is driven with JavaScript on the client, you can use cheap cloud
technologies such as Amazon Web Service's S3 service for storing and
serving your website. There is no need to run a web farm on the
Internet. You only need to pay for the storage fees for storing your
website content and the bandwidth for serving the content. S3 makes a
great container for hosting websites.

The second great advantage is CDN deployment. A CDN, or content
delivery network, is a set of edge servers that are deployed around
the world. By combining AWS CloudFront with S3, you can increase the
speed at which your website is downloaded by serving your content from
the CloudFront edge servers around the world. Your website will appear
faster and more response for your customers and users no matter where
the user is located.

A third great advantage is SSL. Google and other search engines are
starting to provide search optimization points for websites that are
served via SSL. If you use server-side technologies and use a cloud
hosting service to serve your website, you may have issues or extra
costs for serving SSL content and associating a custom domain with
your website. With Amazon CloudFront, you don't have those costs. You
can associate a domain with your S3 buckets and CloudFront edge
locations, and you can also associate an SSL certificate with the
CloudFront servers, all at no additional cost.

What We Learned
---------------
The goal of this post has been to make an argument that using modern
web technologies including JavaScript and CORS, static websites do not
have to be so static and websites that traditionally needed complex
server-side architectures may not necessarily need them anymore. Thanks
to advances in JavaScript and CORS for calling web APIs from web
browsers, services that required technologies such as ASP.NET MVC or
Express can now be accomplished using pure web technologies.

The source code for my GitHub Pages website and the web API are
accessible on [GitHub](https://github.com/mfcollins3):

* [Website](https://github.com/mfcollins3/mfcollins3.github.com)
* [API](https://github.com/mfcollins3/website-api)

Please feel free to refer to them as you explore on your own.

<div class="cover-photo-credit">
Photo credit: <a href="https://www.flickr.com/photos/colind13/5178193721/">ColinD13</a> / <a href="http://hamptonpatiofurniture.com">Source</a> / <a href="http://creativecommons.org/licenses/by/2.0/">CC BY</a>
</div>
