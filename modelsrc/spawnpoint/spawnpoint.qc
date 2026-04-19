$modelname "apapdventure/spawnpoint.mdl"
$cdmaterials "apadventure/models/"

$texturegroup Main
{
    {"logo_color"}
    {"startpoint"}
}

$body Main "spawnpoint.smd"
$staticprop

$sequence Idle "spawnpoint.smd"
$collisionmodel "spawnpoint_phys.smd"
{
    $automass
}