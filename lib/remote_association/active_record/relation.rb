module ActiveRecord
  class Relation
    # Loads relations to ActiveModel models of models, selected by current relation.
    # The analogy is <tt>includes(*args)</tt> of ActiveRecord.
    #
    # May raise <tt>RemoteAssociation::SettingsNotFoundError</tt> if one of args can't be found among
    # Class.activeresource_relations settings
    #
    # Returns all the records matched by the options of the relation, same as <tt>all(*args)</tt>
    #
    # === Examples
    #
    # Author.scoped.includes_remote(:profile, :avatar)
    def includes_remote(*args)
      args.each do |r|
        settings = klass.activeresource_relations[r.to_sym]
        raise RemoteAssociation::SettingsNotFoundError, "Can't find settings for #{r} association" if settings.blank?

        ar_accessor = r.to_sym
        foreign_key = settings[:foreign_key]
        ar_class    = settings[:class_name ].constantize

        fetch_and_join_for_has_one_remote(ar_accessor, foreign_key, ar_class) if settings[:association_type] == :has_one_remote
        fetch_and_join_for_belongs_to_remote(ar_accessor, foreign_key, ar_class) if settings[:association_type] == :belongs_to_remote
      end

      set_remote_resources_prefetched

      self.all
    end

    private

      def fetch_and_join_for_has_one_remote(ar_accessor, foreign_key, ar_class)
        keys = self.uniq.pluck(:id)

        remote_objects = fetch_remote_objects(ar_class, keys)

        self.each do |u|
          u.send("#{ar_accessor}=", remote_objects.select {|s| s.send(foreign_key) == u.id })
        end
      end

      def fetch_and_join_for_belongs_to_remote(ar_accessor, foreign_key, ar_class)
        keys = self.uniq.pluck(foreign_key.to_sym)

        remote_objects = fetch_remote_objects(ar_class, keys)

        self.each do |u|
          u.send("#{ar_accessor}=", remote_objects.select {|s| u.send(foreign_key) == s.id })
        end
      end

      def set_remote_resources_prefetched
        self.each do |u|
          u.instance_variable_set(:@remote_resources_prefetched, true)
        end
      end

      def fetch_remote_objects(ar_class, keys)
        ar_class.find(:all, :params => klass.build_params_hash(keys))
      end

  end
end
