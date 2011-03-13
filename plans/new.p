$r, $g, $b = split_rgb $1
$mask = center_fit %(images/masks/big_willie_style.png) $r
$r = multiply $mask $r
join_rgb $r $g $b
