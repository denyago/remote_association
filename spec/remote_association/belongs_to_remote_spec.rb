require 'spec_helper'

describe RemoteAssociation, "method :belongs_to_remote" do
  before(:all) do
    unset_const(:User)
    class User < ActiveResource::Base
      self.site = REMOTE_HOST
      self.element_name = "user"
    end
    @body = [{user: {id: 1, name: "User A"}}].to_json
    @full_body = [
      {user: {id: 1, name: "User A"}},
      {user: {id: 2, name: "User B"}}
    ].to_json
  end

  before(:each) do
    add_profile(1, 1, "letter A")
  end

  it "uses it's defaults" do
    unset_const(:Profile)
    class Profile < ActiveRecord::Base
      include RemoteAssociation::Base
      belongs_to_remote :user
    end
    FakeWeb.register_uri(:get, "#{REMOTE_HOST}/users.json?id%5B%5D=1", body: @body)

    Profile.first.user.name.should eq('User A')
  end

  it 'should prefetch remote associations of models with defaults (single request)' do
    add_profile(2, 2, "letter B")
    FakeWeb.register_uri(:get, "#{REMOTE_HOST}/users.json?id%5B%5D=1&id%5B%5D=2", body: @full_body)

    profiles = Profile.scoped.includes_remote(:user)
    profiles.first.user.name.should eq('User A')
    profiles.last.user.name.should eq('User B')
  end

  it "should not request remote collection in single request when all foreign_keys are nil" do
    Profile.delete_all
    add_profile(1, 'NULL', "A")
    add_profile(2, 'NULL', "A")
    profiles = Profile.scoped.includes_remote(:user)
    profiles.map(&:user).should eq [nil, nil]
  end

  it "should not request remote data when foreign_key value is nil" do
    profile = Profile.new(user_id: nil)
    profile.user.should_not raise_error FakeWeb::NetConnectNotAllowedError
    profile.user.should be_nil
  end

  describe "has options:"  do
    it ":class_name - able to choose custom class of association" do
      unset_const(:Profile)
      unset_const(:CustomUser)
      class CustomUser < ActiveResource::Base
        self.site = REMOTE_HOST
        self.element_name = "user"
      end
      class Profile < ActiveRecord::Base
        include RemoteAssociation::Base
        belongs_to_remote :user, class_name: "CustomUser"
      end
      FakeWeb.register_uri(:get, "#{REMOTE_HOST}/users.json?id%5B%5D=1", body: @body)
    end

    it ":foreign_key - can set key to extract from it's model" do
      unset_const(:Profile)
      class Profile < ActiveRecord::Base
        include RemoteAssociation::Base
        belongs_to_remote :user, foreign_key: :login_id
        def login_id; user_id; end
      end
      FakeWeb.register_uri(:get, "#{REMOTE_HOST}/users.json?id%5B%5D=1", body: @body)
    end

    after(:each) do
      Profile.first.user.name.should eq('User A')
    end
  end
end
