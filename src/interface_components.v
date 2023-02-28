module ui

//---
// A Composable Widget is concretely a Layout (Stack, Group or CanvasLayout) to be added to the window children tree (sort of DOM).
// A Component is the struct gathering ComponentChild:
//  1) the unique composable widget ( i.e this unique root layout)
//  2) the children of this root layout (i.e. widgets or sub-components). N.B.: the other sub-layouts possibly used in the root layout children tree are not in the component struct.
// All composable widget and children widgets/sub-components have a unique field `component` corresponding to this Component structure.
// All members (layout and children) are then all connected as ComponentChild having `component` field.
// Remark: To become possibly a member of a parent component, a component has to have this field `component` to be connected to
//---

const (
	component_sep = '/' // ':::'
)

pub interface ComponentChild {
mut:
	id string
	component voidptr
}

// TODO: documentation
pub fn component_connect(comp voidptr, children ...ComponentChild) {
	mut c := children.clone()
	for mut child in c {
		child.component = comp
	}
}

// to ensure homogeneity for name related to component
pub fn component_id(id string, parts ...string) string {
	mut part_id := [id]
	part_id << parts.clone()
	return part_id.join(ui.component_sep)
}

// TODO: documentation
pub fn component_parent_id(part_id string) string {
	return part_id.split(ui.component_sep)#[..-1].join(ui.component_sep)
}

// TODO: documentation
pub fn component_id_from(from_id string, id string) string {
	return component_id(component_parent_id(from_id), id)
}

// TODO: documentation
pub fn component_parent_id_by(part_id string, level int) string {
	return part_id.split(ui.component_sep)#[..-level].join(ui.component_sep)
}

// TODO: documentation
pub fn component_id_from_by(from_id string, level int, id string) string {
	return component_id(component_parent_id_by(from_id, level), id)
}
