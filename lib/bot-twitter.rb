# encoding: UTF-8
require 'bot-logger'
require 'monkey-patches'
require 'time'
require 'twitter'
require 'yaml'

# Public: Methods for interacting with Twitter.
#
# Examples:
#
#   require 'bot-twitter.rb'
#
#   BotTwitter.exec_command("twitter last juanghurtado")
#   # => "\"Lorem ipsum dolor\" - 12/12/2011 15:32"
module BotTwitter
  
  @log = BotLogger.log
  
  # Public: Executes a Twitter bot command. It parses the
  #         recieved command arguments looking for a valid
  #         commands (last, show, new…) and arguments (username,
  #         count, message…). If found, execute needed internal
  #         method for that command (get_tweets, send_tweet…).
  #
  # args - An Array with all the arguments of the command.
  #
  # Examples:
  #
  #   BotTwitter.exec_command("twitter last juanghurtado")
  #   # => "\"Lorem ipsum dolor\" - 12/12/2011 15:32"
  #
  # Returns a String (or an Array of Strings) with the response
  # from Twitter, or the error message.
  def self.exec_command(args)
    case args[1]
    when "last"
      @log.info "[BotTwitter] `twitter last` command recieved: #{args}"
      
      case args[2]
        when nil
          return "Please, tell me the user: twitter last juanghurtado"
        else
          username = args[2].sub('@','')
          count = 1
          
          return get_tweets(username, count)
      end
    when "show"
      @log.info "[BotTwitter] `twitter show` command recieved: #{args}"
      
      case args[2]
        when nil
          return "Please, tell me the user: twitter show juanghurtado"
        else
          username = args[2].sub('@','')
          count = args[3].is_numeric? ? args[3].to_i : 5
          
          if !(1..10).include?(count)
            count = 5
          end
          
          return get_tweets(username, count)
      end
    when "new"
      @log.info "[BotTwitter] `twitter new` command recieved: #{args}"
      
      message = args[2]
      
      return "Please, give me the tweet text: twitter new \"Lorem ipsum dolor\"" if message.nil?
      
      return send_tweet(message)
      new
    else
      @log.info "[BotTwitter] `twitter` command recieved: #{args}"
      return \
%{Please, tell me what action do you want me to do with Twitter:
  -> last <username>: Show last tweet by <username>
  -> show [count] <username>: Show last [count] tweets (default 5) by <username>
  -> new "<tweet text>": Create a new tweet on Mr. Botti Twitter account}
    end
  end
  
  private
  
  # Internal: Configure Twitter API with params from YAML config gile
  #
  # config_file - A String with the path of the config YAML file.
  #               Defaults to './config.yml'
  def self.configure(config_file = "./config.yml")
    @log.info "[BotTwitter] Configuring..."
    
    begin
      yaml = YAML::parse(File.open(config_file))
      Twitter.configure do |cfg|
        cfg.consumer_key       = yaml.transform['twitter']['consumer_key']
        cfg.consumer_secret    = yaml.transform['twitter']['consumer_secret']
        cfg.oauth_token        = yaml.transform['twitter']['oauth_token']
        cfg.oauth_token_secret = yaml.transform['twitter']['oauth_token_secret']
        cfg.gateway            = yaml.transform['twitter']['gateway']
      end
    rescue
      @log.error "[BotTwitter] Error during configuration: #{$!}"
    end
  end
  
  # Call to `configure` for auto-config on require
  self.configure
  
  # Internal: Get tweets for a given user.
  #
  # username - A String with the username.
  # count    - A Number with how many tweets we want to get.
  #
  # Examples:
  #
  #   get_tweets('juanghurtado', 3)
  #   # => ["Tweet 1", "Tweet 2", "Tweet 3"]
  #
  # Returns an Array of tweets text Strings.
  def self.get_tweets(username, count)
    if !valid_user?(username)
      @log.warn "[BotTwitter] Getting tweets... Not valid user"
      
      return "User doesn't exists."
    elsif valid_user?(username) && protected_user?(username)
      @log.warn "[BotTwitter] Getting tweets... Protected account"
      
      return "Protected account. Can't show tweets."
    end
    
    begin
      @log.info "[BotTwitter] Getting tweets..."
      
      tweets = []
      Twitter.user_timeline(username, :count => count).each do |tweet|
        tweets << format_tweet(tweet)
      end
      return tweets
    rescue
      @log.error "[BotTwitter] Error getting tweets: #{$!}"
    end
  end
  
  # Internal: Send a tweet to the account for the API configured.
  #
  # msg - A String with the tweet text to be send.
  #
  # Examples:
  #
  #   send_tweet('Lorem ipsum dolor')
  #   # => "Tweet sent: \"Lorem ipsum dolor\""
  def self.send_tweet(msg)
    begin
      @log.info "[BotTwitter] Sending tweet..."
      
      Twitter.update(msg)
      "Tweet sent: \"#{Twitter.home_timeline.first.text}\""
    rescue
      @log.error "[BotTwitter] Error sending tweet: #{$!}"
    end
  end
  
  # Internal: Check if a username has a protected account.
  #
  # username - A String with the username.
  #
  # Examples:
  #
  #   protected_user?('juanghurtado')
  #   # => false
  #
  #   protected_user?('protected_user)
  #   # => true
  #
  # Returns true if the user has a protected account. False if not.
  def self.protected_user?(username)
    begin
      Twitter.user(username).protected?
    rescue
      @log.error "[BotTwitter] Error getting account protected status: #{$!}"
    end
  end
  
  # Internal: Check if a user account is valid.
  #
  # username - A String with the username.
  #
  # Examples:
  #
  #   valid_user?('valid')
  #   # => true
  #
  #   valid_user?('not_valid')
  #   # => false
  #
  # Returns true if the user is valid. False if not.
  def self.valid_user?(username)
    begin
      Twitter.user?(username)
    rescue
      @log.error "[BotTwitter] Error getting existence of user #{username}: #{$!}"
    end
  end
  
  # Internal: Formats a tweet with his text and date.
  #
  # tweet - Tweet object.
  #
  # Examples:
  #
  #   format_tweet(tweet)
  #   # => "\"Lorem ipsum dolor\" - 12/12/2011 15:32"
  def self.format_tweet(tweet)
    "\"#{tweet.text}\" - #{Time.parse(tweet.created_at).strftime('%d/%m/%Y %H:%M')}"
  end
  
end