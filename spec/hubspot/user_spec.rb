# frozen_string_literal: true

# spec/hubspot/company_spec.rb
require 'spec_helper'
require 'hubspot/user'

RSpec.describe Hubspot::User do
  include_examples 'hubspot configuration'

  context 'using a private app with an access_token' do
    context 'without the required scope' do
      describe 'retrieving an owner', cassette: 'users/find_by_id_no_scope' do
        it 'raises an OauthScopeError' do
          expect { Hubspot::User.find(1) }.to raise_error(Hubspot::OauthScopeError, /required scopes/)
        end
      end
    end
  end

  describe '#first fetching a user', cassette: 'users/list_first' do
    let(:user) { Hubspot::User.list.first }

    it 'returns one user/owner' do
      expect(user).to be_a(Array)
      expect(user).to all(be_a(Hubspot::User))
      expect(user.length).to be(1)
    end
  end
end
