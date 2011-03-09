# Pipeline.rb
Pipeline.rb is an interface for manipulating single images, sequences of
images, and frames dumped from video files, according to "plans" written in an
intuitive, flexible domain-specific language (DSL).

## Installing
To get Pipeline.rb running, first you must have Ruby: http://www.ruby-lang.org/en/downloads/

### Dependencies
Second, Pipeline.rb requires both RMagick (https://github.com/rmagick/rmagick)
and FFMpeg (http://ffmpeg.org/download.html).

### RMagick
RMagick depends on ImageMagick, which you can download or build. Whatever floats your
boat: http://www.imagemagick.org/script/index.php

If you already have ImageMagick installed, getting RMagick should be as simple as:
	gem install rmagick

### FFMpeg
Pipeline.rb interfaces with FFMpeg using Antonin Amand's ffmpeg-ruby gem.
I don't think you can `gem install` this, and it is confusing because there are
multiple similarly named packages on rubygems.org.

Nevertheless, if you already have FFMpeg installed, you should be able to
follow Amand's instructions to install ffmpeg-ruby: https://github.com/gwik/ffmpeg-ruby

TIP: If you're like me, and couldn't figure out how to build FFMpeg to work
with ffmpeg-ruby on OS X, try:
	./configure --enable-shared --disable-static

## Usage
Invert an entire directory of images and save the output to
another directory:
	./pipeline.rb -i input/ -p invert.p -o output/

Invert the inversion of an entire directory of images and
save the output in-place:
+ `./pipeline.rb -i input/ -p invert.p -p invert.p --in-place`
+ `./pipeline.rb --in-dir input/ --plans invert.p,invert.p -I`

Invert every frame of a video file and dump the results to a directory:
	./pipeline.rb --in-vid family.mov --plan invert.p --out-dir frames/

Just process a single via stdin:
+ `cat gucci_mane.png | ./pipeline.rb --stdin -p invert.p >gucci_invert.png`
+ `./pipeline.rb --stdin -p invert.p <gucci_mane.png >gucci_invert.png`

## Plan File Syntax
The syntax for Pipeline.rb's plan-files is inspired in part by the patching
systems implemented in both Max/MSP and PureData. Moreover, the language is
intended to be equally intuitive.

Plans allow for two types of commands:
+ Variable Assignments, and
+ Function Calls

For example, a plan to swap the green and blue channels of an image, while
inverting the red channel, takes the following form:
	splitRGB $1
	invert $1
	joinRGB $1 $3 $4

It is important to note that the numeric variables are routinely overwritten by
function calls within a plan. For example, had we wanted to apply ImageMagick's
edge filter with a strength of 8 to an image, we would have written:
	splitRGB
	$red = $1
	edge $3 8
	joinRGB $red $2 $1

In the above example, `splitRGB` saves the red channel of our input to `$1`. We
must store this before we call `edge` on the blue channel (`$2`), since the
output of `edge` will be stored in `$1`. Finally we rejoin the channels. Note
that the green channel (`$2`) is unmodified.
---
Mark Andrus Roberts: <andrus@uchicago.edu>

