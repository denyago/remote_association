[![Build Status](https://secure.travis-ci.org/denyago/remote_association.png?branch=master)](http://travis-ci.org/denyago/remote_association)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/denyago/remote_association)

# Remote Association

  Add ```has_one_remote```, ```has_many_remote```, and ```belongs_to_remote``` associations to models inherited from ActiveResource::Base

  Say, you have Author and a service with Profiles. You can access profile of author as easy as `author.profile`.

  Also, if you have 10K profiles and you need 3 of them, it won't load all profiles and won't do 3 requests to API.
  Instead, just use ```Author.scoped.includes_remote(:profile)``` and it will do a get request like this one:

  ```GET http://example.com/profiles?author_id[]=1&author_id[]=2&author_id[]=3```

  Don't want to use default ```author_id```? You can alter class of ```profile``` association and ```author_id``` key by options.
  Just like in ActiveRecord.

  Notice, that for now, associations work in read-only mode.

## Example

```ruby
  class UserGroup < ActiveResource::Base
    self.site = 'http://example.com'
  end

  class Profile < ActiveResource::Base
    self.site = 'http://example.com'
  end

  class Badge < ActiveResource::Base
    self.site = 'http://example.com'
  end

  class User < ActiveRecord::Base
    include RemoteAssociation::Base

    has_one_remote      :profile
    has_many_remote     :badges
    belongs_to_remote   :group, class_name: 'UserGroup', foreign_key: :group_id, primary_key: 'search[id_in]'
  end

  User.first.profile   # => <Profile>
  User.first.group     # => <Group>
  User.first.badges    # => [<Badge>, <Badge>]
```

## Advanced  usage

```ruby
  # Will load associated objects, when we will need them
  users = Users.scoped.includes_remote(:profile, :badges)

  # just adding SQL condition to out users relation
  users = users.where(active: true)

  # add additional search condition for request to Profiles API
  users = users.where_remote(profile: {search: {kind_in: ['Facebook', 'GitHub']}})

  # time to do ordering and pagination...
  users = users.offset.(100).limit(5).order('name ASC')

  # Fetch 10 users from DB, fetch 10 Profiles and Avatars for those users
  users = users.all
```

## Installation

Add this line to your application's Gemfile:

    gem 'remote_association'

## Contributing

1. Fork it
2. Set up testing database via

    rake spec:db:setup

3. Create your feature branch

    git checkout -b my-new-feature

4. Add tests and run via `rspec`
5. Commit your changes

    git commit -am 'Added some feature'

6. Push to the branch

    git push origin my-new-feature

7. Create new Pull Request
