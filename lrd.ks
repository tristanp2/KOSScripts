declare parameter target_name.

//just to check it exists before launch
set test to vessel(target_name).

run launch.

run rendezvous(target_name).

run dock(target_name).
