---
title: Unit Testing My Go Web Server
disqus_identifier: 2015-05-16-unit-testing-my-go-web-server
cover_photo: /images/golang_testing.png
---
My first post in this series had me write a cool little demo showing
how to make a static web page more dynamic using a Go web server and
CORS. My second post demonstrated my desire to be a craftsman by going
back, refactoring my code, and making it better. In this third post,
I will revisit my Go web server and will make it more professional by
doing what I should have done in the first place: write unit tests.

<!--more-->

As a software developer, I do honestly believe that unit tests are a
necessity, not a nice-to-have. I try to create unit tests as often as
possible. I find that they not only help with showing that the code
that I write works, but they are more helpful for use as debugging
tools by allowing me to rapidly recreate conditions in which something
does not work in order to help me understand why.

I'll be honest though. I don't always get to be a strict conformist to
test-driven development. In my professional life, while I try to test
as much as possible using automated unit tests, sometimes practicality
gets in the way. Time is typically my limiting resource, and often the
schedule makers ask for too much to get done in a short amount of time.
While I can go into why it's not reasonable in all circumstances to
push back, I'll leave that for another post as it's not relevant here.

In my [previous post]({{page.previous.url}}), I refactored my Go web
API server to make the code easier to read and cleaner. Admittedly,
the refactoring was done by making a change, compiling, and then using
**curl** to call the Say Hello API. The refactoring would have been
much better if I had instead written unit tests. I'll retroactively
go back and write the unit tests now. In an ideal world, I would have
written the unit tests first, but I will in the future.

To review, here's the code for the Say Hello API handler. This code
differs a little from the previous post, because I left the name of
the handler in the past as `sayHello`. After writing the post, I
decided to rename the handler function to `sayHelloHandler` instead.

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
	http.Handle("/sayhello", cors.Default().Handler(http.HandlerFunc(errorHandler(sayHelloHandler))))
}

func errorHandler(f func(http.ResponseWriter, *http.Request) error) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if err := f(w, r); nil != err {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			log.Printf("Handling %q: %v", r.RequestURI, err)
		}
	}
}

type welcomeRequest struct {
	FirstName string `json:"firstName"`
	LastName  string `json:"lastName"`
}

type welcomeResponse struct {
	Greeting string `json:"greeting"`
}

