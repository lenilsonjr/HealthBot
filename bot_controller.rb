require 'telegram/bot'
require 'sequel'
require 'cloudinary'
require 'cloudinary/uploader'
require 'cloudinary/utils'

class BotController < Telegram::Bot::UpdatesController
  DB = Sequel.connect('sqlite://heath_bot.db')
  before_action :set_user

  def start!(*)
    if @user.nil?
      Sequel::Model(DB[:users]).create(chat_id: chat['id'])
      respond_with :message, text: "Hello, #{from['username']}! 👋"
      sleep(1)
      respond_with :message, text: "👉🏻I can help you keep tracking of your health 💊 by logging everything you eat 🍔, how much you sleep 😴, how much you drink 🍻, etc."
      sleep(1.5)
      respond_with :message, text: "To start, send me your current weight in kilograms, only numbers ⚖️"
      respond_with :message, text: "You can send me a decimal like `60.5` or just a number like `60`"
    else
      respond_with :message, text: "Hey #{from['username']}, looks like you've already started me 🤔"
    end
  end

  def message(message)
    if @user.nil?
      respond_with :message, text: "Hey #{from['username']}, use /start so I can explain you some stuff"
    end

    # Let's check if the user is inputting in the weight
    if !@user.nil? && @user[:weight].nil? && message['text'] =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/
      @user.update(weight: message['text'])
      respond_with :message, text: "Looks like your weight is #{message['text']} kilograms 🏋🏻‍♀️"
      sleep(1.5)
      respond_with :message, text: "📝 Let me write this down"
    end

    # Let's check if the user is sending a photo
    if !message['photo'].nil?
      file = bot.get_file(file_id: message['photo'].last['file_id'])['result']
      path = "https://api.telegram.org/file/bot#{ENV['TELEGRAM_TOKEN']}/#{file['file_path']}"
      photo = Cloudinary::Uploader.upload(path)

      meal = Sequel::Model(DB[:meals]).create(user_id: @user[:id], photo_url: photo['secure_url'], photo_etag: photo['etag'])

      respond_with :message, text: 'Tell me more about this meal', reply_markup: {
        inline_keyboard: [
          [
            {text: '🍳 Breakfast', callback_data: 'breakfast'},
            {text: '🥗 Lunch', callback_data: 'lunch'},
          ],
          [
            {text: '🍜 Dinner', callback_data: 'dinner'},
            {text: '🍿 Snack', callback_data: 'snack'},
          ]
        ],
      }

    end
  end

  def callback_query(data)
    meal = Sequel::Model(DB[:meals]).where(user_id: @user[:id], meal_type: nil).order(:id).last
    if !meal.nil?
      case data
      when 'breakfast'
        respond_with :message, text: 'Cool. Looks like a yummy breakfast.'
        meal.update(meal_type: data)
      when 'lunch'
        respond_with :message, text: 'Lunch time! Nice!'
        meal.update(meal_type: data)
      when 'dinner'
        respond_with :message, text: 'Remember to eat only light things beforing going to bed'
        meal.update(meal_type: data)
      when 'snack'
        respond_with :message, text: "So you were hungry or just binge eating? 🤔 Take care"
        meal.update(meal_type: data)
      else
        answer_callback_query("Hmmm. 🤔 I'm confused")
      end

      sleep(0.5)
      respond_with :message, text: 'How would you rate this meal?', reply_markup: {
        inline_keyboard: [
          [
            {text: '👍', callback_data: 'good'},
            {text: '🤷🏻‍♂️', callback_data: 'neutral'},
            {text: '👎', callback_data: 'bad'},
          ]
        ],
      }
    end
    
    meal = Sequel::Model(DB[:meals]).where(user_id: @user[:id], meal_rate: nil).order(:id).last
    if !meal.nil?
      case data
      when 'good'
        respond_with :message, text: 'Nice! Keep up the good work'
        meal.update(meal_rate: data)
      when 'neutral'
        respond_with :message, text: 'Yeah. Neutral is good'
        meal.update(meal_rate: data)
      when 'bad'
        respond_with :message, text: 'Oh Cmon, you can do better!'
        meal.update(meal_rate: data)
      else
        answer_callback_query("Hmmm. 🤔 I'm confused")
      end
    end
  end

  private
    def set_user
      @user = DB[:users].first(chat_id: chat['id'])
    end

end
