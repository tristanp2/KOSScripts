runpath("utilities.ks").

declare parameter descent_stage to 1.

set sas to false.
set rcs to false.
set target_periapsis to 40000.
set thrott to 0.
lock throttle to thrott.

if ship:periapsis > target_periapsis {
    set steer_val to ship:retrograde.
    lock steering to steer_val.

    wait 1.
    wait until steeringsettled().

    set thrott to 0.5.


    print "reducing periapsis".

    wait until ship:periapsis < target_periapsis.
}

set thrott to 0.

wait 2.



print "warping to atmo".

until ship:altitude < 70000 {
    set_warp_for_eta(eta:periapsis).
}


print "descending".

print "current stage: " + stage:number.
print "descent stage: " + descent_stage.
until stage:number <= descent_stage {
    print "staging...".
    stage.
    wait 1.
}

print "locking to retrograde".
lock steering to ship:retrograde.

when (not chutessafe) then {
    chutessafe on.
    unlock steering.
    print "deploying safe chutes".
    return (not chutes).
}

wait until ship:altitude < 10000.
print "unlocking steering".
unlock steering.

wait until ship:status = "LANDED" or ship:status = "SPLASHED".
print "landed".
