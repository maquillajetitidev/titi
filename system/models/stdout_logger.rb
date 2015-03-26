require 'logger'

DB.loggers << Logger.new($stdout)
# logger
Dir.mkdir('logs') unless File.exist?('logs')
# logger = Logger.new("logs/#{settings.environment}.log",'weekly')
logger = Logger.new($stdout)
# $stdout.reopen("logs/#{settings.environment}.log", "w")
$stdout.sync = true
# $stderr.reopen($stdout)
logger.level = Logger::WARN

# DB.loggers << logger if logger
# DB.log_warn_duration = 0.1
