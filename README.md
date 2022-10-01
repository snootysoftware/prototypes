# Snooty Software Prototypes

This repository contains a few prototypes of code manipulation tools for Ruby. They're not production ready, but may be a good jumping-off point. We're not actively supporting any of them, but feel free to contact us (info@snootysoftware.com). If you want to do something interesting with them, we may be able to help. 

We highly recommend reading the related blog posts before diving into the code (links below).

- [Monocle](https://blog.luitjes.it/posts/monocle-bidirectional-code-generation/)
- [erb2builder](https://blog.luitjes.it/posts/erb2builder/)

## Getting started

Monocle, erb2builder and Astroturf have passing test suites on Ruby version 2.5.1. I ran into a few failing specs with newer versions, but it's probably an easy fix.

Textractor is a bit older, I didn't try to get it up and running locally. Up until a year ago it was running fine on heroku though, so it shouldn't be too difficult (famous last words).

## erb2builder

[Here's a blogpost that goes into deep detail about how to use this library and how it was built.](https://blog.luitjes.it/posts/erb2builder/)

This library can convert an ERB HTML template to an XML builder template, and the other way around. If you want to use Ruby AST manipulation tools on ERB templates, now you can. We use it to support ERB templates in the monocle library (see below).

## Monocle

[Here's a blogpost that goes into deep detail about how to use this library and how it was built.](https://blog.luitjes.it/posts/monocle-bidirectional-code-generation/)

Monocle is a bi-directional code generation library. You know how you can use an ERB template and some local variables to generate Ruby code, just like a rails scaffold? Monocle lets you define templates in a similar way. The big difference is that these templates are two-way/reversible. Meaning you can parse existing code and get the original template and local variables. If you define your templates right, you can even preserve custom code written after code generation.

It's similar to lenses that you may know from the functional programming world, except you define them in a more elegant way.

## Textractor

TODO extract code and put it in this repo

This tool lets you prepare an ERB template for internationalization. It takes all of the hardcoded strings, and replaces them with t() calls. It also outputs the locale yaml containing the original strings. [Here's a demo video.](https://www.youtube.com/watch?v=gf7Is9axzt8)

This was originally a paid product, so it was split up into a [front-end gem](https://github.com/snootysoftware/textractor-cli) that called a backend server to do the actual processing. This repository only contains the backend code.

## Astroturf

This contains a few utilities for working with ASTs. Among other things it let you query ASTs by XPath. [Here's an older post explaining how that all works.](https://blog.luitjes.it/posts/using-xpath-to-rewrite-ruby-code-with-ease/)

## Contributors

- Lucas Luitjes
- Joachim Nolten
- Ben Lenarts
