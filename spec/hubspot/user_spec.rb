# frozen_string_literal: true

# spec/hubspot/company_spec.rb
require 'spec_helper'
require 'hubspot/user'

RSpec.describe Hubspot::User do
  context 'using an access_token' do
    context 'without the required scope', configure_hubspot: :no_auth do
      describe 'retrieving an owner', cassette: 'users/find_by_id_no_scope' do
        it 'raises an OauthScopeError' do
          expect { Hubspot::User.find(1) }.to raise_error(Hubspot::OauthScopeError, /required scopes/)
        end
      end
    end

    context 'with the required scope', configure_hubspot: true do
      describe '#first fetching a user', cassette: 'users/list_first' do
        let(:user) { Hubspot::User.list.first }

        it 'returns one user/owner' do
          expect(user).to be_a(Hubspot::User)
        end

        it 'responds to friendly field name' do
          expect(user.first_name).not_to be_nil
          expect(user.last_name).not_to be_nil
          expect(user.email).not_to be_nil
        end
      end
    end
  end
end
