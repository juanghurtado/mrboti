# encoding: UTF-8
require 'bot_logger'
require 'monkey_patches'
require 'httparty'

# Public: Methods for interacting with Hudson.
#
# Examples:
#
#   require 'bot-hudson.rb'
#
#   BotHudson.exec_command("hudson list sample_view")
#   # => ["[OK] Job name (http:/..)", "[FAIL] Job name (http:/..)"]
module BotHudson
  @log = BotLogger.log

  begin
    @log.info "[BotHudson] Loading..."

    yaml = YAML::parse(File.open("./config.yml"))
    @base_uri = yaml.transform['hudson']['base_uri']
    @options  = yaml.transform['hudson']['options']
  rescue
    @log.error "[BotHudson] Error during configuration: #{$!}"
  end

  # Public: Executes a Hudson bot command. It parses the
  #         recieved command arguments looking for a valid
  #         commands (build, list…) and arguments (job name,
  #         view name…). If found, execute needed internal
  #         method for that command (build, jobs…).
  #
  # args - An Array with all the arguments of the command.
  #
  # Examples:
  #
  #   BotHudson.exec_command("hudson list sample_view")
  #   # => ["[OK] Job name (http:/..)", "[FAIL] Job name (http:/..)"]
  #
  # Returns a String (or an Array of Strings) with the response
  # from Hudson, or the error message.
  def self.exec_command(args)
    case args[1]
    when "build"
      @log.info "[BotHudson] `hudson build` command recieved: #{args}"

      case args[2]
        when nil
          return "Please, tell me the name of the project to build: hudson build project_name"
        else
          response = build(args[2])

          case
          when response.kind_of?(Net::HTTPOK)
            return "Build for '#{args[2]}' succesfully sent"
          when response.kind_of?(Net::HTTPNotFound)
            return "Project '#{args[2]}' not found"
          else
            return "Sorry, there were problems making that request: #{response.class}"
          end
      end
    when "jobs"
      @log.info "[BotHudson] `hudson jobs` command recieved: #{args}"

      jobs = self.jobs(args[2])

      case jobs
      when Array
        response = ""
        jobs.each do |project|
          status = color_to_status(project['color'])
          response += "-> [#{status}] #{project['name']} (#{project['url']})\n"
        end

        return response
      when String
        return jobs
      end
    when "views"
      @log.info "[BotHudson] `hudson views` command recieved: #{args}"

      views = self.views()

      case views
      when Array
        response = ""
        views.each do |view|
          response += "-> #{view['name']} (#{view['url']})\n"
        end

        return response
      when String
        return views
      end
    else
      @log.info "[BotHudson] `hudson` command recieved: #{args}"
      return \
%{Please, tell me what action do you want me to do with Hudson:
  -> build <job_name> - Launch a build on <job_name>: hudson build sample_name
  -> jobs <view> - List all existing jobs on given <view> (default "all"): hudson list view_name
  -> views - List all existing views: hudson views}
    end
  end

  # Public: Returns the command symbol for this module.
  def self.main_command
    :hudson
  end

  private

  # Internal: Send a build command for a given job.
  #
  # project_name - A String with the job.
  #
  # Examples:
  #
  #   build('sample_job')
  #   # => Net::HTTPOK
  #
  #   build('unexisting_job)
  #   # => Net::HTTPNotFound
  #
  # Returns an HTTPResponse code according to the recieved
  # server response or nil if failed
  def self.build(project_name)
    begin
      project_name = parse_for_url(project_name)
      url = "#{@base_uri}/job/#{project_name}/build"

      @log.info "[BotHudson] Sending POST request to #{url} with options: #{@options}"

      return HTTParty.post(url, @options).response
    rescue
      @log.error "[BotHudson] Error sending build request: #{$!}"
      return nil
    end
  end

  # Internal: List jobs for a given view.
  #
  # view_name - A String with the view name.
  #
  # Examples:
  #
  #   jobs()
  #   # => [{"name"=>"Sample", "url"=>"http://...", "color"=>"blue"}, {...}]
  #
  #   build('sample_view)
  #   # => [{"name"=>"Sample", "url"=>"http://...", "color"=>"blue"}, {...}]
  #
  # Returns an Array of jobs Hashes with "name", "url" and "color" or
  # a String with the error message if request failed.
  def self.jobs(view_name)
    begin
      view_name ||= "All"
      view_name = parse_for_url(view_name)
      url = "#{@base_uri}/view/#{view_name}/api/json"

      @log.info "[BotHudson] Sending GET request to #{url} with options: #{@options}"

      r = HTTParty.get(url, @options)

      case r.response
      when Net::HTTPOK
        return r.parsed_response['jobs']
      when Net::HTTPNotFound
        @log.warn "[BotHudson] View not found: #{$!}"
        return "That view doesn't exists."
      else
        @log.error "[BotHudson] Error sending list request: #{$!}"
        return "-> Error requesting jobs. Try again later: #{r.response}"
      end
    rescue
      @log.error "[BotHudson] Error sending list request: #{$!}"
      return "-> Error requesting jobs. Try again later."
    end
  end

  # Internal: List available views.
  #
  # Examples:
  #
  #   views()
  #   # => [{"name"=>"Sample", "url"=>"http://..."}, {...}]
  #
  # Returns an Array of views Hashes with "name" and "url" or
  # a String with the error message if request failed.
  def self.views
    begin
      url = "#{@base_uri}/api/json"

      @log.info "[BotHudson] Sending GET request to #{url} with options: #{@options}"

      r = HTTParty.get(url, @options)

      case r.response
      when Net::HTTPOK
        return r.parsed_response['views']
      else
        @log.error "[BotHudson] Error sending view list request: #{$!}"
        return "-> Error requesting views. Try again later: #{r.response}"
      end
    rescue
      @log.error "[BotHudson] Error sending list request: #{$!}"
      return "-> Error requesting jobs. Try again later."
    end
  end

  # Internal: Parse a String, making it suitable for URL's.
  #
  # str - A String to be URL suitable.
  #
  # Examples:
  #
  #   parse_for_url("uno dos tres catorce")
  #   # => "uno%20dos%20tres%20catorce"
  #
  # Returns a String suitable for URL purposes.
  def self.parse_for_url(str)
    URI.escape(str, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end

  # Internal: Transform a Hudson color string to corresponding status.
  #
  # color - A String with the color to be transformed.
  #
  # Examples:
  #
  #   color_to_status("blue")
  #   # => "OK"
  #
  #   color_to_status("yellow")
  #   # => "TESTS FAIL"
  #
  # Returns a String with the status for the given color.
  def self.color_to_status(color)
    case color
    when "blue"
      "OK"
    when "red"
      "FAIL"
    when "yellow"
      "TESTS FAIL"
    when "grey"
      "NO BUILD"
    else
      "NO STATUS"
    end
  end
end