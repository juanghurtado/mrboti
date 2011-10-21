$LOAD_PATH << './lib'
require 'bot'
require 'bot_cleverbot'
require 'bot_logger'
require 'eventmachine'

class MrBoti

  def initialize
    # Connect the bot an load it's modules (located at `lib/modules`)
    bot = Bot.new
    bot.connect
    bot.load_modules

    # On incoming friend petition, we check if `from` address
    # is allowed. If it is, accept friend. Decline if not.
    bot.on_friend_petition do |from, item, presence|
      if bot.allowed_friend? from
        bot.accept_friend(from)
      else
        bot.decline_friend(from)
      end
    end

    # On incoming message, we try to exec a command through
    # the recieved message. If not a registered command, execute
    # default action (Cleverbot)
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