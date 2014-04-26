require 'spec_helper'

describe Forminate do
  subject(:model) { model_class.new }

  let :model_class do
    Class.new do
      include Forminate

      attribute :total
      attribute :tax

      attributes_for :dummy_user
      attributes_for :dummy_book, :validate => false
      attributes_for :dummy_credit_card, :validate => :require_credit_card?

      validates_numericality_of :total

      def self.name
        "Cart"
      end

      def calculate_total
        self.total = dummy_book.price || 0.0
      end

      def require_credit_card?
        dummy_book.price && dummy_book.price > 0.0
      end
    end
  end

  describe ".attributes_for" do
    it "adds a reader method for each attribute of the associated model" do
      expect(model.respond_to?(:dummy_user_first_name)).to be_true
    end

    it "adds reader and writer methods for each attribute of the associated model" do
      model.dummy_user_first_name = 'Mo'
      expect(model.dummy_user_first_name).to eq('Mo')
    end

    it "adds reader methods for each associated model" do
      expect(model.dummy_user).to be_an_instance_of(DummyUser)
    end

    it "adds the association to the list of association names" do
      expect(model_class.association_names).to include(:dummy_user)
    end

    describe ":validate option" do
      it "validates associated object based on true or false" do
        model.calculate_total
        expect(model.valid?).to be_false
        model.dummy_user_email = 'bob@example.com'
        expect(model.valid?).to be_true
      end

      it "validates associated objects based on a method name (as a symbol) that evaluates to true or false" do
        model.calculate_total
        model.dummy_user_email = 'bob@example.com'
        expect(model.valid?).to be_true
        model.dummy_book_price = 12.95
        expect(model.valid?).to be_false
        model.dummy_credit_card_number = 4242424242424242
        expect(model.valid?).to be_true
      end
    end
  end

  describe ".attribute_names" do
    it "includes the names of its own attributes and the attributes of associated models" do
      expected_attributes = [
        "total",
        "tax",
        "dummy_user_first_name",
        "dummy_user_last_name",
        "dummy_user_email",
        "dummy_book_title",
        "dummy_book_price",
        "dummy_credit_card_number",
        "dummy_credit_card_expiration",
        "dummy_credit_card_cvv",
      ]
      expect(model_class.attribute_names).to eq(expected_attributes)
    end
  end

  describe ".association_names" do
    it "includes the names of associated models" do
      expect(model_class.association_names).to eq([:dummy_user, :dummy_book, :dummy_credit_card])
    end
  end

  describe ".association_validations" do
    it "includes the names and conditions of association validations" do
      expect(model_class.association_validations).to eq({ :dummy_user => true, :dummy_book => false, :dummy_credit_card => :require_credit_card? })
    end
  end

  describe "#initialize" do
    it "builds associated objects and creates reader methods" do
      expect(model.dummy_user).to be_an_instance_of(DummyUser)
    end

    it "creates writer methods for associated objects" do
      new_dummy_user = DummyUser.new(first_name: 'Mo')
      expect(model.dummy_user).to_not be(new_dummy_user)
      model.dummy_user = new_dummy_user
      expect(model.dummy_user).to be(new_dummy_user)
    end

    it "sets association attributes based on an options hash" do
      new_model = model_class.new(dummy_user_first_name: 'Mo', dummy_user_last_name: 'Lawson')
      expect(new_model.dummy_user_first_name).to eq('Mo')
      expect(new_model.dummy_user_last_name).to eq('Lawson')
    end

    it "sets attributes based on an options hash" do
      new_model = model_class.new(total: 21.49)
      expect(new_model.total).to eq(21.49)
    end
  end

  describe "#association_names" do
    it "delegates to self.association_names" do
      expect(model.association_names).to eq(model_class.association_names)
    end
  end

  describe "#associations" do
    it "returns a hash of association names and associated objects" do
      expect(model.associations[:dummy_user]).to be_an_instance_of(DummyUser)
    end
  end

  describe "#save" do
    context "object is valid" do
      it "saves associations and returns self" do
        model.dummy_user_email = 'bob@example.com'
        model.calculate_total
        DummyUser.any_instance.should_receive(:save)
        expect(model.save).to eq(model)
      end
    end

    context "object is not valid" do
      it "does not save associations and returns false" do
        DummyUser.any_instance.should_not_receive(:save)
        expect(model.save).to be_false
      end
    end
  end

  context "setting an attribute using the attribute name" do
    it "reflects the change on the associated object" do
      model.dummy_user_first_name = 'Mo'
      expect(model.dummy_user.first_name).to eq('Mo')
    end
  end

  context "setting an attribute using the association's attribute" do
    it "reflects the change on the attribute name" do
      model.dummy_user.last_name = 'Lawson'
      expect(model.dummy_user_last_name).to eq('Lawson')
    end
  end

  it "delegates to attr_accessors of associated objects" do
    model.dummy_user_full_name = 'Mo Lawson'
    expect(model.dummy_user.full_name).to eq('Mo Lawson')
    expect(model.dummy_user_full_name).to eq('Mo Lawson')
  end

  it "inherits the validations of its associated objects" do
    model.valid?
    expect(model.errors.full_messages).to eq(["Dummy user email can't be blank", "Total is not a number"])
  end
end
