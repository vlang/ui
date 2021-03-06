module ui

import time

// Inspiration from 2048 game

struct Pos {
	x int = -1
	y int = -1
}

struct TouchInfo {
mut:
	start  Touch
	move   Touch
	end    Touch
	button int
}

struct Touch {
mut:
	pos  Pos
	time time.Time
}
