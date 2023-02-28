#!/usr/bin/env -S v

import json
import os

mut demos := map[string]string{}

dir := os.join_path(os.dir(@FILE), '..', 'demo')
json_file := os.join_path(os.dir(@FILE), 'demos.json')
os.chdir(dir)!
for demo in os.walk_ext('.', '_ui.vv') {
	tmp := demo.split(os.path_separator)
	tmp2 := tmp#[1..]
	tmp3 := tmp2.join(os.path_separator)
	demos[tmp3#[..-6]] = os.read_file(demo)!
}

os.write_file(json_file, json.encode(demos))!
