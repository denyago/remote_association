require 'spec_helper'

describe RemoteAssociation, "method :has_one_remote" do
  before(:all) do
    class CustomProfile < ActiveResource::Base
      self.site = REMOTE_HOST
      self.element_name = "profile"
    end
  end

  before(:each) do
    add_user(1,"User A")
    add_user(2,"User B")
    @body = [PROFILES_JSON.first].to_json
  end

  it "uses it's defaults" do
    class User < ActiveRecord::Base
      include RemoteAssociation::Base
      has_one_remote :custom_profile
    end
    FakeWeb.register_uri(:get, "#{REMOTE_HOST}/profiles.json?user_id%5B%5D=1", body: @body )

    User.first.custom_profile.like.should eq('letter A')
  end

  describe "has options:"  do
    it ":class_name - able to choose custom class of association" do
      class User < ActiveRecord::Base
        include RemoteAssociation::Base
        has_one_remote :profile, class_name: "CustomProfile"
      end
      FakeWeb.register_uri(:get, "#{REMOTE_HOST}/profiles.json?user_id%5B%5D=1", body: @body )
    end
    it ":foreign_key - can set uri param for search" do
      class Profile < ActiveResource::Base
        self.site = REMOTE_HOST
      end
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
