$modelname "apapdventure/frame.mdl"
$cdmaterials "apadventure/models/"

$body Main "frame.smd"
$staticprop

$sequence Idle "frame.smd"
$collisionmodel "frame phys.smd"
{
    $automass
}