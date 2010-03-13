# coding: utf-8
# Copyright 2010 J. Pablo Fernández

class OpenIdScaffoldGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      # Migration.
      m.directory "db/migrate"
      m.migration_template "create_open_ids.rb", "db/migrate", :migration_file_name => "create_open_ids"

      # Model
      m.directory "app/models"
      m.directory "test/fixtures"
      m.directory "test/unit"
      m.file "open_id.rb", "app/models/open_id.rb"
      m.file "open_ids.yml", "test/fixtures/open_ids.yml"
      m.file "open_id_test.rb", "test/unit/open_id_test.rb"

      # Controller
      m.directory "app/controllers"
      m.directory "app/views/sessions"
      m.directory "test/functional"
      m.file "sessions_controller.rb", "app/controllers/sessions_controller.rb"
      m.file "new.html.erb", "app/views/sessions/new.html.erb"
      m.file "sessions_controller_test.rb", "test/functional/sessions_controller_test.rb"

      m.route_resource ":session, :only => [:new, :create, :destroy], :member => { :finish_creating => :get }"
      
      # Read me
      m.readme 'INSTALL'
    end
  end
end

class Rails::Generator::Commands::Create
  # Generate singleton resources. Copied, pasted and modified from
  # http://api.rubyonrails.org/classes/Rails/Generator/Commands/Create.html
  def route_resource(resource)
    sentinel = 'ActionController::Routing::Routes.draw do |map|'

    logger.route "map.resource #{resource}"
    unless options[:pretend]
      gsub_file 'config/routes.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
        "#{match}\n  map.resource #{resource}\n"
      end
    end
  end
end
