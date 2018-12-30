---
title: Refactoring My Go Web Server
cover_photo: /images/renovating.jpg
disqus_identifier: 2015-05-15-refactoring-my-go-web-server
---
In my previous post, I wrote a Go web server
that responded to requests from my static website. Being a
perfectionist, I was a little bothered by the poor quality of the code
in my web server. In this post, I'm going to take a look at the
previous code and clean it up using best practices to make the code
better.

<!--more-->

I like the [Go](https://golang.org) language, but I haven't written
enough programs in it to consider myself a fully proficient developer
in it. I'd love to be using Go professionally someday, but I would
still consider myself an intermediate developer. But that's ok.
Learning a language takes time, and practice makes pefect.

After reading my last post after posting it, I really was not happy
with the code. It looked messy with all of the repetitive error
checking and handling that I was doing in every step of my HTTP
handler.

I looked to the Internet for some guidance on what I could do to make
the code better. Specifically, I looked at a set of slides for a Go
Talk session from 2013 titled [Twelve Go Best Practices](https://talks.golang.org/2013/bestpractices.slide#1).
I'm going to use a few of these best practices to refactor my web
server and API handler.

I'm going to begin by looking at the current state of my web server:

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

Here's what I don't like about this implementation:

1. My entire web server is one module. If I add more APIs in the
   future, will I be adding them to this module? How big will the
   main program module for my web server become?
2. I don't like all of the ```if nil != err``` code in the sayHello
   method. It's ugly and detracts from what the handler is trying to
   achieve. It makes sayHello difficult to read.

I'm going to start by moving the sayHello handler into its own module:

```go
package api

import (
  "encoding/json"
  "fmt"
  "io/ioutil"
  "log"
  "net/http"

  "github.com/rs/cors"  
)

func init() {
  http.Handle("/sayhello",
    cors.Default().Handler(http.HandlerFunc(sayHello)))
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

This simplifies the main program of the web server:

```go
package main

import (
  "log"
  "net/http"
  "os"

  _ "github.com/mfcollins3/website-api/api"
)

func main() {
  port := os.Getenv("PORT")
  log.Println("Listening on port ", port)
  log.Fatal(http.ListenAndServe(":"+port, nil))
}
```

The main program is now much simpler and cleaner. By importing the
`github.com/mfcollins3/website-api/api` package, I can import and
register any HTTP request handlers that I implement now and in the
future. When the `api` package is imported, Go will execute the `init`
functions in each module. The `init` function will register the HTTP
request handler for the web server.

The main program looks better, but the `sayHello` handler is still less
than desirable. I'm going to fix that now. First, I'm going to apply a
technique from the best practices guide called
[function adapters](https://talks.golang.org/2013/bestpractices.slide#12).
Specifically, I'm going to define the `errorHandler` function adapter
to remove the error processing from the `sayHello` handler:

```go
package api

import (
  "encoding/json"
  "fmt"
  "io/ioutil"
  "log"
  "net/http"

  "github.com/rs/cors"  
)

func init() {
  http.Handle("/sayhello",
    cors.Default().Handler(http.HandlerFunc(errorHandler(sayHello))))
}

type welcomeRequest struct {
  FirstName string `json:"firstName"`
  LastName  string `json:"lastName"`
}

type welcomeResponse struct {
  Greeting string `json:"greeting"`
}

func errorHandler(f func(http.ResponseWriter, *http.Request) error) http.Handler {
  return func(w http.ResponseWriter, r *http.Request) {
    if err := f(w, r); nil != err {
      http.Error(w, err.Error(), http.StatusInternalServerError)
      log.Printf("Handling %q: %v", r.RequestURI, err)
    }
  }  
}

func sayHello(w http.ResponseWriter, r *http.Request) error {
  body, err := ioutil.ReadAll(r.Body)
  if nil != err {
    return err
  }

  var request welcomeRequest
  err = json.Unmarshal(body, &request)
  if nil != err {
    return err
  }

  var response welcomeResponse
  response.Greeting = fmt.Sprintf("Welcome %s %s!", request.FirstName,
    request.LastName)
  data, err := json.Marshal(request)
  if nil != err {
    return err
  }

  _, err := w.Write(data)
  return err
}
```

This code looks a lot cleaner. By using the `errorHandler` function
adapter, `sayHello` looks nicer. There's no more repeating error code.
If an error occurs, `sayHello` returns the `error` value and
`errorHandler` will send back the HTTP error response.

Adding `errorHandler` made a big difference. The code is better and
much easier to read, but I think that I can do more. It would be much
better if I could get rid of the `if nul != err` code after each action
in `sayHello`. Looking back at the best practice slides, I think that I
can utilize the [Avoid repitition when possible](https://talks.golang.org/2013/bestpractices.slide#5)
practice by creating a one-off utility type to implement `sayHello`:

```go
type sayHelloRequest struct {
  w   http.ResponseWriter
  r   *http.Request
  err error
}

func (req *sayHelloRequest) readRequestBody() (body []byte) {
  if nil != req.err {
    return
  }

  body, req.err = ioutil.ReadAll(req.r.Body)
  return
}

func (req *sayHelloRequest) unmarshalRequest(body []byte) (request welcomeRequest) {
  if nil != req.err {
    return
  }

  req.err = json.Unmarshal(body, &request)
  return
}

func (req *sayHelloRequest) buildResponse(request welcomeRequest) (response welcomeResponse) {
  if nil != req.err {
    return
  }

  response.Greeting = fmt.Sprintf("Welcome %s %s!", request.FirstName,
    request.LastName)
  return
}

func (req *sayHelloRequest) marshalResponse(response welcomeResponse) (body []byte) {
  if nil != req.err {
    return
  }

  body, req.err = json.Marshal(response)
  return
}

func (req *sayHelloRequest) writeResponse(data []byte) {
  if nil != req.err {
    return
  }

  _, req.err = req.w.Write(data)
}
```

I defined the `sayHelloRequest` type to implement the guts of the
`sayHello` HTTP handler. `sayHelloRequest` will simplify the
implementation of `sayHello`:

```go
func sayHello(w http.ResponseWriter, r *http.Request) error {
  request := &sayHelloRequest{w: w, r: r}
  body := request.readRequestBody()
  welcomeRequest := request.unmarshalRequest(body)
  response := request.buildResponse(welcomeRequest)
  data := request.marshalResponse(response)
  request.writeResponse(data)
  return request.err
}
```

The `sayHello` function is now much smaller and much more readable. The
error handling has been hidden in the internal implementation. By
**reading** `sayHello`, I or anyone else can basically follow what it
does much easier.

While `sayHello` is much more readable, I'm concerned that someone
reading this for the first time is not going to really understand the
value that `readRequestBody` and `unmarshalRequest` do, or why they are
separate operations. Would it be better to `readRequestBody`, then
`buildResponse`, followed by `sendResponse`? It's still not exciting,
but at least reading those names you have a general idea of what is
happening; at least more than `unmarshalRequest`. I'm going to change
the definition of `sayHelloRequest`, change `buildResponse`, and
implement `readRequestBody` and `sendResponse`:

```go
type sayHelloRequest struct {
  w        http.ResponseWriter
  r        *http.Request
  err      error
  request  welcomeRequest
  response welcomeResponse
}

func (req *sayHelloRequest) buildResponse() {
  if nil != req.err {
    return
  }

  req.response.Greeting = fmt.Sprintf("Welcome %s %s!",
    req.request.FirstName, req.request.LastName)
  return
}

func (req *sayHelloRequest) readRequest() {
  if nil != req.err {
    return
  }

  body := req.readRequestBody()
  req.request = req.unmarshalRequest(body)
}

func (req *sayHelloRequest) sendResponse() {
  if nil != req.err {
    return
  }

  data := req.marshalResponse(req.response)
  req.writeResponse(data)
}

func sayHello(w http.ResponseWriter, r *http.Request) error {
  request := &sayHelloRequest{w: w, r: r}
  request.readRequest()
  request.buildResponse()
  request.sendResponse()
  return err
}
```

I think that these changes make `sayHello` much better. It's concise
and easy to understand. The function first reads the client's request
from the request stream, then builds the response, and then sends the
response back to the client. If you have a basic idea of the contents
of the request and the reply, and you know what `sayHello` does, this
function implementation is clearer and easier to understand.

In this post, I set out to revise my web API server and use some Go
best practices to make the code better and easier to both read and
maintain. Along with those goals, I've also made it much easier to add
additional APIs by just adding modules to the web server program. I'm
much happier with the end result.

<div class="cover-photo-credit">
Photo credit: <a href="https://www.flickr.com/photos/katsrcool/15519941044/">Kool Cats Photography over 5 Million Views</a> / <a href="http://foter.com/">Foter</a> / <a href="http://creativecommons.org/licenses/by/2.0/">CC BY</a>
</div>
