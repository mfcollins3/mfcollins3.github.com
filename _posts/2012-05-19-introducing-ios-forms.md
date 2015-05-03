---
title: "New Project: iOS Forms"
disqus_identifier: 2012-05-19-introducing-ios-forms.md
modified_time: 2013-04-16
categories:
- iOS
category_names:
- iOS
tags:
- ios
---
In this post, I will introduce you to the iOS Forms project, a new open source project to help myself and others create form-based data entry applications for the iPhone or iPad.

<!--more-->

Today I am starting a new open source project here on GitHub titled **iOS Forms**.
The iOS Forms project is actually based on work that I have prototyped or built
for other iOS projects that I have released over the past year. The objective
of the project is to make it easier for iOS developers to create data entry
user experiences for iOS applications, and to take advantage of best practices
and standards for data entry.

The iOS Forms library is based on table view user interfaces in iOS. Forms are
presented in a *UITableView* view and can have multiple sections and each
section can have multiple fields. In addition, the forms can be customized at
runtime by dynamically adding sections or fields to a form. The library will
also support multiple form field types that include formatting and custom
keyboards. For example, the *IRCurrencyFormField* class will format the value
of a field as a currency, and will automatically show the field non-formatted
during editing.

The most important part of this library is that there will hopefully be very
little code that needs to be written to implement most features of a data
entry user interface. We will be making use of property lists to define the
structure of the form, and will load and use the property lists at runtime to
build the forms.

I have created a [GitHub Pages website](http://mfcollins3.github.com/ios-forms)
where the software documentation and related blogs will be posted on the
library. The source code itself can be accessed on GitHub
[here](http://github.com/mfcollins3/ios-forms).
