---
layout: post
title: Minimum Viable Products
description: I create a lot of prototypes. I do this to learn, but what are often really good ideas go undeveloped because I have not been developing the ideas correctly. In this post, I will explore a new idea that I want to pursue for developing my ideas in a more structured, formal way.
categories:
- software_development
category_names:
- Software Development
author: Michael F. Collins, III
author_first_name: Michael
author_last_name: Collins
author_gender: male
twitter_creator: mfcollins3
---
I create a lot of prototypes. I do this to learn, but what are often really good ideas go undeveloped because I have not been developing the ideas correctly. In this post, I will explore a new idea that I want to pursue for developing my ideas in a more structured, formal way.
categories:

<!--more-->

Introduction
------------
If there is one shortcoming that I have never had, it's having an interest in learning new things. I love to learn and play with new technologies, whether they are really new technologies or just new to me. For example, over the past year, I have learned Ruby, which is a 20-year-old language, and Erlang, which may be even older. In 1998, I wrote parts of a product for PeopleSoft in COBOL. For most C++ programmers, that may not sound like a whole lot of fun, but in reality it was some of the best work that I have ever done.

The biggest problem that I have had is focus. I have been highly successful in building software products for other people, but when it comes to building my own software products, I have found great frustration with focusing the ideas and turning them into forward momentum. I think that this is caused by two things. I believe that I hold the source code that I write for myself to a higher standard than I may for a customer. For example, with customers I work to write the best code that I can, but I try to get their feedback as much as possible and let them know when it's right. For myself, that feedback loop gets broken often because I focus more on technology than what I want that technology to be doing for me.

There are two books that I have been re-reading recently:

