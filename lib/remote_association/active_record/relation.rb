require 'ostruct'

module ActiveRecord
  class Relation
    # Queues loading of relations to ActiveModel models of models, selected by current relation.
    # The full analogy is <tt>includes(*args)</tt> of ActiveRecord: all the realted objects will
    # be loaded when one or all objects of relation are required.
    #
    # May raise <tt>RemoteAssociation::SettingsNotFoundError</tt> if one of args can't be found among
    # Class.activeresource_relations settings
    #
    # Would not perform remote request if all associated foreign_keys of belongs_to_remote association are nil
    #
    # Returns self - <tt>ActiveRecord::Relation</tt>
    #
    # === Examples
    #
    # Author.scoped.includes_remote(:profile, :avatar).where(author_name: 'Tom').all
    def includes_remote(*args)
      args.each do |r|
        settings = klass.activeresource_relations[r.to_sym]
        raise RemoteAssociation::SettingsNotFoundError, "Can't find settings for #{r} association" if settings.blank?

        if settings[:polymorphic]
          puts "Preload of polymorphic associations not supported"
          next
        end

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

    # Adds conditions (i.e. http query string parameters) to request of each remote API. Those are parameters to query string.
    #
    # Returns self - <tt>ActiveRecord::Relation</tt>
    #
    # === Example
    #
    # Author.scoped.includes_remote(:profile, :avatar).where_remote(profile: {search: {public: true}}, avatar: { primary: true }).all
    #
    # #=> Will do requests to:
    # #  * http://.../prefiles.json?author_id[]=1&author_id[]=N&search[public][]=true
    # #  * http://.../avatars.json?author_id[]=1&author_id[]=N&primary=true
    def where_remote(conditions = {})
      conditions.each do |association, conditions|
        remote_conditions[association.to_sym] = remote_conditions[association.to_sym].deep_merge(conditions)
      end

      self
    end

  private

    # Array of remote associations to load.
    # It contains Hashes with settings for loader.
    attr_accessor :remote_associations

    def remote_associations
      @remote_associations ||= []
    end

    # Hash of parameters to merge into API requests.
    attr_accessor :remote_conditions

    def remote_conditions
      @remote_conditions ||= Hash.new({})
    end

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

      set_remote_resources_loaded unless remote_associations.empty?
    end

    def fetch_and_join_for_has_any_remote(settings)
      keys = @records.uniq.map(&:id)

      remote_objects = fetch_remote_objects(settings.ar_class, keys, settings.ar_accessor)
      join_key = klass.primary_key

      @records.each do |record|
        record.send("#{settings.ar_accessor}=", remote_objects.select { |s| s.send(settings.foreign_key) == record.send(join_key) })
      end
    end

    def fetch_and_join_for_belongs_to_remote(settings)
      keys = @records.uniq.map {|r| r.send settings.foreign_key.to_sym }.compact

      return if keys.empty?

      remote_objects = fetch_remote_objects(settings.ar_class, keys, settings.ar_accessor)
      join_key = settings.ar_class.primary_key

      @records.each do |record|
        record.send("#{settings.ar_accessor}=", remote_objects.select { |s| record.send(settings.foreign_key) == s.send(join_key) })
      end
    end

    def set_remote_resources_loaded
      @remote_resources_loaded = true
      @records.each do |record|
        record.instance_variable_set(:@remote_resources_loaded, true)
      end
    end

    def fetch_remote_objects(ar_class, keys, ar_accessor)
      params = klass.send(:"build_params_hash_for_#{ar_accessor}", keys).deep_merge(remote_conditions[ar_accessor.to_sym])
      ar_class.find(:all, :params => params )
    end

    def remote_resources_loaded?
      !!@remote_resources_loaded
    end
  end
end
