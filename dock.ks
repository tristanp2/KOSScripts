declare parameter target_name.
declare parameter ship_port_name to "".

run utilities.

set target_vessel to vessel(target_name).
set sas to false.
set rcs to false.


if ship_port_name = "" {
	set ship_port to ship:dockingports[0].
}
else {
	for port in ship:dockingports {
		if port:name = ship_port_name {
			set ship_port to port.
			break.
		}
	}
}

if ship_port:hasmodule("ModuleAnimateGeneric") {
	declare local shield_module to ship_port:getmodule("ModuleAnimateGeneric").
	if shield_module:hasevent("open shield") {
		shield_module:doevent("open shield").
	}
}

for port in target_vessel:dockingports {
	if port:state = "ready" and port:nodetype = ship_port:nodetype {
		set target_port to port.
	}
}
clearscreen.
print "targeting port: " + target_port:name.

lock target_pos to target_port:facing:vector * 20 + target_port:nodeposition.
lock dest_vec to target_pos - ship:position.
lock dest_dist to dest_vec:MAG.
set steer_val to dest_vec.

lock relative_velocity to ship:velocity:orbit - target_vessel:velocity:orbit.

set max_dist to dest_dist.
lock goal_speed to min(7, (5 * dest_dist - 100) / 250).
lock goal_velocity to goal_speed * dest_vec:normalized.
lock correction_vec to goal_velocity - relative_velocity.
lock error_direction to vdot(goal_velocity, correction_vec) / abs(vdot(goal_velocity,correction_vec)).
lock speed_error to correction_vec:mag.


lock steering to steer_val.
lock throttle to thrott.

print "making initial approach".
until dest_vec:MAG < 75 {
	print "dist: " + dest_vec:MAG at (0,1).
	print "speed error: " + speed_error at (0,2).
	print "goal speed: " + goal_speed at (0,3).
	print "speed: " + relative_velocity:mag at (0,4).
	print "err dir: " + error_direction at (0,5).
	print "steer error: " + steeringmanager:angleerror at (0,7).
	set steer_val to correction_vec.
	if steeringsettled() {
		set thrott to clamp(applydeadband(speed_error / 4, 0, 0.1),0, 0.2).
	}
	else {
		set thrott to 0.
	}
}
clearscreen.
print "killing velocity".
until relative_velocity:mag < 0.01 {
	set steer_val to -relative_velocity.
	if steeringsettled() {
		set thrott to relative_velocity:mag / 20.
	}
	else {
		set thrott to 0.
	}
}
set thrott to 0.
unlock throttle.
lock goal_speed to min(2, applydeadband(dest_dist / 10, -0.1,0.1)).
lock goal_velocity to goal_speed * dest_vec:normalized.
lock correction_vec to goal_velocity - relative_velocity.
lock deadbandval to min(0.05,dest_dist / 500).
lock fore_vector to ship:facing:forevector.
lock star_vector to ship:facing:starvector.
lock up_vector to ship:facing:upvector.

lock fore_error to vdot(correction_vec, fore_vector).
lock star_error to vdot(correction_vec, star_vector).
lock up_error to vdot(correction_vec, up_vector).
lock fore_val to applydeadband(fore_error, -deadbandval, deadbandval).
lock star_val to applydeadband(star_error, -deadbandval, deadbandval).
lock up_val to applydeadband(up_error, -deadbandval, deadbandval).
lock translate_vector to v(star_val, up_val, fore_val).
set neutral_vector to v(0,0,0).


clearscreen.
print "getting into position".
set steer_val to dest_vec.

wait until steeringsettled(2).
set sas to true.
set rcs to true.
unlock steering.

until dest_dist < 1 and relative_velocity:mag < 0.1 {
	print "fore: " + fore_error at (0,1).
	print "star: " + star_error at (0,2).
	print "up: " + up_error at (0,3).
	print "deadband: " + deadbandval at (0,4).
	print "dist: " + dest_dist at (0,5).
	set ship:control:translation to translate_vector.
}
set ship:control:translation to neutral_vector.
clearscreen.
print "preparing for final approach".
set goal_speed to 0.
set rcs to false.
set sas to false.
set steer_val to lookdirup(-target_port:facing:forevector, target_port:facing:topvector).
lock steering to steer_val.
wait 1.
wait until steeringsettled(3).
unlock steering.
set sas to true.
set deadbandval to 0.0001.
lock goal_speed to clamp(dest_dist / 10, 0.1, 1).

clearscreen.
print "executing final approach".
lock goal_speed to clamp(min(1, dest_dist / 10),0.5,1).
lock target_pos to target_port:nodeposition + target_port:facing:forevector * 5.
set rcs to true.

//need to exit program before ship is docked, or else the invalid target_vessel reference
//	will cause the script to crash. Maybe using target instead of a local will help???
until dest_dist < 1 {
	if dest_dist < 5 {
		set sas to false.
		lock steering to steer_val.
	}
	print "fore: " + fore_error at (0,1).
	print "star: " + star_error at (0,2).
	print "up: " + up_error at (0,3).
	print "deadband: " + deadbandval at (0,4).
	print "dist: " + dest_dist at (0,5).
	print "goal speed: " + goal_speed at (0,6).
	set ship:control:translation to translate_vector.
	wait 0.001.
}

clearscreen.
print "docking completed".
set ship:control:neutralize to true.
set rcs to false.
set sas to false.