# GtalkBot

GtalkBot is a Ruby Gtalk/XMPP client Bot that will connect to a server and will be listening to the authorized users messages and search for specific 'mapped' commands in order to launch specific local tasks.

The main idea would be to use my GoogleTalk account from the mobile or even from the PC Desktop application, to remotely control my Linux NAS server, for an easy way to start/stop/restart some application/service without having to login from SSH to do it.

This is my first Ruby application/script, so bare in mind that coding techniques may need to be improved.

Would also like to add a special note to avoid calling direct Linux commands (there is a 'ls -la' example just as a proof-of-concept) because it may suffer from some security issues, please read this:

http://stackoverflow.com/questions/4650636/forming-sanitary-shell-commands-or-system-calls-in-ruby


Before running the script it is necessary to change the user credentials in the config.ylm file.

Running the script just requires to:
    >ruby gtalkbot.rb


Adding additional commands can be done in the 'initialize_callbacks' function, just requires to add additional callback to the list:

    add_callback(:hello) do |arg|
      sendmessage("Hello World off Ruby! This sh1t r0ck5!")  
    end

The callback name 'hello' will then be used as the command name! Please check the examples to see how to send extra parameters with the command!


### TOBEDONE

* Limit communications to specific accounts (will only listen commands from specific user account)
* Access Control the commands (e.g.: user1 can call all, user2 will only have access to specific commands)
* Escape Parameters from possible security flaws!
