require 'active_attr'

class DummyUser
  include ActiveAttr::Model

  attribute :first_name
  attribute :last_name
  attribute :email

  attr_accessor :full_name

  validates_presence_of :email

  def save
    # fake a persisted model
  end
end
