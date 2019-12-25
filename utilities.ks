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
	declare parameter iter_limit to 50.
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