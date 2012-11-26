module RemoteAssociation
  module HasManyRemote
    # Specifies a one-to-many association with another class. This method should only be used
    # if this class is a kind of ActiveResource::Base and service for this resource can
    # return some kind of foreign key.
    #
    # Methods will be added for retrieval and query for a single associated object, for which
    # this object holds an id:
    #
    # [associations()]
    #   Returns the associated objects. +[]+ is returned if none is found.
    # [associations=(associates)]
    #   Just setter, no saves.
    #
    # (+associations+ is replaced with the symbol passed as the first argument, so
    # <tt>has_many_remote :authors</tt> would add among others <tt>authors.nil?</tt>.)
    #
    # === Example
    #
    # A Author class declares <tt>has_many_remote :profiles</tt>, which will add:
    # * <tt>Author#profiles</tt> (similar to <tt>Profile.find(:all, params: { author_id: [author.id]})</tt>)
    # * <tt>Author#profiles=(profile)</tt> (will set @profiles instance variable of Author# to profile value)
    # The declaration can also include an options hash to specialize the behavior of the association.
    #
    # === Options
    #
    # [:class_name]
    #   Specify the class name of the association. Use it only if that name can't be inferred
    #   from the association name. So <tt>has_many_remote :profiles</tt> will by default be linked to the Profile class, but
    #   if the real class name is SocialProfile, you'll have to specify it with this option.
    # [:foreign_key]
    #   Specify the foreign key used for searching association on remote service. By default this is guessed to be the name
    #   of the current class with an "_id" suffix. So a class Author that defines a <tt>has_many_remote :profiles</tt>
    #   association will use "author_id" as the default <tt>:foreign_key</tt>.
    #   This key will be used in :get request. Example: <tt>GET http://example.com/profiles?author_id[]=1</tt>
    #
    # Option examples:
    #   has_many_remote :firms, :foreign_key => "client_of"
    #   has_many_remote :badges, :class_name => "Label", :foreign_key => "author_id"
    def has_many_remote(remote_rel, options ={})
      rel_options = {
          class_name: remote_rel.to_s.singularize.classify,
          foreign_key: self.model_name.to_s.foreign_key,
          association_type: :has_many_remote
      }.merge(options.symbolize_keys)

      add_activeresource_relation(remote_rel.to_sym, rel_options)

      class_eval <<-RUBY, __FILE__, __LINE__+1

        attr_accessor :#{remote_rel}

        def #{remote_rel}                                                 #  def customers
          if remote_resources_loaded?                                     #    if remote_resources_loaded?
            @#{remote_rel} ? @#{remote_rel} : []                          #      @customers ? @customers : []
          else                                                            #    else
            join_key = self.class.primary_key                             #      join_key = self.class.primary_key
            @#{remote_rel} ||= #{rel_options[:class_name]}.               #      @customers ||= Person.
              find(:all, params: self.class.                              #        find(:all, params: self.class.
                build_params_hash(self.send(join_key)))                   #          build_params_hash(self.send(join_key)))
          end                                                             #    end
        end                                                               #  end

        ##
        # Returns Hash with HTTP parameters to query remote API
        def self.build_params_hash(keys)
          keys = [keys] unless keys.kind_of?(Array)
          {"#{rel_options[:foreign_key]}" => keys}
        end

      RUBY
    end
  end
end
