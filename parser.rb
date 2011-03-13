#!/usr/bin/env ruby
# parser.rb => Plan-File Parser
require 'rubygems'
require 'parslet'
require 'RMagick' #for dealing with the 

$files = { } # NOTE: This is our hash of any files sourced
             # from within a plan-file

# Parslet::Parser
# NOTE: The path returned by the `arg_file` rule will be relative to
# `Pipeline.rb`'s working directory
class Parser < Parslet::Parser
    root :expression

    # Expressions: either a Function Call or Variable Assignment
    rule(:expression)   { fcall.as(:fcall) | assign.as(:assign) }

    # Function Calls, such as:
    #   alpha_blend $1 $alpha $img2
    rule(:fcall)        { fname >> args.as(:args) }
    rule(:fname)        { (alpha | match('_')).repeat(1).as(:fname) >> space? }
    rule(:args)         { (arg >> space).repeat >> arg }
    rule(:arg)          { var | arg_file | arg_float.as(:float) |
                          arg_int.as(:int) | arg_str.as(:string) }
    rule(:arg_str)      { alphanum.repeat(1) }
    rule(:arg_int)      { num.repeat(1) }
    rule(:arg_float)    { arg_int >> str('.') >> arg_int }
    rule(:arg_file)     { str('%') >> str('(') >> (
                            alphanum | str('/') | str('.') | str('_')
                          ).repeat(1).as(:file) >> str(')') }

    # Variable assignment, such as:
    #   $alpha = $1
    rule(:assign)       { var.as(:left) >> space? >> set >> space? >>
                          arg.as(:right) }
    rule(:var)          { str('$') >> arg_str.as(:var) }

    rule(:alphanum)     { alpha | num }
    rule(:num)          { match('[0-9]') }
    rule(:alpha)        { match('[a-zA-Z]') }
    rule(:space?)       { space.maybe }
    rule(:space)        { match('\s').repeat(1) }
    rule(:set)          { match('=') >> space? }
end

# Parse function; returns a Transform
def parse(str)
    def build_transform(name, args)
        def proc_arg(a)
            z = a.to_a.flatten
            puts z
            case z[0]
                when :var
                    return lambda { |state| state[z[1]] }
                when :int
                    return lambda { |state| z[1].to_i }
                when :float
                    return lambda { |state| z[1].to_f }
                when :file
                    # NOTE: We don't want to reopen any sourced images
                    # each time we execute the plan, therefore we update
                    # a database of these images.
                    if $files[z[1]].nil?
                        $files[z[1]] = Magick::ImageList.new(z[1])
                    end
                    return lambda { |state| $files[z[1]] }
                else # string
                    return lambda { |state| z[1].to_s }
                end
        end
        return Transform.new(name, [].push(args).flatten.map { |a| proc_arg(a) })
    end
    t = Parser.new.parse(str)
    if t[:fcall] != nil
        return build_transform(t[:fcall][:fname], t[:fcall][:args])
    else
        return build_transform('=', t[:assign][:args])
    end
rescue Parslet::ParseFailed => error
    puts error #, t.root.error_tree # FIXME: What?
end

