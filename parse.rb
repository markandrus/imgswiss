#!/usr/bin/env ruby
# Parser for Image Filter Plans
require 'RMagick'
require 'parslet'

# NOTE: This is a place holder function for now. It is intended to be called
# when 
def v(s, a)
    return a.call(s)
end

$transforms = {
              # Standard
                # identity
                ''              => lambda { |s, a| s },
                # variable assignment
                '='             => lambda { |s, a| { v(s,a[0]) => v(s,a[1]) } },
              # RMagick
                # edge $$ int 
                'edge'          => lambda { |s, a| { '1' => v(s,a[0]).edge(v(s,a[1])) } },
                # emboss $$
                'emboss'        => lambda { |s, a| { '1' => v(s,a[0]).emboss } },
                # flip $$
                'flip'          => lambda { |s, a| { '1' => v(s,a[0]).flip } },
                # implode $$ float
                'implode'       => lambda { |s, a| { '1' => v(s,a[0]).implode(v(s,a[1])) } },
                # invert $$
                'invert'        => lambda { |s, a| { '1' => v(s,a[0]).negate } },
                # oil_paint $$
                'oil_paint'     => lambda { |s, a| { '1' => v(s,a[0]).oilpaint } },
                # spread $$
                'spread'        => lambda { |s, a| { '1' => v(s,a[0]).spread } },
                # wave $$ int int
                'wave'          => lambda { |s, a| { '1' => v(s,a[0]).wave(v(s,a[1]), v(s,a[2])) } },
              # RMagick'
                # splitRGB $$ 
                'splitRGB'      => lambda { |s, a| { '1' => v(s,a[0]).channel(RedChannel),
                                                     '2' => v(s,a[0]).channel(BlueChannel),
                                                     '3' => v(s,a[0]).channel(GreenChannel) } },
                # joinRGB $$ $$ $$
                'joinRGB'       => lambda { |s, a| { '1' => v(s,a[0]).dup.combine(v(s,a[0]), v(s,a[1]), v(s,a[2])) } }
              }

# Transforms; usage:
#   ts = Transforms.new
#   ts.add(assignment)
#   ts.call(state)
class Transforms
    def initialize
        @transforms = []
    end
    def add(&transform)
        @transforms << transform
    end
    def to_proc
        lambda { |state| @transforms.inject(state) { |state, fn| fn.call(state) } }
    end
end

# Transform; usage:
# NOTE: Args need to be `push`ed on in order.
class Transform
    def initialize(name, args)
        @transform = $transforms[name]
        @args = args
    end
    def to_proc
        # NOTE: I probably need to be smarter about this--Are the updated
        #       images getting freed (Image.destroy!-ed) on update?
        # lambda { |state| state.update(@transform.call(state, @args.map { |arg| state[arg] } )) }
        lambda { |state| state.update(@transform.call(state, @args)) }
    end
end

# Parslet::Parser
class Parser < Parslet::Parser
    root :expression

    # Expressions: either a Function Call or Variable Assignment
    rule(:expression)   { fcall.as(:fcall) | assign.as(:assign) }

    # Function Calls, such as:
    #   alphaBlend $1 $alpha $img2
    rule(:fcall)        { fname >> args.as(:args) }
    rule(:fname)        { alpha.repeat(1).as(:fname) >> space? }
    rule(:args)         { (arg >> space).repeat >> arg }
    rule(:arg)          { var | arg_float.as(:float) | arg_int.as(:int) | arg_str.as(:string) }
    rule(:arg_str)      { alphanum.repeat(1) }
    rule(:arg_int)      { num.repeat(1) }
    rule(:arg_float)    { arg_int >> str('.') >> arg_int }

    # Variable assignment, such as:
    #   $alpha = $1
    rule(:assign)       { var.as(:left) >> space? >> set >> space? >> arg.as(:right) }
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
            case z[0]
                when :var
                    return lambda { |state| state[z[1]] }
                when :int
                    return lambda { |state| z[1].to_i }
                when :float
                    return lambda { |state| z[1].to_f }
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
    puts error, parser.root.error_tree
end

# Test
(parse "wave $1 10 200").to_proc.call({"1" => Magick::ImageList.new("/Users/markandrusroberts/tmp/img.png") })
parse "edge $1 6"
parse "implode $1 0.8"

