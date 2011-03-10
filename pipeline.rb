#!/usr/bin/env ruby
# pipeline.rb => Image Sequence Editor
require 'rubygems'
require 'RMagick'
require 'ffmpeg'

load 'options.rb'
load 'utils.rb'
load 'parser.rb'
load 'transforms.rb'
load 'classes.rb'

# Parse options
options = OptionParse.parse(ARGV)

# Parse any given plan files, accumulating in `$pipeline`
$pipeline = Transforms.new
options.plans.each do |plan|
    verbs "Parsing plan: `" + plan + "'"
    File.readlines(plan).each do |line|
        verbs '    "' + line.chomp! + '"'
        $pipeline.add(&parse(line))
    end
end

def print_pipe(input, plans, output)
    $stderr.print "    " + input
    plans.each { |plan| $stderr.print " >>= " + plan }
    $stderr.puts " >>= " + output
end

# STDIN
if options.stdin
    if $verbose
        puts "Processing..."
        print_pipe("STDIN", options.plans, "STDOUT")
    end
	puts $pipeline.to_proc.call({"1" => Magick::Image.from_blob(ARGF.read)})['1'].to_blob

# DIRECTORY
elsif !options.indir.nil?
    if $verbose
        $stderr.puts "Reading directory: `" + options.indir.path + "'"
        $stderr.puts "Processing..."
    end
    options.indir.each do |file|
        # TODO: Replace this with an actual file-check
        if file != '.' && file != '..' 
            processed = $pipeline.to_proc.call({"1" => Magick::ImageList.new(options.indir.path + file)})['1']
            if !options.outdir.nil?
                processed.write(options.outdir + file)
                if $verbose then print_pipe(file, options.plans, options.outdir + file)
            else
                processed.write(options.indir.path + file)
                if $verbose then print_pipe(file, options.plans, file)
            end
        end
    end

# VIDEO
elsif !options.invideo.empty?
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

