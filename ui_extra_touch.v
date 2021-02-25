module ui

import time

// Inspiration from 2048 game

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
