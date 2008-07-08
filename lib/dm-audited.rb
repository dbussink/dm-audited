require 'rubygems'
gem 'dm-core', '>=0.9.2'
require 'dm-core'

module DataMapper
  module Audited
    def self.included(base)
      base.extend(ClassMethods)
    end
   
    module ClassMethods
      def is_audited
      end
    end
  end
end
