# encoding: UTF-8
require 'bot-logger'
require 'cleverbot'

# Public: Methods for interacting with Cleverbot
#
# Examples:
#
#   require 'bot-cleverbot.rb'
#
#   BotCleverbot.say("How are you doing?")
#   # => "I'm doing fine, thanks."
module BotCleverbot
  
  @log = BotLogger.log
  
  # Public: Send a message to Cleverbot
  #
  # msg - String with the message.
  #
  # Examples:
  #
  #   BotCleverbot.say("How are you doing?")
  #   # => "I'm doing fine, thanks."
  #
  # Returns a String with the response from Cleverbot,
  # or false if there was an error.
  def self.say(msg)
    begin
      @log.info "[BotCleverbot] Sending message to Cleverbot"
      Cleverbot::Client.new.write msg
    rescue
      @log.error "[BotCleverbot] Error sending message to Cleverbot: #{$!}"
      return false
    end
  end
  
end