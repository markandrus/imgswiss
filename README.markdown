# Pipeline.rb
Pipeline.rb is an interface for manipulating single images, sequences of
images, and frames dumped from video files, according to "plans" written in an
intuitive, flexible domain-specific language (DSL).

The DSL for plan-files borrows from a few sources, but I set out with the
intention of reflecting the intuitive structure of Cycling 74's Jitter patches.
For example, a Jitter patch might swap the color channels of an input matrix,
using:
	 |
	[jit.matrix]
	 |
	[jit.unpack]
	 |  \  /  |
	 |   \/   |
	 |   /\   |
	 |  /  \  |
	[jit.pack  ]
	 |
