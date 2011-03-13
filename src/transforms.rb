#!/usr/bin/env ruby
# transforms.rb => Transformations Database
require 'RMagick'

# NOTE: This is a place holder function for now. It is intended to be called
# when... 
def v(s, a)
    if !a.nil?
        return a.call(s)
    else
        return nil
    end
end

# NOTE: Need to use this version in a few places (`d` for 'default')
def vd(s, a, d)
    r = v(s, a)
    # NOTE: If the potential return is not of the same type,
    # we should return something appropriate (ie, the default)
    # FIXME: Throw error on class inequality?
    if r.nil || r.class != d.class
        return d
    else
        return r
    end
end

# TODO: Is this crazy?
$transforms = {
  # Standard
    # identity
    ''              => lambda { |s, a| s },
    # variable assignment
    # NOTE: `v(s,a[0])` returns the name of the variable to be set,
    #        and `v(s,a[1])` returns the actual value.
    # TODO: Should Magick::Image[List](s) be getting `dup`ed?
    '='             => lambda { |s, a| { v(s,a[0]) => v(s,a[1]) } },
  # RMagick
    # edge $$ radius 
    'edge'          => lambda { |s, a| { '1' => v(s,a[0]).edge(v(s,a[1])) } },
    # emboss $$ radius sigma
    'emboss'        => lambda { |s, a| { '1' => v(s,a[0]).emboss(
                                                    v(s,a[1]),
                                                    v(s,a[2])) } },
    # enhance $$
    'enhance'       => lambda { |s, a| { '1' => v(s,a[0]).enhance } },
    # equalize $$
    'equalize'      => lambda { |s, a| { '1' => v(s,a[0]).equalize } },
    # flip $$
    'flip'          => lambda { |s, a| { '1' => v(s,a[0]).flip } },
    # flop $$
    'flop'          => lambda { |s, a| { '1' => v(s,a[0]).flop } },
    # guassian_blur $$ radius sigma
    'guassian_blur' => lambda { |s, a| { '1' => v(s,a[0]).guassian_blur(
                                                    v(s,a[1]),
                                                    v(s,a[2])) } },
    # implode $$ amount
    'implode'       => lambda { |s, a| { '1' => v(s,a[0]).implode(v(s,a[1])) } },
    # invert $$
    'invert'        => lambda { |s, a| { '1' => v(s,a[0]).negate } },
    # level $$ black_point white_point gamma
    'level'         => lambda { |s, a| { '1' => v(s,a[0]).level(
                                                    v(s,a[1]),
                                                    v(s,a[2]),
                                                    v(s,a[3])) } },
    # level_colors $$ black_color white_color invert
    'level_colors'  => lambda { |s, a| { '1' => v(s,a[0]).level_colors(
                                                    v(s,a[1]),
                                                    v(s,a[2]),
                                                    v(s,a[3])) } },
    # linear_stretch $$ black_point white_point
    'linear_stretch'=> lambda { |s, a| { '1' => v(s,a[0]).linear_stretch(
                                                    v(s,a[1]),
                                                    v(s,a[2])) } },
    # liquid_rescale $$ new_width new_height delta_x rigidity
    'liquid_rescale'=> lambda { |s, a| { '1' => v(s,a[0]).linear_stretch(
                                                    v(s,a[1]),
                                                    v(s,a[2]),
                                                    v(s,a[3]),
                                                    v(s,a[4])) } },
    # magnify $$
    'magnify'       => lambda { |s, a| { '1' => v(s,a[0]).magnify } },
    # mask $$ mask
    'mask'          => lambda { |s, a| { '1' => v(s,a[0]).mask(v(s,a[1])) } },
    # median_filter $$ radius
    'median_filter' => lambda { |s, a| { '1' => v(s,a[0]).median_filter(v(s,a[1])) } },
    # minify $$
    'minify'        => lambda { |s, a| { '1' => v(s,a[0]).minify } },
    # modulate $$ brightness saturation hue
    'modulate'      => lambda { |s, a| { '1' => v(s,a[0]).modulate(
                                                    v(s,a[1]),
                                                    v(s,a[2]),
                                                    v(s,a[3])) } },
    # motion_blur $$ radius sigma angle
    'motion_blur'   => lambda { |s, a| { '1' => v(s,a[0]).motion_blur(
                                                    v(s,a[1]),
                                                    v(s,a[2]),
                                                    v(s,a[3])) } },
    # normalize $$
    'normalize'     => lambda { |s, a| { '1' => v(s,a[0]).spread } },
    # oil_paint $$ radius
    'oil_paint'     => lambda { |s, a| { '1' => v(s,a[0]).oilpaint(v(s,a[1])) } },
    # opaque $$ target fill
    'opaque'        => lambda { |s, a| { '1' => v(s,a[0]).opaque(
                                                    v(s,a[1]),
                                                    v(s,a[2])) } },
    # ordered_dither $$ threshold_map
    'ordered_dither'=> lambda { |s, a| { '1' => v(s,a[0]).ordered_dither(v(s,a[1])) } },
    # posterize $$ levels dither
    'posterize'     => lambda { |s, a| { '1' => v(s,a[0]).posterize(
                                                    v(s,a[1]),
                                                    v(s,a[2])) } },
    # quantum_op $$ operator rvalue
    'quantum_op'    => lambda { |s, a| { '1' => v(s,a[0]).quantum_op(
                                                    v(s,a[1]),
                                                    v(s,a[2])) } },
    # radial_blur $$ float
    'radial_blur'   => lambda { |s, a| { '1' => v(s,a[0]).radial_blur(v(s,a[1])) } },
    # resize_to_fill $$ width height gravity
    'resize_to_fill'=> lambda { |s, a| { '1' => v(s,a[0]).resize_to_fill(
                                                    v(s,a[1]),
                                                    v(s,a[2]),
                                                    v(s,a[3])) } },
    # spread $$
    'spread'        => lambda { |s, a| { '1' => v(s,a[0]).spread } },
    # wave $$ int int
    'wave'          => lambda { |s, a| { '1' => v(s,a[0]).wave(
                                                    v(s,a[1]),
                                                    v(s,a[2])) } },
  # RMagick'
    # split_rgb $$ 
    'split_rgb'     => lambda { |s, a| { '1' => v(s,a[0]).channel(
                                                    Magick::RedChannel),
                                         '2' => v(s,a[0]).channel(
                                                    Magick::BlueChannel),
                                         '3' => v(s,a[0]).channel(
                                                    Magick::GreenChannel) } },
    # join_rgb $$ $$ $$
    'join_rgb'      => lambda { |s, a| { '1' => Magick::Image.combine(
                                                    v(s,a[0]),
                                                    v(s,a[1]),
                                                    v(s,a[2])) } },
    # center_fill $$ $parent
    'center_fill'   => lambda { |s, a| { '1' => v(s,a[0]).resize_to_fill(
                                                    v(s,a[1]).columns,
                                                    v(s,a[1]).rows,
                                                    Magick::CenterGravity) } },
    # center_fit $$ $parent
    'center_fit'    => lambda { |s, a|
                                    i = v(s,a[0])
                                    o = v(s,a[1])
                                    i.resize_to_fit!(o.columns, o.rows)
                                    i.page = Magick::Rectangle.new(o.columns, o.rows,
                                                (o.columns-i.columns)/2,
                                                (o.rows-i.rows)/2
                                             )
                                    { '1' => i.flatten_images } },
	# multiply $$ $src
	# NOTE: Black
	'multiply'      => lambda { |s, a| { '1' => v(s,a[0]).composite(
													v(s,a[1]),
													Magick::CenterGravity,
													Magick::MultiplyCompositeOp) } }
}
