# Mr. Boti

Mr. Boti is a Ruby Gtalk/XMPP client bot that, once up and running, will be listening to the messages of authorized users. Messages will be parsed looking, for registered commands in order to launch specific tasks.

## Installation

- Just clone this repo with `git clone git@github.com:juanghurtado/mrboti.git`
- Create a new `config.yml` file with your own data based on the template given at `config-sample.yml`
- Install required gems with the command `bundle` on your terminal
	(you'll need [Bundler](https://github.com/carlhuda/bundler) for this one: `gem install bundler`)

## Running

Running the script just requires to:

```ruby
ruby mr-boti.rb
```

## Current commands

### Twitter

- `twitter last <username>` Show last tweet by `<username>`
- `twitter show [count] <username>` Show last `[count]` tweets (default 5) by `<username>`
- `twitter new "<tweet text>"` Create a new tweet on Mr. Boti Twitter account

### GitHub

- `github commits <username>/<repository> <count>`: Show last `<count>` commits from `<username>`/`<repository>`

### Hudson

- `hudson build <job_name>` - Launch a build on `<job>`
- `hudson jobs <view_name>` - List all existing jobs on given `<view>` (default "all")
- `hudson views` - List all existing views

### Cleverbot

When Mr. Boti don't find an actual command, he will respond you more or less like a human using [Cleverbot]("http://cleverbot.com/").

## Adding more commands

Adding additional commands can be done with the `on_command` bot method:

```ruby
# When Mr. Boti recieves "hello", he responds like the gentleman he is
bot = Bot.new

bot.on_command :hello do |command, from|
  bot.send_message from, "Hello there! My name is Mr. Boti, and I'm here to help you."
end
```

## TO-DO

- Tests
- i18n

## Acknowledgement

This bot is based on the work made by [Nelson Neves](https://github.com/nneves) on
his [GtalkBot](https://github.com/nneves/GtalkBot). Big thanks to him.

Also a big thank you to the Ruby community for the wonderful gems and code used to build this.