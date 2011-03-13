$src = $1
$mask = %(masks/big_willie_style.png)
center_fit $mask $src
$mask = $1
split_rgb $src
$red   = $1
$green = $2
$blue  = $3
multiply $red $mask
join_rgb $1 $green $blue
