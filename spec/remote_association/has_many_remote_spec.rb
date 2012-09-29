require 'spec_helper'

describe RemoteAssociation, 'method :has_many_remote' do
  before(:all) do
    @body = [
      {profile: {id: 1, user_id: 1, like: "letter A"}},
      {profile: {id: 2, user_id: 1, like: "letter B"}}
    ].to_json
    @full_body = [
      {profile: {id: 1, user_id: 1, like: "letter A"}},
      {profile: {id: 2, user_id: 1, like: "letter B"}},
      {profile: {id: 3, user_id: 2, like: "letter C"}},
    ].to_json
  end

  before(:each) do
    unset_const(:User)
    unset_const(:Profile)
    class User < ActiveRecord::Base
      include RemoteAssociation::Base
      has_many_remote :profiles
    end
    class Profile < ActiveResource::Base
      self.site = REMOTE_HOST
    end

    add_user(1,"User A")
    add_user(2,"User B")
  end

  it 'uses default settings' do
    FakeWeb.register_uri(:get, "#{REMOTE_HOST}/profiles.json?user_id%5B%5D=1", body: @body )
    User.first.profiles.map(&:like).should eq ["letter A", "letter B"]
  end

  it 'should prefetch remote associations of models with defaults (single request)' do
    FakeWeb.register_uri(:get, "#{REMOTE_HOST}/profiles.json?user_id%5B%5D=1&user_id%5B%5D=2", body: @full_body)

    users = User.scoped.includes_remote(:profiles)
    users.first.profiles.map(&:like).should eq ["letter A", "letter B"]
    users.last.profiles.map(&:like).should eq ["letter C"]
  end

  describe 'options' do
    it ':class_name' do
      pending
    end

    it ':foreign_key' do
      pending
    end
  end
end