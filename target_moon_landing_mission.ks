function copy_file {
    parameter file_name.
    parameter source_path.
    
    copypath(source_path + file_name, "").
    print "copied: " + file_name.
}

set source_folder to "0:/KOSScripts/".

if homeconnection:isconnected {
    copy_file("launch.ks", source_folder).
    copy_file("transfer.ks", source_folder).
    copy_file("utilities.ks", source_folder).
    copy_file("soi_entry_orbit.ks", source_folder).
    copy_file("target_land.ks", source_folder).
    copy_file("vacuum_launch.ks", source_folder).
    copy_file("basic_reentry.ks", source_folder).
    copy_file("moon_return.ks", source_folder).
}
else {
    print "no home connection available".
    wait 3.
}


set landing_target_name to "Flag1".
set landing_target to vessel(landing_target_name).
set target_body_name to landing_target:body:name. 

print "landing target " + landing_target_name + " found on body " + target_body_name.
wait 4.

if ship:status = "PRELAUNCH" {
    list.
    wait 4.

    clearscreen.
    runpath("launch.ks").
    wait 2.
    clearscreen.
    runpath("transfer.ks", target_body_name).
    wait 2.
    clearscreen.
    runpath("soi_entry_orbit.ks", target_body_name).

    wait 2.
    clearscreen.
    runpath("target_land.ks", landing_target_name).

    print "press 1 to continue...".
    set input_char to terminal:input:getchar().
    until input_char = "1" {
        set input_char to terminal:input:getchar().
    }

    runpath("vacuum_launch.ks", 15000).
    
    wait 2.
    runpath("moon_return.ks").

    wait 2.
    runpath("basic_reentry.ks", 1).
} 
else if ship:status = "ORBITING" and ship:body:name = target_body_name {
    clearscreen.
    runpath("target_land.ks", landing_target_name).

    print "press 1 to continue...".
    set input_char to terminal:input:getchar().
    until input_char = "1" {
        set input_char to terminal:input:getchar().
    }

    runpath("vacuum_launch.ks", 15000).
    
    wait 2.
    runpath("moon_return.ks").

    wait 2.
    runpath("basic_reentry.ks", 1).
}
else if ship:status = "LANDED" and ship:body:name = target_body_name {
    clearscreen.
    print "press 1 to continue...".
    set input_char to terminal:input:getchar().
    until input_char = "1" {
        set input_char to terminal:input:getchar().
    }

    runpath("vacuum_launch.ks", 15000).
    
    wait 2.
    runpath("moon_return.ks").

    wait 2.
    runpath("basic_reentry.ks", 1).
}
else {
    print "ship is not in prelaunch state. exiting...".
}
