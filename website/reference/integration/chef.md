---
layout: default
title: Using With Chef
disqus: true
---
[FactsOpsCodeOhai]: http://code.google.com/p/mcollective-plugins/wiki/FactsOpsCodeOhai
[OpscodeChefHandlers]: http://wiki.opscode.com/display/chef/Exception+and+Report+Handlers

# {{page.title}}

If you're a Chef user you are supported in both facts and classes filters.

## Facts
There is a [community plugin to enable Ohai][FactsOpsCodeOhai] as a fact source.

Using this plugin Ohai facts will be converted from:

{% highlight javascript %}
  "languages": {
    "java": {
      "runtime": {
        "name": "OpenJDK  Runtime Environment",
        "build": "1.6.0-b09"
      },
      "version": "1.6.0"
    },
{% endhighlight %}

to:

{% highlight ruby %}
 "languages.java.version"=>"1.6.0",
 "languages.java.runtime.name"=>"OpenJDK  Runtime Environment",
 "languages.java.runtime.build"=>"1.6.0-b09",
{% endhighlight %}

So you can use the flattened versions of the information provided by Ohai in filters, reports etc.

{% highlight console %}
% mco find --with-fact languages.java.version=1.6.0
{% endhighlight %}

## Class Filters
Chef does not provide a list of roles and recipes that has been applied to a node, to use with MCollective you need to create such a list.

It's very easy with Chef to do this in a handler. See the [Opscode documentation about Chef handlers][OpscodeChefHandlers] for how to install a handler.

This will create a list of all roles and recipes in _/var/tmp/chefnode.txt_ on each node for us to use:

{% highlight ruby %}
module Mcollective
  class DumpRunList < Chef::Handler
    def initialize(args)
      @filename=args[:filename]
    end

    def report
      begin
        fp=open(@filename,"w")

        node.run_list.run_list.roles.each do |i|
          fp.write("role.#{i}\n")
        end

        node.run_list.run_list.recipes.each do |i|
          recipe = i.gsub("::",".")
          fp.write("recipe.#{recipe}\n")
        end

        fp.close
      rescue
        Chef::Log.error("Could not dump runlist to #{@filename} !")
      end
    end
  end 
end
{% endhighlight %}

Saving it as _/var/cache/chef/handlers/mcollective.rb_, you would put the following in your chef client configuration :

{% highlight ruby %}
require "/var/cache/chef/handlers/mcollective"
dumper=Mcollective::DumpRunList.new(:filename => "/var/tmp/chefnode.txt")
report_handlers << dumper
{% endhighlight %}

You should configure MCollective to use this file by putting the following in your _server.cfg_

{% highlight ini %}
classesfile = /var/tmp/chefnode.txt
{% endhighlight %}

You can now use your roles and recipe lists in filters:

{% highlight console %}
% mco find --with-class role.webserver --with-class /apache/
{% endhighlight %}
