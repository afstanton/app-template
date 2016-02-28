# rubocop:disable Style/FileName
file '.ruby-version', 'ruby-2.3.0'
file '.ruby-gemset', @app_name.to_s
# rubocop:enable Style/FileName

inject_into_file 'Gemfile', after: "source 'https://rubygems.org'\n" do
  <<-CODE
ruby '2.3.0'
CODE
end

gem 'ahoy_matey'
gem 'bootstrap-sass'
gem 'browser', '~> 1.1'
gem 'chamber'
gem 'devise'
gem 'high_voltage'
gem 'kaminari'
gem 'pundit'
gem 'simple_form'

gem_group :development do
  gem 'annotate'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'brakeman', require: false
  gem 'bullet'
  gem 'guard', require: false
  gem 'guard-brakeman', require: false
  gem 'guard-rspec', require: false
  gem 'guard-rubocop', require: false
  gem 'html2slim', require: false
  gem 'image_optim', require: false
  gem 'image_optim_pack', require: false
  gem 'metric_fu', require: false
  gem 'overcommit', require: false
  gem 'rails_apps_testing', require: false
  gem 'rails_apps_pages', require: false
  gem 'rails_layout', require: false
  gem 'rails_best_practices', require: false
  gem 'reek', require: false
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
  gem 'scss_lint', require: false
  gem 'slim_lint', require: false
  gem 'xray-rails'
end

gem_group :development, :test do
  gem 'factory_girl_rails'
  gem 'quiet_assets'
  gem 'rspec-rails'
end

gem_group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'launchy'
  gem 'poltergeist'
  gem 'phantomjs', require: 'phantomjs/poltergeist'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'webmock'
end

file '.overcommit_gems', <<-CODE
source 'https://rubygems.org'
ruby '2.3.0'

gem 'brakeman'
gem 'chamber'
gem 'image_optim'
gem 'image_optim_pack'
gem 'overcommit'
gem 'rails_best_practices'
gem 'reek'
gem 'rubocop'
gem 'rubocop-rspec'
gem 'scss_lint'
gem 'slim_lint'
CODE

run 'bundle install'
run 'bundle install --gemfile=.overcommit_gems'

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

application(nil, env: 'development') do
  "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }"
end

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

inject_into_file '.gitignore', after: "/tmp\n" do
  <<-CODE
/coverage
CODE
end

inject_into_file 'spec/spec_helper.rb', before: '# This file was generated' do
  <<-CODE
require 'simplecov'
require 'webmock/rspec'

SimpleCov.start 'rails'

CODE
end

inject_into_file 'config/environments/development.rb', before: "\nend\n" do
  <<-CODE

  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
  end
CODE
end

inject_into_file 'app/controllers/application_controller.rb',
                 after: "ActionController::Base\n" do
  <<-CODE
  include Pundit

CODE
end

rakefile 'rubocop.rake', <<-CODE
require 'rubocop/rake_task'

RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-rspec'
end
CODE

file '.rubocop.yml', <<CODE
require: rubocop-rspec

AllCops:
  TargetRubyVersion: 2.3

Rails:
  Enabled: true
CODE

generate 'annotate:install'

run 'bundle exec guard init'

rake 'db:create'
rake 'db:migrate'

run 'RAILS_ENV=test rake db:create'
run 'RAILS_ENV=test rake db:migrate'

generate 'pages:users --force'
generate 'pages:authorized --force'

generate 'layout:devise bootstrap3 --force'

gem 'slim-rails'

run 'bundle install'

generate 'simple_form:install --bootstrap'

generate 'kaminari:views bootstrap3 -e slim'

run 'erb2slim -d .'

inject_into_file 'app/assets/javascripts/application.js',
                 after: "require bootstrap-sprockets\n" do
  <<-CODE
//= require ahoy
CODE
end

rake 'doc:app'

rake 'rubocop:auto_correct'
run 'rubocop --auto-gen-config'

inject_into_file '.rubocop.yml', before: 'require' do
  <<-CODE
inherit_from: .rubocop_todo.yml

CODE
end

git :init

run 'overcommit --install'

inject_into_file '.overcommit.yml', after: 'HEAD changes' do
  <<-CODE
gemfile: .overcommit_gems

PreCommit:
  Brakeman:
    enabled: true
  BundleCheck:
    enabled: true
  ChamberSecurity:
    enabled: true
  CoffeeLint:
    enabled: false
  CssLint:
    enabled: true
  ImageOptim:
    enabled: false
  JsHint:
    enabled: true
  RailsBestPractices:
    enabled: false
  Reek:
    enabled: false
  RuboCop:
    enabled: true
  ScssLint:
    enabled: true
  SlimLint:
    enabled: false
  TravisLint:
    enabled: true
  YamlSyntax:
    enabled: true
CODE
end

run 'overcommit --sign'

git add: '.'
git commit: '-m "Initial commit"'
