module ActiveRecord
  class Relation
    def prefetch_remote_associations
      keys = self.map(&:id)

      klass.activeresource_relations.each do |k,d|
        join_key = d[:join_key]
        activeresource_accessor = k.to_s
        activeresource_klass = d[:klass]
        set = activeresource_klass.find(:all, :params => { join_key => keys })
        self.each do |u|
          u.send("#{activeresource_accessor}=", set.select {|s| s.send(join_key) == u.id })
          u.instance_variable_set(:@remote_resources_prefetched, true)
        end
      end

      self.all
    end
  end
end
