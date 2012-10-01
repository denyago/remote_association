module ActiveRecord
  class Relation
    # Loads relations to ActiveModel models of models, selected by current relation.
    # The analogy is <tt>includes(*args)</tt> of ActiveRecord.
    #
    # May raise <tt>RemoteAssociation::SettingsNotFoundError</tt> if one of args can't be found among
    # Class.activeresource_relations settings
    #
    # Would not perform remote request if all associated foreign_keys of belongs_to_remote association are nil
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
        ar_class = settings[:class_name].constantize
        association_type = settings[:association_type]

        @remote_associations = (@remote_associations || [])
        @remote_associations << {ar_accessor: ar_accessor, foreign_key: foreign_key,
                                 ar_class: ar_class, association_type: association_type}

      end

      self
    end

  private

    def exec_queries_with_remote_associations
      exec_queries_without_remote_associations
      preload_remote_associations
      @records
    end

    alias_method :exec_queries_without_remote_associations, :exec_queries
    alias_method :exec_queries, :exec_queries_with_remote_associations

    def preload_remote_associations
      return true if @remote_resources_loaded

      (@remote_associations || []).each do |r|

        fetch_and_join_for_has_one_remote(   r[:ar_accessor], r[:foreign_key], r[:ar_class]) if r[:association_type] == :has_one_remote
        fetch_and_join_for_has_many_remote(  r[:ar_accessor], r[:foreign_key], r[:ar_class]) if r[:association_type] == :has_many_remote
        fetch_and_join_for_belongs_to_remote(r[:ar_accessor], r[:foreign_key], r[:ar_class]) if r[:association_type] == :belongs_to_remote
      end
      set_remote_resources_prefetched unless @remote_associations.blank?
    end

    def fetch_and_join_for_has_one_remote(ar_accessor, foreign_key, ar_class)
      keys = @records.uniq.map(&:id)

      remote_objects = fetch_remote_objects(ar_class, keys)

      @records.each do |u|
        u.send("#{ar_accessor}=", remote_objects.select { |s| s.send(foreign_key) == u.id })
      end
    end

    def fetch_and_join_for_has_many_remote(ar_accessor, foreign_key, ar_class)
      keys = @records.uniq.map(&:id)

      remote_objects = fetch_remote_objects(ar_class, keys)

      @records.each do |r|
        r.send("#{ar_accessor}=", remote_objects.select { |s| s.send(foreign_key) == r.id })
      end
    end

    def fetch_and_join_for_belongs_to_remote(ar_accessor, foreign_key, ar_class)
      keys = @records.uniq.map {|r| r.send foreign_key.to_sym }.compact

      return if keys.empty?

      remote_objects = fetch_remote_objects(ar_class, keys)

      @records.each do |u|
        u.send("#{ar_accessor}=", remote_objects.select { |s| u.send(foreign_key) == s.id })
      end
    end

    def set_remote_resources_prefetched
      @remote_resources_loaded = true
      @records.each do |u|
        u.instance_variable_set(:@remote_resources_prefetched, true)
      end
    end

    def fetch_remote_objects(ar_class, keys)
      ar_class.find(:all, :params => klass.build_params_hash(keys))
    end

  end
end
