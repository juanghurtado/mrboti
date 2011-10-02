# encoding: UTF-8
require 'eventmachine'
require 'shellwords'
require 'time'
require 'twitter'
require 'yaml'
require 'xmpp4r/client'
require 'xmpp4r/roster'

include Jabber

class Boti

  # --------------------------------------------------------------
  #  =CONSTRUCTOR
  # --------------------------------------------------------------
  def initialize()
    @yaml = YAML::parse(File.open("config.yml"))
    username = @yaml.transform['bot']['username']
    password = @yaml.transform['bot']['password']
    @allowed = @yaml.transform['bot']['allowed']
    @callbacks = {}
    
    initialize_callbacks()
    
    Jabber::debug = true
    @cl = Client::new(JID::new(username+'/boti'))
    @cl.connect
    @cl.auth(password)
    @cl.send(Presence.new.set_type(:available))
    @roster = Roster::Helper.new(@cl)
    
    # Add a subscription callback to respond to invitations
    @roster.add_subscription_callback do |item, presence|
      friend = presence.from
      if valid_friend? friend
        p "-> Accepting friend request from: #{friend}"
        @roster.accept_subscription(friend)
      else
        p "-> Declining friend request from: #{friend}"
        @roster.decline_subscription(friend)
      end
    end
    
    # Add a message callback to respond to messages
    @cl.add_message_callback do |inmsg|
      @target_account =  inmsg.from.to_s.split('/').first
      
      if !valid_friend? @target_account
        sendmessage "You are not my friend! Leave me alone!"
      else
        exec_cmd(Shellwords.shellwords inmsg.body)
      end
    end
  end
  
  private
  
  # --------------------------------------------------------------
  #  =UTILS
  # --------------------------------------------------------------
  
  #  =|Global utils
  # --------------------------------------------------------------
  def valid_friend? friend
    @allowed.include? friend.split('/').first
  end

  def sendmessage(text)
    @cl.send Message::new(@target_account, text).set_type(:chat).set_id('1').set_subject('Boti')
  end
  
  def random_message(arg)
    sendmessage "I don't know what you are saying. Try writing: help"
  end

  def exec_cmd(params)
    @callbacks.each do |name, callback|
      if params[0].eql?(name) == true
        callback.call params
        return
      end
    end
    
    random_message params
  end
  
  def is_numeric?(s)
    !!Float(s) rescue false
  end
  
  #  =|Twitter utils
  # --------------------------------------------------------------
  def twitter_protected? username
    if Twitter.user(username).protected?
      sendmessage "-> @#{username} has a protected account. I can't show you the tweets."
      return true
    end
  end
  
  def format_tweet tweet
    "\"#{tweet.text}\" - #{Time.parse(tweet.created_at).strftime('%d/%m/%Y %H:%M')}"
  end
  
  # --------------------------------------------------------------
  #  =CALLBACKS
  # --------------------------------------------------------------
  def add_callback(name, &callback)
    name = name.to_s
    @callbacks[name] = callback
    self
  end

  def initialize_callbacks
    add_callback(:help) do |arg|
      sendmessage \
%{Available commands:
  -> help: Show this help
  -> twitter: Show tweets
        - twitter last <username>: Show last tweet by <username>
        - twitter show [count] <username>: Show last [count] tweets (default 5) by <username>
        - new "<tweet text>": Create a new tweet on Mr. Botti Twitter account}
    end
    
    add_callback(:twitter) do |arg|
      twitter arg
    end
  end

  # --------------------------------------------------------------
  #  =COMMANDS
  # --------------------------------------------------------------
  
  #  =|Twitter command
  # --------------------------------------------------------------
  def twitter(arg)
    if arg[1] == nil
      sendmessage \
%{Please, what action do you want me to do with twitter:
  -> last <username>: Show last tweet by <username>
  -> show [count] <username>: Show last [count] tweets (default 5) by <username>
  -> new "<tweet text>": Create a new tweet on Mr. Botti Twitter account}
      return
    end
    
    begin
      Twitter.configure do |config|
        config.consumer_key = @yaml.transform['twitter']['consumer_key']
        config.consumer_secret = @yaml.transform['twitter']['consumer_secret']
        config.oauth_token = @yaml.transform['twitter']['oauth_token']
        config.oauth_token_secret = @yaml.transform['twitter']['oauth_token_secret']
        config.gateway = @yaml.transform['twitter']['gateway']
      end
      
      case arg[1]
      when "last"
        if arg[2] == nil
          sendmessage("Please, tell me the user: twitter last juanghurtado")
          return
        end
        username = arg[2].sub('@','')
        
        return if twitter_protected? username
        
        sendmessage "-> Looking for last tweet by: @#{username}"
        tweet = Twitter.user_timeline(username).first
        sendmessage format_tweet(tweet)
      when "show"
        if (arg[2] == nil && arg[3] == nil)
          sendmessage("Please, tell me the user: twitter last juanghurtado")
          return
        end
        
        if (arg[2] != nil && arg[3] == nil) || (arg[2] != nil && arg[3] != nil)
          username = (arg[3].nil? ? arg[2] : arg[3]).sub('@','')
          
          if arg[3].nil?
            count = 5
          else
            count = is_numeric?(arg[2]) ? arg[2].to_i : 5
            count = count > 10 ? 5 : count
          end
          
          return if twitter_protected? username
          
          sendmessage "-> Looking last #{count} tweets by: @#{username}"
          Twitter.user_timeline(username, :count => count).each do |tweet|
            sendmessage format_tweet(tweet)
          end
        end
      when "new"
        if arg[2] == nil
          sendmessage("Please, give the tweet text: twitter new \"Lorem ipsum dolor\"")
          return
        end
        
        sendmessage "-> Sending new @botirb tweet"
        Twitter.update("#{arg[2]}")
        sendmessage "-> Tweet sent: \"#{Twitter.home_timeline.first.text}\""
      end
    rescue
      p "--> #{$!}"
      sendmessage "-> Can't do that operation"
    end
  end
  
  
end

# --------------------------------------------------------------
#  =INIT
# --------------------------------------------------------------
EM.run {
  chatbot = Boti.new()
}