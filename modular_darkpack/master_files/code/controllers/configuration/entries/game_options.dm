/datum/config_entry/number/max_save_slots
	protection = CONFIG_ENTRY_LOCKED
	default = 5
	min_val = 1
	max_val = 30

/datum/config_entry/number/extra_save_slots_byond_member
	protection = CONFIG_ENTRY_LOCKED
	default = 5
	min_val = 5
	max_val = 50

/datum/config_entry/number/hunger_modifier
	default = 0.5

/datum/config_entry/number/movedelay/sprint_delay
	integer = FALSE

/datum/config_entry/number/movedelay/sprint_delay/ValidateAndSet()
	. = ..()
	var/datum/movespeed_modifier/config_walk_run/M = get_cached_movespeed_modifier(/datum/movespeed_modifier/config_walk_run/sprint)
	M.sync()
