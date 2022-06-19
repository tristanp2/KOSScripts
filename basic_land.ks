runpath("utilities.ks").

function find_minimum_surface_angle_geoposition {
    declare parameter sample_pos_list.
    declare parameter sample_dist to 1000.


    local min_sampled_ang to 1000.
    local min_sampled_pos to v(0,0,0).

    for sample_pos in sample_pos_list {
        local sample_ang to sample_surface_angle(sample_pos, sample_dist / 2).
        if sample_ang < min_sampled_ang {
            set min_sampled_ang to sample_ang.
            set min_sampled_pos to sample_pos.
        }
    }
    
    return ship:body:geopositionof(min_sampled_pos).
}

print "update 6".
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


set target_periapsis to 12000.
lock thrott to clamp(abs(ship:orbit:periapsis - target_periapsis) / target_periapsis, 0.1, 0.5). 

print "raising periapsis to " + target_periapsis.
wait until ship:orbit:periapsis > target_periapsis.

set thrott to 0.

wait 2.

print "warping to periapsis".
ff_to_periapsis().

set target_periapsis to -1000.

set_timewarp(1).

wait 2.
wait until steeringsettled().

lock surface_velocity to ship:orbit:velocity:surface.
lock vertical_speed to vdot(ship:up:forevector, surface_velocity).

lock vertical_velocity to vertical_speed * ship:up:forevector.

set steering to ship:retrograde.
clearscreen.
print "reducing periapsis".

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

clearscreen.
print "starting descent".

lock horizontal_velocity to vxcl(ship:up:forevector, surface_velocity).
lock horizontal_speed to horizontal_velocity:mag.
lock ship_accel to ship:availablethrust / ship:mass.

lock vertical_kill_time to abs(vertical_speed) / ship_accel. 
lock horizontal_kill_time to abs(horizontal_speed) / ship_accel.
lock total_kill_time to vertical_kill_time + horizontal_kill_time.

lock center_dist to ship:altitude + ship:body:radius. 
lock g_accel to ship:body:mu / center_dist^2. 
lock altitude to max(alt:radar - 1000, 0).
lock final_speed to sqrt(vertical_speed^2 + 2 * g_accel * altitude).
lock average_speed to 0.5 * (final_speed + vertical_speed).
lock impact_eta to (final_speed - vertical_speed) / g_accel.

lock forward_vec to horizontal_velocity:normalized.
lock side_vec to vcrs(ship:up:forevector, horizontal_velocity):normalized.

set throttle to 0.
lock speed_ratio to min(max(horizontal_speed - vertical_speed, 0) / (horizontal_speed + vertical_speed), 1).
lock steer_val to (1 - speed_ratio) * ship:up:forevector:normalized 
        - speed_ratio
        * horizontal_velocity:normalized.
lock surface_speed to surface_velocity:mag.
set steering to steer_val.
wait until steeringsettled().

until altitude < 2000  {
    set steering to steer_val.

    if impact_eta >  2 * total_kill_time {
        set throttle to 0.
        set_warp_for_eta(impact_eta - 1.5 * total_kill_time).
        print "waiting        " at (0,7).
    }
    else {
        print "adjusting speed" at (0,7).
        set_timewarp(1). 

        if steeringmanager:rollerror < 5 {
            set throttle to min((3 * total_kill_time - impact_eta) / ship_accel, 1).
        } 
        else {
            set throttle to 0.
        }
    }

    print "impact eta: " + impact_eta at (0,3).
    print "total kill time: " + total_kill_time at(0,4).
    print "impact speed: " + final_speed at (0,5).
    print "g accel: " + g_accel at (0,6).
    print "vertical speed: " + vertical_speed at (0,8).
    print "horizontal speed: " + horizontal_speed at (0,9).

    wait 0.1.
}

set_timewarp(1).
print "ded".

lock surface_kill_time to surface_velocity:mag / ship_accel.
lock steering to clamp(-vertical_speed, 0, 1) * ship:up:forevector:normalized - min(0.5, abs(horizontal_speed / vertical_speed)) 
        * horizontal_velocity:normalized.

wait 1.
wait until steeringsettled().
legs on.
lock cast_pos to ship:position - ship:up:forevector * average_speed * impact_eta  + horizontal_velocity * impact_eta.
lock target_speed to max(alt:radar / 10, 1).
lock normal_vec to surface_normal(cast_pos).

set cast_arrow to vecdraw(ship:position, cast_pos, RGB(1,0,0), "cast", 1.0, true, 0.2, true).
set normal_arrow to vecdraw(cast_pos, normal_vec * 400, RGB(0,1,0), "normal", 1.0, true, 0.2, true). 
set draw_period to 2.
set last_draw to time:seconds - draw_period - 1.
set impact_alt to alt:radar + 
        ship:body:geopositionof(ship:position):terrainheight - ship:body:geopositionof(cast_pos):terrainheight.

clearscreen.
until ship:status = "LANDED" {
    if impact_alt < 2500 {
        set throttle to clamp((surface_velocity:mag - target_speed) / max(target_speed, 3), 0, 1).
        set throttle_param to "target speed".
    }
    else {
        set throttle to clamp(surface_kill_time - impact_eta * 0.6, 0, 1).
        set throttle_param to "impact eta".
    }

    if time:seconds - last_draw > draw_period {
        set cast_arrow:vec to cast_pos.
        set normal_arrow:start to cast_pos.
        set normal_arrow:vec to normal_vec * 400.
        set last_draw to time:seconds.
        set impact_alt to alt:radar + 
                ship:body:geopositionof(ship:position):terrainheight - 
                ship:body:geopositionof(cast_pos):terrainheight.
        print "sampled impact surface ang: " + sample_surface_angle(cast_pos, cast_pos:mag) at (0,7). 
        print "impact alt: " + impact_alt at (0,8).
    }

    print "throttle param: " + throttle_param + "        " at (0,0).
    print "surface speed: " + surface_velocity:mag at (0,1).
    print "altitude: " + alt:radar at (0,2).
    print "impact eta: " + impact_eta at (0,3).
    print "total kill time: " + total_kill_time at (0,4).
    print "target speed: " + target_speed at (0,5).
    print "surface speed: " + surface_velocity:mag at(0,6).
    print "vertical speed: " + vertical_speed at (0,9).
    wait 0.1.
}

print "landed".

unlock steering.
unlock throttle.
set sas to true.
