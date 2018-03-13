run utilities.

set sas to false.
set rcs to false.
set steer_val to lookdirup(heading(90,90):vector, ship:facing:topvector).
set init_top to ship:facing:topvector.

list engines in englist.
set g to kerbin:mu / kerbin:radius^2.
lock accvec to ship:sensors:acc - ship:sensors:grav.
lock gforce to accvec:MAG / g.

lock steering to steer_val.
set thrott to 1.
lock throttle to thrott.
clearscreen.
from {local x is 5.} until x = 0 step {set x to x-1.} do {
	print "T - " + x.
	wait 1.
}

set Kp to 0.1.
set Ki to 0.06.
set Kd to 0.12.

set pid to pidloop(Kp, Ki, Kd, -0.75, 0.75).
//need to figure out a good way to calculate this on the fly
set apo_time to 90.
set pid:setpoint to apo_time.


lock ship_speed to ship:velocity:surface:mag.

when stage:ready and (flameoutoccured(englist) or maxthrust = 0) then{
	stage.
	preserve.
	list engines in englist.
}
set dest_alt to 80000.

set atmo_pid to pidloop(0.01, 0.003, 0.01, -0.5, 0.5).
set atmo_pid:setpoint to 2.0.
lock pitch_above to 90 - min(1, ship:apoapsis / (dest_alt - 5000))*90.
lock steer_dir to lookdirup(heading(90, pitch_above):vector, init_top).
clearscreen.
wait until ship_speed > 100.
set dthrott to 0.

until eta:apoapsis >= apo_time or ship:apoapsis > dest_alt {
	set dthrott to atmo_pid:update(time:seconds, gforce).
	set thrott to thrott + dthrott.
	set thrott to max(0.05, thrott).
	set steer_val to steer_dir.
}
until ship:apoapsis > dest_alt {
	set steer_val to steer_dir.
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
set eta_Kp to 0.01.
set eta_Ki to 0.003.
set eta_Kd to 0.012.

set steer_val to velocityat(ship, time + eta:apoapsis):orbit.
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
set steer_val to velocityat(ship, time + eta:apoapsis):orbit.
clearscreen.
print "waiting to get closer to apoapsis".
	
wait until eta:apoapsis < 12.
set eta_pid to pidloop(eta_Kp, eta_Ki, eta_Kd, 0, 1).
set eta_pid:setpoint to 10.0.
clearscreen.
lock diff to (dest_alt - ship:periapsis) / dest_alt.
set thrott to 0.75.
set start_apo to ship:apoapsis.
lock apo_diff to ship:apoapsis - start_apo.
until ship:periapsis >= (dest_alt - 100) or apo_diff > 1000 {
	set thrott to max(diff, 0.05).
	print "waiting for periapsis to reach: " + (dest_alt - 1000) + " or " + (ship:altitude - 100) at (0,0).
	print ship:periapsis at (0,1).
	print "time to apo: " + eta:apoapsis at (0,2).
	print "apo diff: " + apo_diff at (0,3).
	if thrott < 0 {
		set thrott to 0.
	}
	else if thrott > 1 {
		set thrott to 1.
	}
	print thrott at (0,4).
	wait 0.001.
}

clearscreen.