function copy_if_missing {
    parameter file_name.
    parameter source_path.
    
    if not exists(file_name) {
        copypath(source_path + file_name, "").
    }
}

if ship:status  "PRELAUNCH" {
    set source_folder to "0:/KOSScripts/".

    copy_if_missing("launch.ks", source_folder).
    copy_if_missing("utilities.ks", source_folder).
    copy_if_missing("basic_reentry.ks", source_folder).

    runpath("launch.ks").

    print "starting reeentry in 30s".
    wait 30.

    runpath("basic_reentry.ks").
} 
else {
    print "ship is not in prelaunch state. exiting...".
}
