$LOAD_PATH << './lib'
require 'bot'
require 'bot-cleverbot'
require 'bot-logger'
require 'bot-twitter'
require 'eventmachine'

class MrBoti
  
  def initialize
    bot = Bot.new
    bot.connect
  
    bot.on_command :twitter do |command, from|
      bot.send_message from, BotTwitter.exec_command(command)
    end
    
    bot.on_friend_petition do |from, item, presence|
      if bot.allowed_friend? friend
        bot.accept_friend(friend)
      else
        bot.decline_friend(friend)
      end
    end

    bot.on_message do |command, from, msg|
      bot.exec_command_or_do(command, from) do |command, from|
        bot.send_message from, BotCleverbot.say(command)
      end
    end
  end
  
end

EM.run {
  mrboti = MrBoti.new
}