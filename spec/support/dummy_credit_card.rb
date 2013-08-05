require 'active_attr'

class DummyCreditCard
  include ActiveAttr::Model

  attribute :number
  attribute :expiration
  attribute :cvv

  validates_presence_of :number
  validates_length_of :number, in: 12..19
end

