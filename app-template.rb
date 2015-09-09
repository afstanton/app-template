file '.ruby-version', 'ruby-2.2.3'
file '.ruby-gemset', "#{@app_name}"

inject_into_file 'Gemfile', after: "source 'https://rubygems.org'\n" do <<-'RUBY'
ruby '2.2.3'
RUBY
end

postgres = true if yes?("Postgres >= 9.4?")
heroku = true if yes?("Using Heroku?")
stripe = true if yes?("Use Stripe?")

# GEMS BEGIN
gem 'high_voltage'
gem 'devise'
gem 'pundit'
gem 'bootstrap-sass'
gem 'ahoy_matey'
gem 'simple_form'
gem 'kaminari'
gem 'puma'

if !postgres
  gem 'activeuuid', '>= 0.5.0'
end

if stripe
  gem 'stripe-rails'
end

gem_group :development do
  gem 'rails_apps_testing'
  gem 'rails_apps_pages'
  gem 'rails_layout'
  gem 'annotate'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'rubocop', require: false
  gem 'brakeman', require: false
  gem 'metric_fu', require: false
  gem 'xray-rails'
  gem 'bullet'
  gem 'guard'
  gem 'guard-rspec', require: false
  gem 'guard-annotate'
  gem 'guard-rubocop'
  gem 'guard-brakeman'
  gem 'guard-bundler'
  gem 'guard-coffeescript'
end

gem_group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'quiet_assets'
end

gem_group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'launchy'
  gem 'selenium-webdriver'
  gem 'poltergeist'
  gem 'phantomjs', :require => 'phantomjs/poltergeist'
  gem 'simplecov', :require => false
  gem 'webmock'
  gem 'mutant-rspec'
end

if heroku
  gem_group :production do
    gem 'rails_12factor'
  end
end
# GEMS END

run 'bundle install'

run 'gem install foreman'

# GENERATORS BEGIN
generate 'simple_form:install --bootstrap'

generate 'testing:configure rspec --force'

generate 'devise:install'
generate 'devise user'

generate 'pundit:install'

generate 'pages:home'
generate 'pages:about'
generate 'analytics:google'

generate 'layout:install bootstrap3 --force'
generate 'layout:navigation --force'

generate 'ahoy:stores:active_record'

generate 'kaminari:config'

generate 'annotate:install'

if stripe
  generate 'stripe:install'
end

run 'bundle exec guard init'
# GENERATORS END

# MODIFY FILES BEGIN
file '.gitattributes', <<-CODE
# Auto detect text files and perform LF normalization
* text=auto

# Custom for Visual Studio
*.cs     diff=csharp

# Standard to msysgit
*.doc    diff=astextplain
*.DOC    diff=astextplain
*.docx diff=astextplain
*.DOCX diff=astextplain
*.dot  diff=astextplain
*.DOT  diff=astextplain
*.pdf  diff=astextplain
*.PDF    diff=astextplain
*.rtf    diff=astextplain
*.RTF    diff=astextplain
CODE

inject_into_file '.gitignore', after: "/tmp\n" do <<-'RUBY'
/coverage
/config/secrets.yml
RUBY
end

file 'Procfile', <<-CODE
web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}
CODE

run 'echo "RACK_ENV=development" >>.env'
run 'echo "PORT=3000" >> .env'

run 'echo ".env" >> .gitignore'

application(nil, env: "development") do
  "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }"
end

inject_into_file 'app/controllers/application_controller.rb', after: "ActionController::Base\n" do <<-'RUBY'
  include Pundit

RUBY
end #done

inject_into_file 'spec/spec_helper.rb', before: "# This file was generated" do <<-'RUBY'
require 'simplecov'
SimpleCov.start 'rails'

RUBY
end

inject_into_file 'spec/spec_helper.rb', before: "# This file was generated" do <<-'RUBY'
require 'webmock/rspec'

RUBY
end

inject_into_file 'config/environments/development.rb', before: "\nend\n" do <<-'RUBY'

  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
  end
RUBY
end
# MODIFY FILES END

rake 'db:create'
rake 'db:migrate'

run 'RAILS_ENV=test rake db:create'
run 'RAILS_ENV=test rake db:migrate'

# GENERATORS 2 BEGIN
generate 'pages:users --force'
generate 'pages:authorized --force'

generate 'layout:devise bootstrap3 --force'
# GENERATORS 2 END

# GEMS 2 BEGIN
gem 'haml-rails'
# GEMS 2 END

run 'bundle install'

# MODIFY FILES 2 BEGIN
rake 'haml:erb2haml'

inject_into_file 'app/assets/javascripts/application.js', after: "require bootstrap-sprockets\n" do <<-'RUBY'
//= require ahoy
RUBY
end

copy_file 'config/secrets.yml', 'config/secrets.yml.dist'
# MODIFY FILES 2 END

# GENERATORS 3 BEGIN
generate 'kaminari:views bootstrap3 -e haml'
# GENERATORS 3 END

rake 'doc:app'

git :init
git add: "."
git commit: '-m "Initial commit."'

if heroku
  run 'heroku create'
  git push: 'heroku master'
  run 'heroku run rake db:migrate'
end

