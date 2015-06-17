file '.ruby-version', 'ruby-2.2.2'
file '.ruby-gemset', "#{@app_name}"

inject_into_file 'Gemfile', after: "source 'https://rubygems.org'\n" do <<-'RUBY'
ruby '2.2.2'
RUBY
end

postgres = true if yes?("Postgres >= 9.4?")

gem 'bootstrap-sass', '~> 3.3.4'
gem 'haml-rails'
gem 'devise'
gem 'ahoy_matey'

if !postgres
  gem 'activeuuid', '>= 0.5.0'
end

gem 'doorkeeper'
gem 'kaminari'
gem 'grape'
gem 'hashie-forbidden_attributes'
gem 'wine_bouncer'
gem 'grape-swagger'
gem 'swagger-ui_rails'
gem 'grape-kaminari'

gem_group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'jazz_hands', github: 'nixme/jazz_hands', branch: 'bring-your-own-debugger'
  gem 'pry-byebug'
  gem 'did_you_mean'
  gem 'faker'
end

gem_group :test do
  gem 'simplecov', :require => false
  gem 'webmock'
end

gem_group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'annotate'
  gem 'rubocop', require: false
  gem 'brakeman', require: false
  gem 'guard'
  gem 'guard-rspec', require: false
  gem 'guard-annotate'
  gem 'guard-rubocop'
  gem 'guard-brakeman'
  gem 'xray-rails'
end

run 'bundle install'

generate 'rspec:install'

inject_into_file 'spec/spec_helper.rb', before: "# This file was generated" do <<-'RUBY'
require 'simplecov'
SimpleCov.start 'rails'

RUBY
end

inject_into_file 'spec/spec_helper.rb', before: "# This file was generated" do <<-'RUBY'
require 'webmock/rspec'

RUBY
end

inject_into_file '.gitignore', after: "/tmp\n" do <<-'RUBY'
coverage
RUBY
end

file 'spec/support/devise.rb', <<-CODE
RSpec.configure do |config|
  config.include Devise::TestHelpers, type: :controller
end
CODE

file 'app/assets/stylesheets/application.scss', <<-CODE
//= require swagger-ui
// "bootstrap-sprockets" must be imported before "bootstrap" and "bootstrap/variables"
@import "bootstrap-sprockets";
@import "bootstrap";
CODE

run "rm app/assets/stylesheets/application.css"

inject_into_file 'app/assets/javascripts/application.js', after: "require jquery\n" do <<-'RUBY'
//= require ahoy
//= require bootstrap-sprockets
//= require swagger-ui
RUBY
end

inject_into_file 'app/views/layouts/application.html.erb', after: "<body>\n" do <<-'RUBY'
  <p class="notice"><%= notice %></p>
  <p class="alert"><%= alert %></p>
RUBY
end

inject_into_file 'app/controllers/application_controller.rb', after: "protect_from_forgery with: :exception\n" do <<-'RUBY'

  private

  def current_resource_owner
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end

RUBY
end

generate 'controller welcome'

route "root 'welcome#index'"

file 'app/views/welcome/index.html.erb', <<-CODE
<h2>Hello World</h2>
<p>
  The time is now: <%= Time.now %>
</p>
CODE

generate 'devise:install'
generate 'devise user'
generate 'devise:views'

application(nil, env: "development") do
  "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }"
end

if postgres
  generate 'ahoy:stores:active_record -d postgresql-jsonb'
else
  generate 'ahoy:stores:active_record'
end

generate 'doorkeeper:install'
generate 'doorkeeper:migration'
generate 'doorkeeper:application_owner'

comment_lines 'config/initializers/doorkeeper.rb', 'fail "Please configure doorkeeper resource_owner_authenticator block located in #{__FILE__}"'
inject_into_file 'config/initializers/doorkeeper.rb', after: "enable_application_owner :confirmation => false\n" do <<-'RUBY'
  enable_application_owner :confirmation => true
RUBY
end
inject_into_file 'config/initializers/doorkeeper.rb', after: "resource_owner_authenticator do\n" do <<-'RUBY'
    current_user || warden.authenticate!(scope: :user)
RUBY
end
inject_into_file 'app/models/user.rb', after: ":recoverable, :rememberable, :trackable, :validatable\n" do <<-'RUBY'
  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner
RUBY
end

generate 'kaminari:config'
generate 'kaminari:views bootstrap3 -e haml'

application do
  "config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')"
  "config.autoload_paths += Dir[Rails.root.join('app', 'api', '*')]"
end

file 'config/initializers/reload_api.rb', <<-CODE
if Rails.env.development?
#  ActiveSupport::Dependencies.explicitly_unloadable_constants << "Twitter::API"

  api_files = Dir[Rails.root.join('app', 'api', '**', '*.rb')]
  api_reloader = ActiveSupport::FileUpdateChecker.new(api_files) do
    Rails.application.reload_routes!
  end
  ActionDispatch::Callbacks.to_prepare do
    api_reloader.execute_if_updated
  end
end
CODE

generate 'wine_bouncer:initializer'

comment_lines 'config/initializers/wine_bouncer.rb', 'config.auth_strategy = :default'
inject_into_file 'config/initializers/wine_bouncer.rb', after: "config.auth_strategy = :default\n" do <<-'RUBY'
  config.auth_strategy = :swagger
RUBY
end

generate 'annotate:install'

run 'bundle exec guard init'

generate 'haml:application_layout convert'
remove_file 'app/views/layouts/application.html.erb'
rake 'haml:erb2haml'

rake 'db:create'
rake 'db:migrate'



