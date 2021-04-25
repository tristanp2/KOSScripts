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

wait 2.

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

lock system_radial_v to ship:position - ship:body:orbit:body:position.
lock ship_target_ang to abs(vang(system_outward_vec, system_radial_v)).

clearscreen.
print "warping to next burn point".
set last_ship_ang to ship_target_ang.
set last_d_ship_ang to 1.
set delta_t to 0.
lock d_ship_ang to abs(ship_target_ang - last_ship_ang) * 0.7 + last_d_ship_ang * 0.3.
until ship_target_ang < 0.1 {
    set delta_t to time:seconds - delta_t.
    set d_ship_ang to abs(ship_target_ang - last_ship_ang) / delta_t * 0.7 + last_d_ship_ang * 0.3.
    set alph to ship_target_ang / d_ship_ang.
    set last_d_ship_ang to d_ship_ang.
    set last_ship_ang to ship_target_ang.
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

lock return_orbit to ship:orbit:nextpatch.
lock steering to ship:prograde.

wait until steeringsettled().

clearscreen.

set thrott to 0.5.

until return_orbit:periapsis < 40000 {
    print "return orbit periapsis: " + return_orbit:periapsis at (0,0).
}

set thrott to 0.
clearscreen.
print "on return trajectory".
wait 2.

print "press 1 to continue...".
set input_char to terminal:input:getchar().
until input_char = "1" {
    set input_char to terminal:input:getchar().
}

ff_to_next_transition().

unlock steering.
unlock throttle.
