require 'spec_helper'

describe Forminate::AssociationBuilder do
  let(:name) { 'dummy_book' }
  let(:attrs) do
    {
      dummy_user_first_name: 'Mo',
      dummy_book_title: 'The Hobbit'
    }
  end

  subject { Forminate::AssociationBuilder.new(name, attrs) }

  describe '#build' do
    context 'non-ActiveRecord model' do
      it 'populates the association with the given attributes' do
        expect(subject.build.title).to eq('The Hobbit')
      end
    end

    context 'ActiveRecord model' do
      let(:name) { 'dummy_user' }

      context 'primary key not present in attributes' do
        it 'populates the association with the given attributes' do
          expect(subject.build.first_name).to eq('Mo')
        end
      end

      context 'primary key present in attributes' do
        let(:user) do
          DummyUser.create(
            first_name: 'Mo',
            last_name: 'Lawson',
            email: 'mo@example.com'
          )
        end
        let(:attrs) do
          {
            dummy_user_id: user.id,
            dummy_user_first_name: 'Matthew',
            dummy_book_title: 'The Hobbit'
          }
        end

        it 'populates the association from the database' do
          expect(subject.build.last_name).to eq('Lawson')
        end

        it 'overrides database values with passed in values' do
          expect(subject.build.first_name).to eq('Matthew')
        end
      end
    end
  end
end
