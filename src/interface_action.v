module ui

// Adding actions field for a Widget or Component (having id field) makes it react as user-dedined actions
// see tool_key for parsing action as string

// This provides user defined action actions (see grid and grid_data as a use case)
pub type ActionFn = fn (context voidptr)

pub type Actions = map[string]Action

pub struct Action {
pub mut:
	action_fn ActionFn = unsafe { nil }
	context   voidptr
}

pub interface Actionable {
	id string
mut:
	actions Actions
}

// TODO: documentation
pub fn (mut s Actionable) add_action(action string, context voidptr, action_fn ActionFn) {
	s.actions[action] = Action{
		context:   context
		action_fn: action_fn
	}
}

// TODO: documentation
pub fn (s &Actionable) run_action(action string) {
	if a := s.actions[action] {
		a.action_fn(a.context)
	}
}
