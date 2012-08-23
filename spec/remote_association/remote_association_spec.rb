require 'spec_helper'

describe RemoteAssociation do
  before(:all) do
    REMOTE_HOST = "http://127.0.0.1:3000"
    PROFILES_JSON = [
      {profile: {id: 1, user_id: 1, like: "letter A"}},
      {profile: {id: 2, user_id: 2, like: "letter B"}}
    ]
  end

  before(:each) do
    class Profile < ActiveResource::Base
      self.site = REMOTE_HOST
    end
    class User < ActiveRecord::Base
      include RemoteAssociation
      belongs_to_remote :profile
    end

    add_user(1,"User A")
    add_user(2,"User B")
  end

  it 'should prefetch remote associations of models with defaults (single request)' do
    FakeWeb.register_uri(:get, "#{REMOTE_HOST}/profiles.json?user_id%5B%5D=1&user_id%5B%5D=2", body: PROFILES_JSON.to_json)

    users = User.scoped.prefetch_remote_associations
    users.first.profile.like.should eq('letter A')
    users.last.profile.like.should eq('letter B')
  end

  it 'should autoload remote associations of each models without prefetching (1+N requiests)' do
    FakeWeb.register_uri(:get, "#{REMOTE_HOST}/profiles.json?user_id%5B%5D=1", body: [PROFILES_JSON.first].to_json)
    FakeWeb.register_uri(:get, "#{REMOTE_HOST}/profiles.json?user_id%5B%5D=2", body: [PROFILES_JSON.last].to_json)

    users = User.scoped
    users.first.profile.like.should eq('letter A')
    users.last.profile.like.should eq('letter B')
  end

  describe "method :belongs_to_remote with options:" do
    before(:each) do
      @body = [PROFILES_JSON.first].to_json
    end
    it ":class_name - able to choose custom class of association" do
      class CustomProfile < ActiveResource::Base
        self.site = REMOTE_HOST
        self.element_name = "profile"
      end
      class User < ActiveRecord::Base
        include RemoteAssociation
        belongs_to_remote :profile, class_name: "CustomProfile"
      end
      FakeWeb.register_uri(:get, "#{REMOTE_HOST}/profiles.json?user_id%5B%5D=1", body: @body )
    end
    it ":foreign_key - can set uri param for search" do
       class CustomProfile < ActiveResource::Base
        self.site = REMOTE_HOST
        self.element_name = "profile"
      end
      class User < ActiveRecord::Base
        include RemoteAssociation
        belongs_to_remote :profile, foreign_key: :login_id
      end
      FakeWeb.register_uri(:get, "#{REMOTE_HOST}/profiles.json?login_id%5B%5D=1", body: @body)
    end
    after(:each) do
      User.first.profile.like.should eq('letter A')
    end
  end
end
