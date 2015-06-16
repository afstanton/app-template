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

gem_group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
end

gem_group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
end

run 'bundle install'

generate 'rspec:install'

file 'spec/support/devise.rb', <<-CODE
RSpec.configure do |config|
  config.include Devise::TestHelpers, type: :controller
end
CODE

file 'app/assets/stylesheets/application.scss', <<-CODE
// "bootstrap-sprockets" must be imported before "bootstrap" and "bootstrap/variables"
@import "bootstrap-sprockets";
@import "bootstrap";
CODE

run "rm app/assets/stylesheets/application.css"

inject_into_file 'app/assets/javascripts/application.js', after: "require jquery\n" do <<-'RUBY'
//= require ahoy
//= require bootstrap-sprockets
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

generate 'haml:application_layout convert'
remove_file 'app/views/layouts/application.html.erb'
rake 'haml:erb2haml'

rake 'db:create'
rake 'db:migrate'


