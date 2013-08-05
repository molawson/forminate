require 'spec_helper'
require 'client_side_validations'
require 'forminate/client_side_validations'

describe Forminate::ClientSideValidations do
  subject(:model) { model_class.new }

  let :model_class do
    Class.new do
      include Forminate
      include Forminate::ClientSideValidations

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

  describe "#client_side_validation_hash" do
    it "constructs a hash of validations and messages for use with the client_side_validations gem" do
      expected_hash = {
        total: {
          numericality: [{ messages: { numericality: "is not a number" } }]
        },
        dummy_user_email: {
          presence: [{ message: "can't be blank" }]
        }
      }
      expect(model.client_side_validation_hash).to eq(expected_hash)
      expected_hash = {
        total: {
          numericality: [{ messages: { numericality: "is not a number" } }]
        },
        dummy_user_email: {
          presence: [{ message: "can't be blank" }]
        },
        dummy_credit_card_number: {
          presence: [{ message: "can't be blank" }],
          length: [{
            messages: {
              minimum: "is too short (minimum is 12 characters)",
              maximum: "is too long (maximum is 19 characters)"
            },
            minimum: 12,
            maximum: 19
          }]
        },
      }
      model.dummy_book_price = 12.95
      expect(model.client_side_validation_hash).to eq(expected_hash)
    end
  end
end
