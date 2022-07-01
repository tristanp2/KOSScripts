// prereq: in lower circular orbit on same body and plane as target body

declare parameter target_body_name.

runpath("utilities.ks").

set enable_triggers to true.
enable_stage_trigger().

set target_body to body(target_body_name).
set source_body to ship:orbit:body.
set target to target_body.

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
set predicted_target_encounter_true_anomaly to mod(target_body:orbit:trueanomaly + target_angle_change,360).

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


set kuniverse:timewarp:mode to "RAILS".
set_timewarp(50).
lock steering to ship:prograde:forevector.
until angle_diff < 1 {
    if angle_diff < 20 {
        set_timewarp(5).
    }
    else {
        set_timewarp(50).
    }

    print "angle diff: " + angle_diff at (0,0).
    wait 0.1.
}
clearscreen.

set_timewarp(1).

lock ship_center_dist to (ship:position - ship:body:position):mag.
set target_orbit_sma to (ship_center_dist + target_orbit_apoapsis) / 2.

lock required_periapsis_speed to calculate_altitude_speed(ship:body:mu, ship_center_dist, target_orbit_sma).

lock target_position_rel_body to target_body:position - target_body:body:position.
lock target_normal to vcrs(target_position_rel_body, target_body:velocity:orbit):normalized.
lock tangential_incline_vector to vcrs(target_normal, ship:position - ship:body:position):normalized. 
lock required_velocity to required_periapsis_speed * tangential_incline_vector:normalized.
lock correction_vector to required_velocity - ship:velocity:orbit.

set initial_correction_mag to correction_vector:mag.
lock ship_accel to max(ship:availablethrust / ship:mass, 0.001).
lock burn_time to correction_vector:mag / ship_accel.
print "calculated required speed: " + required_periapsis_speed.
print "target angle: " + phase_angle.
print "current angle: " + current_angle.
print "starting burn".
wait 2.

lock thrott to clamp(burn_time / 2, 0, 1).
set throttle to 0.
set sas to false.
lock steer_val to correction_vector.
set steering to steer_val.

print "waiting for steering to settle".

wait 1.
wait until steeringsettled().
print "steering settled?".
wait 2.
clearscreen.

lock ship_apoapsis to ship:orbit:apoapsis + ship:body:radius.

until correction_vector:mag / initial_correction_mag < 0.01 or ship_apoapsis > target_orbit_apoapsis {
    set throttle to thrott.
    set steering to steer_val.
    print "burn time: " + burn_time at (0,0).
    print "required speed: " + required_periapsis_speed at (0,1).
    print "ship apoapsis: " + ship_apoapsis at (0,2).
    print "target apoapsis: " + target_orbit_apoapsis at (0,3).
    print "correction mag: " + correction_vector:mag at (0,4).
    print "correction left: " + correction_vector:mag / initial_correction_mag at (0,5).
    wait 0.001.
}

set throttle to 0.
lock ship_position to ship:position - ship:body:position.
lock ship_normal to vcrs(ship_position, ship:velocity:orbit):normalized.
lock relative_inclination to vang(ship_normal, target_normal)..

if abs(relative_inclination) > 0.5 {
    clearscreen.
    print "relative inclination of " + relative_inclination + ". matching incline".
    set start_inclination to relative_inclination.
    lock ship_position to ship:position - ship:body:position.
    lock ship_norm_dist to vdot(target_normal, ship_position).
    lock ship_norm_speed to vdot(target_normal, ship:velocity:orbit).

    // super inaccurate
    lock node_eta to abs(ship_norm_dist / ship_norm_speed).

    lock base_vec to vxcl(target_normal, ship:velocity:orbit).
    //set initial_speed to ship:velocity:orbit:mag.
    lock required_velocity to base_vec.

    lock steer_val to correction_vector:normalized.
    lock burn_time to correction_vector:mag / ship_accel.

    set steering to steer_val.
    lock thrott to min(burn_time / 3, relative_inclination / start_inclination). 

    set below to false.

    if ship_norm_dist < 0 {
        set below to true.
    }

    until (below and ship_norm_dist > 0) or (not below and ship_norm_dist < 0) {
        print "norm dist: " + ship_norm_dist at (0,1).
        print "norm speed: " + ship_norm_speed at (0,2).
        print "node eta: " + node_eta at (0,3).

        set_warp_for_eta(node_eta, 100).

        wait 0.1.
    }

    set_timewarp(1).

    wait until steeringsettled().

    set initial_apoapsis to ship:orbit:apoapsis.
    wait 0.1.
    until ship:orbit:hasnextpatch and ship:orbit:nextpatch:body = target_body or relative_inclination < 0.1 {
        print "relative_inclination: " + relative_inclination at (0,1).
        print "correction mag: " + correction_vector:mag at (0,2).
        print  "burn time: " + burn_time at (0,3). 

        set throttle to thrott.
        set steering to steer_val. 

        wait 0.1.
    }

    set throttle to 0.
    
    lock apo_diff to initial_apoapsis - ship:orbit:apoapsis.
    set initial_diff to apo_diff.

    if(apo_diff / initial_apoapsis > 0.005) {
        print "fixing apoapsis                  " at (0,0).
        if ship:orbit:apoapsis < initial_apoapsis {
            lock steering to ship:prograde:forevector.
        }
        else {
            lock steering to -ship:prograde:forevector.
        }

        wait until steeringsettled().
        lock thrott to (apo_diff / initial_diff) * (ship_position:mag / initial_apoapsis).

        until apo_diff / initial_diff < 0.01 {
            set throttle to thrott.

            print "apo_diff: " + apo_diff at (0,5).
            wait 0.001.
        }
    }
    
    print "done" at (0,6).
}

set_timewarp(1).


set enable_triggers to false.
lock throttle to 0.
lock steering to ship:facing.

wait 2.
wait until steeringsettled().

unlock steering.
unlock throttle.
