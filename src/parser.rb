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
    rule(:expression)   { fcall.as(:fcall) | fassign.as(:fassign) | assign.as(:assign) }

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

    # Function Assignment, such as:
    #    `$r, $g, $b = split_rgb $1`, or
    #    `$inv = invert $1`
    rule(:fassign)      { ((var >> str(',') >> space?).repeat >> var >> space?).as(:left) >>
                          set >> space? >> fcall.as(:fcall) }

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
            case z[0]
                when :var
                    return lambda { |state| state[z[1]] }
                when :varname
                    return lambda { |state| z[1].to_s }
                when :varnames # NOTE: drop first element, ie `:varnames`
                    return lambda { |state| z.drop(1) }
                when :fcall
                    return z[1].to_proc
                when :int
                    return lambda { |state| z[1].to_i }
                when :float
                    return lambda { |state| z[1].to_f }
                when :file
                    # NOTE: We don't want to reopen any sourced images
                    # each time we execute a plan, therefore we keep
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
    elsif t[:assign] != nil
        return build_transform('=', [{:varname => t[:assign][:left][:var]},
                                    t[:assign][:right]])
    elsif t[:fassign] != nil
        right = build_transform(t[:fassign][:fcall][:fname],
                                t[:fassign][:fcall][:args])
		left = []
		if t[:fassign][:left].kind_of?(Array)
			left = t[:fassign][:left].to_a.map { |e| e[:var] }
		else
			left = t[:fassign][:left][:var]
		end
        return build_transform('<=', [{:varnames => left}, {:fcall => right}])
    end
rescue Parslet::ParseFailed => error
    puts error #, t.root.error_tree # FIXME: What?
end

