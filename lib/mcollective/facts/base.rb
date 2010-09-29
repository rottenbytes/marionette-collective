module MCollective
    module Facts
        # A base class for fact providers, to make a new fully functional fact provider 
        # inherit from this and simply provide a self.get_facts method that returns a 
        # hash like:
        #
        #  {"foo" => "bar",
        #   "bar" => "baz"}
        class Base
            # Registers new fact sources into the plugin manager
            def self.inherited(klass)
                PluginManager << {:type => "facts_plugin", :class => klass.to_s}

                @@fact_timestamp = Time.now.to_i
                @@facts={}
                @@cachetime = Config.instance.pluginconf["facts.cachetime"].to_i
                Log.instance.debug("Initializing fact cache timestamp (#{@@fact_timestamp})")
                Log.instance.debug("Initializing fact cache to nil")
                Log.instance.debug("Caching facts for #{@@cachetime} seconds")
            end

            # Returns the value of a single fact
            def get_fact(fact)
                # outdated cache / no initialized facts
                Log.instance.debug("cache analysis : #{@@fact_timestamp} / Actual : " + Time.now.to_i.to_s)
                if ((Time.now.to_i - @@fact_timestamp.to_i).to_i > @@cachetime) or @@facts.empty? then
                    # update facts
                    Thread.exclusive do
                       Log.instance.debug("Outdated/uninitialized facts, updating")
                       @@facts=get_facts
                       # update timestamp
                       @@fact_timestamp = Time.now.to_i
                    end
                end
            
                @@facts.include?(fact) ? @@facts[fact] : nil
            end

            # Returns true if we know about a specific fact, false otherwise
            def has_fact?(fact)
                facts = get_facts

                facts.include?(fact)
            end
            
            
        end
    end
end
