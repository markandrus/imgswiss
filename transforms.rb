#!/usr/bin/env ruby
# transforms.rb => Transformations Database
require 'RMagick'

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

