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
        foregin_key = settings[:foreign_key]
        ar_class    = settings[:class_name ].constantize

        fetch_and_join_for_has_one_remote(ar_accessor, foregin_key, ar_class) if settings[:association_type] == :has_one_remote
      end

      set_remote_resources_prefetched

      self.all
    end

    private

      def fetch_and_join_for_has_one_remote(ar_accessor, foregin_key, ar_class)
        keys = self.uniq.pluck(:id)

        remote_objects = ar_class.find(:all, :params => { foregin_key => keys })

        self.each do |u|
          u.send("#{ar_accessor}=", remote_objects.select {|s| s.send(foregin_key) == u.id })
        end
      end

      def set_remote_resources_prefetched
        self.each do |u|
          u.instance_variable_set(:@remote_resources_prefetched, true)
        end
      end

  end
end
