/datum/movespeed_modifier/config_walk_run/sprint/sync()
	var/mod = CONFIG_GET(number/movedelay/sprint_delay)
	multiplicative_slowdown = isnum(mod)? mod : initial(multiplicative_slowdown)
