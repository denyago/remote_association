require "active_record"
require "active_support"

require "remote_association/version"
require "remote_association/active_record/relation"

module RemoteAssociation

  # Include this class to hav associations to ActiveResource models
  #
  # It will add methods to your class:
  # * <tt>has_one_remote(name, *oprions)</tt>
  # * <tt>activeresource_relations</tt>
  # * <tt>add_activeresource_relation(name, options)</tt>
  module Base
    def self.included(base)
      base.extend ClassMethods
      base.send :include, InstanceMethods

      base.class_eval do
      end
    end

    module ClassMethods
      # Specifies a one-to-one association with another class. This method should only be used
      # if this class is a kind of ActiveResource::Base and service for this resource can
      # return some kind of foreign key.
      #
      # Methods will be added for retrieval and query for a single associated object, for which
      # this object holds an id:
      #
      # [association()]
      #   Returns the associated object. +nil+ is returned if none is found.
      # [association=(associate)]
      #   Just setter, no saves.
      #
      # (+association+ is replaced with the symbol passed as the first argument, so
      # <tt>has_one_remote :author</tt> would add among others <tt>author.nil?</tt>.)
      #
      # === Example
      #
      # A Author class declares <tt>has_one_remote :profile</tt>, which will add:
      # * <tt>Authort#profile</tt> (similar to <tt>Profile.find(:first, params: { author_id: [author.id]})</tt>)
      # * <tt>Author#profile=(profile)</tt> (will set @profile instance variable of Author# to profile value)
      # The declaration can also include an options hash to specialize the behavior of the association.
      #
      # === Options
      #
      # [:class_name]
      #   Specify the class name of the association. Use it only if that name can't be inferred
      #   from the association name. So <tt>has_one_remote :profile</tt> will by default be linked to the Profile class, but
      #   if the real class name is SocialProfile, you'll have to specify it with this option.
      # [:foreign_key]
      #   Specify the foreign key used for searching association on remote service. By default this is guessed to be the name
      #   of the current class with an "_id" suffix. So a class Author that defines a <tt>has_one_remote :profile</tt>
      #   association will use "author_id" as the default <tt>:foreign_key</tt>.
      #   This key will be used in :get request. Example: <tt>GET http://example.com/profiles?author_id[]=1</tt>
      #
      # Option examples:
      #   has_one_remote :firm, :foreign_key => "client_of"
      #   has_one_remote :author, :class_name => "Person", :foreign_key => "author_id"
      def has_one_remote(remote_rel, options ={})
        rel_options = {
                       class_name: remote_rel.to_s.classify,
                       foreign_key: self.model_name.to_s.foreign_key
                      }.merge(options.symbolize_keys)

        add_activeresource_relation(remote_rel.to_sym, rel_options)

        class_eval <<-RUBY, __FILE__, __LINE__+1

          attr_accessor :#{remote_rel}

          def #{remote_rel}
            if remote_resources_prefetched?
              @#{remote_rel} ? @#{remote_rel}.first : nil
            else
              @#{remote_rel} ||= #{rel_options[:class_name]}.find(:first, params: { #{rel_options[:foreign_key]}: [self.id]})
            end
          end

        RUBY

      end

      # Adds settings of relation to ActiveResource model.
      #
      # === Parameters
      # * <tt>name</tt> a Symbol, representing name of association
      # * <tt>options</tt> a Hash, contains :class_name and :foreign_key settings
      #
      # === Examples
      #
      # Author.add_activeresource_relation(:profile, {class_name: "Profile", foreign_key: "author_id"})
      def add_activeresource_relation(name, options)
        existing_relations = activeresource_relations
        existing_relations[name] = options
        @activeresource_relations = existing_relations
      end

      # Returns settings for relations to ActiveResource models.
      #
      # === Examples
      #
      # Author.activeresource_relations #=> [{profile: {class_name: "Profile", foreign_key: "author_id"}}]
      def activeresource_relations
        @activeresource_relations ||= {}
      end
    end

    module InstanceMethods

      # Returns <tt>true</tt> if associations to remote relations already loaded and set
      def remote_resources_prefetched?
        @remote_resources_prefetched
      end
    end
  end

  class SettingsNotFoundError < StandardError; end
end
