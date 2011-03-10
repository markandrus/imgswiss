#!/usr/bin/env ruby
# utils.rb => Utilities

def pipe_str(input, plans, output)
    str = "    " + input
    plans.each { |plan| str += " >>= " + plan }
    return str + " >>= " + output
end

