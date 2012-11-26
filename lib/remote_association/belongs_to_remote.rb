module RemoteAssociation
  module BelongsToRemote
      # Specifies a one-to-one association with another class. This method should only be used
      # if this class contains the foreign key. If the other class contains the foreign key,
      # then you should use +has_one_remote+ instead.
      #
      # Methods will be added for retrieval and query for a single associated object, for which
      # this object holds an id:
      #
      # [association]
      #   Returns the associated object. +nil+ is returned if none is found.
      #   When foreign_key value is nil, remote request would not be executed.
      # [association=(associate)]
      #   Just setter, no saves.
      #
      # (+association+ is replaced with the symbol passed as the first argument, so
      # <tt>belongs_to_remote :author</tt> would add among others <tt>author.nil?</tt>.)
      #
      # === Example
      #
      # A Post class declares <tt>belongs_to_remote :author</tt>, which will add:
      # * <tt>Post#author</tt> (similar to <tt>Author.find(:first, params: { id: [post.author_id]})</tt>)
      # * <tt>Post#author=(author)</tt> (will set @author instance variable of Post# to author value)
      # The declaration can also include an options hash to specialize the behavior of the association.
      #
      # === Options
      #
      # [:class_name]
      # Specify the class name of the association. Use it only if that name can't be inferred
      # from the association name. So <tt>belongs_to_remote :author</tt> will by default be linked to the Author class, but
      # if the real class name is Person, you'll have to specify it with this option.
      # [:foreign_key]
      # Specify the foreign key used for the association. By default this is guessed to be the name
      # of the association with an "_id" suffix. So a class that defines a <tt>belongs_to_remote :person</tt>
      # association will use "person_id" as the default <tt>:foreign_key</tt>. Similarly,
      # <tt>belongs_to_remote :favorite_person, :class_name => "Person"</tt> will use a foreign key
      # of "favorite_person_id".
      # [:primary_key]
      # Specify the http query parameter to find associated object used for the association. By default this is <tt>id</tt>.
      # Example:
      #  belongs_to_remote :firm, :primary_key => 'search[id_in]' #=> ...?firms.json?search%5Bid_in%5D%5B%5D=1
      #
      # Option examples:
      #   belongs_to_remote :firm, :foreign_key => "client_of"
      #   belongs_to_remote :author, :class_name => "Person", :foreign_key => "author_id"
      def belongs_to_remote(remote_rel, options ={})
        rel_options = {
                       class_name:  remote_rel.to_s.classify,
                       foreign_key: remote_rel.to_s.foreign_key,
                       association_type: :belongs_to_remote,
                       primary_key: primary_key
                      }.merge(options.symbolize_keys)

        add_activeresource_relation(remote_rel.to_sym, rel_options)

        class_eval <<-RUBY, __FILE__, __LINE__+1

          attr_accessor :#{remote_rel}

          def #{remote_rel}
            if remote_resources_loaded?
              @#{remote_rel} ? @#{remote_rel}.first : nil
            else
              @#{remote_rel} ||= self.#{rel_options[:foreign_key]}.present? ? #{rel_options[:class_name]}.find(:first, params: self.class.build_params_hash(self.#{rel_options[:foreign_key]})) : nil
            end
          end

          ##
          # Returns Hash with HTTP parameters to query remote API
          def self.build_params_hash(keys)
            keys = [keys] unless keys.kind_of?(Array)
            {"#{rel_options[:primary_key]}" => keys}
          end

        RUBY

      end
  end
end
