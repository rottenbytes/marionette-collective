module MCollective
    # A simple singleton class that allows logging at various levels.
    class Log
        include Singleton

        @logger = nil

        # A bit of meta programmation to reduce code duplication
        def self.log_at(name)
            define_method(name) { |msg| 
                log(@loglevel, msg)
            }
        end
        
        levels = ["info", "warn", "debug", "fatal", "error"]
        levels.each { |level|
            log_at level.to_sym
        }


        def initialize
            config = Config.instance
            raise ("Configuration has not been loaded, can't start logger") unless config.configured
            @logmechanism = config.logmechanism
            @loglevel = map_level(config.loglevel)
            
            case @logmechanism 
                when "syslog"
                    require 'syslog'
                    begin
                        @logger = Syslog.open("mcollectived")
                    rescue RuntimeError
                        # sometimes already opened, ruby syslog bug ?
                    end
                    # loglevel has to be a valid syslog level (maybe remove since map_level ensures integrity ?)
                    valid_levels = ["crit", "warning", "info", "debug", "err"]
                    raise("Loglevel should be a valid syslog level (#{@loglevel} passed)") unless valid_levels.include? @loglevel
                    
                when "logger"
                    @logger = Logger.new(config.logfile, config.keeplogs, config.max_log_size)
                    @logger.formatter = Logger::Formatter.new
                    
                    @logger.level =@loglevel
                else
                    raise("Invalid log mechanism !")
                end
        end
        
        def finalize
            # For sanity (even if finalize may not be always called)
            if @logmechanism == "syslog"
                @logger.close
            end
        end 

        def map_level(level)
            levels = ["info", "warn", "debug", "fatal", "error"]
            logger_levels = [ Logger::INFO, Logger::WARN, Logger::DEBUG, Logger::FATAL, Logger::ERROR ]
            syslog_levels = [ "info", "warning", "debug", "crit", "err" ]
            
            case @logmechanism
                when "syslog"
                    return syslog_levels[levels.index level]
                when "logger"
                    return logger_levels[levels.index level]
            end
        end 

        # cycles the log level increasing it till it gets to the highest
        # then down to the lowest again
        def cycle_level
            levels = ["info", "warn", "debug", "fatal", "error"]
        
            case @logmechanism
                when "syslog"
                    syslog_levels = [ "info", "warning", "debug", "crit", "err" ]
                    old_level = syslog_levels.index @loglevel
                    
                    if ((syslog_levels.index @loglevel) +1 < syslog_levels.length)
                        @loglevel = syslog_levels[(syslog_levels.index(@loglevel) +1)]
                    else
                        @loglevel = syslog_levels[0]
                    end
                    log(@loglevel,"Switching loglevel from #{levels[old_level]} to #{@loglevel}")
                when "logger"
                    logger_levels = [ Logger::INFO, Logger::WARN, Logger::DEBUG, Logger::FATAL, Logger::ERROR ]
                    old_level = logger_levels.index @loglevel
                    
                    if ((logger_levels.index @loglevel) +1 < logger_levels.length)
                        @loglevel = logger_levels[(logger_levels.index(@loglevel) +1)]
                    else
                        @loglevel = logger_levels[0]
                    end
                    log(@loglevel,"Switching loglevel from #{levels[old_level]} to #{logger_levels[@loglevel]}")
            end
        end
                 
        private
        # do some fancy logging with caller information etc
        def log(severity, msg)
            case @logmechanism
                when "logger"
                    begin
                        from = File.basename(caller[1])
                        @logger.add(severity) { "#{$$} #{from}: #{msg}" }
                    rescue Exception => e
                    end
                when "syslog"
                    Syslog.send(severity, msg)
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
