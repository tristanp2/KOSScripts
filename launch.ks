runpath("utilities.ks").

set sas to false.
set rcs to false.
set steer_vec to lookdirup(heading(90,90):vector, ship:facing:topvector).
set init_top to ship:facing:topvector.

list engines in englist.
set g to kerbin:mu / kerbin:radius^2.

lock steering to steer_vec.
set thrott to 1.
lock throttle to thrott.
clearscreen.
from {local x is 5.} until x = 0 step {set x to x-1.} do {
	print "T - " + x.
	wait 1.
}

lock ship_speed to ship:velocity:surface:mag.

set enable_triggers to true.
enable_stage_trigger().

set dest_alt to 80000.

set apo_time to 90.
set atmo_pid to pidloop(0.01, 0.003, 0.01, -0.5, 0.5).
set atmo_pid:setpoint to 1.
lock pitch_above to 90 - min(1, ship:apoapsis / (dest_alt - 5000))*90.
lock steer_dir to lookdirup(heading(90, pitch_above):vector, init_top).
clearscreen.
wait until ship_speed > 100.
set dthrott to 0.
set last_speed to ship_speed.
lock d_speed to ship_speed - last_speed.

until eta:apoapsis >= apo_time or ship:apoapsis > dest_alt {
    print d_speed at (0,0).
	set dthrott to atmo_pid:update(time:seconds, d_speed).
	set thrott to thrott + dthrott.
	set thrott to max(0.05, thrott).
	set steer_vec to steer_dir.
    set last_speed to ship_speed.
    wait 0.1.
}

set Kp to 0.1.
set Ki to 0.06.
set Kd to 0.12.
set pid to pidloop(Kp, Ki, Kd, -0.75, 0.75).
//need to figure out a good way to calculate this on the fly
set apo_time to 90.
set pid:setpoint to apo_time.

clearscreen.

until ship:apoapsis > dest_alt {
	set steer_vec to steer_dir.
	set dthrott to pid:update(time:seconds, eta:apoapsis).	
	set thrott to thrott + dthrott.
	print dthrott at (0,0).
	print ship_speed at (0,2).
	print eta:apoapsis at (0,3).
	if thrott < 0 {
		set thrott to 0.
	}
	else if thrott > 1 {
		set thrott to 1.
	}
	wait 0.001.
}
clearscreen.
set ct to 40.
print "starting circularisation phase".
print "waiting until " + ct + "s to apo".
if Career():canmakenodes {
    set steer_vec to velocityat(ship, time + eta:apoapsis):orbit.
}
else {
    lock steer_vec to ship:prograde.
}
set thrott to 0.
until eta:apoapsis <= ct {
	print "time to apo: " + eta:apoapsis at (0,2).
	if eta:apoapsis > ct + 10{
		set kuniverse:timewarp:rate to 10.
	}
	else{
		set kuniverse:timewarp:rate to 0.
	}
	wait 0.1.
}
set thresh to -2*dest_alt.

clearscreen.
set thrott to 0.5.
lock diff to thresh - ship:periapsis.
set err to min(1, diff / 4000).

until diff < 0.1 or eta:apoapsis < 13{
	print "waiting for peri to be bigger than " + thresh at(0,0).
	print ship:periapsis at (0,1).
	print "time to apo: " + eta:apoapsis at (0,2).
	set thrott to max(err, 0.1).
	print thrott at (0,4).
	if thrott < 0 {
		set thrott to 0.
	}
	else if thrott > 1 {
		set thrott to 1.
	}
	wait 0.001.
}
set thrott to 0.
if Career():canmakenodes {
    set base_steer_vec to velocityat(ship, time + eta:apoapsis):orbit.
}
else {
    lock base_steer_vec to ship:prograde:forevector.
}
clearscreen.
print "waiting to get closer to apoapsis".
	
wait 1.
set kuniverse:timewarp:rate to 5.
wait until eta:apoapsis < 10.
set kuniverse:timewarp:rate to 1.

set eta_Kp to 0.01.
set eta_Ki to 0.06.
set eta_Kd to 0.012.

set eta_pid to pidloop(eta_Kp, eta_Ki, eta_Kd, 0, 1).
set eta_pid:setpoint to 10.0.

clearscreen.
lock diff to (dest_alt - ship:periapsis) / dest_alt.
set target_eta to 10.
set thrott to 0.75.
lock eta_diff to (target_eta - eta:apoapsis) / target_eta. 
set max_correction_mag to 0.5.
lock eta_correction_vec to max_correction_mag * eta_diff * ship:up:forevector.
lock steer_vec to base_steer_vec + eta_correction_vec.
set start_apo to ship:apoapsis.
lock apo_diff to ship:apoapsis - start_apo.
until ship:periapsis >= (dest_alt - 100) or apo_diff > 1000 {
    //set dthrott to eta_pid:update(time:seconds, eta:apoapsis).
    //set thrott to thrott + dthrott.
	set thrott to max(diff, 0.05).
	print "waiting for periapsis to reach: " + (dest_alt - 1000) + " or " + (ship:altitude - 100) at (0,0).
	print ship:periapsis at (0,1).
	print "time to apo: " + eta:apoapsis at (0,2).
	print "apo diff: " + apo_diff at (0,3).
    print "dthrott: " + dthrott at (0,5).
	if thrott < 0 {
		set thrott to 0.
	}
	else if thrott > 1 {
		set thrott to 1.
	}
	print thrott at (0,4).
	wait 0.001.
}

set thrott to 0.
wait 1.

set enable_triggers to false.
unlock steering.
unlock throttle.

clearscreen.
