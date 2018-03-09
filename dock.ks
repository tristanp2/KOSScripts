declare parameter target_name.
declare parameter ship_port_name to "".

run utilities.

set target_vessel to vessel(target_name).
set rcs_restore to rcs.
set rcs to true.

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

lock target_pos to target_port:facing:vector * 20 + target_vessel:position.
lock dest_vec to target_pos - ship:position.
lock dest_dist to dest_vec:MAG.
set steer_val to dest_vec.

lock relative_velocity to ship:velocity:orbit - target_vessel:velocity:orbit.

set max_dist to dest_dist.
lock goal_speed to min(7, 5 * dest_dist / 250).
lock goal_velocity to goal_speed * dest_vec:normalized.
lock correction_vec to goal_velocity - relative_velocity.
lock error_direction to vdot(goal_velocity, correction_vec) / abs(vdot(goal_velocity,correction_vec)).
lock steer_vec to error_direction * correction_vec.
lock speed_error to correction_vec:mag * error_direction.
lock deadbandval to min(1,dest_dist / max_dist).
lock control_val to  applydeadband(speed_error, -deadbandval,deadbandval).
lock fore_val to control_val.

lock steering to steer_val.

until dest_vec:MAG < 1 {
	print "dist: " + dest_vec:MAG at (0,1).
	print "speed error: " + speed_error at (0,2).
	print "goal speed: " + goal_speed at (0,3).
	print "fore: " + fore_val at (0,4).
	print "speed: " + relative_velocity:mag at (0,5).
	print "err dir: " + error_direction at (0,6).
	set steer_val to steer_vec.
	set ship:control:fore to fore_val.
}

set ship:control:neutralize to true.