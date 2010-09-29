module MCollective
    # A pretty sucky config class, ripe for refactoring/improving
    class Config
        include Singleton

        attr_reader :topicprefix, :daemonize, :pluginconf, :libdir, :configured, :logfile,
                    :keeplogs, :max_log_size, :loglevel, :identity, :daemonize, :connector,
                    :securityprovider, :factsource, :registration, :registerinterval, :topicsep,
                    :classesfile, :rpcauditprovider, :rpcaudit, :configdir, :rpcauthprovider,
                    :rpcauthorization, :color, :configfile, :rpchelptemplate

        def initialize
            @configured = false
        end

        def loadconfig(configfile)
            @stomp = Hash.new
            @subscribe = Array.new
            @pluginconf = Hash.new
            @connector = "Stomp"
            @securityprovider = "Psk"
            @factsource = "Yaml"
            @identity = Socket.gethostname
            @registration = "Agentlist"
            @registerinterval = 0
            @topicsep = "."
            @classesfile = "/var/lib/puppet/classes.txt"
            @rpcaudit = false
            @rpcauditprovider = ""
            @rpcauthorization = false
            @rpcauthprovider = ""
            @configdir = File.dirname(configfile)
            @color = true
            @configfile = configfile
            @rpchelptemplate = "/etc/mcollective/rpc-help.erb"
            @keeplogs = 5
            @max_log_size = 2097152

            if File.exists?(configfile)
                File.open(configfile, "r").each do |line|

                    # strip blank spaces, tabs etc off the end of all lines
                    line.gsub!(/\s*$/, "")

                    unless line =~ /^#|^$/
                        if (line =~ /(.+?)\s*=\s*(.+)/)
                            key = $1
                            val = $2

                            case key
                                when "topicsep"
                                    @topicsep = val
                                when "registration"
                                    @registration = val.capitalize
                                when "registerinterval"
                                    @registerinterval = val.to_i
                                when "topicprefix"
                                    @topicprefix = val
                                when "logfile"
                                    @logfile = val
                                when "keeplogs"
                                    @keeplogs = val.to_i
                                when "max_log_size"
                                     @max_log_size = val.to_i
                                when "loglevel"
                                     @loglevel = val
                                when "libdir"
                                    @libdir = val
                                    unless $LOAD_PATH.include?(val)
                                        $LOAD_PATH << val
                                    end
                                when "identity"
                                    @identity = val
                                when "color"
                                    val =~ /^1|y/i ? @color = true : @color = false
                                when "daemonize"
                                    val =~ /^1|y/i ? @daemonize = true : @daemonize = false
                                when "securityprovider"
                                    @securityprovider = val.capitalize
                                when "factsource"
                                    @factsource = val.capitalize
                                when "connector"
                                    @connector = val.capitalize
                                when "classesfile"
                                    @classesfile = val
                                when /^plugin.(.+)$/
                                    @pluginconf[$1] = val
                                when "rpcaudit"
                                    val =~ /^1|y/i ? @rpcaudit = true : @rpcaudit = false
                                when "rpcauditprovider"
                                    @rpcauditprovider = val.capitalize
                                when "rpcauthorization"
                                    val =~ /^1|y/i ? @rpcauthorization = true : @rpcauthorization = false
                                when "rpcauthprovider"
                                    @rpcauthprovider = val.capitalize
                                when "rpchelptemplate"
                                    @rpchelptemplate = val

                                else
                                    raise("Unknown config parameter #{key}")
                            end
                        end
                    end
                end

                @configured = true

                PluginManager.loadclass("Mcollective::Facts::#{@factsource}")
                PluginManager.loadclass("Mcollective::Connector::#{@connector}")
                PluginManager.loadclass("Mcollective::Security::#{@securityprovider}")
                PluginManager.loadclass("Mcollective::Registration::#{@registration}")
                PluginManager.loadclass("Mcollective::Audit::#{@rpcauditprovider}") if @rpcaudit
                PluginManager << {:type => "global_stats", :class => RunnerStats.new}
            else
                raise("Cannot find config file '#{configfile}'")
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
