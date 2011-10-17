# encoding: UTF-8
require 'bot-logger'
require 'monkey-patches'
require 'octopi'

# Public: Methods for interacting with GitHub.
#
# Examples:
#
#   require 'bot-github.rb'
#
#   BotGithub.exec_command("github commmits rails/rails 3")
#   # => ["commit1", "commit2", "commit3"]
module BotGithub

  @log = BotLogger.log

  @log.info "[BotGitHub] Loading..."

  # Public: Executes a GitHub bot command. It parses the
  #         recieved command arguments looking for a valid
  #         commands (commits…) and arguments (username,
  #         repository name…). If found, execute needed internal
  #         method for that command (get_commits…).
  #
  # args - An Array with all the arguments of the command.
  #
  # Examples:
  #
  #   BotGithub.exec_command("github commmits rails/rails 3")
  #   # => ["commit1", "commit2", "commit3"]
  #
  # Returns a String (or an Array of Strings) with the response
  # from GitHub, or the error message.
  def self.exec_command(args)
    case args[1]
    when "commits"
      @log.info "[BotGitHub] `github commits` command recieved: #{args}"

      case args[2]
        when nil
          return "Please, tell me the username/repository pair: github commits rails/rails"
        else
          return "The format for username and repository should be: username/repository" if !args[2].include?('/')

          username, repository = *args[2].split('/')

          count = args[3].is_numeric? ? args[3].to_i : 5

          if !(1..10).include?(count)
            count = 5
          end

          return get_commits(username, repository, count)
      end
    else
      @log.info "[BotGitHub] `github` command recieved: #{args}"
      return \
%{Please, tell me what action do you want me to do with GitHub:
  -> commits <username>/<repository> <count>: Show last <count> commits from <username>/<repository>: github commits rails/rails 8}
    end
  end

  private

  # Internal: Get commits from a repository.
  #
  # username   - A String with the username of the repository owner.
  # repository - A String with the repository name.
  # count      - A Number with the count of commits to be returned.
  #
  # Examples:
  #
  #   get_commits('rails', 'rails', 2)
  #   # => ['[123asd23] "Commit 1 message…"', '[123asd23] "Commit 1 message…"']
  #
  # Returns an Array of String with the composed text for each commit.
  def self.get_commits(username, repository, count)
    commits = []

    Octopi::Repository.find(:user => username, :name => repository).commits[0..count].each do |commit|
      commits << parse_commit(commit)
    end

    return commits
  end

  # Internal: Format a commit to make it visually readable.
  #
  # commit - A Commit object.
  #
  # Examples:
  #
  #   parse_commit(commit)
  #   # => '[123123asd] "Lorem ipsum dolor…"'
  #
  # Returns a String with the formatted commit.
  def self.parse_commit(commit)
    id = commit.id[0..7]
    message = commit.message.split("\n").first
    name = commit.author['name']
    email = commit.author['email']
    date = Time.parse(commit.committed_date).strftime("%d/%m/%Y %H:%M")
    url = "http://github.com/"+ commit.url

    return "[#{id}] \"#{message}\"\n#{name} <#{email}> #{date}\n#{url}\n\n"
  end
end