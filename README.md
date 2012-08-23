[![Build Status](https://secure.travis-ci.org/denyago/remote_association.png?branch=master)](http://travis-ci.org/denyago/remote_association)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/denyago/remote_association)

# Remote Association

  Add ```has_``` and ```belongs_``` associations to models inherited from ActiveResource::Base

  Say, you have Author and a service with Profiles. You can access profile of author as easy as `author.profile`.

  Also, if you have 10K profiles and you need 3 of them, it won't load all profiles and won't do 3 requests to API.
  Instead, just use ```Author.scoped.includes_remote(:profile)``` and it will do a get request like this one:

  ```GET http://example.com/profiles?author_id[]=1&author_id[]=2&author_id[]=3```

  Don't want to use default ```author_id```? You can alter class of ```profile``` association and ```author_id``` key by options.
  Just like in ActiveRecord.

  Notice, that for now, associations work in read-only mode.

## Example

```ruby
  class Profile < ActiveResource::Base
    self.site = REMOTE_HOST
  end
  class User < ActiveRecord::Base
    include RemoteAssociation::Base
    has_one_remote :profile
  end

  User.first.profile

```

## Installation

Add this line to your application's Gemfile:

    gem 'remote_association'

## TODO

Implement 'has_many_remote' analogie of 'AR.has_many'

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
