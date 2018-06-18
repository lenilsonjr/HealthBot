require 'rack/app'
require 'telegram/bot'
require 'dotenv/load'
require 'sequel'
require 'cloudinary'
require File.expand_path('bot_controller.rb', File.dirname(__FILE__))

class HealthBot < Rack::App

  DB = Sequel.connect('sqlite://heath_bot.db')

  DB.create_table? :users do
    primary_key :id
    String :chat_id
    Float :weight
    Integer :height
  end

  DB.create_table? :meals do
    primary_key :id
    Integer :user_id
    String :photo_url
    String :photo_etag
    String :meal_type
    String :meal_rate
  end

  Cloudinary.config do |config|
    config.cloud_name = ENV['CLOUDNARY_CLOUDNAME']
    config.api_key = ENV['CLOUDNARY_APIKEY']
    config.api_secret = ENV['CLOUDNARY_APISECRET']
    config.secure = true
    config.cdn_subdomain = true
  end

  bot = Telegram::Bot::Client.new(ENV['TELEGRAM_TOKEN'])
  mount Telegram::Bot::Middleware.new(bot, BotController), to: "/robot"

  if ENV['ENVIRONMENT'] == 'development'
    require 'logger'
    logger = Logger.new(STDOUT)
    poller = Telegram::Bot::UpdatesPoller.new(bot, BotController, logger: logger)
    poller.start
  end

end

run HealthBot
