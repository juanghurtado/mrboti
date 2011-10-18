$LOAD_PATH << './lib'
require 'bot'
require 'bot-cleverbot'
require 'bot-logger'
require 'bot-github'
require 'bot-hudson'
require 'bot-twitter'
require 'eventmachine'

class MrBoti

  def initialize
    bot = Bot.new
    bot.connect

    bot.on_command :twitter do |command, from|
      bot.send_message from, BotTwitter.exec_command(command)
    end

    bot.on_command :github do |command, from|
      bot.send_message from, BotGithub.exec_command(command)
    end

    bot.on_command :hudson do |command, from|
      bot.send_message from, BotHudson.exec_command(command)
    end

    bot.on_friend_petition do |from, item, presence|
      if bot.allowed_friend? from
        bot.accept_friend(from)
      else
        bot.decline_friend(from)
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