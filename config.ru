require 'rack/app'
require 'telegram/bot'
require 'dotenv/load'
require File.expand_path('bot_controller.rb', File.dirname(__FILE__))

class HealthBot < Rack::App

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