type sayHelloRequest struct {
	w        http.ResponseWriter
	r        *http.Request
	err      error
	request  welcomeRequest
	response welcomeResponse
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

func (req *sayHelloRequest) buildResponse() {
	if nil != req.err {
		return
	}

	req.response.Greeting = fmt.Sprintf("Welcome %s %s!", req.request.FirstName,
		req.request.LastName)
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

func sayHelloHandler(w http.ResponseWriter, r *http.Request) error {
	request := &sayHelloRequest{w: w, r: r}
	request.readRequest()
	request.buildResponse()
	request.sendResponse()
	return request.err
}
```

One of the things that I like about Go and drew me towards programming
in Go is its strong standard library. The standard library doesn't have
everything, but it has a lot. For example, starting to write unit tests
in Go is easy thanks to the `testing` package and the `go test`
command. The `testing` package doesn't have everything that I'm used to
such as [NUnit](http://www.nunit.org) or [xUnit.NET](http://xunit.github.io/),
but it has enough to get started with.

Writing unit tests in Go is pretty simple. Using the `testing` package
and the `go test` command, all that you need to do is create modules in
the package directory that have the suffix **_test.go** in the file
names. The compiler will ignore these files when building the package
libraries or executables, but `go test` will compile and build the
modules to run the unit tests.

Test functions themselves are pretty simple as well. The method just
needs to start with the `Test` prefix and accept a single parameter of
type `testing.T`:

```go
package api

import "testing"

func TestSomething(t *testing.T) {
  // TODO: write unit test code
}
```

I'm going to write my first unit test for the Say Hello API. I'll start
by testing the [happy path](http://en.wikipedia.org/wiki/Happy_path):

```go
package api

import (
  "bytes"
  "encoding/json"
  "net/http"
  "net/http/httptest"
  "strings"
  "testing"
)

func TestSayHelloHandlerOutputsGreeting(t *testing.T) {
  requestReader := strings.NewReader(
    "{\"firstName\":\"Michael\",\"lastName\":\"Collins\"}")
  r, err := http.NewRequest("POST",
    "https://michaelfcollins3.herokuapp.com/sayhello", requestReader)
  if nil != err {
    t.Error(err)
    return
  }

  w := httptest.NewRecorder()
  w.Body = new(bytes.Buffer)

  err = sayHelloHandler(w, r)
  if nil != err {
    t.Error(err)
    return
  }

  var response welcomeResponse
  err = json.Unmarshal(w.Body.Bytes(), &response)
  if nil != err {
    t.Error(err)
    return
  }

  if "Welcome Michael Collins!" != response.Greeting {
    t.Errorf("The greeting was incorrect: %s", response.Greeting)
  }
}
```

This test case will test that given my name as input, the Say Hello
handler will return the message "Welcome Michael Collins!". I can run
this test using the following command:

    $ go test ./...

When I run the command, I get the following output:

    ?       github.com/mfcollins3/website-api       [no test files]
    ok      github.com/mfcollins3/website-api/api   0.009s

Because my API code and unit test is in the `api/` subdirectory of my
project workspace, I pass `./...` as an argument to the `go test`
command. This instructs the `go test` command to look recursively in
my project workspace's subdirectories for test cases to run.

Looking at the test case, what I like about unit testing HTTP handlers
in Go is built in support for a feature that I use often in other
languages: mock objects. In the case of HTTP, the `httptest` package
implements the [ResponseRecorder](http://golang.org/pkg/net/http/httptest/#ResponseRecorder)
type. `ResponseRecorder` lets me simulate an `http.ResponseWriter`
object so that I can test my HTTP handler code and validate the result
that would be returned to the HTTP client. Go has support for some
other mock types that can be used for testing things like I/O as well.

My test case is successful. But my *professional mind* is screaming at
me that my code is ugly and unreadable. The test works, but for anyone
that is not me, it's not very readable. Another reader is going to have
a hard time sitting down and understanding what the heck this test case
does. I need to clean up the test just like I did for the production
code:

```go

type sayHelloHandlerTestCase struct {
  t   *testing.T
  err error
  r   *http.Request
  w   *http.ResponseRecorder
}

func newTestCase(t *testing.T) *sayHelloHandlerTestCase {
  testCase := &sayHelloHandlerTestCase{t: t}

  requestReader := strings.NewReader(
    "{\"firstName\":\"Michael\",\"lastName\":\"Collins\"}")
  testCase.r, testCase.err = http.NewRequest("POST",
    "https://michaelfcollins3.herokuapp.com/sayhello", requestReader)

  testCase.w = httptest.NewRecorder()
  testcase.w.Body = new(bytes.Buffer)

  return testCase
}

func (tc *sayHelloHandlerTestCase) callSayHelloHandler() {
  if nil != tc.err {
    return
  }

  tc.err = sayHelloHandler(tc.w, tc.r)
}

func (tc *sayHelloHandlerTestCase) assertGreetingIsCorrect() {
  if nil != tc.err {
    tc.t.Error(tc.err)
    return
  }

  if http.StatusOK != tc.w.Code {
    tc.t.Errorf("The HTTP status code was %d", tc.w.Code)
    return
  }

  var response welcomeResponse
  tc.err = json.Unmarshal(tc.w.Body.Bytes(), &response)
  if nil != tc.err {
    tc.t.Error(tc.err)
    return
  }

  if "Welcome Michael Collins!" != response.Greeting {
    tc.t.Errorf("The greeting was incorrect: %s", response.Greeting)
  }
}

func TestSayHelloHandlerOutputsGreeting(t *testing.T) {
  test := newTestCase(t)
  test.callSayHelloHandler()
  test.assertGreetingIsCorrect()
}
```

The code looks cleaner to me. Reading the test case is easy:

1. I set up the test case.
2. I invoke `sayHelloHandler`.
3. I validate that the response contains the correct greeting.

If I need to know the internals of the test case, I can look at the
appropriate test function. There's more that I can do here, but I
achieved my main goal, which was to make the test case more
understandable, and I think that I did that.
