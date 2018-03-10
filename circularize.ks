declare parameter target_semimajor.
declare parameter peri_thresh to 400.
declare parameter apo_thresh to 400.

set thrott to 0.
set steer_val to ship:prograde.
lock steering to steer_val.
lock throttle to thrott.

set sas_state to sas.
set sas to false.
set rcs to false.

lock peri_diff to ship:periapsis - target_semimajor.
lock apo_diff to ship:apoapsis - target_semimajor.
lock apo_peri_diff to ship:apoapsis - ship:periapsis.
set burn_pid to pidloop(0.01,0.006,0.003, -0.5, 0.5).
set burn_pid:setpoint to 1.
lock thrott_val to ship:mass / ship:availablethrust.


declare function filter_deadband{
	declare parameter value.
	declare parameter deadband_value to 0.01.
	
	if abs(value) < 0.05{
		return 0.
	}
	return value.
}
	
//TODO: Find a good way to make this handle apo and peri flipping.
//	Right now, it just always adjusts the apoapsis first. Maybe just get it to look at semi-major?


// Reducing orbit:
//	Shrinking apo first causes apsii to flip
// Increasing orbit:
// 	Growing peri first causes apsii to flip.
set reducing to false.
if ship:obt:semimajoraxis - ship:body:radius > target_semimajor {
	set reducing to true.
}

declare function adjust_peri{
	clearscreen.
	print "warping closer to apoapsis".
	wait 3.
	set kuniverse:timewarp:rate to 50.
	wait until eta:apoapsis < 90.
	print "tiptoeing closer to apoapsis".
	set kuniverse:timewarp:rate to 10.
	wait until eta:apoapsis < 20.
	set kuniverse:timewarp:rate to 0.
	
	if peri_diff < 0{
		set burn_dir to velocityat(ship, time + eta:apoapsis):orbit.
	}
	else{
		set burn_dir to -velocityat(ship, time + eta:apoapsis):orbit.
	}
	
	set steer_val to burn_dir.
	wait until eta:apoapsis < 10.
	clearscreen.
	print "adjusting ship periapsis to " + target_semimajor.
	
	//separate cases to avoid blowing past abs(peri_diff)
	if peri_diff < 0{
		until peri_diff > -100{
			print "periapsis: " + ship:periapsis at (0,1).
			print "thrott: " + thrott at (0,2).
			//set thrott to thrott +  filter_deadband(burn_pid:update(time:seconds, accel)).
			set thrott to thrott_val.
			wait 0.001.
		}
	}
	else{
		until peri_diff < 100{
			print "periapsis: " + ship:periapsis at (0,1).
			print "thrott: " + thrott at (0,2).
			//set thrott to thrott + filter_deadband(burn_pid:update(time:seconds, accel)).
			set thrott to thrott_val.
			wait 0.001.
		}
	}		
	print "apoapsis adjustment completed".
	set thrott to 0.
}

declare function adjust_apo{
	clearscreen.
	print "warping closer to periapsis".
	wait 3.
	set kuniverse:timewarp:rate to 50.
	wait until eta:periapsis < 90.
	print "tiptoeing closer to periapsis".
	set kuniverse:timewarp:rate to 10.
	wait until eta:periapsis < 20.
	set kuniverse:timewarp:rate to 0.
	
	if apo_diff < 0{
		set burn_dir to velocityat(ship, time + eta:periapsis):orbit.
	}
	else{
		set burn_dir to -velocityat(ship, time + eta:periapsis):orbit.
	}
	
	set burn_pid:setpoint to 50.
	set steer_val to burn_dir.
	wait until eta:periapsis < 10.
	clearscreen.
	
	print "adjusting ship apoapsis to " + target_semimajor.
	if apo_diff < 0{
		until apo_diff > -100{
			print "apoapsis: " + ship:apoapsis at (0,1).
			print "thrott: " + thrott at (0,2).
			//set thrott to thrott + filter_deadband(burn_pid:update(time:seconds, accel)).
			set thrott to thrott_val.
			wait 0.001.
		}
	}
	else{
		until apo_diff < 100{
			print "apoapsis: " + ship:apoapsis at (0,1).
			print "thrott: " + thrott at (0,2).
			//set thrott to thrott + filter_deadband(burn_pid:update(time:seconds, accel)).
			set thrott to thrott_val.
			wait 0.001.
		}
	}
	print "apoapsis adjustment completed".
	set thrott to 0.
}

clearscreen.
print "starting circularization".
until abs(peri_diff) < peri_thresh and abs(apo_diff) < apo_thresh{
	if reducing {
		//adjust periapsis
		clearscreen.
		print "evaluating periapsis".
		print "periapsis difference: " + peri_diff.
		print "current periapsis: " + ship:periapsis.
		if abs(peri_diff) > peri_thresh{
			adjust_peri().
		}
		else{
			print "no periapsis adjustment necessary".
		}
		
		//adjust apoapsis
		clearscreen.
		print "evaluating apoapsis".
		print "apoapsis difference: " + apo_diff.
		print "current apoapsis: " + ship:apoapsis.
		if abs(apo_diff) > apo_thresh{
			adjust_apo().
		}
		else{
			print "no apoapsis adjustment necessary".
		}
	}
	else {	
		//adjust apoapsis
		clearscreen.
		print "evaluating apoapsis".
		print "apoapsis difference: " + apo_diff.
		print "current apoapsis: " + ship:apoapsis.
		if abs(apo_diff) > apo_thresh{
			adjust_apo().
		}
		else{
			print "no apoapsis adjustment necessary".
		}
		
		//adjust periapsis
		clearscreen.
		print "evaluating periapsis".
		print "periapsis difference: " + peri_diff.
		print "current periapsis: " + ship:periapsis.
		if abs(peri_diff) > peri_thresh{
			adjust_peri().
		}
		else{
			print "no periapsis adjustment necessary".
		}
	}	
}
clearscreen.
print "circularization completed".
unlock steering.
unlock throttle.

set sas to sas_state.
