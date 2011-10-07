# encoding: UTF-8
require 'log4r'

class BotLogger
  
  def self.log
    log = Log4r::Logger.new('Logger')
    format = Log4r::PatternFormatter.new(:pattern => "[%l] %d -> %m")
    log.add Log4r::StdoutOutputter.new('console', :formatter => format)
    return log
  end
  
end