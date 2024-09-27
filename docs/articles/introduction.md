# Building a Cross-Platform App with Flutter and Rust: A Beginner’s Journey

## Context

I recently started building an application. One of my requirements being able to run seamlessly on web, iOS, and Android, I decided to build a multi-platform solution without the overhead of maintaining multiple codebases. In this article, I’ll walk you through my choices and approach to developing this app using Flutter for the frontend and Rust for the backend.

## Choices

After researching popular cross-platform frameworks, I narrowed my options to React Native and Flutter. React Native, backed by Meta, had strong community support and familiarity with JavaScript, but Flutter won me over due to its impressive performance, growing ecosystem, and the ability to handle OS upgrades smoothly without worrying about native components breaking.

I chose Flutter and haven’t looked back since. Though learning Dart was initially a challenge, the performance benefits and smooth development experience have made it worth the investment.

For the database, I went with PostgreSQL, a tool I’m very comfortable with. However, for the API, instead of sticking with Django as I did in [my previous projects](https://medium.com/@thomas.simmer/neotemplate-a-basic-nextjs-django-website-d1932f912c8d), I saw this as an opportunity to level up my Rust skills and take advantage of its performance benefits. Even if development would probably be longer, my code would be more robust and easier to scale if the application became big.

[In this other article](https://medium.com/@thomas.simmer/rust-writing-tests-in-rocket-49dd1733350e), I shared a template for writing APIs with Rocket, a famous Rust web framework, and Diesel, a popular ORM. While Rocket offers a great developer experience, I decided to try Actix for this project. Actix is known for its high performance, particularly in handling asynchronous tasks, and has a larger community, which makes it a good fit for a more scalable, production-ready app.

While Diesel is a powerful ORM, I ran into issues when trying to write integration tests for asynchronous views with pools of database connections. That’s when I discovered that Diesel doesn’t support asynchronous operations thanks to [this great article](https://www.lpalmieri.com/posts/2020-08-31-zero-to-production-3-5-html-forms-databases-integration-tests/#3-2-choosing-a-database-crate). I then came across **sqlx**, a fully asynchronous library that also offers compile-time safety, meaning it can catch errors before you even run your code. This means that sqlx can catch errors in your database queries at compile-time, before you even run your code. For example, if you accidentally join two tables on the wrong column, sqlx will flag this error upfront—making the development process more reliable.

If you’ve faced similar challenges with async databases in Rust, I’d love to hear how you approached it—feel free to share in the comments!

## Goals

As I said earlier, I have a new idea of application, and it needs to run on every platform. I am completely new to Flutter and Actix, but I eventually get something that works and wanted to share it with others in case it helps. I will not share the idea nor the entire codebase of this full-stack app now, but I wanted to share the first bricks:

1. A login/signup page using a username and password (without email, for privacy).
2. A recovery code page for new users.
3. A 2FA setup page using OTP with an external app like Google Authenticator.
4. A main app view with four tabs.
5. A profile tab where users can change settings like language, theme, 2FA and logout.
6. An account recovery page for users who lose access to 2FA or their password.

Maintaining a clean architecture was critical from the start to ensure that the app could scale smoothly as more features are added. I took the time to study existing Flutter and Actix projects, learning best practices to keep the codebase organized and maintainable. If you’ve tackled similar challenges or have suggestions on how to improve the architecture or performance, I’d love to hear from you. Feel free to share your thoughts in the comments or even contribute with a pull request.

This journey of building a multi-platform app with Flutter and Rust has been both challenging and rewarding. From selecting the right frameworks to optimizing for async database interactions, I’ve learned a lot that I’m excited to share. In the next articles, I’ll dive deeper into the technical aspects of this project—covering everything from testing in Actix to handling authentication in Flutter. I hope this introduction gives you a sense of what’s to come, and I can’t wait to hear your thoughts or suggestions. Here’s a quick demo to see the app in action.

[![Watch the video](/docs/screenshots/1.png)](https://youtu.be/ZCqYWs-lrRM)
