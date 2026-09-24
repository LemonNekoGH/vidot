extends SceneTree

var tree: SceneTree
var _collect_only = false
var _argument_error = ""
var _files: Array = []
var _test_name_pattern = null
var _current_file = ""
var _current_module: RefCounted = null
var _root_task
var _suite_stack: Array = []
var _next_task_id: int = 1
var _active_errors: Array = []
var _file_errors: Array = []
var _baseline_nodes: Dictionary = {}

func _initialize() -> void:
	self.tree = self
	self.process_frame.connect(self._run)

func _run():
	self.process_frame.disconnect(self._run)
	self._read_arguments()
	if not self._argument_error.is_empty():
		self._emit({
			"type": "runner_error",
			"message": self._argument_error,
		})
		self.quit()
		return
	for child in self.root.get_children():
		self._baseline_nodes[child.get_instance_id()] = true
	for file in self._files:
		var started_at = Time.get_ticks_msec()
		if not self._collect(file):
			self._emit_file_finish(started_at)
			continue
		if not self._collect_only:
			await self._run_suite(self._root_task, [])
			await self._cleanup_test_nodes()
			self._emit_file_finish(started_at)
		self._current_module = null
		self._root_task.clear()
	self._emit({
		"type": "run_finish",
	})
	self.quit()

func _read_arguments() -> void:
	var test_name = ""
	for argument in OS.get_cmdline_user_args():
		if argument == "--vidot-collect":
			self._collect_only = true
		elif argument.begins_with("--vidot-test-name-pattern="):
			var source = argument.trim_prefix("--vidot-test-name-pattern=")
			var pattern = ClassDB.instantiate("RegEx")
			var error = pattern.compile.call(source)
			if error != Error.OK:
				self._argument_error = "could not compile test name pattern (error " + str(error) + ")"
				continue
			self._test_name_pattern = pattern
		elif argument.begins_with("--vidot-test-name="):
			test_name = argument.trim_prefix("--vidot-test-name=")
		elif argument.begins_with("--vidot-test="):
			if test_name.is_empty():
				self._argument_error = "--vidot-test must follow --vidot-test-name"
				continue
			self._files.append({
				"name": test_name,
				"path": argument.trim_prefix("--vidot-test="),
			})
			test_name = ""

func _collect(file) -> bool:
	self._current_file = file.get("path")
	self._file_errors = []
	self._next_task_id = 1
	self._suite_stack.clear()
	self._root_task = self._new_suite(file.get("name"))
	self._suite_stack = [self._root_task]
	var loaded = self._load_test_script(file.get("path"))
	if loaded.get("script") == null:
		self._file_errors.append(self._error(loaded.get("error")))
		self._emit_collected()
		return false
	self._current_module = loaded.script.new() as RefCounted
	if self._current_module == null or not self._current_module.has_method("vidot_collect"):
		self._file_errors.append(self._error("generated test module must define vidot_collect(api)"))
		self._emit_collected()
		return false
	self._current_module.call("vidot_collect", self)
	if self._test_name_pattern != null:
		self._filter_task(self._root_task, "", self._test_name_pattern)
	self._emit_collected()
	return true

func _load_test_script(file: String):
	if file.begins_with("res://") or file.begins_with("user://"):
		var resource = load(file)
		if resource is GDScript:
			return {
				"script": resource,
				"error": "",
			}
		return {
			"script": null,
			"error": "could not load test script " + str(file),
		}
	if not FileAccess.file_exists(file):
		return {
			"script": null,
			"error": "test script does not exist: " + str(file),
		}
	var script = GDScript.new()
	script.source_code = FileAccess.get_file_as_string(file)
	var reload_error = script.reload()
	if reload_error != Error.OK:
		return {
			"script": null,
			"error": "could not compile test script " + str(file) + " (error " + str(reload_error) + ")",
		}
	return {
		"script": script,
		"error": "",
	}

func describe(name: String, callback: Callable) -> void:
	var suite = self._new_suite(name)
	self._suite_stack.back().children.append(suite)
	self._suite_stack.append(suite)
	callback.call()
	self._suite_stack.pop_back()

func test(name: String, callback: Callable) -> void:
	self._suite_stack.back().children.append({
		"id": self._take_task_id(),
		"name": name,
		"mode": "run",
		"type": "test",
		"callback": callback,
	})

func beforeAll(callback: Callable) -> void:
	self._suite_stack.back().before_all.append(callback)

func beforeEach(callback: Callable) -> void:
	self._suite_stack.back().before_each.append(callback)

func afterEach(callback: Callable) -> void:
	self._suite_stack.back().after_each.append(callback)

func afterAll(callback: Callable) -> void:
	self._suite_stack.back().after_all.append(callback)

func expect(actual) -> Expectation:
	return self.Expectation.create(self, actual)

func record_assertion(message: String) -> void:
	self._active_errors.append(self._error(message, "AssertionError"))

