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

