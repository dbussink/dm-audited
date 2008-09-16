require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataMapper::Audited" do

  before :all do
    DataObjects::Sqlite3.logger = DataObjects::Logger.new('spec/sql.log', 0)

    class Cow
      include DataMapper::Resource
      include DataMapper::Audited

      property :id,        Integer, :serial => true
      property :name,      String
      property :breed,     String

      is_audited

      auto_migrate!(:default)
    end

    module DataMapper
      module Audited
        class Audit
          auto_migrate!(:default)
        end
      end
    end
  end

  it "is included when DataMapper::Audited is loaded" do
    Cow.new.should be_kind_of(DataMapper::Audited)
  end

  it "should create a new Audit object when creating an object" do
    c = Cow.new(:name => "Bertha")
    c.save

    audit = DataMapper::Audited::Audit.first(:auditable_type => c.class.to_s, :auditable_id => c.id.to_s)

    audit.should_not be_nil
    audit.changes[:name].should_not be_nil
    audit.action.should eql("create")
  end

  it "should create a new Audit object when changing an object" do
    c = Cow.create(:name => "Bertha")

    c.name = "Cindy"
    c.save

    audits = DataMapper::Audited::Audit.all(:auditable_type => c.class.to_s, :auditable_id => c.id.to_s, :order => [:created_at])

    audits.length.should == 2
    audits.last.should_not be_nil

    audits.last.changes[:name].should_not be_nil
    audits.last.changes[:name].first.should eql("Bertha")
    audits.last.changes[:name].last.should eql("Cindy")
    audits.last.action.should eql("update")
  end

  it "should create a new Audit object when destroying an object" do
    c = Cow.create(:name => "Bertha")

    c.destroy

    c.audits.length.should == 2
    c.audits.last.should_not be_nil

    c.audits.last.action.should eql("destroy")
  end

end
