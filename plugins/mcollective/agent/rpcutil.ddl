metadata    :name        => "Utilities and Helpers for SimpleRPC Agents",
            :description => "General helpful actions that expose stats and internals to SimpleRPC clients", 
            :author      => "R.I.Pienaar <rip@devco.net>",
            :license     => "Apache License, Version 2.0",
            :version     => "1.0",
            :url         => "http://marionette-collective.org/",
            :timeout     => 3

action "inventory", :description => "System Inventory" do
    display :always
    
    output :agents,
           :description => "List of agent names",
           :display_as => "Agents"
    
    output :facts,
           :description => "List of facts and values",
           :display_as => "Facts"
    
    output :classes,
           :description => "List of classes on the system",
           :display_as => "Classes"

    output :version,
           :description => "MCollective Version",
           :display_as => "Version"
end

action "get_fact", :description => "Retrieve a single fact from the fact store" do
     display :always
     
     input :fact,
         :prompt      => "The name of the fact",
         :description => "The fact to retrieve",
         :type        => :string,
         :validation  => '^[a-z_]+$',
         :optional    => false,
         :maxlength    => 40
     
     output :fact,
            :description => "The name of the fact being returned",
            :display_as => "Fact"
     
     output :value,
            :description => "The value of the fact",
            :display_as => "Value"
end

action "daemon_stats", :description => "Get statistics from the running daemon" do
    display :always
    
    output :threads,
           :description => "List of threads active in the daemon",
           :display_as => "Threads"
    
    output :agents,
           :description => "List of agents loaded",
           :display_as => "Agents"
    
    output :pid,
           :description => "Process ID of the daemon",
           :display_as => "PID"
    
    output :times,
           :description => "Processor time consumed by the daemon",
           :display_as => "Times"
    
    output :validated,
           :description => "Messages that passed security validation",
           :display_as => "Security Validated"
    
    output :unvalidated,
           :description => "Messages that failed security validation",
           :display_as => "Failed Security"
    
    output :passed,
           :description => "Passed filter checks",
           :display_as => "Passed Filter"
    
    output :filtered,
           :description => "Didn't pass filter checks",
           :display_as => "Failed Filter"

    output :starttime,
           :description => "Time the server started",
           :display_as => "Start Time"
    
    output :total,
           :description => "Total messages received",
           :display_as => "Total Messages"

    output :replies,
           :description => "Replies sent back to clients",
           :display_as => "Replies"

    output :configfile,
           :description => "Config file used to start the daemon",
           :display_as => "Config File"
    
    output :version,
           :description => "MCollective Version",
           :display_as => "Version"
end

action "agent_inventory", :description => "Inventory of all agents on the server" do
    display :always
    
    output :agents,
           :description => "List of agents on the server",
           :display_as => "Agents"
end
