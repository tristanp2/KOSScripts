set script_version to "soi_entry_orbit0.0".
print "script_version: " + script_version.

set sas to false.

declare parameter target_body_name.

runpath("utilities.ks").

if ship:body:name <> target_body_name {
    ff_to_next_transition().

    print "transferring".
    print "current body: " + ship:body:name.
    set current_body_name to ship:body:name.
    wait until ship:body:name <> current_body_name.

    print "transferred to " + ship:body:name.
}
else {
    print "already in target body soi".
}

lock radial_v to ship:position - ship:body:position.
lock ship_vel to ship:velocity:orbit.

lock cancel_vel to vxcl(radial_v, ship_vel).

lock steering to -cancel_vel.
wait 2.

wait until steeringsettled().
lock thrott to cancel_vel:mag / 10.
lock throttle to thrott.

wait until cancel_vel:mag < 0.1.

set thrott to 0.
print "radial normal velocity cancelled".

wait 2.

lock system_outward_vec to ship:body:position - ship:body:orbit:body:position.
set outward_burn_vec to vxcl(radial_v, system_outward_vec).

lock steering to outward_burn_vec.

wait 1.
wait until steeringsettled().


set target_periapsis to 12000.
lock thrott to clamp(abs(ship:orbit:periapsis - target_periapsis) / target_periapsis, 0.1, 0.5). 

print "raising periapsis to " + target_periapsis.
wait until ship:orbit:periapsis > target_periapsis.

set thrott to 0.

wait 2.

print "warping to periapsis".
ff_to_periapsis().

set target_periapsis to ship:orbit:periapsis - 1000.

set_timewarp(1).

wait 2.
wait until steeringsettled().

lock surface_velocity to ship:orbit:velocity:surface.
lock vertical_speed to vdot(ship:up:forevector, surface_velocity).

lock vertical_velocity to vertical_speed * ship:up:forevector.

set steering to ship:retrograde.
clearscreen.
print "circularizing...".

wait until steeringsettled().
lock thrott to clamp(abs(ship:orbit:periapsis / (ship:orbit:periapsis - target_periapsis)), 0.1, 1).

until ship:orbit:periapsis < target_periapsis  {
    if vertical_speed  < 0 {
        set steering to ship:retrograde:forevector.
    }
    else {
        set steering to ship:retrograde:forevector - 0.05 * vertical_velocity.
    }

    print "apoapsis: " + ship:orbit:apoapsis at(0,1).
    print "periapsis: " + ship:orbit:periapsis at (0,2).
    print "thrott: " + thrott at (0,3).
    print "vertical speed: " + vertical_speed at (0,4).
    wait 0.1.
}

set thrott to 0.
unlock throttle.
unlock steering.
set sas to true.
