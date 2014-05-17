#The MIT License (MIT)
#
#Copyright (c) 2014 Venturit Inc
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
#----------------------------- /// --------------------------------------
# See http://guides.rubyonrails.org/rails_application_templates.html
#
#requires ruby 2.1.0 and rails 4.1.1
#
# usage:
# rails new yourappname -m https://raw.githubusercontent.com/venturit/agile-approach/master/venturit_rails4_template.rb
#
#
# Add commonly used gems
gem 'acts-as-taggable-on'
gem 'activeadmin', github: 'gregbell/active_admin'
gem 'aws-sdk'

gem 'friendly_id'
gem 'foundation-rails'
gem 'foundation-icons-sass-rails'

gem 'haml-rails'

gem 'devise'

gem 'modernizr-rails', github:'venturit/modernizr-rails'

gem 'paperclip'
gem 'pg'
gem 'pundit'
gem 'puma'

gem 'state_machine'
gem 'sendgrid'
gem 'simple_form'

gem_group :production do
  gem 'airbrake'
  gem 'rails_12factor'
  gem 'unicorn'
end

gem_group :development do
  gem 'brakeman'
  gem 'better_errors'
  gem 'foreman'
  gem 'quiet_assets'
end

gem_group :development, :test do
  gem 'brakeman'
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'mailcatcher'
end

gem_group  :test do
  gem 'database_cleaner'
end

#insert ruby version 
insert_into_file 'Gemfile', "\nruby '2.1.0'", after: "source 'https://rubygems.org'\n"

#remove layout
remove_file 'app/views/layouts/application.html.erb'

#create haml layout
layout = 
<<-layout
!!!
%html
  %head
    %title #{app_name.humanize}
    = stylesheet_link_tag :application
    = csrf_meta_tag
  %body
    = yield
    = javascript_include_tag :application
layout

create_file "app/views/layouts/application.html.haml", layout

#create database conf
databases = 
<<-databases
development:
  adapter:  postgresql
  host:     localhost
  encoding: unicode
  database: #{app_name}_dev
  pool:     5
  username: postgres
  password: 
  template: template0

test:
  adapter:  postgresql
  host:     localhost
  encoding: unicode
  database: #{app_name}_test
  pool:     5
  username: postgres
  password: 
  template: template0

databases

remove_file 'config/database.yml'

create_file 'config/database.yml.sample',databases

run 'cp config/database.yml.sample config/database.yml'

run "echo 'config/database.yml' >> .gitignore"

#create .env
dotenv = 
<<-dotenv
DOMAIN=
FROM_EMAIL=
ADMIN_NAME=
ADMIN_EMAIL=
ADMIN_PASSWORD=
S3_BUCKET=
S3_KEY=
S3_SECRET=
AIRBRAKE_API_KEY=
SECRET_KEY_BASE=
SENDGRID_USERNAME=
SENDGRID_PASSWORD=
dotenv


create_file '.env.sample',dotenv

run 'cp .env.sample .env'

run "echo '.env' >> .gitignore"


#create procfile for foreman
procfile = 
<<-procfile
web: bundle exec puma -p $PORT
procfile

create_file 'Procfile',procfile

remove_file 'public/index.html'

remove_file 'public/images/rails.png'

remove_file 'README.rdoc'

#add enviroment settings
environment "config.action_mailer.default_url_options = {host: ENV['DOMAIN']}", env: ['development','production', 'test']


smtp_paperclip_env =
<<-SPE

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default :charset => "utf-8"

  config.action_mailer.smtp_settings = {
    address: "smtp.sendgrid.net",
    port: 25,
    domain: ENV['DOMAIN'],
    authentication: "plain",
    user_name: ENV["SENDGRID_USERNAME"],
    password: ENV["SENDGRID_PASSWORD"]
  }

  config.paperclip_defaults = {
    :storage => :s3,
    :s3_credentials => {
      :bucket =>  ENV["S3_BUCKET"],
      :access_key_id =>  ENV["S3_KEY"],
      :secret_access_key =>  ENV["S3_SECRET"]
    }
  }
SPE

environment smtp_paperclip_env, env: ['development','production']

#clean up public folder
remove_file 'rm public/index.html'

remove_file 'rm public/images/rails.png'

#install gems
run 'bundle install'

#run generators
generate 'devise:install'

generate 'rspec:install'

generate 'devise User'

generate 'active_admin:install'

generate 'foundation:install'

#clean up foudation layout
remove_file 'app/views/layouts/application.html.erb'

#set devise test helper for rspec
insert_into_file 'spec/spec_helper.rb', "\n  config.include Devise::TestHelpers, type: :controller\n", after: "RSpec.configure do |config|\n"

#set devise email address
gsub_file 'config/initializers/devise.rb', "'please-change-me-at-config-initializers-devise@example.com'","ENV['FROM_EMAIL']"
