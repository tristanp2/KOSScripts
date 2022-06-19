// prereq: in lower circular orbit on same body and plane as target body

declare parameter target_body_name.

runpath("utilities.ks").

enable_stage_trigger().

set target_body to body(target_body_name).
set source_body to ship:orbit:body.

// TODO: This currently only works for transferring to a satellite (i.e kerbin -> mun)
set mu to source_body:mu.

lock ship_pos to V(0,0,0) - source_body:position.
lock target_pos to target_body:position - source_body:position.

set ship_sma to ship:orbit:semimajoraxis.
set target_orbit_periapsis to ship_sma.
set target_orbit_apoapsis to target_body:orbit:semimajoraxis.
set target_orbit_sma to (target_orbit_periapsis + target_orbit_apoapsis) / 2.

set target_orbit_period to 2 * constant:pi * sqrt(target_orbit_sma^3 / mu).
set travel_time to target_orbit_period / 2.

set target_angle_change to (360 / target_body:orbit:period) * travel_time.
set phase_angle to 180 - target_angle_change.

lock ship_norm to vcrs(ship:velocity:orbit, ship_pos).

lock source_target_norm to vcrs(target_pos, ship_pos).
lock norm_dir to vdot(source_target_norm, ship_norm). 

lock current_angle to choose vang(target_pos, ship_pos) if norm_dir > 0 else -vang(target_pos, ship_pos).
 
print "travel time to target: " + travel_time.
print "target angle (degrees) movement during travel: " + target_angle_change.
print "phase angle: " + phase_angle.
print "current angle: " + current_angle.

lock angle_diff to abs(current_angle - phase_angle).

wait 3.
clearscreen.

set kuniverse:timewarp:rate to 50.
until angle_diff < 1 {
    if angle_diff < 20 {
        set kuniverse:timewarp:rate to 5.
    }
    else {
        set kuniverse:timewarp:rate to 50.
    }

    print "angle diff: " + angle_diff at (0,0).
    wait 0.1.
}
clearscreen.

set kuniverse:timewarp:rate to 1.
print "target angle: " + phase_angle.
print "current angle: " + current_angle.
print "starting burn".
wait 2.

lock apo_error to (target_body:orbit:apoapsis - ship:orbit:apoapsis) / 5000.
set thrott to 1.
set sas to false.
set steer_val to ship:velocity:orbit.
lock steering to steer_val.

print "waiting for steering to settle".

wait 1.
wait until steeringsettled().
print "steering settled?".
wait 2.
lock throttle to thrott.
clearscreen.

until apo_error < 0.5 or encounter <> "None" {
    set thrott to max(min(apo_error, 1), 0).
    print "apo error: " + apo_error at (0,0).
    print "ship apoapsis: " + ship:orbit:apoapsis at (0,1).
}

set thrott to 0.

wait 2.

unlock steering.
unlock throttle.
