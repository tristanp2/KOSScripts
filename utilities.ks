set INFINITY to 3.402823e38.

function set_timewarp {
    declare parameter target_rate.

    if kuniverse:timewarp:rate <> target_rate {
        set kuniverse:timewarp:rate to target_rate.
    }
}
function set_warp_for_eta {
    declare parameter target_eta.
    local warp to 1.
    if target_eta > 10000 {
        set warp to 10000.
    }
    else if target_eta > 1000 {
        set warp to 1000.
    }
    else if target_eta > 100 {
        set warp to 100.
    }
    else if target_eta > 50 {
        set warp to 50.
    }
    else if target_eta > 10 {
        set warp to 10.
    }
    else {
        set warp to 1.
    }

    set_timewarp(warp).
    return warp.
}

function surface_normal {
    declare parameter pos.
    local target_body to ship:body.

    local up_vec to (pos - target_body:position):normalized.
    local north_vec to vxcl(up_vec, latlng(90,0):position - pos):normalized * 3.
    local side_vec to vcrs(up_vec, north_vec):normalized * 3.

    local a_pos to target_body:geopositionof(pos - north_vec + side_vec):position.
    local b_pos to target_body:geopositionof(pos - north_vec - side_vec):position.
    local c_pos to target_body:geopositionof(pos + north_vec):position.

    return vcrs(a_pos - c_pos, b_pos - c_pos):normalized.
}

function surface_angle {
    declare parameter pos.

    local radial to pos - ship:body:position.
    local normal to surface_normal(pos).

    return vang(normal, radial).
}

function sample_surface_angle {
    declare parameter pos.
    declare parameter sample_distance to 1000.
    declare parameter num_samples to 4.

    local target_body to ship:body.

    local up_vec to (pos - target_body:position):normalized.
    local base_north_vec to vxcl(up_vec, latlng(90,0):position - pos):normalized.
    local base_side_vec to vcrs(up_vec, base_north_vec):normalized.
    local angle_sum to 0.

    from {local i to 1.} until i > num_samples step {set i to i + 1.} do {
        local dist to sample_distance * i / num_samples.
        local north_vec to base_north_vec * dist.
        local side_vec to base_side_vec * dist.
        local a_pos to pos - north_vec + side_vec.
        local b_pos to pos - north_vec - side_vec.
        local c_pos to pos + north_vec.
        local a_ang to surface_angle(a_pos).
        local b_ang to surface_angle(b_pos).
        local c_ang to surface_angle(c_pos).
        local avg_ang to (a_ang + b_ang + c_ang) / 3.
        set angle_sum to angle_sum + avg_ang.
    }
    return angle_sum / num_samples.
}

function ff_to_next_transition {
    declare parameter break_time to 10.
    until eta:transition < break_time {
        set_warp_for_eta(eta:transition).
    }
    set_timewarp(1).
}

function ff_to_periapsis {
    declare parameter break_time to 10.
    until eta:periapsis < break_time {
        set_warp_for_eta(eta:periapsis).
    }
    set_timewarp(1).
}

declare function clamp {
	declare parameter value.
	declare parameter range_low to 0.
	declare parameter range_high to 1.
	
	if value < range_low{
		return range_low.
	}
	if value > range_high{
		return range_high.
	}
	return value.
}
declare function applydeadband {
	declare parameter value.
	declare parameter min_value to -0.1.
	declare parameter max_value to 0.1.
	
	if value > min_value and value < max_value {
		return 0.
	}
	return value.
}
declare function flameoutoccured {
	declare parameter eng_list.
	for eng in eng_list{
		if eng:flameout{
			return true.
		}
	}
	return false.
}

declare function enable_stage_trigger {
    when stage:ready and (flameoutoccured(englist) or maxthrust = 0) then{
        stage.
        list engines in englist.
        return true.
    }
}

declare function steeringsettled {
	declare parameter max_error to 5.
	return abs(steeringmanager:angleerror) < max_error and abs(steeringmanager:rollerror) <  max_error.
}

//hill climbs to find the impact time and site
//returns a lexicon with the following keys: pos, geopos, eta, iter
//iter corresponds to the number of iterations used to find the impact site
//the loop here will compute for forever if the ship is thrusting
//this is because the positionat prediction function uses the current frame's estimated trajectory,
// not taking into account acceleration aside from gravity, so the narrowing of the search becomes invalid.
//
//if no value is found in < iter_limit iterations, the function returns an empty lexicon
function impact_pos_eta {
	declare parameter iter_limit to 120.
	declare parameter min_step to 0.01.
	
	local time_step_base to 60.
	local dir to 1.
	local init_time to time:seconds.
	local current_time to init_time.
	local alph to 1.0.
	lock time_step to time_step_base * alph.
	local iteration to 0.
	local pos_above to true.
	until iteration > iter_limit {
		local pos to positionat(ship, current_time).
		local geopos to ship:body:geopositionof(pos).
		local terrain_height to geopos:terrainheight.
		local pos_alt to ship:body:altitudeof(pos).
		
		local diff to pos_alt - terrain_height.
		
		// pos has just gone below terrain
		if diff < 0 and pos_above {
			set alph to alph / 2.
			set pos_above to false.
			set dir to -1.
		}
		// pos is above terrain
		else if diff > 0 and not pos_above {
			set alph to alph / 2.
			set pos_above to true.
			set dir to 1.
		}
		
		if time_step < min_step {
			return lexicon("pos", pos,"geopos", geopos, "eta", current_time - init_time, "iter", iteration).
		}	
		
		set current_time to current_time + dir*time_step.
		set iteration to iteration + 1.
	}
	return lexicon().
}
