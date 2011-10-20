# encoding: UTF-8
require 'bot-logger'
require 'yaml'
require 'xmpp4r/client'
require 'xmpp4r/roster'
include Jabber

# UGLY PATCH: https://github.com/ln/xmpp4r/issues/3#issuecomment-1739952
require 'socket'
class TCPSocket
    def external_encoding
        Encoding::BINARY
    end
end

require 'rexml/source'
class REXML::IOSource
    alias_method :encoding_assign, :encoding=
    def encoding=(value)
        encoding_assign(value) if value
    end
end

begin
    # OpenSSL is optional and can be missing
    require 'openssl'
    class OpenSSL::SSL::SSLSocket
        def external_encoding
            Encoding::BINARY
        end
    end
rescue
  p $!
end
# END UGLY PATCH

# Public: Methods for create and maintain a Jabber bot. Class
#         should be constructed under an EventMachine run
#         method, for keeping the bot alive. More info at:
#         http://rubyeventmachine.com/
#
# Examples:
#
#   require 'bot.rb'
#   require 'eventmachine'
#
#   EM.run {
#     bot = Bot.new 'config.yml'
#     bot.connect
#
#     bot.on_message do |text, from, msg|
#       puts "Message recieved from #{from}: '#{text}'"
#     end
#   }
class Bot

  # Public: Initialize a Bot.
  #
  # config_file - A String naming the config file (default: nil).
  def initialize(config_file = "./config.yml")
    @log = BotLogger.log

    begin
      @config    = YAML::parse(File.open(config_file))
      @username  = @config.transform['bot']['username']
      @password  = @config.transform['bot']['password']
      @allowed   = @config.transform['bot']['allowed']
      @debug     = @config.transform['bot']['debug']
      @client    = Client::new(JID::new(@username+'/boti'))
      @commands  = {}
    rescue
      @log.error "Error parsing config file '#{config_file}': #{$!}"
    end
  end

  # Public: Register a new bot command listener that will execute &block
  #         when executing it with `exec_command`
  #
  # name   - A Symbol with the command name.
  # &block - A Block to be executed when calling the bot command with the
  #          given name.
  #
  # Examples:
  #
  #   bot = Bot.new
  #   bot.connect
  #
  #   bot.on_command(:hello) do |command, from|
  #     puts "Hello world, #{from}!"
  #   end
  #
  #   bot.exec_command("hello world", "sample@user.com")
  #   # => "Hello world, sample@user.com"
  #
  def on_command(name, &block)
    name = name.to_s
    @commands[name] = block

    @log.info "New command added: #{name}"
  end

  # Public: Search for a registered bot command to execute it if found.
  #         Command is executed on a new Thread.
  #
  # command - A String containing the command to be executed.
  # from    - A String containing the address of the user that
  #           made the command execution petition.
  #
  # Examples:
  #
  #   bot = Bot.new
  #   bot.connect
  #
  #   bot.exec_command("existing command", "sample@user.com")
  #   # => true
  #
  #   bot.exec_command("nonexisting command", "sample@user.com")
  #   # => false
  #
  # Returns true if a command is found and executed, false if not.
  def exec_command(command, from)
    if !@client.is_connected?
      @log.warn "Bot is not connected. Can't execute the command."
      return false
    end

    begin
      command = Shellwords.shellwords(command)

      @commands.each do |name, block|
        if command[0].downcase.eql?(name)
          @log.info "Registered command found. Executing: '#{name}'"
          Thread.new {
            block.call(command, from)
          }
          return true
        end
      end

      @log.warn "Command '#{command[0]}' not found. Full trace: #{command}"
      return false
    rescue
      @log.error "Error executing '#{command}': #{$!}"
      return false
    end
  end

  # Public: Search for a registered bot command and tries to execute it.
  #         If the command is not found, executes the Block.
  #
  # command - A String containing the command to be executed.
  # from    - A String containing the address of the user that
  #           made the command petition.
  # &block  - Block to be executed if the command bot is not found.
  #           It recieves as parameters a String with the command,
  #           and a String with the address of the user that made
  #           the command execution petition.
  #
  #   bot = Bot.new
  #   bot.connect
  #
  #   bot.exec_command_or_do("existing", "sample@user.com") do |command, from|
  #     puts "This won't be executed"
  #   end
  #
  #   bot.exec_command_or_do("nonexisting", "sample@user.com") do |command, from|
  #     puts "This will be executed"
  #   end
  def exec_command_or_do(command, from, &block)
    return if self.exec_command(command, from)

    unless block.nil?
      @log.info "Executing default action"
      block.call(command, from)
    end
  end

  # Public: Connect the bot to the server.
  #
  # Examples:
  #
  #   bot = Bot.new
  #
  #   bot.connect
  def connect
    if @debug
      Jabber::debug = @debug
      @log.info "Jabber debug mode is active"
    end

    begin
      @log.info "Connecting to '#{@username}'..."
      @client.connect

      @log.info "Authenticating..."
      @client.auth(@password)

      @client.send(Presence.new.set_type(:available))
      @roster = Roster::Helper.new(@client)

      @log.info "Connected with user '#{@username}'"
    rescue
      @log.error "Error connecting to '#{@username}': #{$!}"
    end
  end

  # Public: Disconnect the bot from the server.
  # Examples:
  #
  #   bot = Bot.new
  #
  #   bot.connect
  #   sleep 30
  #   bot.disconnect
  def disconnect
    begin
      @log.info "Closing '#{@username}' session"
      @client.close
      @log.info "Session closed"
    rescue
      @log.error "Error disconnecting '#{@username}': #{$!}"
    end
  end

  # Public: Returns the bot connection status.
  #
  # Examples:
  #
  #   bot = Bot.new
  #
  #   bot.is_connected?
  #   # => false
  #
  #   bot.connect
  #
  #   bot.is_connected?
  #   # => true
  #
  # Returns true if the bot is connected to the server, false if not.
  def is_connected?
    if @client.is_connected?
      @log.info "Asked if bot is connected: YES it is"
      return true
    else
      @log.info "Asked if bot is connected: NO it isn't"
      return false
    end
  end

  # Public: Creates a callback for friend petition requests.
  #
  # &block - The Block executed on every friend petition request.
  #          Block will recieve as parameters: a String representing
  #          the address of the user that made the petition, a
  #          Jabber::Roster::Helper::RosterItem representing the
  #          user on your Roster (or nil if not present), and a
  #          <presence /> stanza representing the user that made
  #          the petition.
  #
  # Examples:
  #
  #   bot = Bot.new
  #
  #   bot.on_friend_petition do |from, item, presence|
  #     puts "Incoming friend petition from #{from}"
  #   end
  def on_friend_petition(&block)
    @roster.add_subscription_request_callback do |item, presence|
      begin
        from = presence.from
        @log.info "Incoming friend petition from '#{from}'"
        block.call(from, item, presence)
      rescue
        @log.error "Error processing friend petition from '#{from}': #{$!}"
      end
    end
  end

  # Public: Creates a callback for incoming messages.
  #
  # &block - The Block executed on every message recieved.
  #          Block will recieve as parameters: a String representing
  #          the message recieved, a String representing the address
  #          of the user sending the message, and a <message /> stanza
  #          representing the whole message object recieved.
  #
  # Examples:
  #
  #   bot = Bot.new
  #
  #   bot.on_message do |text, from, msg|
  #     puts "Message recieved from #{from}: '#{text}'"
  #   end
  def on_message(&block)
    @client.add_message_callback do |msg|
      begin
        from = msg.from.to_s.split('/').first
        @log.info "Incoming message from '#{from}'"
        block.call(msg.body, from, msg)
      rescue
        @log.error "Error recieving message from '#{from}': #{$!}"
      end
    end
  end

  # Public: Wrapper for sending a message to a user, regardless if the message
  #         is a String with the text of the message, or an Array of texts.
  #
  # to   - A String with the address of the user that will recieve the message.
  # text - A String with the message to be send to the user, or an Array of
  #        text message Strings.
  #
  # Examples:
  #
  #   bot = Bot.new
  #   bot.connect
  #
  #   bot.send_message "sample@user.com", "Hello world!"
  #   # => true
  #
  #   bot.send_message "sample@user.com", [ "Hello", "World" ]
  #   # => true
  #
  #   bot.disconnect
  #
  #   bot.send_message "sample@user.com", "Hello world!"
  #   # => false
  #
  # Returns true if message/s was/were sended, false if not.
  def send_message(to, message)
    if !@client.is_connected?
      @log.warn "Bot is not connected. Can't send the message."
      return false
    end

    case message
    when Array
      message.each do |text|
        sleep 1
        return unless send(to, text)
      end
    when String
      return send(to, message)
    else
      @log.error "Message is not an Array nor a String. Can't send."
      return false
    end
  end

  # Public: Checks if a friend is allowed to interact with the Bot.
  #
  # friend - A String with the address of the user that will be checked.
  #
  # Examples:
  #
  #   bot = Bot.new
  #
  #   bot.allowed_friend? 'invalid@friend.com'
  #   # => false
  #
  #   bot.allowed_friend? 'valid@friend.com'
  #   # => true
  #
  # Returns true if the user can interact with the Bot, false if not.
  def allowed_friend?(friend)
    @allowed.include? friend.to_s.split('/').first
  end

  # Public: Accept a friend request petition.
  #
  # friend - A String with the address of the friend making the petition.
  #
  # Examples:
  #
  #   bot = Bot.new
  #
  #   bot.accept_friend('friend@example.net')
  def accept_friend(friend)
    begin
      @roster.accept_subscription(friend)
    rescue
      @log.error "Error accepting friend #{friend}: #{$!}"
    end
  end

  # Public: Decline a friend request petition.
  #
  # friend - A String with the address of the friend making the petition.
  #
  # Examples:
  #
  #   bot = Bot.new
  #
  #   bot.decline_friend('friend@example.net')
  def decline_friend(friend)
    begin
      @roster.decline_subscription(friend)
    rescue
      @log.error "Error declining friend #{friend}: #{$!}"
    end
  end

  private

  # Internal: Send a message text to a user address.
  #
  # to   - A String with the address of the user that will recieve the message.
  # text - A String with the message to be send to the user.
  #
  # Examples:
  #
  #   send "sample@user.com", "Hello world!"
  #
  # Returns true if message is sended, false if not.
  def send(to, text)
    begin
      @log.info "Sending message to '#{to}'"
      @client.send Message::new(to, text).set_type(:chat).set_id('1').set_subject('Boti')
      return true
    rescue
      @log.error "Error sending message to '#{to}'"
      return false
    end
  end
end