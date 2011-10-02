# Mr. Boti

Mr. Boti is a Ruby Gtalk/XMPP client bot that, once up and running, will be listening to the authorized users messages and search for specific registered commands in order to launch specific tasks.

## Installation

- Just clone this repo with `git clone git@github.com:juanghurtado/mrboti.git`
- Create a new `config.yml` file with your own data based on the template given at `config-sample.yml`
- Install required gems with the command `bundle` on your terminal (you'll need [Bundler](https://github.com/carlhuda/bundler) for this one: `gem install bundler`)

## Running

Running the script just requires to:

```ruby
ruby boti.rb
```

## Current commands

- `help` Show a list of available commands
- `twitter` Working with Twitter
  - `twitter last <username>` Show last tweet by `<username>`
  - `twitter show [count] <username>` Show last `[count]` tweets (default 5) by `<username>`
  - `new "<tweet text>"` Create a new tweet on Mr. Botti Twitter account

## Adding more commands

Adding additional commands can be done in the `initialize_callbacks` function:

```ruby
# When Mr. Boti recieves "hello", he responds like the gentleman he is
add_callback(:hello) do |arg|
  sendmessage "Hello there! My name is Mr. Boti, and I'm here to help you."
end
```

## Acknowledgement

This bot is based on the work made by [Nelson Neves](https://github.com/nneves) on his [GtalkBot](https://github.com/nneves/GtalkBot). Big thanks to him.