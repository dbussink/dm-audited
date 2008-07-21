require 'rubygems'
gem 'dm-core', '>=0.9.2'
gem 'dm-serializer', '>=0.9.2'
require 'dm-core'
require 'dm-timestamps'
require 'dm-serializer'

module DataMapper
  module Audited
    def self.included(base)
      base.extend(ClassMethods)
    end

    module InstanceMethods

      def create_audit(action)
        # It needs to provide User.current_user if the user is to be saved
        # The implementer needs to provide this and for example needs to make
        # sure that the implementation is thread safe.
        # The request is also optionally included if it can be found in the
        # Application controller. Here again the implementer needs to provide
        # this and make sure it's thread safe.
        user    = defined? User        && User.respond_to?(:current_user)           ? User.current_user.id        : nil
        request = defined? Application && Application.respond_to?(:current_request) ? Application.current_request : nil

        changed_attributes = {}
        @audited_attributes.each do |key, val|
          changed_attributes[key] = [val, attributes[key]]
        end

        Audit.create!(:auditable_type => self.class.to_s,
                      :auditable_id   => self.id,
                      :user_id        => user,
                      :action         => action,
                      :request        => request,
                      :changes        => changed_attributes)
        remove_instance_variable("@audited_attributes")
        remove_instance_variable("@audited_new_record") if instance_variable_defined?("@audited_new_record")
      end

      def audits
        Audit.all(:auditable_type => self.class.to_s, :auditable_id => self.id.to_s, :order => [:created_at, :id])
      end

    end

    module ClassMethods
      def is_audited

        include DataMapper::Audited::InstanceMethods

        before :save do
          @audited_attributes = original_values.clone
          @audited_new_record = new_record?
        end

        before :destroy do
          @audited_attributes = original_values.clone
        end

        after :save do
          create_audit(@audited_new_record ? 'create' : 'update')
        end

        after :destroy do
          create_audit('destroy')
        end

      end
    end

    class Audit
      include DataMapper::Resource

      property :id,             Integer, :serial => true
      property :auditable_type, String
      property :auditable_id,   String
      property :user_id,        String
      property :request,        String
      property :action,         String
      property :changes,        Text
      property :created_at,     DateTime

      def auditable
        auditable_type.constantize.get(auditable_id)
      end

      def changes=(property)
        attribute_set(:changes, property.to_yaml)
      end

      def changes
        @changes_hash ||= YAML.load(attribute_get(:changes))
      end
    end

  end
end
