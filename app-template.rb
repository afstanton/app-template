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

generate 'haml:application_layout convert'
remove_file 'app/views/layouts/application.html.erb'
rake 'haml:erb2haml'

rake 'db:create'
rake 'db:migrate'


