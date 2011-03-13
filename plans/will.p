$src = magnify $1
$mask = center_fit %(images/masks/big_willie_style.png) $src
$mask = modulate $mask 0.75 1 1
screen $src $mask
