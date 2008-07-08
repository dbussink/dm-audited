require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataMapper::Audited" do

  before :all do
    class Cow
      include DataMapper::Resource
      include DataMapper::Audited

      property :id,        Integer, :serial => true
      property :name,      String
      property :breed,     String

      is_audited

      auto_migrate!(:default)
    end
  end

  it "is included when DataMapper::Searchable is loaded" do
    Cow.new.should be_kind_of(DataMapper::Audited)
  end

end
