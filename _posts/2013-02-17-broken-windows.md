---
layout: post
title: Broken Windows
description: Microsoft's Windows 8 is revolutionary, but when talking about Microsoft Windows is revolutionary really a good thing? In this post, I will look at my feelings of Windows 8 and the Windows platform in general, and will talk about how Windows 8 has affected me as a long-time Windows developer.
disqus_identifier: 2013-02-17-broken-windows
author: Michael F. Collins, III
author_first_name: Michael
author_last_name: Collins
author_gender: male
twitter_creator: mfcollins3
modified_time: 2013-04-16
categories:
- Software_Development
category_names:
- Software Development
tags:
- windows
- microsoft
---
Microsoft's Windows 8 is revolutionary, but when talking about Microsoft Windows is revolutionary really a good thing? In this post, I will look at my feelings of Windows 8 and the Windows platform in general, and will talk about how Windows 8 has affected me as a long-time Windows developer.

<!--more-->

I have been a Windows programmer since version 1.0. I learned to program it as a child using the first edition of _Programming Windows_ by [Charles Petzold](http://www.charlespetzold.com/books.html). From pure C-based SDK programming, I evolved with the platform to use C++ frameworks including Borland's Object Windows Library (OWL) and the Microsoft Foundation Class (MFC) Library. I took a break to do Java development in the late 1990s, but I came back to Windows with .NET in 2000.

I remember the first big *innovation* in Windows when I went to the Microsoft Professional Developer Conference in 2005. This was when Microsoft announced Windows Vista and showed off .NET 3.0 with WPF. I was instantly in love with the change in the desktop between Windows XP and Windows Vista, and I was really excited about the possibilities for building rich graphical applications with WPF. Then came Windows 7 with its improvements in the shell and the taskbar features. They were all very cool and I was excited to be building desktop applications.

I was at the first Microsoft BUILD conference back in 2011 when Microsoft first revealed Windows 8 to developers and I came home with a Samsung slate containing the first developer preview. Initially, I was pretty impressed with the platform and I created a couple of WinRT applications quickly during the week of the conference. But after the conference and more time passed, I quickly became less enamored with Windows 8.

In my opinion, Microsoft missed the mark with Windows 8. This is not to say that Windows 8 is a bad operating system. I am actually using it (I have it installed in Parallels Desktop on my MacBook Pro, which is my primary personal computer). I think what has failed with Windows 8 was Microsoft's strategy. Microsoft spent 2011 building the hype for Windows 8 and spent 2012 getting developers and consumers ready for Windows 8, but Microsoft's message was inadequate and too soon. Microsoft embraced mobility and mobile platforms as the future of computing, but I think that Microsoft moved to de-value the desktop before consumers (especially enterprise consumers) were ready.

I think that it was quite ironic, for example, that only a couple of days before or after the Windows 8 announcement (I forget which) where Microsoft stood up and proclaimed that the desktop was dead, Apple held their massive media event where they announced that the desktop was very much alive and rolled out a new generation of MacBook Airs, MacBook Pros, and iMacs.

In addition to Microsoft's failed messaging to consumers, I think that Microsoft very much miscommunicated with developers in the rollout of WinRT. I actually like WinRT very much, although I have not done any significant product development for it in the past six months. The problem that I have is that Microsoft left desktop developers like me in a dark room without addressing our concerns. As a product developer and consultant, I have many projects that I am working on for Neudesic or for customers that aren't going to cater will to the new "modern UI" approach of Windows. My target audience is not users who will be interacting with my products using mobile devices, or at least mobile devices will not be the primary interface. My programs still work better as desktop applications. Given that, what happens to the WPF applications that I have invested in, or the Win32 or MFC applications that I still may maintain over time? We now know that the desktop technologies will still continue as even Office 2013 and Visual Studio 2012 continue to use them, but that messaging was missing for months.

I remember a similar issue back in the days of the first dot-com boom and the rise of the Internet. Back then, everyone felt the need to build web applications. Every application had to be on the web. The only problem was that the people making these decisions didn't fully understand the limitations of HTML and JavaScript at the time. Granted, the failures back then have led to the much improved and innovated web of today, but many applications that were converted to web applications back in the late 1990s and early 2000s probably should not have been. There were quite a few desktop applications that worked so much better as desktop applications, and in the end, consumers suffered.

I see the same problem in Windows 8 that I saw back then. Everyone is jumping on the mobility bandwagon, and Microsoft's marketing division is trying to get to the front of the crowd and lead them down the parade route. But the problem is that not every application works as a mobile application either. Some applications just work on a desktop. Some applications don't work with touch-based user interfaces. Some applications don't work with the layout and form factor of mobile interfaces. Some products were just meant to be used on a normal desktop running in a Window.

Using Windows 8 in a desktop, I find myself using it quite peculiarly than most that I talk to. I run Windows 8 in a Parallels partition on my Mac, but I also rarely run any of the "modern UI" applications. It's almost like I run a remote desktop in a virtual machine to get to a Windows desktop so that I can do actual software development or work with the programs that I already have. I miss my Start menu, but I have worked around that. But 99% of my time in Windows 8 still is in the desktop. I like having multiple Windows open like I do on my Mac or Windows 7. I like working on programs concurrently. I really love my iPad, but sometimes I am not so productive when I have to pause one application to work in another. In Windows, quite often I will have a web browser up sharing the screen with my IDE so that I can do technical research in one window and code the results of my research in another. I can't do this in either Windows 8 (or at least I have not figured out how to) and I can't do it on my iPad, but this is one of the productivity reasons why I still use a desktop computer. Having to switch Windows into desktop mode seems like an extra step that I can do without.

Windows 8 is not a bad operating system. I'm actually pretty happy with it initially. Some tasks that I used to to quite easily are now a little bit harder, but when I can get to the desktop mode, I can successfully run my applications. I know where Microsoft was trying to go with Windows 8, but they made a mistake in the execution. Windows 8 would have been great for a pure mobile experience similar to what I have with iOS and my iPad. But for non-mobile productivity, I really want my desktop operating system back. Microsoft bounced back from Windows Vista when they came out with Windows 7. I only hope that Microsoft will apply the same philosophy when it comes to working on Windows 9, and I hope that they don't take too long. I imagine that it's only a matter of time before someone else (like Apple) jumps in to reclaim the desktop if Microsoft has decided to abandon it altogether.

Just my thoughts on the matter.
