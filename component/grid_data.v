module component

// TODO: put outside if useful if vlib?

type DataType = int | string

// type Data = []bool | []int | []string

struct RankedData {
mut:
	i   int
	val DataType
}

fn (gd GridVar) ranked_data() []RankedData {
	mut rd := []RankedData{}
	for i, v in gd.data() {
		rd << RankedData{i, v}
	}
	return rd
}

pub fn (gd GridVar) idx_sorted() []int { //([]int, map[int]int) {
	// mut m := map[int]int{}

	mut arr := gd.ranked_data()
	arr.sort_with_compare(fn (a &RankedData, b &RankedData) int {
		match a.val {
			int {
				if b.val is int {
					if a.val < b.val {
						return -1
					} else if a.val > b.val {
						return 1
					} else {
						return 0
					}
				}
			}
			string {
				if b.val is string {
					if a.val < b.val {
						return -1
					} else if a.val > b.val {
						return 1
					} else {
						return 0
					}
				}
			}
		}
	})
	// for i, rv in arr {
	// 	m[rv.i] = i
	// }
	sa := arr.map(it.i)
	return sa //, m
}
