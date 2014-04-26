class DummyUser < ActiveRecord::Base
  validates_presence_of :email

  attr_accessor :full_name
end
