set script_version to "target_land0.2".
print "script_version: " + script_version.

set sas to false.

declare parameter target_vessel_name.
declare parameter descent_stage to 2.

until stage:number <= descent_stage {
    stage.
    wait 1.
}

runpath("utilities.ks").
enable_stage_trigger().

clearscreen.
print "starting descent".

set target_vessel to vessel(target_vessel_name).
set target to target_vessel.

lock initial_target_pos to target_vessel:position + target_vessel:up:forevector * 3000.
set initial_target_periapsis to target_vessel:altitude + 3000.

print "initial target periapsis: " + initial_target_periapsis.

set initial_burn_lng to mod(target_vessel:geoposition:lng + 360, 360).

lock lng_diff to abs(mod(ship:geoposition:lng + 540 - initial_burn_lng, 360)).

print "warping to target longitude of " + initial_burn_lng.

until lng_diff < 5 {
    if lng_diff > 180 {
        set_timewarp(100).
    }
    else if lng_diff > 45 {
        set_timewarp(50).
    } else if lng_diff > 10 {
        set_timewarp(10).
    }
    else {
        set_timewarp(5).
    }


    print "lng_diff: " + lng_diff at (0,3).
    print "initial_burn_lng: " + initial_burn_lng at (0,4).
    print "ship lng: " + (ship:geoposition:lng + 180) at (0,5).
    wait 0.1.
}

set_timewarp(0).
wait 2.

set thrott to 0.
lock throttle to thrott.
set steer_val to ship:retrograde.
lock steering to steer_val.

wait 3.

print "waiting for steering to settle".
wait until steeringsettled(2).

clearscreen.
print "reducing periapsis to " + initial_target_periapsis.

until ship:periapsis < initial_target_periapsis {
    set thrott to clamp((ship:periapsis - initial_target_periapsis) / ship:periapsis, 0.1, 1).

    print "thrott: " + thrott at (0,1).
    print "periapsis: " + ship:periapsis at (0,2).
    print "target periapsis: " + initial_target_periapsis at (0,3).
    wait 0.1.
}

set thrott to 0.

lock surface_velocity to ship:orbit:velocity:surface.
lock vertical_speed to vdot(ship:up:forevector, surface_velocity).

lock vertical_velocity to vertical_speed * ship:up:forevector.

lock horizontal_velocity to vxcl(ship:up:forevector, surface_velocity).
lock horizontal_speed to horizontal_velocity:mag.
lock ship_accel to ship:availablethrust / ship:mass.

lock vertical_kill_time to abs(vertical_speed) / ship_accel. 
lock horizontal_kill_time to abs(horizontal_speed) / ship_accel.
lock total_kill_time to vertical_kill_time + horizontal_kill_time.

lock surface_speed to surface_velocity:mag.
lock target_pos to target_vessel:position + target_vessel:up:forevector * 1500.
lock target_eta to target_pos:mag / surface_speed.

until target_eta < total_kill_time * 1.2 {
    set_timewarp(eta:periapsis - total_kill_time * 1.2).


    print "wait until " + (total_kill_time * 1.2) + "s to target" at (0,1).
    print "target_eta: " + target_eta at (0,2).
    wait 0.1.
}

set_timewarp(0).

lock center_dist to ship:altitude + ship:body:radius. 
lock g_accel to ship:body:mu / center_dist^2. 
lock altitude to max(alt:radar - 1000, 0).
lock final_speed to sqrt(vertical_speed^2 + 2 * g_accel * altitude).
lock average_speed to 0.5 * (final_speed + vertical_speed).
lock impact_eta to (final_speed - vertical_speed) / g_accel.

lock forward_vec to horizontal_velocity:normalized.
lock side_vec to vcrs(ship:up:forevector, horizontal_velocity):normalized.

set throttle to 0.
set target_altitude to ship:altitude.

lock target_velocity to vxcl(ship:up:forevector, (target_eta * ship_accel) * target_pos:normalized).
lock correction_vector to target_velocity - surface_velocity.
lock steer_val to lookdirup(correction_vector, ship:facing:topvector).

wait until steeringsettled().
clearscreen.

until horizontal_speed < 10 {
    set throttle to clamp(correction_vector:mag / 30, 0, 1).
    set steering to steer_val.

    print "horizontal_speed: " + horizontal_speed at (0,0).
    print "vertical_speed: " + vertical_speed at (0,1).
    print "correction mag: " + correction_vector:mag at (0,2).
    print "target_eta: " + target_eta at (0,3).
    print "vertical kill time: " + vertical_kill_time at (0,4).
    print "horizontal kill time: " + horizontal_kill_time at (0,5).

    wait 0.1.
}

clearscreen.
print "final descent".
legs on.

lock target_position to target_vessel:position + target_vessel:north:forevector * 10.
lock target_distance to target_position:mag.
lock target_eta to target_distance / vertical_speed.
lock horizontal_target_vector to vxcl(target_vessel:up:forevector, target_position).
lock horizontal_target_distance to horizontal_target_vector:mag.

lock target_horizontal_speed to clamp(horizontal_target_distance / 20, 0 , 100).
lock target_horizontal_velocity to target_horizontal_speed * horizontal_target_vector:normalized.

set target_vertical_speed to vertical_speed. 

lock target_velocity to target_horizontal_velocity + target_vertical_speed * ship:up:forevector.
lock correction_vector to target_velocity - surface_velocity.
lock correction_burn_time to correction_vector:mag / ship_accel.

lock steer_val to correction_vector.

wait until steeringsettled().

until ship:status = "LANDED" {
    print "target_distance: " + target_distance at (0,1).
    print "horizontal distance: " + horizontal_target_distance at (0,2).
    print "horizontal correction vector mag: " + correction_vector:mag at (0,3).
    print "vertical speed: " + vertical_speed at (0,4).
    print "target vertical speed: " + target_vertical_speed at (0,5).
    print "horizontal speed: " + horizontal_speed at (0,6).
    print "target_horizontal_speed: " + target_horizontal_speed at (0,7).

    set ideal_vertical_speed to -target_distance / 10.
    set target_vertical_speed to choose ideal_vertical_speed if ideal_vertical_speed > vertical_speed else vertical_speed.

    if alt:radar < 10 {
        set impact_eta to alt:radar / vertical_speed.
        set vertical_accel to vertical_speed / impact_eta.
        set horizontal_eta to horizontal_target_distance / horizontal_speed.
        set horizontal_accel to horizontal_speed / horizontal_eta.

        set throttle to sqrt(vertical_accel^2 + horizontal_accel^2) / ship_accel.
    }
    else {
        set throttle to clamp(correction_burn_time, 0, 1).
        set steering to steer_val.
    }

    wait 0.1.
}

print "landed".

set thrott to 0.
unlock steering.
unlock throttle.
set sas to true.
