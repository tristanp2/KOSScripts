declare parameter target_name.

run utilities.

set sas_state to sas.
set sas to false.
set rcs to false.

//radially outward vector
lock ship_radial_v to ship:position - ship:body:position.
lock ship_norm_v to vcrs(ship:velocity:orbit, ship_radial_v).
lock ship_norm_dir to lookdirup(ship_norm_v, ship_radial_v).
set target_vessel to vessel(target_name).
set target to target_vessel.
declare local steer_val to ship:facing.
declare local thrott to 0.
declare local warp_rate to 0.
if ship:body <> target_vessel:body{
	print "Cannot rendezvous with ship in other SOI".
}

//norm defines the orbital_plane

lock target_radial_v to target_vessel:position - target_vessel:body:position.
lock target_norm_v to vcrs(target_vessel:velocity:orbit, target_radial_v).
lock target_norm_dir to lookdirup(target_norm_v, target_radial_v).

//relative inclination in degrees is just angle between normal vecs?
lock plane_diff to vang(ship_norm_v, target_norm_v).
print "target: " + target_vessel.
print "difference in orbital planes: " + plane_diff + " degrees".

if plane_diff > 0.5 {
	//TODO: align orbital planes
	set steer_val to ship_norm_dir.
}
else{
	print "no plane adjustment necessary".
}
//
//	1. match ship apo and peri to target periapsis
//  2. wait for target periapsis, then extend apoapsis reasonably
//	3. wait for close encounter with target, then match velocities.
//
print "target periapsis: " + target_vessel:periapsis.



declare local burn_dir to 0.

run circularize(target_vessel:periapsis).

//everything that takes over controls should be called before these two lines
lock steering to steer_val.
lock throttle to thrott.

wait 1.

lock ship_ang_norm to vcrs(ship_radial_v, target_radial_v).
lock norm_dir to vdot(ship_ang_norm, ship_norm_v).
//need differentiate between behind and in front

//we are behind if norm_dir is negative
if norm_dir < 0 {
	lock ang_diff to 360 - vang(ship_radial_v, target_radial_v).
}
else {
	lock ang_diff to vang(ship_radial_v, target_radial_v).
}
clearscreen.

//TODO: make this work for non-equatorial orbits
set lan_diff to ship:obt:lan - target_vessel:obt:lan.
lock rel_anomaly to mod(ship:obt:trueanomaly + (ship:obt:argumentofperiapsis - target_vessel:obt:argumentofperiapsis) + lan_diff + 360, 360).

print "angular difference: " + ang_diff.
print "anomaly to target peri: " + rel_anomaly.
wait 1.
set kuniverse:timewarp:rate to 50.
clearscreen.
until rel_anomaly > 355{
	if rel_anomaly > 350{
		set kuniverse:timewarp:rate to 5.
	}
	else if rel_anomaly > 340{
		set kuniverse:timewarp:rate to 10.
	}
	
	print "anomaly: " + rel_anomaly at (0,3).
	wait 0.001.
}
set kuniverse:timewarp:rate to 0.
set steer_val to ship:obt:velocity:orbit.
wait until rel_anomaly > 358.
set ship_peri_time to time:seconds.

set time_diff to (ang_diff/360) * ship:obt:period.
print "time diff: " + time_diff / 60 + " minutes".
set real_time_diff to time_diff.
set orbits_required to 1.
set max_period_shift to 300.
until real_time_diff < max_period_shift{
	set orbits_required to orbits_required + 1.
	set real_time_diff to time_diff / orbits_required.
}
print "final time diff: " + real_time_diff / 60 + " minutes".
print "orbits required: " + orbits_required.
	
