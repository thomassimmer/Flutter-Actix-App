# Building a Flutter / Rust app: Introduction

## Context

In this article [](here), I shared **NeoTemplate**, a Django / React template to start an app quickly. I did it with the idea of using it for the moment I will have an idea of web application. I recently found this idea! However, it should run on every platform to be very interesting, but serving different platforms can mean having multiple codebases. For instance, you can have: - one for the website and one for mobiles - one for the website, one for iOS, and one for Android
Starting this project alone, I decided not to go in that direction.

## Choices

Then, I had basically two "safe" choices to develop a multiplatform app that may easily become a big one: - going with **React Native**, developed by Meta, a well-known framework, existing for several years now, with a lot of resources on the Internet, good integration with native mobile features, and a code similar to a language I already know, JavaScript - or going with **Flutter**, developed by Google, a more recent framework, with a good-looking documentation, better performances according to some sources, already used for some big projects like Google Pay, a growing popularity, a new language for me to learn, Dart, and also the safety of having a code that can't break when upgrading the device's OS because it's not using native components, like RN does.
I decided to go with Flutter.

For my database, I went for PostgreSQL because it's what I feel best with.

For my API, I could have gone with Django one more time but, still being learning Rust, I decided it would be better for the performances and, even if development would take longer, my code would be more robust and easier to scale if the app becomes big.

In this other article [](here), I presented a template for writing APIs with Rocket, a famous Rust web framework. I used it at work with Diesel, a quite popular ORM, and while we worked well with it, I decided to try another Rust framework to be able to compare it. I decided to go for Actix, another web framework, probably even more famous than Rocket, mostly because I fell on good articles about it.

I wanted my API to be fully asynchronous and while starting to develop it with Diesel, and bb8, a crate to make asynchronous database connection pools, it turned out to be a nightmare for writing tests. Luckily, I found out with this great article [https://www.lpalmieri.com/posts/2020-08-31-zero-to-production-3-5-html-forms-databases-integration-tests/#3-2-choosing-a-database-crate](here) that: - Diesel is **synchronous** and does not plan to roll out async support in the near future, - **sqlx** provides an asynchronous interface and is compile-time safe
-> This means that the compiler checks for errors in your queries by connecting to the database and checking, for instance, if you are joining two tables using the wrong column. It's quite powerful! - someone succeded in doing what I wanted, i.-e. writing integration tests for asynchronous views using a database connection pool, and this is always nice to find!
I got greatly inspired by this article and decided to go with sqlx.

## Goals

As I said earlier, I have a new app idea and it needs to run on every platforms. I am completely new to Flutter and Actix but still I got something that works and wanted to share with others in case it helps. I will not share the idea neither the entire codebase of this full-stack app now, but I wanted to share the first bricks:

    - a first page where you can login / signup using a username and a password (no email because my user shouldn't be personally identifiable)
    - a second page where freshly registered users can see their recovery codes
    - a third page where freshly registered user can enable 2-factor authentication (2FA) with one-time passwords (OTP) using an external app like Google's Authenticator
    - a fourth page that is a typical app view with four tabs using a common base screen with a logout button
    - a fifth page for the profile tab where people can change their languages, theme and enable/disable 2FA

This took me around two weeks on my free time and I am quite happy with the results so I decided to make a small serie of articles to explain things I have learned and that I didn't somewhere else on the Internet. I will probably discuss:

    - How I organized my code to make sure futur developments will be as smooth as possible
    - How I wrote integration tests for my API
    - How I implemented my authentication logic in flutter using BloC
    - How I implemented my API requesting logic in flutter
    - How I implemented locale and theme selection in flutter
