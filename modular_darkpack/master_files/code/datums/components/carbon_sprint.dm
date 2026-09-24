///The grace period where you can stop sprinting but still be considered sprinting
#define STAMINA_SUSTAINED_RUN_GRACE (0.5 SECONDS)
///The amount of tiles you need to move to be considered moving in a sustained sprint
#define STAMINA_SUSTAINED_SPRINT_THRESHOLD 8
///How to calculate how much stamina is taken per tile while sprinting, With current numbers, lvl 1 is 5.5, lvl 5 is 2.3
#define STAMINA_SPRINT_COST 4

/datum/component/carbon_sprint
	var/mob/living/carbon/carbon_parent
	var/sprinting = FALSE
	var/sustained_moves = 0
	var/last_dust

	///Our very own dust
	var/obj/effect/sprint_dust/dust = new(null)

/datum/component/carbon_sprint/Destroy(force)
	QDEL_NULL(dust)
	return ..()

/datum/component/carbon_sprint/RegisterWithParent()
	. = ..()
	carbon_parent = parent
	RegisterSignal(carbon_parent, COMSIG_KB_CARBON_SPRINT_DOWN, PROC_REF(keyDown))
	RegisterSignal(carbon_parent, COMSIG_KB_CARBON_SPRINT_UP, PROC_REF(keyUp))

/datum/component/carbon_sprint/UnregisterFromParent()
	. = ..()
	UnregisterSignal(carbon_parent, COMSIG_MOB_CLIENT_PRE_MOVE)
	UnregisterSignal(carbon_parent, COMSIG_KB_CARBON_SPRINT_DOWN)
	UnregisterSignal(carbon_parent, COMSIG_KB_CARBON_SPRINT_UP)

/datum/component/carbon_sprint/proc/onMobMove(datum/source, list/move_args)
	var/direct = move_args[MOVE_ARG_DIRECTION]
	if(SEND_SIGNAL(carbon_parent, COMSIG_CARBON_PRE_SPRINT) & INTERRUPT_SPRINT)
		if(sprinting)
			stopSprint()
		return

	if(HAS_TRAIT(carbon_parent, TRAIT_NO_SPRINT))
		stopSprint()
		return

	//leave them with a little bit of stamina left
	if(!HAS_TRAIT(carbon_parent, TRAIT_NO_SPRINT) && (carbon_parent.staminaloss >= 90))
		ADD_TRAIT(carbon_parent, TRAIT_NO_SPRINT, STAMINA)
		to_chat(carbon_parent, span_warning("You feel exhausted from a lack of stamina..."))
		return

	var/_step_size = (direct & (direct-1)) ? 1.4 : 1 //If we're moving diagonally, we're taking roughly 1.4x step size
	if(!sprinting)
		sprinting = TRUE
		carbon_parent.set_move_intent(MOVE_INTENT_SPRINT)
		dust.appear("sprint_cloud", direct, get_turf(carbon_parent), 0.6 SECONDS)
		last_dust = world.time
		sustained_moves += _step_size

	else if(world.time > last_dust + STAMINA_SUSTAINED_RUN_GRACE)
		if(direct & carbon_parent.last_move)
			if((sustained_moves < STAMINA_SUSTAINED_SPRINT_THRESHOLD) && ((sustained_moves + _step_size) >= STAMINA_SUSTAINED_SPRINT_THRESHOLD))
				dust.appear("sprint_cloud_small", direct, get_turf(carbon_parent), 0.4 SECONDS)
				last_dust = world.time
			sustained_moves += _step_size

		else
			if(sustained_moves >= STAMINA_SUSTAINED_SPRINT_THRESHOLD)
				dust.appear("sprint_cloud_small", direct, get_turf(carbon_parent), 0.4 SECONDS)
				last_dust = world.time
			if(direct & turn(carbon_parent.last_move, 180))
				dust.appear("sprint_cloud_tiny", direct, get_turf(carbon_parent), 0.3 SECONDS)
				last_dust = world.time
			sustained_moves = 0

	//We set forced to TRUE because we want sprinting to override TRAIT_STUNIMMMUNE, which makes you immune to all other stamina damage.
	carbon_parent.apply_damage((STAMINA_SPRINT_COST / carbon_parent.st_get_stat(STAT_STAMINA)) + 1.5, STAMINA, forced = TRUE)

/datum/component/carbon_sprint/proc/keyDown()
	RegisterSignal(carbon_parent, COMSIG_MOB_CLIENT_PRE_MOVE, PROC_REF(onMobMove))

/datum/component/carbon_sprint/proc/keyUp()
	UnregisterSignal(carbon_parent, COMSIG_MOB_CLIENT_PRE_MOVE)
	//You'll have to release and re-press to start sprinting again.
	REMOVE_TRAIT(carbon_parent, TRAIT_NO_SPRINT, STAMINA)

/datum/component/carbon_sprint/proc/stopSprint()
	sprinting = FALSE
	sustained_moves = FALSE
	last_dust = null
	carbon_parent.set_move_intent(MOVE_INTENT_RUN)

/obj/effect/sprint_dust
	icon = 'goon/icons/effects.dmi'
	icon_state = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/sprint_dust/proc/appear(state, dir, turf/T, duration)
	if(!T)
		return
	if(state == "sprint_cloud")
		src.dir = SOUTH
	src.dir ||= dir
	abstract_move(T)
	flick(state, src)
	if(!QDELETED(src))
		addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, moveToNullspace)), duration)

/datum/keybinding/living/sprint
	hotkey_keys = list("Shift")
	name = "Sprint"
	full_name = "Sprint"
	description = "Move fast at the cost of stamina"
	keybind_signal = COMSIG_KB_CARBON_SPRINT_DOWN

/datum/keybinding/living/sprint/up(client/user)
	. = ..()
	if(.)
		return
	SEND_SIGNAL(user.mob, COMSIG_KB_CARBON_SPRINT_UP)

#undef STAMINA_SUSTAINED_RUN_GRACE
#undef STAMINA_SUSTAINED_SPRINT_THRESHOLD
#undef STAMINA_SPRINT_COST

/mob/living/carbon
/*
	var/sprinting = FALSE
	///How many tiles we have continuously moved in the same direction
	var/sustained_moves = 0
*/
