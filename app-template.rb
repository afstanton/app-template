file '.ruby-version', 'ruby-2.2.2'
file '.ruby-gemset', "#{@app_name}"

inject_into_file 'Gemfile', after: "source 'https://rubygems.org'\n" do <<-'RUBY'
ruby '2.2.2'
RUBY
end

gem 'bootstrap-sass', '~> 3.3.4'
gem 'haml-rails'
gem 'devise'

gem_group :development, :test do
  gem 'rspec-rails'
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

generate 'haml:application_layout convert'
remove_file 'app/views/layouts/application.html.erb'
rake 'haml:erb2haml'


