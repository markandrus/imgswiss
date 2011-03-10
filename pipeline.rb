#!/usr/bin/env ruby
# pipeline.rb => Image Sequence Editor
require 'rubygems'
require 'RMagick'
require 'ffmpeg'

load 'options.rb'
load 'parser.rb'
load 'transforms.rb'
load 'classes.rb'
load 'utils.rb'

# Parse options
options = OptionParse.parse(ARGV)

# Parse any given plan files, accumulating in `$pipeline`
$pipeline = Transforms.new
options.plans.each do |plan|
    if $verbose then $stderr.puts "Parsing plan: `" + plan + "'" end
    File.readlines(plan).each do |line|
        if $verbose then $stderr.puts '    "' + line.chomp! + '"' end
        $pipeline.add(&parse(line))
    end
end

# --std-in
if options.stdin
    if $verbose
        $stderr.puts "Processing..."
        $stderr.puts pipe_str("STDIN", options.plans, "STDOUT")
    end
	puts $pipeline.to_proc.call({"1" => Magick::Image.from_blob(ARGF.read)})['1'].to_blob

# --in-dir
elsif !options.indir.nil?
    if $verbose
        $stderr.puts "Reading directory: `" + options.indir.path + "'"
        $stderr.puts "Processing..."
    end
    options.indir.each do |file|
        if File.file?(options.indir.path + file)
            processed = $pipeline.to_proc.call({"1" => Magick::ImageList.new(options.indir.path + file)})['1']
			# TODO: rewrite this so that processed.write() operates over a list
			# of locations...
            if !options.outdir.nil?
                if $verbose then $stderr.puts pipe_str(file, options.plans, options.outdir + file) end
                processed.write(options.outdir + file)
			end
            if options.inplace
                if $verbose then $stderr.puts pipe_str(file, options.plans, file) end
                processed.write(options.indir.path + file)
            end
        end
    end

# --in-vid
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
			$stderr.puts pipe_str(options.invideo, options.plans, options.outdir)
		else
			$stderr.puts pipe_str(options.invideo, options.plans, "/dev/null")
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

