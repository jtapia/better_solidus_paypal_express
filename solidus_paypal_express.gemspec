# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'solidus_paypal_express/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'solidus_paypal_express'
  s.version     = SolidusPayPalExpress.version
  s.summary     = 'Adds PayPal Express as a Payment Method to Solidus Commerce'
  s.description = s.summary
  s.required_ruby_version = '>= 2.1.0'

  s.author       = 'Jonathan Tapia'
  s.email        = 'jonathan.tapia@magmalabs.io'
  s.homepage     = 'http://www.magmalabs.io'
  s.license      = %q{BSD-3}

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- spec/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'solidus_core', ['> 1.2', '< 3']
  s.add_dependency 'solidus_support'
  s.add_dependency 'deface', '~> 1.0'
  s.add_dependency 'paypal-sdk-merchant'

  s.add_development_dependency 'byebug'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'capybara-webkit'
  s.add_development_dependency 'capybara-screenshot'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'chromedriver-helper'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_bot'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'shoulda-matchers'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'puma'
  s.add_development_dependency 'require_all'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'webmock'
end
