declare function clamp {
	declare parameter value.
	declare parameter range_low.
	declare parameter range_high.
	
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
	return steeringmanager:angleerror < max_error.
}