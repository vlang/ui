module ui

import time

struct Pos {
	x int = -1
	y int = -1
}

struct TouchInfo {
mut:
	start Touch
	end   Touch
}

struct Touch {
mut:
	pos  Pos
	time time.Time
}
