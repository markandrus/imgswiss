#!/usr/bin/env ruby
# Parser for Image Filter Plans
require 'rubygems'
require 'RMagick'
require 'ffmpeg'
require 'parslet'
require 'optparse'
require 'ostruct'

$verbose = false

class OptionParse
    def self.parse(args)
        options = OpenStruct.new
        options.stdin = false
        options.inplace = false
        options.plans = []
        options.invideo = ""
        options.outvideo = ""

        opts = OptionParser.new do |opts|
            opts.banner = "Pipeline Image Sequence Editor <andrus@uchicago.edu>\n" +
                          "Usage: pipeline.rb [options]\n" +
                          "Example: pipeline.rb -p plan.p -i images/"
            opts.separator ""
            opts.separator "Specific options:"
            # Input
            opts.on("-i", "--in-dir DIR", "Read input from DIR") do |dir|
                options.indir = Dir.new(dir)
            end
            opts.on("--stdin", "Read input for a single image via STDIN") do
                options.stdin = true
            end
            opts.on("--in-vid PATH", String, "Read video using FFmpeg") do |path|
                options.invideo = path
            end
            # Output
            opts.on("-o", "--out-dir DIR", "Save output to DIR") do |dir|
                options.outdir = dir
            end
            opts.on("--out-vid PATH", String, "Save processed video as `filename'") do |path|
                options.outvideo = path
            end
            opts.on("-I", "--in-place", "Overwrite input files with output") do
                options.inplace = true
            end
            # Plan(s)
            opts.on("-p", "--plan PLAN", "Process according to PLAN") do |plan|
                options.plans << plan
            end
            opts.on("--plans x,y,z", Array, "Process through a sequence of plans") do |plans|
                options.plans.concat(plans)
            end
            # Boilerplate
            opts.on_tail("-h", "--help", "Show this message") do
                puts opts
                exit
            end
            opts.on_tail("-v", "--verbose", "Verbose output") do
                $verbose = true
            end
            opts.on_tail("--version", "Show version") do
                puts "0.1"
                exit
            end
        end
        opts.parse!(args)
        options
    end
end

options = OptionParse.parse(ARGV)

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
                'splitRGB'      => lambda { |s, a| { '1' => v(s,a[0]).channel(Magick::RedChannel),
                                                     '2' => v(s,a[0]).channel(Magick::BlueChannel),
                                                     '3' => v(s,a[0]).channel(Magick::GreenChannel) } },
                # joinRGB $$ $$ $$
                'joinRGB'       => lambda { |s, a| { '1' => Magick::Image.combine(v(s,a[0]), v(s,a[1]), v(s,a[2])) } }
              }

# Transforms; usage:
#   ts = Transforms.new
#   ts.add(assignment)
#   ts.to_proc.call(state)
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
    puts error, t.root.error_tree
end

# Build our transformation pipeline
$pipeline = Transforms.new
options.plans.each do |plan|
    if $verbose
        $stderr.puts "Parsing plan: `" + plan + "'"
    end
    File.readlines(plan).each do |line|
        line.chomp!
        if $verbose
            $stderr.puts '    "' + line + '"'
        end
        $pipeline.add(&parse(line))
    end
end

# Load images
if options.stdin # are we processing stdin?
    if $verbose
        $stderr.puts "Reading single image from STDIN..."
    end
    file = Magick::Image.from_blob(ARGF.read)
    if !file.nil?
        if $verbose
            $stderr.puts "    OK!"
            $stderr.puts "Processing..."
            $stderr.print "    STDIN"
            options.plans.each { |plan| $stderr.print " >>= " + plan }
            $stderr.puts " >>= STDOUT"
        end
        puts $pipeline.to_proc.call({"1" => file})['1'].to_blob
    end
elsif !options.indir.nil? # then let's load a dir of files
    files = []
    if $verbose
        puts "Reading directory: `" + options.indir.path + "'"
    end
    options.indir.each do |file|
        if file != '.' && file != '..'
            if $verbose
                $stderr.puts "    Adding `" + options.indir.path + file + "'"
            end
            files << Magick::ImageList.new(options.indir.path + file)
        end
    end
    # Apply 
    # NOTE: We could collapse this process with the one above
    if $verbose
        puts "Processing..."
    end
    files.each do |file|
        if $verbose
            $stderr.print "    " + file.filename
            options.plans.each { |plan| $stderr.print " >>= " + plan }
            if !options.outdir.nil?
                $stderr.puts " >>= " + options.outdir + file.filename.rpartition('/').last
            else
                $stderr.puts " >>= " + file.filename
            end
        end
        processed = $pipeline.to_proc.call({"1" => file})['1'] # Process
        if !options.outdir.nil? # write to outdir
            processed.write(options.outdir + file.filename.rpartition('/').last)
        end
        if options.inplace # overwrite input file
            processed.write(file.filename)
        end
    end
elsif !options.invideo.empty? # then let's read a video
    frames = []
    if $verbose
        puts "Reading video: `" + options.invideo + "'"
        #if !options.videostart.nil?
        #    puts "    Start: " + options.videostart + " "
        #end
        #if !options.videostop.nil?
        #    puts "    Stop: " + options.videostop + " "
        #end
        if !options.outdir.nil?
            puts "Dumping frames to: `" + options.outdir + "'"
        end
    end
    # THANKS: ffmpeg-ruby / animated_gif_example.rb
    video = FFMPEG::InputFormat.new(options.invideo)
    framename = options.invideo.rpartition('/').last
    # TODO: Add a CLI option to specify initial offset
    # stream.seek(12)
    i = 0
    # pts is presentation timestamp
    # dts is decoding timestamp
    video.first_video_stream.decode_frame do |frame, pts, dts|
        i += 1
        # TODO: Add a CLI option to specify the end
        # stop when decoding timestamp (~position) reach 18
        # break if dts > 18
        # TODO: Change the 5 in the following. I don't know what this is? FPS?
        # decode 1 frame for 5
        next unless i % 5 == 0
        # TODO: Add a CLI option to specify output frame filetype
        if !options.outdir.nil?
            $pipeline.to_proc.call(
                    {"1" => Magick::ImageList.new.from_blob(frame.to_ppm)}
                )['1'].write(options.outdir + framename + i.to_s + '.png')
        end
    end
end

