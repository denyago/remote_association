require "active_record"
require "active_support"

require "remote_association/version"
require "remote_association/has_one_remote"
require "remote_association/has_many_remote"
require "remote_association/belongs_to_remote"
require "remote_association/active_record/relation"

module RemoteAssociation

  # Include this class to hav associations to ActiveResource models
  #
  # It will add methods to your class:
  # * <tt>has_one_remote(name, *options)</tt>
  # * <tt>has_many_remote(name, *options)</tt>
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
      include RemoteAssociation::HasOneRemote
      include RemoteAssociation::HasManyRemote
      include RemoteAssociation::BelongsToRemote

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
