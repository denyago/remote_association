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

  it 'returns nil if no object present' do
    unset_const(:Profile)
    class Profile < ActiveRecord::Base
      include RemoteAssociation::Base
      belongs_to_remote :user
    end
    FakeWeb.register_uri(:get, "#{REMOTE_HOST}/users.json?id%5B%5D=1", body: [].to_json)

    Profile.first.user.should be_nil
  end

  it 'should prefetch remote associations of models with defaults (single request)' do
    add_profile(2, 2, "letter B")
    FakeWeb.register_uri(:get, "#{REMOTE_HOST}/users.json?id%5B%5D=1&id%5B%5D=2", body: @full_body)

    profiles = Profile.scoped.includes_remote(:user).all
    profiles.first.user.name.should eq('User A')
    profiles.last.user.name.should eq('User B')
  end

  it "should not request remote collection in single request when all foreign_keys are nil" do
    Profile.delete_all
    add_profile(1, 'NULL', "A")
    add_profile(2, 'NULL', "A")
    profiles = Profile.scoped.includes_remote(:user).all
    profiles.map(&:user).should eq [nil, nil]
  end

  it "should not request remote data when foreign_key value is nil" do
    profile = Profile.new(user_id: nil)
    profile.user.should be_nil
  end

  describe "#build_params_hash_for_relation" do
    it "returns valid Hash of HTTP query string parameters" do
      unset_const(:Profile)
      class Profile < ActiveRecord::Base
        include RemoteAssociation::Base
        belongs_to_remote :user
      end

      Profile.build_params_hash_for_user(10).should eq({'id' => [10]})
      Profile.build_params_hash_for_user([10, 13, 15]).should eq({'id' => [10, 13, 15]})
    end
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

    it ":primary_key - can set key to query from remote API" do
      unset_const(:Profile)
      class Profile < ActiveRecord::Base
        include RemoteAssociation::Base
        belongs_to_remote :user, primary_key: 'search[id_in]'
      end
      FakeWeb.register_uri(:get, "#{REMOTE_HOST}/users.json?search%5Bid_in%5D%5B%5D=1", body: @body)
    end

    after(:each) do
      Profile.first.user.name.should eq('User A')
    end
  end

  context "safe when using several remotes" do
    before do
      unset_const(:User)
      class User < ActiveRecord::Base
        include RemoteAssociation::Base
        belongs_to_remote :foo, foreign_key: 'user_side_foo_id', class_name: "CustomFoo", primary_key: 'foo_id'
        belongs_to_remote :bar, foreign_key: 'user_side_bar_id', class_name: "CustomBar", primary_key: 'bar_id'

        def user_side_foo_id; self.id; end
        def user_side_bar_id; self.id; end
      end
      class CustomFoo < ActiveResource::Base
        self.site = REMOTE_HOST
        self.element_name = "foo"
      end
      class CustomBar < ActiveResource::Base
        self.site = REMOTE_HOST
        self.element_name = "bar"
      end

      @foo_body = [{foo: {id: 1, foo_id: 1, value: "F1"}}].to_json
      @bar_body = [{bar: {id: 1, bar_id: 1, value: "B1"}}].to_json

      FakeWeb.register_uri(:get, "#{REMOTE_HOST}/foos.json?foo_id%5B%5D=1", body: @foo_body)
      FakeWeb.register_uri(:get, "#{REMOTE_HOST}/bars.json?bar_id%5B%5D=1", body: @bar_body)
    end

    it "returns remotes respectively by primary and classname" do
      User.delete_all
      add_user(1, 'Tester')
      User.first.foo.id.should == 1
      User.first.foo.value.should == 'F1'
      User.first.bar.id.should == 1
      User.first.bar.value.should == 'B1'
    end
  end
end
