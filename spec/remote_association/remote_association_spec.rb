require 'spec_helper'

describe RemoteAssociation do
  before(:all) do
    class Profile < ActiveResource::Base
      self.site = "http://127.0.0.1:3000"
    end
    class User < ActiveRecord::Base
      include RemoteAssociation
      belongs_to_remote :profile
    end
  end

  it 'should load remote associations of models' do
    add_user(1,"User A")
    add_user(2,"User B")
    puts User.all.inspect
  end
end