wait 5.
set goal_period to ship:obt:period + real_time_diff.
lock period_diff to goal_period - ship:obt:period.
set thrott to 0.5.
clearscreen.
until period_diff < 0.01{
	set thrott to max(0.01, min(0.5, period_diff / 100)).
	print "adjusting period to  " + goal_period at (0,0).
	print "period: " + ship:obt:period at (0,1).
	print "diff: " + period_diff at (0,2).
	wait 0.001.
}
clearscreen.
set thrott to 0.
wait 2.
set kuniverse:timewarp:rate to 50.
set orbit_counted to false.
set orbit_count to 0.
until orbit_count = orbits_required{
	if ship:obt:trueanomaly > 320 and not orbit_counted{
		set orbit_counted to true.
		set orbit_count to orbit_count + 1.
	}
	else if ship:obt:trueanomaly < 320 and orbit_counted{
		set orbit_counted to false.
	}
	if ship:altitude > ship:periapsis + 10000{
		set kuniverse:timewarp:rate to 100.
	}
	print "angle between ships: " + ang_diff at (0,0).
	print "orbit: " + orbit_count at (0,1).
	print "waiting for orbit " + orbits_required at (0,2).
	wait 0.001.
}
//velocity towards target
lock relative_velocity to ship:velocity:orbit - target_vessel:velocity:orbit.
//direction towards target
lock relative_direction to target_vessel:position - ship:position.
lock target_dist to relative_direction:mag.

//want our velocity to be in this direction
lock goal_dir to relative_direction:normalized.
clearscreen.
until eta:periapsis < 120{
	set kuniverse:timewarp:rate to 10.
	print "target dist: " + target_dist at (0,0).
}
set kuniverse:timewarp:rate to 0.

//want our velocity to be in this direction
lock goal_dir to relative_direction:normalized.
set max_speed to 100.
set max_dist to target_dist.
lock goal_speed to max_speed * (log10(target_dist)/log10(max_dist)).
lock ship_speed to relative_velocity:mag.
lock speed_error to clamp((goal_speed - ship_speed) / goal_speed,-1,1).
lock speed_prop to max(0, speed_error).
lock goal_velocity to goal_speed * goal_dir.
lock correction_vec to -vxcl(goal_dir, relative_velocity).
lock vec_error to min(5, correction_vec:mag/10).
lock total_error to vec_error + 2*abs(speed_error).
lock burn_vec to (goal_velocity - relative_velocity).
set thrott to 0.

set steer_val to burn_vec.
clearscreen.
until target_dist < 4000{
	if total_error < 0.5{
		set thrott to 0.
		wait 2.
		set kuniverse:timewarp:rate to 10.
		until total_error > 3 or target_dist < 4000{
			print "vec_error: " + vec_error at (0,0).
			print "speed error: " + speed_error at (0,1).
			print "thrott: " + thrott at (0,2).
			print "total_error: " + total_error at (0,3).
			print "goal speed: " + goal_speed at(0,4).
			wait 0.001.
		}
		set kuniverse:timewarp:rate to 0.
		wait 4.
	}
	set steer_val to burn_vec.
	set thrott to min(0.5, vec_error + speed_prop).
	if thrott  < 0.05{
		set thrott to 0.
	}
	print "vec_error: " + vec_error at (0,0).
	print "speed error: " + speed_error at (0,1).
	print "thrott: " + thrott at (0,2).
	print "total_error: " + total_error at (0,3).
	print "goal speed: " + goal_speed at(0,4).
	wait 0.001.
}
set thrott to 0.
clearscreen.
set max_dist to target_dist.
set max_speed to ship_speed.
set max_approach to 100.
lock goal_speed to min(max_approach, max_approach * (target_dist / 500)).
wait 2.
set steer_val to burn_vec.
wait 3.

clearscreen.
print "zeroing in...".
until target_dist < 50{
	set steer_val to burn_vec.
	set thrott to abs(speed_error) + vec_error.
	if thrott < 0.05{
		set thrott to 0.
	}
	print "speed_error: " + speed_error at (0,1).
	print "vec_error: " + vec_error at (0,2).
	print "goal_speed: " + goal_speed at (0,3).
}
clearscreen.
print "killing relative velocity".
until relative_velocity:mag < 0.01{
	set thrott to relative_velocity:mag / 20.
	set steer_val to -relative_velocity.
}
print "we r ther".

set sas to sas_state.



