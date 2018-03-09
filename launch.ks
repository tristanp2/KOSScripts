run utilities.


list engines in englist.
set g to kerbin:mu / kerbin:radius^2.
lock accvec to ship:sensors:acc - ship:sensors:grav.
lock gforce to accvec:MAG / g.

set steer_val to UP.
lock steering to steer_val.

set Kp to 0.1.
set Ki to 0.03.
set Kd to 0.12.

set thrott to 1.
lock throttle to thrott.
clearscreen.
from {local x is 5.} until x = 0 step {set x to x-1.} do {
	print "T - " + x.
	wait 1.
}
set pid to pidloop(Kp, Ki, Kd, -0.75, 0.75).
set pid:setpoint to 90.0.


lock ship_speed to ship:velocity:surface:mag.

when stage:ready and (flameoutoccured(englist) or maxthrust = 0) then{
	stage.
	preserve.
	list engines in englist.
	wait 0.1.
}
set dest_alt to 80000.

set atmo_pid to pidloop(0.01, 0.006, 0.006, -0.5, 0.5).
set atmo_pid:setpoint to 2.0.
clearscreen.
wait until ship_speed > 100.
set dthrott to 0.
until eta:apoapsis >= 90 or ship:apoapsis > dest_alt {
	set dthrott to atmo_pid:update(time:seconds, gforce).
	set thrott to thrott + dthrott.
	set thrott to max(0.05, thrott).
	set dir to 90 - min(1,(ship:apoapsis/(dest_alt-5000)))*90.
	set steer_val to r(0,0,-90) + heading(90,dir).
}
until ship:apoapsis > dest_alt {
	set dir to 90 - min(1,(ship:apoapsis/(dest_alt-5000)))*90.
	set steer_val to r(0,0,-90) + heading(90,dir).
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

set eta_pid to pidloop(eta_Kp, eta_Ki, eta_Kd, -0.5,0.5).
set eta_pid:setpoint to ct-5.
clearscreen.
set thrott to 0.5.
until ship:periapsis > thresh or eta:apoapsis < 13{
	print "waiting for peri to be bigger than " + thresh at(0,0).
	print ship:periapsis at (0,1).
	print "time to apo: " + eta:apoapsis at (0,2).
	set dthrott to eta_pid:update(time:seconds, eta:apoapsis).
	set thrott to thrott + dthrott.
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
set thrott to 0.75.
until ship:periapsis >= (dest_alt - 300) or ship:periapsis >= (ship:altitude - 10) {
	set dthrott to eta_pid:update(time:seconds, eta:apoapsis).
	set thrott to thrott + dthrott.
	print "waiting for periapsis to reach: " + (dest_alt - 1000) + " or " + (ship:altitude - 100) at (0,0).
	print ship:periapsis at (0,1).
	print "time to apo: " + eta:apoapsis at (0,2).
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