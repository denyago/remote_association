require 'ostruct'

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

        ar_class = settings[:class_name].constantize

        remote_associations << OpenStruct.new(
                                ar_accessor:      r.to_sym,
                                foreign_key:      settings[:foreign_key],
                                ar_class:         ar_class,
                                association_type: settings[:association_type]
                              )
      end

      self
    end

    attr_accessor :remote_associations

    def remote_associations
      @remote_associations ||= []
    end

  private

    # A method proxy for exec_queries: it wraps around original one
    # and preloads remote associations. Returns {Array} of fetched
    # records, like original exec_queries.
    def exec_queries_with_remote_associations
      exec_queries_without_remote_associations
      preload_remote_associations
      @records
    end

    alias_method :exec_queries_without_remote_associations, :exec_queries
    alias_method :exec_queries, :exec_queries_with_remote_associations

    # Does heavy lifting on fetching remote associations from distant places:
    #   - checks, if remote_resources_loaded? already
    #   - iterates through remote_associations and loads objects for each one
    def preload_remote_associations
      return true if remote_resources_loaded?

      remote_associations.each do |r|
        case r.association_type
          when :has_one_remote    then fetch_and_join_for_has_any_remote(r)
          when :has_many_remote   then fetch_and_join_for_has_any_remote(r)
          when :belongs_to_remote then fetch_and_join_for_belongs_to_remote(r)
        end
      end

      set_remote_resources_prefetched unless remote_associations.empty?
    end

    def fetch_and_join_for_has_any_remote(settings)
      keys = @records.uniq.map(&:id)

      remote_objects = fetch_remote_objects(settings.ar_class, keys)

      @records.each do |r|
        r.send("#{settings.ar_accessor}=", remote_objects.select { |s| s.send(settings.foreign_key) == r.id })
      end
    end

    def fetch_and_join_for_belongs_to_remote(settings)
      keys = @records.uniq.map {|r| r.send settings.foreign_key.to_sym }.compact

      return if keys.empty?

      remote_objects = fetch_remote_objects(settings.ar_class, keys)

      @records.each do |r|
        r.send("#{settings.ar_accessor}=", remote_objects.select { |s| r.send(settings.foreign_key) == s.id })
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

    def remote_resources_loaded?
      !!@remote_resources_loaded
    end

  end
end
