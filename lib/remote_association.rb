require "active_record"
require "active_support"

require "remote_association/version"
require "remote_association/active_record/relation"

module RemoteAssociation
  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods

    base.class_eval do
    end
  end

  module ClassMethods
    def belongs_to_remote(remote_rel, options ={})
      rel = activeresource_relations
      rel[remote_rel.to_sym] = {
        klass:      ( options[:class_name]  ? options[:class_name].constantize : remote_rel.to_s.classify.constantize),
        join_key:   ( options[:foreign_key] ? options[:foreign_key]            : self.model_name.to_s.foreign_key               )
      }

      class_eval <<-RUBY, __FILE__, __LINE__+1

        attr_accessor :#{remote_rel}

        def #{remote_rel}
          if @remote_resources_prefetched == true
            @#{remote_rel} ? @#{remote_rel}.first : nil
          else
            @#{remote_rel} ||= #{rel[remote_rel.to_sym][:klass].to_s}.find(:first, params: { #{rel[remote_rel.to_sym][:join_key]}: [self.id]})
          end
        end

      RUBY

      @activeresource_relations = rel
    end

    def has_many_remote(remote_rel, options ={})
    end

    def activeresource_relations
      @activeresource_relations ||= {}
    end
  end

  module InstanceMethods
  end
end
