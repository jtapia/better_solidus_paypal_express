require 'capybara/rspec'
require 'capybara/rails'
require 'capybara/poltergeist'
# require 'capybara-screenshot/rspec'

RSpec.configure do |config|
  # Capybara.javascript_driver = :poltergeist
  # Capybara.javascript_driver = :selenium

  Capybara.javascript_driver = :selenium

  Capybara.configure do |config|
    config.default_max_wait_time = 10
    config.default_driver        = :selenium
  end

  Capybara.register_driver :selenium do |app|
    Capybara::Selenium::Driver.new(app)
  end
  # Capybara.register_driver(:selenium) do |app|
  #   Capybara::Poltergeist::Driver.new app, js_errors: true, timeout: 60
  # end

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!
end
