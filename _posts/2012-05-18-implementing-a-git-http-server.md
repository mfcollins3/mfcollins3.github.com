---
layout: post
title: Implementing a Git HTTP Server
description: In this post, I will look at the Git smart HTTP protocol and will demonstrate how to create a web application that can host and serve Git repositories to users. Demonstrations will be shown using Node.js.
disqus_identifier: 2012-05-18-implementing-a-git-http-server
author: Michael F. Collins, III
author_first_name: Michael
author_last_name: Collins
author_gender: male
twitter_creator: mfcollins3
modified_time: 2013-04-23
categories:
- Git
category_names:
- Git
tags:
- git
---
Introduction
------------
In this post, I will look at the Git smart HTTP protocol and will demonstrate how to create a web application that can host and serve Git repositories to users. Demonstrations will be shown using Node.js.

<!--more-->

GitHub is a marvelous website and I use it almost every day. It's great that we
have GitHub to complement Git, which has quickly become one of my favorite
development tools, and hands down my favorite version control system for
project management. However, as good as both are, they both have issues that
affect my use of them at work.

First, not everything that I write is open source and can be hosted on GitHub.
For my professional work, I need to ensure that my clients have access to the
source code that I am writing for them. I also need to ensure that their
intellectual property is stored confidentially. Sure, I could always pay to
host their source code in a private account on GitHub, but sometimes customers
just do not want to go there, especially if they do not understand the
technology.

Second, there are programs that I write for internal use within Neudesic, or
projects that I would like to work on internally. I wish that I could have a
GitHub-like website hosted someplace on the company intranet that works like
GitHub, but there are not a lot of options out there. There is the GitHub
option, but it's rather pricey for the enterprise edition of it and getting
the commitment to spend that much money annually has not happened yet.

Third, I need a true intranet application. This means that users need to be
authenticated against my company's domain server. It also means that I need Git
to be hosted and running on a Windows server. Since we are a Microsoft partner,
this is pretty critical. So far, Git does not have a great reputation running
on other web servers besides Apache, which I would prefer not to run if I could
help it.

What I really want is something similar to GitHub that I can use to facilitate
collaboration between myself and my peers, and that I can place on my
company's intranet. Since I don't see anything out there that I can readily
use, I am going to look into my own programming skills to figure out if I can
build it myself.

I started this project a couple of months ago when I first posted my GitHub
Pages website and I did have limited success. I was able to write a simple
Git server using Node.js and it worked great on my Mac and on an Ubuntu Linux
VM, but the server failed miserably under Windows. Fortunately, persistence has
paid off an I was finally able to get my Git server to work in a Windows
environment inside of IIS. In this post, I will tell you what I did to make
that work.

Understanding the Git HTTP protocol
-----------------------------------
My overall goal with this project is that I want to start "dogfooding" my
hosted Git solution as quickly as possible. I want to publish this solution
on my company's intranet so that others can start helping me to build new
features for the site and it can become better. I identified five operations
that are critical initially towards facilitating collaboration:

1. Push the initial change set from my local repository to the project
   repository.
2. Clone the project repository.
3. Push change sets from my local repository to the project repository.
4. Fetch change sets from the project repository.
5. Pull change sets from the project repository.

I listed #1 and #3 separately because I'm not sure if the protocol is different
for a new repository versus an initialized repository. For now, I will be
creating the hosted project repository manually. Also, I will not be enforcing
authentication initially. I will add those features into the service later.

