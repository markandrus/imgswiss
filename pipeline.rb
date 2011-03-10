#!/usr/bin/env ruby
# Parser for Image Filter Plans
require 'rubygems'
require 'RMagick'
require 'ffmpeg'

include 'options.rb'
include 'parser.rb'
include 'transforms.rb'
include 'classes.rb'

options = OptionParse.parse(ARGV)

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

