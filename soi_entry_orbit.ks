set script_version to "soi_entry_orbit0.0".
print "script_version: " + script_version.

set sas to false.

declare parameter target_body_name.
declare parameter dest_sma to 12000.
set target_periapsis to dest_sma.

runpath("utilities.ks").

set enable_triggers to true.
enable_stage_trigger().

if ship:body:name <> target_body_name {
    ff_to_next_transition(target_body_name).

    print "target peri: " + target_periapsis.
    print "transferring".
    print "target body: " + target_body_name.
    wait until ship:body:name = target_body_name.

    print "transferred to " + ship:body:name.
}
else {
    print "already in target body soi".
}

lock ship_position to ship:position - ship:body:position.
lock target_normal to -ship:body:angularvel:normalized.
lock ship_vel to ship:velocity:orbit.
lock ship_accel to max(ship:availablethrust / ship:mass, 0.001).
lock tangential to vcrs(ship_position, target_normal):normalized.

set intermediate_peri to ship_position:mag / 3.
lock target_sma to (ship_position:mag + intermediate_peri) / 2.
lock required_velocity to calculate_altitude_speed(ship:body:mu, ship_position:mag, target_sma) * tangential.
lock correction_vector to required_velocity - ship:velocity:orbit.
set initial_correction_mag to correction_vector:mag.

lock steering to correction_vector.
lock burn_time to correction_vector:mag / ship_accel.
lock thrott to burn_time / 2.
wait 2.
wait until steeringsettled().

print "setting up initial orbit with apo speed " + required_velocity:mag.
until correction_vector:mag / initial_correction_mag < 0.01 {
    set throttle to thrott.
    wait 0.01.
}

set throttle to 0.

if ship:orbit:inclination > 5 {
    lock normal_dist to vdot(target_normal, ship_position).
    lock normal_speed to vdot(target_normal, ship:velocity:orbit).
    lock node_eta to abs(normal_dist / normal_speed).
    set equatorial_eta to normal_dist / normal_speed.
    set below to choose true if normal_dist < 0 else false.

    clearscreen.
    print "waiting for equator".
    until (below and normal_dist > 0) or (not below and normal_dist < 0) {
        if(node_eta > 1000) {
           set_warp_for_eta(eta:periapsis). 
        }
        else {
            set_warp_for_eta(node_eta).
        }

        print "normal distance: " + normal_dist at (0,1).
        print "normal speed: " + normal_speed at (0,2).
        print "equator eta: " + node_eta at (0,3).

        wait 0.1.
    }
    set_timewarp(1).

    lock circular_speed to calculate_circular_speed(ship:body:mu, ship_position:mag). 
    lock required_velocity to circular_speed * vcrs(ship_position, target_normal):normalized. 
    lock correction_vector to required_velocity - ship:velocity:orbit.
    lock steer_val to correction_vector.
    lock burn_time to correction_vector:mag / ship_accel.
    lock thrott to burn_time / 2.

    set steering to steer_val.
    wait until steeringsettled().

    until correction_vector:mag  < 0.1 {
        set steering to steer_val.
        set throttle to thrott.
        
        print "correction mag: " + correction_vector:mag at (0,4).
        
        wait 0.01.
    }
}
clearscreen.

set throttle to 0.


print "reducing periapsis to " + target_periapsis.
lock tangential to vcrs(ship_position, target_normal):normalized.
lock target_sma to (ship_position:mag + target_periapsis + ship:body:radius) / 2.
lock required_velocity to calculate_altitude_speed(ship:body:mu, ship_position:mag, target_sma) * tangential. 
lock correction_vector to required_velocity - ship:velocity:orbit.
lock steer_val to correction_vector.
lock burn_time to correction_vector:mag / ship_accel.
lock thrott to burn_time / 2.

set steering to steer_val.
wait until steeringsettled().

until correction_vector:mag < 0.1 {
    set steering to steer_val.
    set throttle to thrott.

    print "correction mag: " + correction_vector:mag at (0,1).
    wait 0.001.
}

set throttle to 0.

wait 2.

clearscreen.
print "warping to periapsis".
ff_to_periapsis(30).

set_timewarp(1).

clearscreen.

lock circular_speed to calculate_circular_speed(ship:body:mu, ship:altitude + ship:body:radius).
lock target_velocity to circular_speed * vxcl(ship:up:forevector, ship:prograde:forevector).
lock correction_vector to target_velocity - ship:velocity:orbit.
lock correction_time to correction_vector:mag / ship_accel.
lock steer_val to correction_vector. 
set steering to steer_val.

print "calculated circular speed: " + circular_speed.

wait until eta:periapsis < correction_time.

print "circularizing...".

lock thrott to clamp(correction_time / 2, 0, 1).
set steering to steer_val.
wait until steeringsettled().

until correction_vector:mag < 0.1 {
    set throttle to thrott.
    set steering to steer_val.

    print "apoapsis: " + ship:orbit:apoapsis at(0,2).
    print "periapsis: " + ship:orbit:periapsis at (0,3).
    print "thrott: " + thrott at (0,4).
    print "circular speed: " + circular_speed at (0,6).
    print "correction mag: " + correction_vector:mag at (0,7).
    print "correction time: " + correction_time at (0,8).
    wait 0.001.
}

set enable_triggers to false.
set throttle to 0.
unlock throttle.
unlock steering.
set sas to true.