* [The Cucumber Book](http://pragprog.com/book/hwcuc/the-cucumber-book) by Matt Wynne and Aslak Helles&oslash;y
* [The Lean Startup](http://www.amazon.com/Lean-Startup-Entrepreneurs-Continuous-Innovation/dp/0307887898) by Eric Ries

I was turned onto _The Lean Startup_ at the last Phoenix Startup Weekend from a presentation that they had and I bought the book and read it. It was very insightful. The central theme of the book was the concept of **minimum viable product**. The problem, as identified in the book, is that often startups, or any project in general, fails because the companies and project teams wait too long to release their products to the marketplace. The author argues that releasing software early and often, even before the product is fully baked, begins a feedback loop that allows customers to define how the product evolves in the future and allows the product team to focus on those features that will bring the greatest return to the customers that are actually interested in using the product.

Herein lies the crux of my problem. Having a perfectionist mentality when it comes to my own projects, I set myself up for failure quite often by having grand visions in my head of what I want to build that I too often become frustrated by my lack of vision when it comes to actually building what I once envisioned. I don't make enough *working* software to begin the feedback loop with myself much less getting feedback from others. My main problem, I believe, is that getting to the point of initial feedback is taking too long for my own personal projects. I am not stopping to do the minimum possible to get my own projects to a point where I can begin that feedback loop. When it comes to applying new technologies, I am taking them to a point where I can explore and experiment, but I am not setting up those experiments to a point where I can turn them into a real product.

A Brief Introduction to Cucumber
--------------------------------
In case you're not familiar with Cucumber, this is one technology that you really should take a look at. Typically marketed as a tool for test driven development, or more specifically behavior-driven development, Cucumber allows you to define your test scenarios in plain English (or whatever other language you use as your primary language) and will let you craft code to execute each part of your test case. Cucumber uses a language or syntax named **Gherkin** to specify your test. For example, if I were creating an ATM, this could be a Cucumber test:

{% highlight gherkin %}
Given my account has a balance of $100
When I withdraw $20
Then $20 will be released by the cash device
And my account balance will be $80
{% endhighlight %}

Gherkin defines three main keywords or step types:

* **Given**
* **When**
* **Then**

A **Given** step is used to specify a precondition for setting up the test scenario, such as I have a bank account at the bank and it has a balance of $100. A **When** step is then used to specify the action that I am going to perform and test. In this example, my action is withdrawing $20 from my bank account. Finally, the **Then** steps are used to specify the end result that must be valid for the scenario to succeed. In my example, I have two conditions:

1. $20 must magically be released to me by the cash dispenser device
2. My account must be debited and the balance must be $80

This **Given-When-Then** script defines what is called a scenario. A scenario describes a behavior that the product must fulfill. One or more scenarios can be further grouped into a feature. A feature specifies some value that the software should provide for users. Here's a complete feature for the cash withdrawal feature of an ATM:

{% highlight gherkin %}
Feature: Withdraw Cash
  Most customers will use the ATM to make quick withdrawals of cash from their checking or savings accounts. The ATM will only dispense $20 bills.

  Scenario: Withdraw money from an account
    Given my account has a balance of $100
    When I withdraw $20
    Then $20 will be released by the cash device
    And my account balance will be $80

  Scenario: Insufficient funds
    Given my account has a balance of $40
    When I try to withdraw $60
    Then I will receive an insufficient funds error

  Scenario: Amount not a multiple of $20
  	Given my account has a balance of $100
  	When I try to withdraw $15
  	Then I will receive an error that I must specify a multiple of $20
{% endhighlight %}

Cucumber is implemented in Ruby, but that does not mean that Cucumber is only viable for Ruby applications. I have used Cucumber to test iPhone and iPad applications, web sites, node.js applications, and C++ applications. On the Microsoft .NET platform, Cucumber features are provided by a project named [SpecFlow](http://www.specflow.org/specflownew/) and it is very useful for testing .NET and Windows code.

Now that a feature has been defined with one or more scenarios, the real magic of Cucumber comes into play. Cucumber will read the Gherkin definitions, and typically using regular expressions, can match each step in a scenario to a piece of test code that executes that step. For example, in Ruby, the steps above could be defined as:

{% highlight ruby %}
Given(/^my acount has a balance of \$100$/) do
  @account = Account.new
  @account.credit(100)
end

When(/^I withdraw \$20/) do
  @cash_device = CashDevice.new(1000)
  @atm = ATM.new(@cash_device)
  @atm.withdraw(20, @account)
end

Then(/^\$20 will be released by the cash device$/) do
  @cash_device.balance.should eq(980)
end

Then(/^my account balance will be \$80$/) do
  @account.balance.should eq(80)
end
{% endhighlight %}

If I were using SpecFlow, my equivalent C# step definitions would look like this:

{% highlight c# %}
[Binding]
public class StepDefinitions
{
	private readonly Account account;
	private readonly Atm atm;
	private readonly CashDevice cashDevice;

	public StepDefinitions()
	{
		this.account = new Account();
		this.cashDevice = new CashDevice(1000);
		this.atm = new Atm(this.cashDevice);
	}

	[Given(@"^my account has a balance of \$100$")]
	public void GivenMyAccountHasABalanceOf100()
	{
		this.account.Credit(100);
	}

	[When(@"^I withdraw \$20$")]
	public void WhenIWithdraw20()
	{
		this.atm.Withdraw(20, this.account);
	}

	[Then(@"^\$20 will be released by the cash device$")]
	public void Then20WillBeReleasedByTheCashDevice()
	{
		Assert.Equal(980, this.cashDevice.Balance);
	}

	[Then(@"^my account balance will be \$80$")]
	public void ThenMyAccountBalanceWillBe80()
	{
		Assert.Equal(80, this.account.Balance);
	}
}
{% endhighlight %}

The step definitions act as a bridge between the Gherkin descriptions of the scenarios and the application code. You can either program directly against the application in the step definitions, or more commonly, you can create a support layer to adapt the test code to the application. For more information, definitely check out [The Cucumber Book](http://pragprog.com/book/hwcuc/the-cucumber-book) regardless of whether you are using Cucumber, SpecFlow, or one of the other ports. It's an excellent guide to this type of testing.

Minimum Viable Product
----------------------
So what does Cucumber have to do with the Minimum Viable Product concept? It is my opinion that using Cucumber (or related technologies such as SpecFlow for Windows and .NET users) helps to address the problem that many startups or projects have in the early phases of development. I believe that in the early phases of development for any project, there are lots of ideas but not necessarily a solid vision. This makes sense if you think of product development in terms of something called *Blue Sky Engineering*. In Blue Sky Engineering, you basically start with a limitless blue sky where anything can happen, but over time you build up constraints to that vision that limit the solution to a specific problem or a specific workflow for a business process.

I believe that this phase of the project is where most new projects fail because the point is that it's hard to define a vision for a product. At the early stages, there is not an established user interface or web application framework to present the features in. There is not an existing *look-and-feel* that you will follow, or constraints or established standards that you need to conform to when you are implementing these features. This causes a big problem, because to get to a minimum viable product stage some of these things need to be addressed before you can make progress and demonstrate that your initial set of features work.

Cucumber does not solve the problem that in the long term you need to build out the user interface for all of the features, whether that is a desktop application, web application, or command line or console mode application. But using Cucumber can delay the need for these until later in the project and gives time for those ideas to mature based on the direction that the feature development is going in. Cucumber can solve these problems by letting developers focus in the early stages on proving the technology behind the features and becoming comfortable with the problem domain before considerable expense is put into building out a lot of infrastructure. If, as a developer, I can focus on building only what is necessary to complete a feature, even though I may not have the final user interface ready, I can demonstrate using my features and scenarios that I can solve the business problem.

Cucumber can also be used to help jumpstart the feedback loop that is often the cause of failure on products. Using Cucumber, I can start to engage *early adopters*. My early adopters may not have something tangible that they can work on, but if these early adopters are business users, friends, colleagues, or someone else that I can sit down with, I can use these features and scenarios to demonstrate the basic ideas behind the product and I can craft new scenarios to fit the discussions that we have or to perform *what-if* scenarios to see how edge conditions are going to be handled and to fill in the holes in the implementation.

On the surface, this may not seem to be in line with the minimum viable product concept, but I would argue that it is extremely close because it does enable the feedback loop sooner rather than later. If I do the minimum to prove that a feature can be implemented, it's possible that I can begin the feedback loop within hours instead of days or weeks. If my scenario involves doing some database analysis or integration with a remote web service, I could just implement the basic parts of what is needed and drive the scenario through Cucumber. But I can code my step definitions in a way that allows me to customize the values, such as how much money to withdraw from my accounts using the earlier example, and then my early adopters and I can play with different scenarios for how the system should react under different conditions.

Most importantly, what I can achieve is that I can receive feedback, whether it is from myself or from others, about the viability of the idea that I am developing. I can also develop new ideas of where to go next. Having actual working features may help me to better visualize the kind of user interface that I want for the feature in the end product, or I may get ideas for how to tie together two or more features as part of a greater workflow that will provide additional value for my users.

Conclusion
----------
Cucumber and its related tools are not a holy grail to solve all of the problems of a software development project, but I believe that when used right, can help guide new software projects towards a successful path. In this post, I have made an argument that Cucumber technologies can help guide development teams to a minimum viable product stage earlier. I believe that by doing this, the feedback loop that is critical to the ultimate success for new software products can begin much sooner. I encourage you to explore these wonderful technologies to find out how they can help you and your projects become more successful. In future posts, I will begin to frame my explorations in terms of Cucumber features and scenarios in order to validate this hypothesis as it relates to my own projects.
