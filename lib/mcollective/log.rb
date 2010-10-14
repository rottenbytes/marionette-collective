module MCollective
    # A simple singleton class that allows logging at various levels.
    class Log
        include Singleton

        @logger = nil

        def initialize
            config = Config.instance
            raise ("Configuration has not been loaded, can't start logger") unless config.configured
            @logmechanism = config.logmechanism
            
            case @logmechanism 
                when "syslog"
                    require 'syslog'
                    begin
                        @logger = Syslog.open("mcollectived")
                    rescue RuntimeError
                        # sometimes already opened, ruby syslog bug ?
                    end
                    # loglevel has to be a valid syslog level
                    valid_levels = ["crit", "emerg", "alert", "warning", "notice", "info", "debug", "err"]
                    raise("Loglevel should be a valid syslog level") unless valid_levels.include? @loglevel
                when "logger"
                    @logger = Logger.new(config.logfile, config.keeplogs, config.max_log_size)
                    @logger.formatter = Logger::Formatter.new
                    
                    case config.loglevel
                        when "info"
                            @logger.level = Logger::INFO
                        when "warn"
                            @logger.level = Logger::WARN
                        when "debug"
                            @logger.level = Logger::DEBUG
                        when "fatal"
                            @logger.level = Logger::FATAL
                        when "error"
                            @logger.level = Logger::ERROR
                        else
                            @logger.level = Logger::INFO
                            error("Invalid log level #{config.loglevel}, defaulting to info")
                    end
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

        # cycles the log level increasing it till it gets to the highest
        # then down to the lowest again
        def cycle_level
            # FIXME : need rework/refactor to be done with syslog too
            if @logmechanism == "syslog"
                config = Config.instance

                case @logger.level
                    when Logger::FATAL
                        @logger.level = Logger::ERROR
                        error("Logging level is now ERROR configured level is #{config.loglevel}")

                    when Logger::ERROR
                        @logger.level = Logger::WARN
                        warn("Logging level is now WARN configured level is #{config.loglevel}")

                    when Logger::WARN
                        @logger.level = Logger::INFO
                        info("Logging level is now INFO configured level is #{config.loglevel}")

                    when Logger::INFO
                        @logger.level = Logger::DEBUG
                        info("Logging level is now DEBUG configured level is #{config.loglevel}")

                    when Logger::DEBUG
                        @logger.level = Logger::FATAL
                        fatal("Logging level is now FATAL configured level is #{config.loglevel}")

                    else
                        @logger.level = Logger::DEBUG
                        info("Logging level now DEBUG configured level is #{config.loglevel}")
                end
            end
        end

        ######## FIXME #########
        # Refactor this too
        ########################
        
        # logs at level INFO
        def info(msg)
            case @logmechanism
                when "syslog"
                    Syslog.info(msg)
                when "logger"
                    log(Logger::INFO, msg)
                end
        end

        # logs at level WARN
        def warn(msg)
            case @logmechanism
                when "syslog"
                    Syslog.warning(msg)
                when "logger"
                    log(Logger::WARN, msg)
                end
        end

        # logs at level DEBUG
        def debug(msg)
            case @logmechanism
                when "syslog"
                    Syslog.debug(msg)
                when "logger"
                    log(Logger::DEBUG, msg)
                end
        end

        # logs at level FATAL - looks like fatal is not available in syslog ?!?
        def fatal(msg)
            case @logmechanism
                when "syslog"
                    Syslog.crit(msg)
                when "logger"
                    log(Logger::FATAL, msg)
                end
        end

        # logs at level ERROR
        def error(msg)
            case @logmechanism
                when "syslog"
                    Syslog.err(msg)
                when
                    log(Logger::ERROR, msg)
                end
        end

        private
        # do some fancy logging with caller information etc
        def log(severity, msg)
            begin
                from = File.basename(caller[1])
                @logger.add(severity) { "#{$$} #{from}: #{msg}" }
            rescue Exception => e
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
