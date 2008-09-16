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
        user    = defined?(::User)        && ::User.respond_to?(:current_user) && ::User.current_user ? ::User.current_user.id        : nil
        request = defined?(::Application) && ::Application.respond_to?(:current_request)              ? ::Application.current_request : nil

        changed_attributes = {}
        @audited_attributes.each do |key, val|
          changed_attributes[key] = [val, attributes[key]] unless val == attributes[key]
        end

        audit_attributes = {
          :auditable_type => self.class.to_s,
          :auditable_id   => self.id,
          :user_id        => user,
          :action         => action,
          :changes        => changed_attributes
        }

        if request
          params = request.params
          if defined?(::Application) && defined?(Merb::Controller)
            params = Application._filter_params(params)
          end

          audit_attributes.merge!(
            :request_uri    => request.uri,
            :request_method => request.method,
            :request_params => params
          )
        end

        remove_instance_variable("@audited_attributes")
        remove_instance_variable("@audited_new_record") if instance_variable_defined?("@audited_new_record")

        Audit.create(audit_attributes) unless changed_attributes.empty? && action != 'destroy'
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
      property :auditable_id,   Integer
      property :user_id,        Integer
      property :request_uri,    String, :size => 255
      property :request_method, String
      property :request_params, Text
      property :action,         String
      property :changes,        Text
      property :created_at,     DateTime

      def auditable
        auditable_type.constantize.get(auditable_id)
      end

      def changes=(properties)
        attribute_set(:changes, JSON.dump(properties))
      end

      def changes
        @changes_hash ||= Mash.new(JSON.load(attribute_get(:changes)))
      end

      def request_params=(params)
        attribute_set(:request_params, JSON.dump(params))
      end

      def request_params
        @request_params_hash ||= Mash.new(JSON.load(attribute_get(:request_params)))
        @request_params_hash
      end

    end

  end
end
