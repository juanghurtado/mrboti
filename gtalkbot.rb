require 'eventmachine'
require 'xmpp4r/client'
require 'yaml'
include Jabber

puts "-> GtalkBot class loaded!"

class GtalkBot

  #--------------------------------------------
  # Initialize function
  #--------------------------------------------
  def initialize()
    puts "-> Initialize GtalkBot method called!"
    
    # get configurations from config.yml file
    tree = YAML::parse( File.open( "config.yml" ) )
    obj_tree = tree.transform
    yml_un=obj_tree['username']
    yml_pw=obj_tree['password']
    yml_dn=obj_tree['devicename']
    yml_to=obj_tree['target']
    
    # defines message target address
    @target_account = yml_to

    # initialize variable for the array of strings
    @stringlist = [""]

    # initialize @callbacks object
    @callbacks = {}
    initialize_callbacks()

    #Jabber::debug=true
    jid = JID::new(yml_un+'/'+yml_dn)
    password = yml_pw
    @cl = Client::new(jid)
    @cl.connect
    @cl.auth(password)
    @cl.send(Presence.new.set_type(:available)) 

    # Add a message callback to respond to peer requests
    @cl.add_message_callback do |inmsg|
      puts "Received Message: "+inmsg.body 
      #self.sendmessage("You have sent me this message: #{inmsg.body}")

      # adding message to string array
      @stringlist = inmsg.body.split(' ')
      
      #puts "Printing CMD array:"
      #puts @stringlist.inspect
      exec_cmd(@stringlist)
    end
  end

  #------------------------------------
  # function to send xmpp reply message
  #------------------------------------
  def sendmessage(text)
    to = @target_account
    subject = "XMPP4R test"
    body = text
    message = Message::new(to, body).set_type(:chat).set_id('1').set_subject(subject)
    @cl.send message
  end

  #-----------------------------------------------
  # function to add callbacks to @callbacks object
  #-----------------------------------------------
  def add_callback(name, &callback)
    name = name.to_s
    @callbacks[name] = callback
    self
  end

  #------------------------------------------------------------
  # function to run callbacks from @callback object (if exists)
  #------------------------------------------------------------
  def run_callback(name, *args)
    name = name.to_s
    @callbacks[name].call(*args) if @callbacks[name]
  end

  #--------------------------------------------------------------
  # function called to execute a remote command (initial parsing)
  #--------------------------------------------------------------
  def exec_cmd(params)

    #puts params.inspect

    @callbacks.each do |name, callback|
      if params[0].eql?(name) == true
        callback.call(params)
        return
      end
    end
    puts "-> NO CMD FOUND!"
  end

  #-------------------------------------------------------------
  # Initialize Callbacks - to be customized
  #-------------------------------------------------------------
  def initialize_callbacks

    # help
    add_callback(:help) do |arg|
      commandlist()
    end

    # exit
    add_callback(:exit) do |arg|
      finalize()
    end

    # quit
    add_callback(:quit) do |arg|
      finalize()
    end

    # Gtalk Status Ready
    add_callback(:ready) do |arg|
      SetStatusReady()
    end

    # Gtalk Status Do Not Disturb
    add_callback(:busy) do |arg|
      SetStatusDND()
    end

    # ...
    #add_callback(:dir) do |arg|
    #  puts arg.inspect
    #  if(arg[1] == nil)
    #    arg[1] = "/home"
    #  end
    #  Dir.chdir arg[1] # need to escape path from malicious ;rm -rf injection
    #  result = %x(ls -la)
    #  sendmessage(">ls -la #{arg[1]}\r\n#{result}")     
    #  puts result
    #end

    # Network
    add_callback(:network) do |arg|
      ethernet_interfaces()
    end
  
    # List system active users
    add_callback(:activeusers) do |arg|
      active_users()
    end   

  end

  #-------------------------------------------------------------
  # other auxiliar functions
  #--------------------------------------------------------------

  #--------------------------------------------------------------
  # List Callback Commands
  def commandlist()
     sendmessage("Available commands:")
     @callbacks.each do |name|
        puts "--> #{name[0]}"
        sendmessage("#{name[0]}")
      end
  end  
  #--------------------------------------------------------------
  # Gtalk Status Ready
  def SetStatusReady()
    @cl.send(Presence.new.set_type(:available)) 
  end
  #--------------------------------------------------------------
  # Gtalk Status Do Not Disturb
  def SetStatusDND()
    @cl.send(Jabber::Presence.new.set_show(:dnd))
  end
  #--------------------------------------------------------------
  # Exit Application
  def finalize()
    puts "-> Finalize GtalkBot method called"
    #@cl.close
    EM.stop
    return
  end
  #--------------------------------------------------------------
  # Ethernet Interfaces configuration
  def ethernet_interfaces
    ifaces = /(eth\d)/.match(`ifconfig -a`).captures.inject([]) do |result, iface|
      ifconfig = `ifconfig #{iface}`
      ip = /inet\saddr:(\d+\.\d+\.\d+\.\d+)/.match(ifconfig).captures.last
      mac = /HWaddr\s(\w+\:\w+\:\w+\:\w+\:\w+\:\w+)/.match(ifconfig).captures.last
      puts "--> ip: #{ip} | mac: #{mac}"
      sendmessage("ip: #{ip} | mac: #{mac}")
    end
  end
  #--------------------------------------------------------------
  def active_users
    users =`who`.split("\n").collect do |user|
      user_data = user.strip.split(/\s+/)
      ip = /\((.*)\)/.match(user_data.last).captures.last
      active_since = user_data[2] + ' ' + user_data[3]

      puts "--> [#{user_data[0]}] user active since [#{active_since}] from ip [#{ip}]"
      sendmessage("[#{user_data[0]}] user active since [#{active_since}] from ip [#{ip}]")
    end
  end
  #--------------------------------------------------------------

end

EM.run {
  puts "-> Launching EventMachine Run Event"
  chatbot = GtalkBot.new()
  chatbot.sendmessage("GTalkBot Initialized!")
}
