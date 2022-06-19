declare parameter enter_stable_orbit to true.

runpath("utilities.ks").

ff_to_next_transition().

print "transferring".
print "current body: " + ship:body:name.
set current_body_name to ship:body:name.
wait until ship:body:name <> current_body_name.

print "transferred to " + ship:body:name.

    

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

lock system_outward_vec to ship:body:position - ship:body:orbit:body:position.
set outward_burn_vec to vxcl(radial_v, system_outward_vec).

lock steering to outward_burn_vec.

wait 1.
wait until steeringsettled().

set thrott to 0.5.

print "raising periapsis".
wait until ship:orbit:periapsis > 12000.

set thrott to 0.

wait 2.

if enter_stable_orbit {
    print "warping to periapsis".
    ff_to_periapsis(20).

    set_timewarp(1).
    lock vertical_speed to max(vdot(ship:up:forevector, ship:orbit:velocity:surface), 0).
    lock steering to ship:retrograde:forevector - (vertical_speed / 5) * ship:up:forevector.
    wait until steeringsettled().

    set target_apoapsis to ship:orbit:periapsis.
    set thrott to 1.
    wait until ship:orbit:apoapsis > 0.
    lock thrott to clamp((ship:orbit:apoapsis - target_apoapsis) / target_apoapsis, 0, 1).
    wait until ship:orbit:apoapsis - target_apoapsis < 1000.
    
    set thrott to 0.


    print "press 1 to continue...".
    set input_char to terminal:input:getchar().
    until input_char = "1" {
        set input_char to terminal:input:getchar().
    }
}

lock local_radial_v to ship:position - ship:body:position.
lock ship_target_ang to abs(vang(system_outward_vec, local_radial_v)).

clearscreen.
print "warping to next burn point".
set last_ship_ang to ship_target_ang.
set last_d_ship_ang to 1.
set last_t to time:seconds.
lock delta_t to time:seconds - last_t.
wait 1.
until ship_target_ang < 5 {
    set d_ship_ang to abs(ship_target_ang - last_ship_ang) / delta_t * 0.7 + last_d_ship_ang * 0.3.
    set alph to ship_target_ang / min(d_ship_ang, 0.5).
    set last_d_ship_ang to d_ship_ang.
    set last_ship_ang to ship_target_ang.
    set last_t to time:seconds.
    if alph > 10000 {
        set_timewarp(1000).
    }
    else if alph > 1000 {
        set_timewarp(100).
    }
    else if alph > 100 {
        set_timewarp(10).
    }

    print "relative angle: " + ship_target_ang at (0,1).
    print "alph: " + alph at (0,2).
    print "d ship ang: " + d_ship_ang at (0,3).
    wait 0.1.
}

set_timewarp(1).
lock steering to ship:prograde.
wait until steeringsettled().

if not ship:orbit:hasnextpatch {
    set thrott to 1.
    wait until ship:orbit:hasnextpatch.
    set thrott to 0.
}

lock return_orbit to ship:orbit:nextpatch.

clearscreen.

set thrott to 0.5.

until return_orbit:periapsis < 40000 {
    print "return orbit periapsis: " + return_orbit:periapsis at (0,0).
}

set thrott to 0.
clearscreen.
print "on return trajectory".
wait 2.

if not enter_stable_orbit {
    print "press 1 to continue...".
    set input_char to terminal:input:getchar().
    until input_char = "1" {
        set input_char to terminal:input:getchar().
    }
}

ff_to_next_transition().

unlock steering.
unlock throttle.
