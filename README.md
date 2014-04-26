# Forminate

[![Build Status](https://img.shields.io/travis/molawson/forminate.svg)](https://travis-ci.org/molawson/forminate)
[![Code Climate](https://img.shields.io/codeclimate/github/molawson/forminate.svg)](https://codeclimate.com/github/molawson/forminate)
[![Code Climate Coverage](https://img.shields.io/codeclimate/coverage/github/molawson/forminate.svg)](https://codeclimate.com/github/molawson/forminate)

Doing CRUD operations in Rails is pretty awesome. Just remember the first time you generated a Rails scaffold and almost immediately started creating and editing records in the database from a web form. I'd bet that hooked a lot of people. It certainly caught my attention.

Before too long, you need to create a page in a Rails app that has to update multiple models from a single form. Now, you feel the pain.

> Life is pain, Highness. Anyone who says differently is selling something.
_&mdash; Man in Black_

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

### Requirements

Currently, forminate only works with ActiveRecord and [ActiveAttr](https://github.com/cgriego/active_attr) models. I would love to extend it to support other models (and it may actually work with others), but only these two have been tested.

### Example

To see how this works, lets take the classic example of a single page checkout process. We want to be able to have the user sign up and/or purchase a membership from a single form. We already have the following models in our system, all of which are needed on the checkout page.

```ruby
class Membership < ActiveRecord::Base
  # database columns: name, price
  validates_presence_of :name
end

class User < ActiveRecord::Base
  # database columns: first_name, last_name, email
  validates_presence_of :email
  attr_accessor :temporary_note
end

class CreditCard
  include ActiveAttr::Model

  attribute :number
  attribute :expiration
  attribute :cvv

  validates_presence_of :number, :expiration, :cvv
  validates_length_of :number, in: 12..19
end
```

To better model what's actually happening on the checkout page, we create a Cart form object that includes a user, membership, and credit_card.

```ruby
class Cart
  include Forminate

  attribute :total
  attribute :tax

  attributes_for :user
  attributes_for :membership, validate: false
  attributes_for :credit_card, validate: :require_credit_card?

  validates_numericality_of :total

  def require_credit_card?
    membership.price && membership.price.to_f > 0.0
  end
end
```

This small class gives us a lot of nice features.

### Attributes

The heart and soul of forminate is the `.attributes_for` method. Calling that method does a couple of things.

First, it sets up an association to an instance of the desired object, using the naming conventions you're used to in Rails, and exposes that object with reader and writer methods.

```ruby
cart = Cart.new
cart.credit_card # => #<CreditCard number: nil, expiration: nil, cvv: nil>

payment_card = CreditCard.new(number: 4242424242424242, expiration: 0115, cvv: 123)
cart.credit_card = payment_card
cart.credit_card # => #<CreditCard number: 4242424242424242, expiration: 0115, cvv: 123>
```

It also sets up reader and writer methods for all of the associated object's attributes To prevent method name conflicts, it prepends the underscore version of the model name.

```ruby
cart = Cart.new
cart.credit_card_number # => nil
cart.credit_card_number = 4242424242424242
cart.credit_card_number # => 4242424242424242
```

Using these new attribute names, you can initialize your form object with a hash of attributes, just like ActiveRecord models.

```ruby
cart = Cart.new(credit_card_number: 4242424242424242, credit_card_expiration: 0115, credit_card_cvv: 123)
cart.credit_card_number # => 4242424242424242
cart.credit_card # => #<CreditCard number: 4242424242424242, expiration: 0115, cvv: 123>
```

#### Supported methods

Forminate explicitly sets up reader and writer methods for accessing methods related to database columns for ActiveRecord models or attributes for ActiveAttr models.

Additionally, you can call any method on an associated object via the form object by prepending the object's name, just like you do with other attributes. For example, the `User` class above has defined an `attr_accessor` for `temporary_note`.

```ruby
cart = Cart.new
cart.user_temporary_note # => nil
cart.user_temporary_note = "I won't be here long"
cart.user_temporary_note # => "I won't be here long"
```

### Rails Forms

Now that we've got all these handy methods defined, we can get back to building those Rails forms we all know and love.

In your controller, you can create an instance variable for your form object like you would do with a normal model.

```ruby
class CartController < ApplicationController
  def new
    @cart = Cart.new
  end
end
```

Then, you can setup your form view just like you'd expect.

```erb
<%= form_for @cart, url: cart_path, method: :post do |f| %>
  <div class="field">
    <%= f.label :user_email %>
    <%= f.text_field :user_email %>
  </div>
  <div class="field">
    <%= f.label :user_first_name %>
    <%= f.text_field :user_first_name %>
  </div>
  <div class="field">
    <%= f.label :user_last_name %>
    <%= f.text_field :user_last_name %>
  </div>
  <div class="field">
    <%= f.label :credit_card_number %>
    <%= f.text_field :credit_card_number %>
  </div>
  <div class="field">
    <%= f.label :credit_card_cvv %>
    <%= f.text_field :credit_card_cvv %>
  </div>
  <%# etc., etc. %>
<% end %>
```

### Persistence

Forminate coordinates all the persistence for you. It includes a `#save` method that persists all the associated objects that also respond to `#save`. As long as ActiveRecord is available, forminate will wrap it's save in a single transaction, so if any of the associated models fails to save, it will roll everything back.

With this behavior, you can write your controller create actions just like you always have.

```ruby
class CartController < ApplicationController
  def new
    @cart = Cart.new
  end

  def create
    @cart = Cart.new(params[:cart])
    if @cart.save
      flash[:notice] = 'All good.'
      redirect_to root_url
    else
      flash[:alert] = 'Something went terribly wrong.'
      render :new
    end
  end
end
```

Forminate also exposes a `#before_save` hook method that can be used in your form object if you need to do any extra work just before the models are saved.

### Validations

By default, a forminate object will "inherit" all it's associated objects validations. Before saving it's associated objects, forminate will make sure that they're all valid. If not, it will return `false` and the form object will include an ActiveRecord-like errors object.

When calling `.attributes_for` to setup an associated object, you can pass a hash of options, which can include a `:validate` key. The value of the `:validate` key can be either, `true`, `false`, or a symbol that matches the name of a method that should be called to determine whether or not the association's validation should be checked (This is very similar to the `:if` option for the `.validates` methods in Rails).

From our example:

```ruby
class Cart
  include Forminate

  attribute :total
  attribute :tax

  attributes_for :user
  attributes_for :membership, validate: false
  attributes_for :credit_card, validate: :require_credit_card?

  validates_numericality_of :total

  def require_credit_card?
    membership.price && membership.price.to_f > 0.0
  end
end
```

In this case, if the membership that's being purchased is "free", we'll skip the credit card validations, and we won't bother with the membership validations at all.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
