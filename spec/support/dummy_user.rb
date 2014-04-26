class DummyUser < ActiveRecord::Base
  validates_presence_of :email

  attr_accessor :temporary_note
end