func instantiate(path: String):
	var loaded = self._load_test_script(path)
	if loaded.get("script") == null:
		self.record_assertion(loaded.get("error"))
		return null
	var instance = loaded.script.new()
	if instance == null:
		self.record_assertion("could not instantiate script " + str(path))
		return null
	return instance

func waitUntil(predicate: Callable, timeoutMs: int) -> bool:
	var deadline = Time.get_ticks_msec() + timeoutMs
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await self.process_frame
	return predicate.call() == true

func _run_suite(suite, parents: Array):
	if suite.get("mode") == "skip":
		return
	var lineage = parents.duplicate()
	lineage.append(suite)
	await self._run_file_hooks(suite.get("before_all"))
	for child in suite.get("children"):
		if child.get("mode") == "skip":
			continue
		if child.get("type") == "suite":
			await self._run_suite(child, lineage)
		else:
			await self._run_test(child, lineage)
	await self._run_file_hooks(suite.get("after_all"))

func _run_test(task, lineage: Array):
	var started_at = Time.get_ticks_msec()
	self._active_errors = []
	self._emit({
		"type": "test_start",
		"file": self._current_file,
		"id": task.get("id"),
	})
	for suite in lineage:
		await self._run_callbacks(suite.get("before_each"))
	if self._active_errors.is_empty():
		await self._run_callback(task.get("callback"))
	for index in range(lineage.size() - 1, -1, -1):
		await self._run_callbacks(lineage[index].get("after_each"))
	await self._cleanup_test_nodes()
	var event = {
		"type": "test_finish",
		"file": self._current_file,
		"id": task.get("id"),
		"state": "pass" if self._active_errors.is_empty() else "fail",
		"duration": Time.get_ticks_msec() - started_at,
	}
	if not self._active_errors.is_empty():
		event.errors = self._active_errors
	self._emit(event)

func _run_callbacks(callbacks: Array):
	for callback in callbacks:
		await self._run_callback(callback)

func _run_callback(callback: Callable):
	if callback.get_argument_count() == 0:
		await callback.call()
		return
	await callback.call(self)

func _run_file_hooks(callbacks: Array):
	self._active_errors = []
	await self._run_callbacks(callbacks)
	self._file_errors.append_array(self._active_errors)

func _cleanup_test_nodes():
	var queued = false
	for child in self.root.get_children():
		if not self._baseline_nodes.has(child.get_instance_id()) and not child.is_in_group("vidot-persistent-game"):
			child.queue_free()
			queued = true
	if queued:
		await self.process_frame

func _new_suite(name: String):
	return {
		"id": "0" if self._suite_stack.is_empty() else self._take_task_id(),
		"name": name,
		"mode": "run",
		"type": "suite",
		"children": [],
		"before_all": [],
		"before_each": [],
		"after_each": [],
		"after_all": [],
	}

func _take_task_id() -> String:
	var id = str(self._next_task_id)
	self._next_task_id += 1
	return id

func _filter_task(task, parent_name: String, pattern) -> bool:
	var name = task.get("name") if parent_name.is_empty() else "" + str(parent_name) + " " + str(task.get("name"))
	if task.get("type") == "test":
		task.mode = "skip" if pattern.search.call(name) == null else "run"
		return task.get("mode") == "run"
	var has_matching_test = false
	for child in task.get("children"):
		if self._filter_task(child, name, pattern):
			has_matching_test = true
	task.mode = "run" if has_matching_test else "skip"
	return has_matching_test

func _emit_collected() -> void:
	self._emit({
		"type": "file_collected",
		"file": self._current_file,
		"tree": self._public_task(self._root_task),
	})

func _public_task(task):
	var public_task = {
		"id": task.get("id"),
		"name": task.get("name"),
		"mode": task.get("mode"),
		"type": task.get("type"),
	}
	if task.get("type") == "suite":
		var children: Array = []
		public_task.children = children
		for child in task.get("children"):
			children.append(self._public_task(child))
	return public_task

func _emit_file_finish(started_at: int) -> void:
	var event = {
		"type": "file_finish",
		"file": self._current_file,
		"duration": Time.get_ticks_msec() - started_at,
	}
	if not self._file_errors.is_empty():
		event.errors = self._file_errors
	self._emit(event)

func _error(message: String, name: String = "Error"):
	return {
		"name": name,
		"message": message,
	}

func _emit(event) -> void:
	print(self.EVENT_PREFIX + JSON.stringify(event))

const EVENT_PREFIX = "VIDOT "

class Expectation extends RefCounted:
	var _runner
	var _actual

	static func create(runner, actual) -> Expectation:
		var expectation = Expectation.new()
		expectation._runner = runner
		expectation._actual = actual
		return expectation

	func toBe(expected) -> bool:
		return self._finish(is_same(self._actual, expected), "to be", expected)

	func toEqual(expected) -> bool:
		return self._finish(self._actual == expected, "to equal", expected)

	func _finish(matched: bool, matcher: String, expected) -> bool:
		if matched:
			return true
		var message = "expected " + str(var_to_str(self._actual)) + " " + str(matcher) + " " + str(var_to_str(expected))
		self._runner.record_assertion(message)
		return false
