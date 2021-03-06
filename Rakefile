require 'rubygems'
require 'spec'
require 'rake/clean'
require 'rake/gempackagetask'
require 'spec/rake/spectask'
require 'pathname'
 
CLEAN.include '{log,pkg}/'
 
spec = Gem::Specification.new do |s|
  s.name             = 'dm-audited'
  s.version          = '0.0.1'
  s.platform         = Gem::Platform::RUBY
  s.has_rdoc         = true
  s.extra_rdoc_files = %w[ README LICENSE ]
  s.summary          = 'DataMapper plugin providing auditing for resources'
  s.description      = s.summary
  s.author           = 'Dirkjan Bussink'
  s.email            = 'd.bussink@gmail.com'
  s.homepage         = 'http://github.com/dbussink/dm-audited'
  s.require_path     = 'lib'
  s.files            = FileList[ '{lib,spec}/**/*.rb', 'spec/spec.opts', 'Rakefile', *s.extra_rdoc_files ]
  s.add_dependency('dm-core', ">=0.9.2")
end
 
task :default => [ :spec ]
 
WIN32 = (RUBY_PLATFORM =~ /win32|mingw|cygwin/) rescue nil
SUDO  = WIN32 ? '' : ('sudo' unless ENV['SUDOLESS'])
 
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end
 
desc "Install #{spec.name} #{spec.version}"
task :install => [ :package ] do
  sh "#{SUDO} gem install pkg/#{spec.name}-#{spec.version} --no-update-sources", :verbose => false
end
 
desc 'Run specifications'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts << '--options' << 'spec/spec.opts' if File.exists?('spec/spec.opts')
  t.spec_files = Pathname.glob(Pathname.new(__FILE__).dirname + 'spec/**/*_spec.rb')
end
