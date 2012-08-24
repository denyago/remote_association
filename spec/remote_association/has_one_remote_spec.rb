require 'spec_helper'

describe RemoteAssociation, "method :has_one_remote" do
  before(:all) do
    @body = [{profile: {id: 1, user_id: 1, like: "letter A"}}].to_json
    @full_body = [
      {profile: {id: 1, user_id: 1, like: "letter A"}},
      {profile: {id: 2, user_id: 2, like: "letter B"}}
    ].to_json
  end

  before(:each) do
    unset_const(:User)
    unset_const(:Profile)
    class User < ActiveRecord::Base
      include RemoteAssociation::Base
      has_one_remote :profile
    end
    class Profile < ActiveResource::Base
      self.site = REMOTE_HOST
    end

    add_user(1,"User A")
    add_user(2,"User B")
  end

  it "uses it's defaults" do
    FakeWeb.register_uri(:get, "#{REMOTE_HOST}/profiles.json?user_id%5B%5D=1", body: @body )

    User.first.profile.like.should eq('letter A')
  end

  it 'should prefetch remote associations of models with defaults (single request)' do
    FakeWeb.register_uri(:get, "#{REMOTE_HOST}/profiles.json?user_id%5B%5D=1&user_id%5B%5D=2", body: @full_body)

    users = User.scoped.includes_remote(:profile)
    users.first.profile.like.should eq('letter A')
    users.last.profile.like.should eq('letter B')
  end

  describe "has options:"  do
    it ":class_name - able to choose custom class of association" do
      unset_const(:User)
      unset_const(:CustomProfile)
      class CustomProfile < ActiveResource::Base
        self.site = REMOTE_HOST
        self.element_name = "profile"
      end
      class User < ActiveRecord::Base
        include RemoteAssociation::Base
        has_one_remote :profile, class_name: "CustomProfile"
      end
      FakeWeb.register_uri(:get, "#{REMOTE_HOST}/profiles.json?user_id%5B%5D=1", body: @body )
    end
    it ":foreign_key - can set uri param for search" do
      unset_const(:User)
      class User < ActiveRecord::Base
        include RemoteAssociation::Base
        has_one_remote :profile, foreign_key: :login_id
      end
      FakeWeb.register_uri(:get, "#{REMOTE_HOST}/profiles.json?login_id%5B%5D=1", body: @body)
    end
    after(:each) do
      User.first.profile.like.should eq('letter A')
    end
  end
end
