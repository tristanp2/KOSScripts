// non-atmospheric landing prototype
// assumed orbital situation: in reasonably low orbit above body of target position
// input: surface coords of target position

declare parameter target_vessel_name.
declare target_vessel to vessel(target_vessel_name).
declare tr to addons:tr.
declare sas_state to sas.

set sas to false.

// body relative positions
run utilities.

set target_body to ship:body.
set target_pos to target_vessel:position - target_vessel:body:position.
set target_geo_pos to target_vessel:body:geopositionof(target_pos).
lock my_pos to ship:position - ship:body:position.
lock ship_norm_v to vcrs(ship:velocity:orbit, my_pos).

lock ship_target_norm_v to vcrs(target_pos, my_pos).
lock orbit_target_normal_magnitude to vdot(ship_norm_v, ship_target_norm_v).
lock orbit_target_normal_sign to orbit_target_normal_magnitude / abs(orbit_target_normal_magnitude).
lock rel_angle to orbit_target_normal_sign * vang(target_pos, my_pos).

print "Normal mag".
print orbit_target_normal_magnitude.

clearscreen.
set kuniverse:timewarp:rate to 50.
print rel_angle at (0,3).
if (rel_angle < 120) {
	print "Orbiting around..." at (0,2).
	until rel_angle  < 0 {
		print rel_angle at (0,3).
		wait 0.1.
	}
}

print "Getting closer to target..." at (0,2).
until rel_angle < 120 and rel_angle > 0 {
	print rel_angle at(0,3).
	wait 0.1.
}

set kuniverse:timewarp:rate to 0.
wait until kuniverse:timewarp:issettled.

declare steer_val to -ship:orbit:velocity:orbit.
declare thrott_val to 0.

lock throttle to thrott_val.
lock steering to steer_val.
wait 1.

wait until steeringsettled().
print "steering settled. reducing orbit".
set thrott_val to 1.

until tr:hasimpact {
	wait 0.001.
}.

set thrott_val to 0.1.

print "impact at: " at (0,4).
print tr:impactpos at (4,5).



lock impact_body_pos to tr:impactpos:position.
lock dist to (impact_body_pos - target_pos):mag.

unlock throttle.
unlock steering.

until false {
	print dist.
	wait 0.1.
}
//declare min_dist to dist.
//until dist - min_dist > 100 {
//	print dist at (0,6).
//	set min_dist to dist.
//	wait 0.1.
//}

set thrott_val to 0.


// clearscreen.
