$modelname "apadventure/location_pickup.mdl"
$cdmaterials "apadventure/models/"

$bodygroup Main {
    studio "location_pickup.dmx"
    blank
}

$sequence idle "location_pickup.dmx"

$animation a_rotate "location_anims/rotate.dmx" loop subtract idle 0
$animation a_bob "location_anims/bob.dmx" loop subtract idle 0

$sequence rotate {
    a_rotate
    //loop
    delta
}
$sequence bob {
    a_bob
    //loop
    delta
}