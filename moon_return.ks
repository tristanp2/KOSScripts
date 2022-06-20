runpath("utilities.ks").

declare parameter max_return_orbit_periapsis to 40000.

lock system_outward_vec to ship:body:position - ship:body:orbit:body:position.
lock body_retrograde to -(ship:body:velocity:orbit:normalized - ship:body:orbit:body:velocity:orbit)..
lock ship_current_ang to abs(vang(body_retrograde, ship:velocity:orbit)).

lock garb_eta to ship:orbit:period / 360 * ship_current_ang.


set last_ang to ship_current_ang. 
wait 0.1.
set increasing to true.

clearscreen.
print "waiting for good orbital velocity".

until false {
    if increasing and ship_current_ang < last_ang {
        set increasing to false.
    }
    else if not increasing and ship_current_ang > last_ang 
    {
        break.
    }

    print "current ang: " + ship_current_ang at (0,1).
    print "increasing: " + increasing at (0,2).
    print "garb_eta: " + garb_eta at (0,3).

    set_warp_for_eta(garb_eta).
    set last_ang to ship_current_ang.
    wait 0.1.
}

set_timewarp(1).
wait 3.
clearscreen.
print "gud?".

lock steering to ship:prograde.

wait 3.
wait until steeringsettled().

if not ship:orbit:hasnextpatch {
    set throttle to 1.
    wait until ship:orbit:hasnextpatch.
    set throttle to 0.
}

lock return_orbit to ship:orbit:nextpatch.

clearscreen.

set throttle to 0.5.

until return_orbit:periapsis < max_return_orbit_periapsis {
    print "return orbit periapsis: " + return_orbit:periapsis at (0,0).
}

set throttle to 0.
clearscreen.
print "on return trajectory".
wait 2.

ff_to_next_transition().

unlock steering.
unlock throttle.
