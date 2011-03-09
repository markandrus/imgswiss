# Pipeline.rb
Pipeline.rb is an interface for manipulating single images, sequences of
images, and frames dumped from video files, according to "plans" written in an
intuitive, flexible domain-specific language (DSL).

# Plan File Syntax
The syntax for Pipeline.rb's plan-files is inspired in part by the patching
systems implemented in both Max/MSP and PureData.

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
