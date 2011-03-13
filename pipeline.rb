#!/usr/bin/env ruby
# pipeline.rb => Image Sequence Editor
require 'rubygems'
require 'RMagick'
require 'ffmpeg'

load 'src/options.rb'
load 'src/parser.rb'
load 'src/transforms.rb'
load 'src/classes.rb'
load 'src/utils.rb'

# Parse options
options = OptionParse.parse(ARGV)

# Parse any given plan files, accumulating in `$pipeline`
$pipeline = Transforms.new
options.plans.each do |plan|
    if $verbose then $stderr.puts "Parsing plan: `" + plan + "'" end
    File.readlines(plan).each do |line|
        if $verbose then $stderr.puts '    "' + line.chomp + '"' end
        $pipeline.add(&parse(line.chomp))
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
        $stderr.puts "Reading video: `" + options.invideo + "'"
        if !options.vidstart.nil? then $stderr.puts "    Start: " + options.vidstart.to_s + " " end
        if !options.vidend.nil? then $stderr.puts "    Stop: " + options.vidend.to_s + " " end
        if !options.outdir.nil?
			$stderr.puts pipe_str(options.invideo, options.plans, options.outdir)
		else
			$stderr.puts pipe_str(options.invideo, options.plans, "/dev/null")
        end
    end
    framename = options.invideo.rpartition('/').last
    stream = FFMPEG::InputFormat.new(options.invideo).first_video_stream
    if !options.vidstart.nil?
		stream.seek(options.vidstart)
	else
		options.vidstart = 0
	end
    i = 0
    # THANKS: ffmpeg-ruby/animated_gif_example.rb
    stream.decode_frame do |frame, pts, dts|
        i += 1
		if !options.vidend.nil?
			break if dts > (options.vidend*30 + options.vidstart*30)
		end
		if !options.framefilter.nil?
			next unless i % options.framefilter == 0
		end
        if !options.outdir.nil?
			type = options.frametype.nil? ? 'png' : options.frametype
            $pipeline.to_proc.call(
                    {"1" => Magick::ImageList.new.from_blob(frame.to_ppm)}
                )['1'].write(options.outdir + framename + '.' + i.to_s + '.' + type)
        end
    end
end

