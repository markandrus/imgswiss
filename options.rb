#!/usr/bin/env ruby
# parser.rb => Plan-File Parser
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

		# TODO: Is `to_i` necessary in some of these?
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
			# Input: Video
            opts.on("--in-vid PATH", String, "Read video using FFMpeg") do |path|
                options.invideo = path
            end
			opts.on("--vid-start POS", Integer, "Process video from POS (default: 0)") do |pos|
				options.vidstart = pos.to_i
			end
			opts.on("--vid-end POS", Integer, "Stop processing video at POS (default: `end`)") do |pos|
				options.vidend = pos.to_i
			end
			opts.on("--frame-filter NUM", Integer, "Process every NUM frames (default: 1; i.e. every)") do |num|
				options.framefilter = num.to_i
			end
            # Output
            opts.on("-o", "--out-dir DIR", "Save output to DIR") do |dir|
                options.outdir = dir
            end
			opts.on("-t", "--frame-type TYPE", "Save frames as TYPE (default: png)") do |type|
				options.frametype = type
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

