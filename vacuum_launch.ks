runpath("utilities.ks").

set sas to false.

declare parameter target_radius.

lock center_dist to ship:altitude + ship:body:radius. 
lock g_accel to ship:body:mu / center_dist^2. 
lock ship_accel to ship:availablethrust / ship:mass.

set vertical_speed_redundancy_time to 15.
lock min_vertical_speed to g_accel * vertical_speed_redundancy_time.

lock target_vertical_speed to clamp(1000 - alt:radar, min_vertical_speed, min_vertical_speed * 3).

lock target_velocity to target_vertical_speed * ship:up:forevector.

lock surface_velocity to ship:orbit:velocity:surface.
lock vertical_speed to vdot(ship:up:forevector, surface_velocity).

lock correction_vector to target_velocity - surface_velocity.
lock correction_time to correction_vector:mag / ship_accel.

lock steer_val to lookdirup(correction_vector, ship:facing:topvector).

until alt:radar > 1000 {
    set steering to steer_val.
    set throttle to correction_time.

    wait 0.1.
}

set throttle to 0.

print "reached desired vertical speed. burning east.".

lock target_accel to 20 * clamp((target_radius - ship:apoapsis) / target_radius, 0, 1).
lock thrott to target_accel / ship_accel. 
lock pitch_angle to 45 * clamp(-vertical_speed / 2, 0, 1).
lock steer_val to heading(90, pitch_angle).

until ship:apoapsis > target_radius {
    set throttle to thrott.
    set steering to steer_val.

    wait 0.1.
}

set throttle to 0.

print "apoapsis raised to " + ship:apoapsis + ". warping to apoapsis".

until eta:apoapsis < 30 {
    set_warp_for_eta(eta:apoapsis - 15).
    wait 0.1.
}

set_timewarp(0).
wait 3.

lock steer_val to ship:prograde.
set steering to steer_val.

wait 3.
wait until steeringsettled(3).

set_timewarp(5).
wait until eta:apoapsis < 10.
set_timewarp(0).

lock target_accel to 10 * clamp((target_radius - ship:periapsis) / target_radius, 0, 1).

until ship:orbit:semimajoraxis - ship:orbit:body:radius > target_radius {
    if eta:periapsis < eta:apoapsis {
        set steer_val to ship:prograde + ship:up:forevector.
    }
    else {
        set steer_val to ship:prograde.
    }
    set throttle to thrott.
    set steering to steer_val.

    wait 0.1.
}

set throttle to 0.

