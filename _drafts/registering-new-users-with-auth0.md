---
title: Registering New Users With Auth0
cover_photo: standing-in-line.jpg
---
I'm starting to build out the Naked Coders website. One of the first
things that I need to do is allow users to sign into the website in
order to manage their accounts and get product support. In this post,
I will show the first step of that process by implementing a user
registration process using the Auth0 service.

<!--more-->

Naked Coders is going to be a company, and it's going to produce
software and possibly hardware products in the future. The website at
[https://nakedcoders.io](https://nakedcoders.io) is a public website.
It's going to be the primary means in which potential customers will
learn about the company, the products and services that the company
offers, purchase products or services, and get support for products or
services that the customers have purchased.

In order to allow customers to purchase products, manage their account
information, or get support, I want to know who the customers are. I
want customers to be able to sign into the website using some form of
credential so that I can customize their experience for them and show
them exactly which products or services that they are currently using.

I could go through the process of building my own user management
system, and maybe I will someday, but I want to get my company and
website running as quickly as possible, and to do that, I'm going to
take advantage of one of the wonderful features of the modern web, the
proliferation of application services that will help me to implement
common and complex functionality so that I can focus on my core needs
to get the company and the website running.

To implement user management, authentication, and eventually single
sign-on services, I'm going to use the services provided by
[Auth0](https://auth0.com). Auth0 implements the user management and
sign-on for websites and applications. Eventually when I get to
building my applications, I can look to implement authentication and
single sing-on using OAuth. Auth0 also implements single sign-on using
third-party services such as Facebook, Twitter, Google, and GitHub.

Auth0 provides a basic sign-in and registration form, but they do not
fit in well with custom designs. Although my website hasn't been built
yet and is lacking any sense of a design, I'm still going to implement
a custom registration process so that when I do come up with a website
design, it will look like it's part of the website and will be branded
appropriately.

Here's how the registration process is going to work:

<img class="img-responsive center-block" src="/images/user_registration.png" alt="User registration flow for the website">

First, the user will browse to the website and will choose to register
by filling in a standard user registration form. When the form is
submitted, the website will use JavaScript to call the `/user/signup`
web service. The web service will invoke web APIs exposed by Auth0 to
create the new user's account. After the user's account is registered
with Auth0, the web service will publish a message to the RabbitMQ
exchange with the routing key `user.new`. By publishing a message to
the RabbitMQ broker, any application or service that is interested in
new user accounts being created can be notified when a new user
registers to perform some action on behalf of the user or the company
such as adding the user to a CRM system or sending the user a welcome
email.

<div class="cover-photo-credit">
Photo credit: <a href="https://www.flickr.com/photos/luiscdiaz/330340600/">Maldita la hora</a> / <a href="http://foter.com/">Foter</a> / <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC BY-SA</a>
</div>