Now it is time to jump in and start understanding the communication that
happens between a Git client and a Git HTTP server. Fortunately, Git is open
source and I can utilize the source code for the [git-http-backend](https://github.com/git/git/blob/master/http-backend.c)
command. I decided that I am going to use that code as a reference, but not
necessarily port from it. I want to understand what it does inside of each
request, but my solution may not work exactly the same.

As it turns out, Git supports a couple of options that can be specified via
environment variables to help us out with debugging. First, we can turn on
tracing for network calls that Git makes to an HTTP server. With this enabled,
Git will output the HTTP requests and headers for each call that it makes,
and will also output the HTTP status code and response headers for each
response. This will be useful as we look at each scenario. To turn on this
tracing, we just have to set the `GIT_CURL_VERBOSE` environment variable:

    SET GIT_CURL_VERBOSE=1

The next thing that is worthwhile to look at is using
[Fiddler](http://www.fiddler2.com/fiddler2/) to observe and debug the HTTP
calls. We can set a second environment variable to force Git to send its HTTP
requests through Fiddler's HTTP proxy:

    SET HTTP_PROXY=http://localhost:8888

With those set, we can start observing the HTTP calls that the Git client will
send to the Git HTTP server, and we can start to implement the Git HTTP server.

Setting Up the Development Environment
--------------------------------------
As I mentioned earlier, this solution has to work on a Microsoft Windows
server. Specifically, this solution needs to be hostable inside of IIS and not
require running the Apache web server. Now, I could always run the Apache web
server, but the point is that I do not want to.

To implement this project, I am going to use [Node.js](http://nodejs.org) as
the implementation language (in another post, I may take a look at using
ASP.NET to implement the same behavior). My Node.js application will be hosted
in IIS using [iisnode](https://github.com/tjanczuk/iisnode).

For the implementation, I will be using [CoffeeScript](http://coffeescript.org)
instead of JavaScript. It's a personal choice, I prefer CoffeeScript. I will
use Ruby Rake to automate the process of compiling the CoffeeScript into
JavaScript for execution.

The Node.js application will be based on [Express](http://expressjs.com). I am
doing this because there will eventually be a web user interface for the site
and I want the Git HTTP server to play into it. Also, Express has routing
behaviors which will become useful when I implement the Git HTTP protocol.

My project directory structure looks like this:

    C:\Projects\GitHttpServer\MAIN  <-- root directory for project workspace
      .git\                         <-- local Git repository
      build\                        <-- generated by Rakefile; build outputs go here
        temp\                       <-- intermediate files generated by Rakefile
        web\                        <-- IIS website hosted here; built by Rakefile
      node_modules\                 <-- Express and Jade go here
      src\                          <-- source code to be compiled goes here
        web\                        <-- Express/CoffeeScript files go here
          public\                   <-- Static content will go here
          routes\                   <-- Node.js code for HTTP request handling
          views\                    <-- Jade views will go here
          iisnode.yml               <-- YAML configuration for iisnode
          gitserver.coffee          <-- Main program for the Git HTTP server
          web.config                <-- IIS configuration
      .gitignore                    <-- Files/directories for Git to ignore
      package.json                  <-- Node.js package definition
      Rakefile                      <-- Ruby Rake script used to build site

The **web.config** file is important because it links my Node.js application to
IIS and allows IIS to send requests to iisnode. The web.config file also
contains URL rewriting rules that will map incoming requests either to the
static content in the **public** directory, or to the dynamic content
implemented by my server. The web.config file looks like this:

{% highlight xml %}
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <add name="iisnode" path="gitserver.js" verb="*" modules="iisnode"/>
    </handlers>
    <rewrite>
      <rules>
        <rule name="LogFile" patternSyntax="ECMAScript" stopProcessing="true">
          <match url="^[a-zA-Z0-9_\-]+\.js\.logs\/\d+.txt$"/>
        </rule>
        <rule name="NodeInspector" patternSyntax="ECMAScript" stopProcessing="true">
          <match url="^gitserver.js\/debug[\/]?"/>
        </rule>
        <rule name="StaticContent">
          <action type="Rewrite" url="public{{REQUEST_URI}}"/>
        </rule>
        <rule name="DynamicContent">
          <conditions>
            <add input="{{REQUEST_FILENAME}}" matchType="IsFile" negate="True"/>
          </conditions>
          <action type="Rewrite" url="gitserver.js"/>
        </rule>
      </rules>
    </rewrite>
  </system.webServer>
</configuration>
{% endhighlight %}

The **iisnode.yml** file is a new feature that was recently added to iisnode.
Using iisnode.yml, we can set configuration options for iisnode without having
to include those settings in the web.config file. I am initially going to set
two settings for iisnode. The first setting, **node_env** will let the Express
framework know that it is being used in a development environment. When I go
into product, I will change the value. The second setting, **promoteServerVars**
will allow my Node.js application to obtain the value of the **AUTH_USER**
HTTP server variable so that I can get the user name of the authenticated user.
When I later turn on Windows authentication for my web application, the
AUTH_USER variable will contain the domain name of the user accessing the
website.

{% highlight yaml %}
node_env: development
promoteServerVars: AUTH_USER
{% endhighlight %}

With my directory structure established, I next created a website in IIS and
pointed the root of the site to the **build\web** subdirectory where my build
script will write the compiled JavaScript files and web content. My development
website is hosted at http://localhost:8000. Now, I just need to create
something to listen for incoming requests. I created the **gitserver.coffee**
file with a basic Express web application template:

{% highlight coffeescript %}
###
Copyright 2012 Michael F. Collins, III
###

###############################################################################
#
# gitserver.coffee
#
# This program implements the Git HTTP Server application. This program will
# host an HTTP server that will process and dispatch incoming HTTP requests to
# the correct handler.
#
# Copyright 2012 Michael F. Collins, III
#
###############################################################################

express = require 'express'
routes = require './routes'

app = module.exports = express.createServer()

app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.query()
  app.use app.router
  app.use express.static, __dirname + '/public'

app.configure 'development', ->
  app.use express.errorHandler
    dumpExceptions: true
    showStack: true

app.configure 'production', ->
  app.use express.errorHandler()

app.get '/', routes.index

app.listen process.env.PORT, ->
  console.log "Git HTTP Server listening on port #{process.env.PORT} in #{app.settings.env} mode"
{% endhighlight %}

With the basic web application set up, I can start looking at the Git HTTP
protocol and start to implement the server side of the protocol.

Pushing the Initial Change Set to the Project Repository
--------------------------------------------------------
Using GitHub as a model, starting a new hosted project involves the following
operations:

1. I go to GitHub and create the hosted repository for my project.
2. I create the local repository for my project.
3. I create the initial change set. This typically involves creating a READAME
   file and committing the file to my repository.
4. I add my GitHub project repository as a remote repository to my local
   repository and assign the remote repository the alias *origin*.
5. I push the initial change set to the remote repository and create the
   *master* branch.

I handled step 1 manually for now, as I am not focusing on the project creation
story yet. I created a directory on my hard drive at **C:\GitProjects\GitServer**
and initialized the repository as a bare repository:

    C:\GitProjects\GitServer> git init --bare

I performed the second step when I created my development environment in the
previous section. For the third step, I committed the basic application
template that I created above after testing to make sure that the website's
home page was served from IIS using iisnode and appeared in my web browser.

For the fourth step, I need to create the link between my local repository and
the remote repository. In order to do that, I need a URL structure that I can
use and specify for my project. For now, I am going to use the following URL
format to specify the Git repository for a hosted project:

    http://<webserver>/<username>/<projectname>/git

In the case of this project, my Git repository URL will look like this:

    http://localhost:8000/michael.collins/gitserver/git

I added the remote repository to my local repository:

    git remote add origin http://localhost:4000/michael.collins/gitserver/git

My new remote repository is now being aliased as *origin*. Now it's time to
try to push the initial change set from my local repository to my new remote
repository. I know in advance that this is going to fail, because I have not
implemented the server side of the operation, but because I set the
`GIT_CURL_VERBOSE` environment variable, Git will show me the HTTP requests
that it is sending to my server so that I can start to implement a handler for
each request.

Executing the push command `git push -u origin master` shows me that Git is
first trying to send the following request to my server:

    GET http://localhost:8000/michael.collins/gitserver/git/info/refs?service=git-receive-pack

This request will return a 404 since that URL is not handled by the web
application, so now I can look to implement it. Looking at the source code for
the `git-http-backend` command, I can see that the Git CGI handler outputs some
header bytes and then executes the the `git-receive-pack` command. The output
of the `git-receive-pack` command is appended to the HTTP response and returned
to the Git client. The full command line that is executed looks like this:

    git-receive-pack --stateless-rpc --advertise-refs (projectroot)

When I tried this project earlier, this was where my first failure occurred.
On Windows, the `git-receive-pack` command is a shortcut that executes the
`git receive-pack` command. This is the behavior that we really want. Node.js
seems incapable of executing the `git-receive-pack` command using the `spawn`
API, so we need another way of executing the command. What I did was to create
a new file in my web server directory named **git-receive-pack.cmd** that I
could execute instead:

    @git receive-pack %*

My implementation for this handler looks like this:

{% highlight coffeescript %}
child_process = require 'child_process'
spawn = child_process.spawn

exports.getInfoRefs = (req, res) ->
  res.setHeader 'Expires', 'Fri, 01 Jan 1980 00:00:00 GMT'
  res.setHeader 'Pragma', 'no-cache'
  res.setHeader 'Cache-Control', 'no-cache, max-age=0, must-revalidate'
  res.setHeader 'Content-Type', 'application/x-git-receive-pack-advertisement'

  packet = "# service=git-receive-pack\n"
  length = packet.length + 4
  hex = "0123456789abcdef"
  prefix = hex.charAt (length >> 12) & 0xf
  prefix = prefix + hex.charAt (length >> 8) & 0xf
  prefix = prefix + hex.charAt (length >> 4) & 0xf
  prefix = prefix + hex.charAt length & 0xf
  res.write "#{prefix}#{packet}0000"

  git = spawn 'C:/Projects/GitHttpServer/MAIN/build/web/git-receive-pack.cmd', ['--stateless-rpc', '--advertise-refs', 'C:/GitProjects/GitServer']
  git.stdout.pipe res
  git.stderr.on 'data', (data) ->
    console.log "stderr: #{data}"
  git.on 'exit', ->
    res.end()
{% endhighlight %}

I can add this handler to my Git server application by assigning a route:

{% highlight coffeescript %}
app.get '/:user/:project/git/info/refs', routes.getInfoRefs
{% endhighlight %}

For now, you will notice that I am hard-coding the paths to the Git repository
and to the processes that I am spawning. I am also ignoring the user name and
project name parameters in the URL. That will get fixed later. Right now,
I just want to see the solution work.

The **getInfoRefs** handler basically outputs a set of HTTP headers to disable
response caching and set the content type of the response. Next, there are a
set of header bytes that need to be output in a special format. The first bytes
returned are the length of the record specified as a 4 character hexadecimal
string. I create the header record, get it's length, build the hexadecimal
string, and then write the record to the response.

After the header record, the rest of the output comes from executing the
`git receive-pack` command. I spawn the batch script that I created earlier
and pass the parameters to the script. The script executes Git and passes
the parameters to the `receive-pack` command. I then redirect the standard
output stream of the Git child process to the HTTP response stream. I also
listen for any errors being written to the standard error stream and log those
errors. Finally, when the Git process finishes executing, I close the HTTP
response stream.

Obviously, this is a bare bones implementation that needs more work, but when
I ran it, I found that this operation succeeded, so I am able to move to the
next step in the process. The next step is Git executes an HTTP POST to send
the change set to the remote repository:

    POST http://localhost:8000/michael.collins/gitserver/git/git-receive/pack

The payload of the request is a blob containing the change sets to be pushed
to the hosted repository. Again, this will execute the `git receive-pack`
command, so I have to take the body of the HTTP request and send it via the
standard input stream to Git. The handler for this request looks like this:

{% highlight coffeescript %}
exports.postReceivePack = (req, res) ->
  res.setHeader 'Expires', 'Fri, 01 Jan 1980 00:00:00 GMT'
  res.setHeader 'Pragma', 'no-cache'
  res.setHeader 'Cache-Control', 'no-cache, max-age=0, must-revalidate'
  res.setHeader 'Content-Type', 'application/x-git-receive-pack-result'

  git = spawn 'C:/Projects/GitHttpServer/MAIN/build/web/git-receive-pack.cmd', ['--stateless-rpc', 'C:/GitProjects/GitServer']
  req.pipe git.stdin
  git.stdout.pipe res
  git.stderr.on 'data', (data) ->
    console.log "stderr: #{data}"
  git.on 'exit', ->
    res.end()
{% endhighlight %}

This handler gets added to the Git server application:

{% highlight coffeescript %}
app.post '/:user/:project/git/git-receive-pack', routes.postReceivePack
{% endhighlight %}

I then find that executing the push command again now succeeds:

    git push -u origin master

I should be able to go to my hosted repository and execute the `git log`
command, and my change set should now appear in the repository, which it
does.

In terms of my objectives, my first objective was to push the initial change
set to the hosted repository, which I just accomplished. My third objective is
to push later change sets to the remote repository. Since I now have changes
because I implemented the `git push` behavior for the initial commit, I can
commit my changes to my local repository and execute `git push origin master`
again. What I saw was that the Git client successfully pushed my additional
changes to the hosted repository. Checking the hosted repository verifies that
my changes are now in the remote repository. So two objectives are completed.

Cloning the Hosted Git Repository
---------------------------------
Fresh on the success of pushing changes from my local repository to my hosted
repository, the next thing that I want to do is to be able to clone the hosted
repository. It is not so much an issue for me, since I do have a local
repository, but long-term I do not want to be the only person working on this
project. I am a busy person. I want help and collaborators and they will need
to be able to clone my repository.

Following the workflow from the previous section, I am going to start off and
execute a `git clone` command to see what happens:

    git clone http://localhost:8000/michael.collins/gitserver/git

Executing this command shows me that Git is first trying to send the following
request to my web application:

    GET http://localhost:8000/michael.collins/gitserver/git/info/refs?service=git-upload-pack

While I did implement support for the `/info/refs` path in the previous
section, the command was for `git-receive-pack`. `git-upload-pack` is another
command that I have to implement.

Here's the interesting thing about `git-upload-pack`. While the
`git-receive-pack` command on Windows is a shortcut for the `git receive-pack`
command, `git-upload-pack` is actually an executable on Windows. It can also
be executing using the `git upload-pack` command. To make life simple, I am
going to create a second batch script that aliases the `git-upload-pack`
command:

    @git upload-pack %*

Next, I am going to change my implementation of `getInfoRefs` to support
executing the service specified in the `service` query parameter:

{% highlight coffeescript %}
exports.getInfoRefs = (req, res) ->
  service = req.query.service

  res.setHeader 'Expires', 'Fri, 01 Jan 1980 00:00:00 GMT'
  res.setHeader 'Pragma', 'no-cache'
  res.setHeader 'Cache-Control', 'no-cache, max-age=0, must-revalidate'
  res.setHeader 'Content-Type', "application/x-#{service}-advertisement" # <-- change here

  packet = "# service=#{service}\n" # <-- change here
  length = packet.length + 4
  hex = "0123456789abcdef"
  prefix = hex.charAt (length >> 12) & 0xf
  prefix = prefix + hex.charAt (length >> 8) & 0xf
  prefix = prefix + hex.charAt (length >> 4) & 0xf
  prefix = prefix + hex.charAt length & 0xf
  res.write "#{prefix}#{packet}0000"

  # change the batch script that is called
  git = spawn "C:/Projects/GitHttpServer/MAIN/build/web/#{service}.cmd", ['--stateless-rpc', '--advertise-refs', 'C:/GitProjects/GitServer']
  git.stdout.pipe res
  git.stderr.on 'data', (data) ->
    console.log "stderr: #{data}"
  git.on 'exit', ->
    res.end()
{% endhighlight %}

Updating my web application and running the `git clone` command should show me
that this operation now works. The next HTTP request that is sent to the web
application by the `git clone` command is an HTTP POST that looks like this:

    POST http://localhost:8000/michael.collins/gitserver/git/git-upload-pack

Why this is a POST on the `clone` is unknown to me. It is also not relevant
because I do not need to process the POST data. I just need to forward the body
to Git. The implementation here is very similar to the POST operation that I
implemented in the previous section, so I am just going to copy the code and
modify it to run the correct batch script:

{% highlight coffeescript %}
exports.postUploadPack = (req, res) ->
  res.setHeader 'Expires', 'Fri, 01 Jan 1980 00:00:00 GMT'
  res.setHeader 'Pragma', 'no-cache'
  res.setHeader 'Cache-Control', 'no-cache, max-age=0, must-revalidate'
  res.setHeader 'Content-Type', 'application/x-git-upload-pack-result'

  git spawn 'C:/Projects/GitHttpServer/MAIN/build/web/git-upload-pack.cmd', ['--stateless-rpc', 'C:/GitProjects/GitServer']
  req.pipe git.stdin
  git.stdout.pipe res
  git.stderr.on 'data', (data) ->
    console.log "stderr: #{data}"
  git.on 'exit', ->
    res.end()
{% endhighlight %}

I added this operation to my web application:

{% highlight coffeescript %}
app.post '/:user/:project/git/git-upload-pack', routes.postUploadPack
{% endhighlight %}

Again, updating the web application and running the `git clone` command should
show me that this operation completes. In fact, what I found was that
implementing this operation resulted in the clone operation succeeding and
the cloned repository was now in my workspace. A third objective is now
completed.

Fetching and Pulling Changes from the Hosted Repository
-------------------------------------------------------
Three of five objectives complete. I can clone a repository, make changes to
it, and push my changes back to the hosted repository. The last piece of the
puzzle is that other people that I am collaborating with need to be able to
pull my changes. Therefore, I need support for `git fetch` and `git pull`.

In order to test a fetch, I committed the changes that I made in the last
section and pushed the changes to the host repository. I next went to the
cloned repository and executed a `git fetch origin` command. What I found was
that the operation completed successfully. It pulled down the changes into
my new local repository. Executing `git merge origin/master` merged the changes
from the *origin/master* branch into my local *master* branch. A fourth
objective complete and I did not have to do anything.

My next thought is that maybe `git pull` will work the same way, since I'm
guessing that it uses the same logic as `git fetch` and `git merge`. To test
it out, I created edited the README file in my project repository and pushed
the change to the hosted repository. I next switched over to my other local
repository and executed the `git pull origin` command to pull the changes
from the *origin/master* branch and merge them into my local *master* branch.
Again, the operation completed successfully and my local repository was updated
with the changes from the other repository.

Five out of five objectives completed successfully.

Conclusion and Next Steps
-------------------------
In this post, I created a Node.js application that allowed me to expose hosted
Git repositories using IIS and running on a Windows server. The web application
is not necessarily complete as there are still features like error handling and
user authentication and authorization that have to be implemented, but the
basic operations needed to clone, push, pull, and fetch are now supported.

In the next post on this subject, I will look at what I can do in order to make
the solution stronger and usable in an intranet scenario.

I also know that some of the people that I work with aren't so keen yet on
using Node.js over ASP.NET MVC, so I may take a look at creating the same
functionality inside of an ASP.NET MVC application.
