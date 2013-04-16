---
layout: post
title: Bad Habits Around Unit Testing
description: If I have one bad habit as a developer, it is writing code without
  creating the proper unit or acceptance tests. In this post, I discuss my bad
  habit and look at what I should be doing to fix the problem.
disqus_identifier: 2012-05-24-bad-habits-around-testing
author: Michael F. Collins, III
author_first_name: Michael
author_last_name: Collins
author_gender: male
twitter_creator: mfcollins3
modified_time: 2013-04-16
---
It is not that I am a bad person, but like everyone else, I can be prone to
displaying bad habits on occasion. I do not mean to be bad, but sometimes I
just do not think about it, or when it comes to programming, I do not allocate
the proper time to do things such as writing unit tests for my code.

If I were acting as a proper programmer or software development professional,
I would probably be following Robert Martin's
[Three Laws of Test Driven Development](http://butunclebob.com/ArticleS.UncleBob.TheThreeRulesOfTdd):

1. You are not allowed to write any production code unless it is to make a
   failing unit test pass.
2. You are not allowed to write any more of a unit test than is sufficient to
   fail; and compilation failures are failures.
3. You are not allowed to write any more production code than is sufficient to
   pass the one failing unit test.

Beyond unit testing, I am also a firm believer in automated functional or
acceptance tests and I have become fond of the [Cucumber](http://cukes.info)
style of tools that use Gherkin to express the test scenarios in natural
language. If I were a proper professional software developer, then I should
also follow the workflow for writing tested software:

1. Describe the behavior in plain text.
2. Write a step definition.
3. Run and watch it fail.
4. Write code to make the step pass.
5. Run again and see the step pass.
6. Repeat steps 2-5 until green like a cuke (all of the steps pass).

Maybe my bad habits are driven by laziness. Maybe it is fatigue or pressure
that I feel that I need to deliver sooner. More often than not, however,
these bad habits have a way of biting me.

The primary reason that I write unit tests or acceptance tests is not to
demonstrate to anyone that the code passes the tests. More often than not, the
unit or acceptance tests turn into my debugging sessions. If I have tests that
I have written that fail, or functionality that is failing, I will use the
unit tests or the acceptance tests to debug the problem. That is the primary
value that I get out of it. I find, after the fact, that if I do not build and
maintain the automated test cases, then when problems occur, I spend a lot of
time trying to set up a scenario repeatedly so that I can debug and understand
what it going on. Debugging with a manual test is nowhere near as efficient as
debugging against an automated unit or acceptance test.

So mental note to myself: unit test good; acceptance test good; not writing
tests is bad. Spend the time to write tests for the code that you write. In
the end you will be glad that you put forth the effort and have them as a
safety net when time comes to pop open your debugger.