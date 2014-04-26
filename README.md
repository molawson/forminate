# Forminate

[![Build Status](https://img.shields.io/travis/molawson/forminate.svg)](https://travis-ci.org/molawson/forminate)
[![Code Climate](https://img.shields.io/codeclimate/github/molawson/forminate.svg)](https://codeclimate.com/github/molawson/forminate)

Doing CRUD operations in Rails is pretty awesome. Just remember the first time you generated a Rails scaffold and almost immediately started creating and editing records in the database from a web form. I'd bet that hooked a lot of people. It certainly caught my attention.

Before too long, you need to create a page in a Rails app that has to update multiple models from a single form. Now, you feel the pain.

> Life is pain, Highness. Anyone who says differently is selling something.
&mdash; Man in Black

If you're at this point, let me introduce you to form objects. The general idea is that you create an object that represents the form you want to display in the view, and that form object handles aggregating and coordinating the various models that make up the form. For more information on the particulars of form objects and some example implementations in Rails, check out these great posts from [Code Climate](http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-fat-activerecord-models/), [Thoughtbot](http://robots.thoughtbot.com/activemodel-form-objects), and [Pivotal Labs](http://pivotallabs.com/form-backing-objects-for-fun-and-profit/).

_Forminate gives you a handy way to create form objects that inherit behavior from the models you need and have just enough of the behavior you'd expect from an ActiveRecord or ActiveAttr model to make working with them feel very familiar._

## Installation

Add this line to your application's Gemfile:

    gem 'forminate'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install forminate

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
