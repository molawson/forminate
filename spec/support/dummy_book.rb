class DummyBook
  include ActiveAttr::Model

  attribute :title
  attribute :price

  validates_presence_of :title
end
