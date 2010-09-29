module MCollective
    module RPC
        # Various utilities for the RPC system
        class Helpers
            # Return color codes, if the config color= option is false
            # just return a empty string
            def self.color(code)
                colorize = Config.instance.color

                colors = {:red => "[31m",
                          :green => "[32m",
                          :yellow => "[33m",
                          :cyan => "[36m",
                          :bold => "[1m",
                          :reset => "[0m"}

                if colorize
                    return colors[code] || ""
                else
                    return ""
                end
            end

            # Helper to return a string in specific color
            def self.colorize(code, msg)
                "#{self.color(code)}#{msg}#{self.color(:reset)}"
            end

            # Returns a blob of text representing the results in a standard way
            #
            # It tries hard to do sane things so you often
            # should not need to write your own display functions
            #
            # If the agent you are getting results for has a DDL
            # it will use the hints in there to do the right thing specifically
            # it will look at the values of display in the DDL to choose
            # when to show results
            #
            # If you do not have a DDL you can pass these flags:
            #
            #    printrpc exim.mailq, :flatten => true
            #    printrpc exim.mailq, :verbose => true
            #
            # If you've asked it to flatten the result it will not print sender
            # hostnames, it will just print the result as if it's one huge result,
            # handy for things like showing a combined mailq.
            def self.rpcresults(result, flags = {})
                flags = {:verbose => false, :flatten => false}.merge(flags)

                result_text = ""

                # if running in verbose mode, just use the old style print
                # no need for all the DDL helpers obfuscating the result
                if flags[:verbose]
                    result_text = old_rpcresults(result, flags)
                else
                    result.each do |r|
                        begin
                            ddl = DDL.new(r.agent).action_interface(r.action.to_s)

                            sender = r[:sender]
                            status = r[:statuscode]
                            message = r[:statusmsg]
                            display = ddl[:display]
                            result = r[:data]

                            # appand the results only according to what the DDL says
                            case display
                                when :ok
                                    if status == 0
                                        result_text << text_for_result(sender, status, message, result, ddl)
                                    end

                                when :failed
                                    if status > 0
                                        result_text << text_for_result(sender, status, message, result, ddl)
                                    end

                                when :always
                                    result_text << text_for_result(sender, status, message, result, ddl)

                                when :flatten
                                    result_text << text_for_flattened_result(status, result)

                            end
                        rescue Exception => e
                            # no DDL so just do the old style print unchanged for
                            # backward compat
                            result_text = old_rpcresults(result, flags)
                        end
                    end
                end

                result_text
            end

            # Return text representing a result
            def self.text_for_result(sender, status, msg, result, ddl)
                statusses = ["",
                             colorize(:red, "Request Aborted"),
                             colorize(:yellow, "Unknown Action"),
                             colorize(:yellow, "Missing Request Data"),
                             colorize(:yellow, "Invalid Request Data"),
                             colorize(:red, "Unknown Request Status")]

                result_text = "%-40s %s\n" % [sender, statusses[status]]
                result_text << "   %s\n" % [colorize(:yellow, msg)] unless msg == "OK"

                # only print good data, ignore data that results from failure
                if [0, 1].include?(status)
                    if result.is_a?(Hash)
                        # figure out the lengths of the display as strings, we'll use
                        # it later to correctly justify the output
                        lengths = result.keys.map{|k| ddl[:output][k][:display_as].size}

                        result.keys.each do |k|
                            # get all the output fields nicely lined up with a
                            # 3 space front padding
                            display_as = ddl[:output][k][:display_as]
                            display_length = display_as.size
                            padding = lengths.max - display_length + 3
                            result_text << " " * padding

                            result_text << "#{display_as}:"

                            if result[k].is_a?(String) || result[k].is_a?(Numeric)
                                result_text << " #{result[k]}\n"
                            else
                                result_text << "\n\t" + result[k].pretty_inspect.split("\n").join("\n\t") + "\n"
                            end
                        end
                    else
                        result_text << "\n\t" + result.pretty_inspect.split("\n").join("\n\t")
                    end
                end

                result_text << "\n"
                result_text
            end

            # Returns text representing a flattened result of only good data
            def self.text_for_flattened_result(status, result)
                result_text = ""

                if status <= 1
                    unless result.is_a?(String)
                        result_text << result.pretty_inspect
                    else
                        result_text << result
                    end
                end
            end

            # Backward compatible display block for results without a DDL
            def self.old_rpcresults(result, flags = {})
                result_text = ""

                if flags[:flatten]
                    result.each do |r|
                        if r[:statuscode] <= 1
                            data = r[:data]

                            unless data.is_a?(String)
                                result_text << data.pretty_inspect
                            else
                                result_text << data
                            end
                        else
                            result_text << r.pretty_inspect
                        end
                    end

                    result_text << ""
                else
                    result.each do |r|

                        if flags[:verbose]
                            result_text << "%-40s: %s\n" % [r[:sender], r[:statusmsg]]

                            if r[:statuscode] <= 1
                                r[:data].pretty_inspect.split("\n").each {|m| result_text += "    #{m}"}
                                result_text += "\n"
                            elsif r[:statuscode] == 2
                                # dont print anything, no useful data to display
                                # past what was already shown
                            elsif r[:statuscode] == 3
                                # dont print anything, no useful data to display
                                # past what was already shown
                            elsif r[:statuscode] == 4
                                # dont print anything, no useful data to display
                                # past what was already shown
                            else
                                result_text << "    #{r[:statusmsg]}"
                            end
                        else
                            unless r[:statuscode] == 0
                                result_text << "%-40s %s\n" % [r[:sender], colorize(:red, r[:statusmsg])]
                            end
                        end
                    end
                end

                result_text << ""
            end

            # Add SimpleRPC common options
            def self.add_simplerpc_options(parser, options)
                parser.separator ""

                # add SimpleRPC specific options to all clients that use our library
                parser.on('--np', '--no-progress', 'Do not show the progress bar') do |v|
                    options[:progress_bar] = false
                end
            end
        end
    end
end
