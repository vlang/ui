module ui

//---
// A Composable Widget is concretely a Layout (Stack, Group or CanvasLayout) to be added to the window children tree (sort of DOM).
// A Component is the struct gathering:
//  1) the unique composable widget ( i.e this unique root layout)
//  2) the children of this root layout (i.e. widgets or sub-components). N.B.: the other sub-layouts possibly used in the root layout children tree are not in the component struct.
// All composable widget and children widgets/sub-components have a unique field `component` corresponding to this Component structure.
// All members (layout and children) are then all connected.
// Remark: To become possibly a member of a parent component, a component has to have this field `component` to be connected to 
//---

interface Component {
mut:
	component voidptr
}

// Only layout can contain component type
pub fn (s &Stack) component_type() string {
	return s.component_type
}

pub fn (s &Group) component_type() string {
	return s.component_type
}

pub fn (s &CanvasLayout) component_type() string {
	return s.component_type
}

// All the component could be listed here to have an overall of all components
pub fn component_doublelistbox(w Component) &DoubleListBox {
	return &DoubleListBox(w.component)
}
