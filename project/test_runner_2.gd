@tool
extends Node

# Expected output:
# Starting GDTask Tests...
# All tests completed!
# Basic Task: PASSED Expected result 42, got 42
# Task Chaining: PASSED Expected product 20, got 20
# Watcher Task: PASSED Expected counter >= 3, got 3
# Repeater Task: PASSED Expected counter 3, got 3
# Delay Task: PASSED Expected delay >= 0.2s and product 'delayed', got delayed, elapsed 0.2
# Timeout Task: PASSED Expected CANCELLED, got CANCELLED
# SigResponse Task: PASSED Expected signal emitted, got true
# Any and All Tasks: PASSED Any status: COMPLETED, All status: COMPLETED
# RPCTask: PASSED Expected COMPLETED with Response, got {sender_id:0001, code:ACK, data[16]}
# Cancellation: PASSED Expected CANCELLED, got CANCELLED
# Performance: Task Creation: PASSED Time: 0.005 s, Memory: 0.1484375 KB for 1000 tasks
# Performance: Task Chaining: PASSED Time: 0.02 s, Memory: 2279.41796875 KB for 1000 chained tasks
# Performance: Repeater: PASSED Time: 1.63 s, Memory: 0.23046875 KB for 100 repetitions
# Repeater Infinite: PASSED Expected counter >= 2, got 4
# Delay Task: PASSED Expected counter=1, product='delayed', elapsed>=0.2s, completed emitted, got counter=1, product=delayed, elapsed=0.201, completed=[true]
# Performance: Delay: PASSED Time: 0.014 s, Memory: 233.03515625 KB for 100 delays
# Delay Cancel: PASSED Expected counter=0, status=CANCELLED, got counter=0, status=CANCELLED


#var task_mgr: GDTaskMgr
var test_results: Array[String] = []

func _ready() -> void:
	#task_mgr = GDTaskMgr.new()
	#add_child(task_mgr)
	run_tests()

func run_tests() -> void:
	print("Starting GDTask Tests...")
	await test_basic_task()
	await test_task_chain()
	await test_watcher()
	await test_repeater()
	await test_delay()
	await test_timeout()
	await test_sigresponse()
	await test_any_all()
	await test_rpc_task()

	await test_cancellation()
	await test_performance()
	await test_repeater_performance()
	await test_repeater_infinite()
	await test_delay2()
	await test_delay_performance()
	await test_delay_cancel()

	print("All tests completed!")
	for result in test_results:
		print_rich(result)

func report_result(test_name: String, passed: bool, message: String = "") -> void:
	var status := "[color=green]PASSED[/color]" if passed else "[color=salmon]FAILED[/color]"
	test_results.append("%s: %s %s" % [test_name, status, message])

func test_basic_task() -> void:
	var task := GDTask.new(func() -> int: return 42)
	await task.run()
	var result : int = task.product
	var passed := task.status == GDTask.Status.COMPLETED and result == 42
	report_result("Basic Task", passed, "Expected result 42, got %s" % result)

func test_task_chain() -> void:
	var task1 := GDTask.new(func() -> int: return 10)
	var task2 := task1.then(func(x : int) -> int: return x * 2)
	await task2.run()
	var result : int = task2.product
	var passed := task2.status == GDTask.Status.COMPLETED and result == 20
	report_result("Task Chaining", passed, "Expected product 20, got %s" % task2.product)

func test_watcher() -> void:
	var counter : Array[int] = [0] # Use an Array to hold the counter
	var task := GDTask.Watcher.new(func() -> bool: counter[0] += 1; return counter[0] >= 3, [], 0.1)
	await task.run()
	var passed := task.status == GDTask.Status.COMPLETED and counter[0] >= 3
	report_result("Watcher Task", passed, "Expected counter >= 3, got %s" % counter[0])

func test_repeater() -> void:
	var counter : Array[int] = [0]
	var task := GDTask.Repeater.new(3, 0.1, func() -> void: counter[0] += 1)
	await task.run()
	var passed := task.status == GDTask.Status.COMPLETED and counter[0] == 3
	report_result("Repeater Task", passed, "Expected counter 3, got %s" % counter[0])

func test_delay() -> void:
	var start_time := Time.get_ticks_msec()
	var task := GDTask.Delay.new(0.2, func() -> String: return "delayed")
	await task.run()
	var elapsed : float = (Time.get_ticks_msec() - start_time) / 1000.0
	var passed : bool = task.status == GDTask.Status.COMPLETED and task.product == "delayed" and elapsed >= 0.2
	report_result("Delay Task", passed, "Expected delay >= 0.2s and product 'delayed', got %s, elapsed %s" % [task.product, elapsed])

func test_timeout() -> void:
	var task := GDTask.Timeout.new(0.1, func() -> String: await get_tree().create_timer(0.5).timeout; return "toolong")
	await task.run()
	var passed := task.status == GDTask.Status.CANCELLED
	report_result("Timeout Task", passed, "Expected CANCELLED, got %s" % GDTask.Status.keys()[task.status])

func test_sigresponse() -> void:
	var signal_emitted : Array[bool] = [false]
	var task := GDTask.SigResponse.new(get_tree().process_frame, func() -> void: signal_emitted[0] = true)
	await task.run()
	var passed := task.status == GDTask.Status.COMPLETED and signal_emitted
	report_result("SigResponse Task", passed, "Expected signal emitted, got %s" % signal_emitted)

func test_any_all() -> void:
	var task1 := GDTask.new(func() -> int : await get_tree().create_timer(0.1).timeout; return 1)
	var task2 := GDTask.new(func() -> int : await get_tree().create_timer(0.2).timeout; return 2)
	var any_task := GDTask.Any.new([task1, task2])
	await any_task.run()
	var any_passed := any_task.status == GDTask.Status.COMPLETED
	var all_task := GDTask.All.new([task1, task2])
	await all_task.run()
	var all_passed := all_task.status == GDTask.Status.COMPLETED
	report_result("Any and All Tasks", any_passed and all_passed, "Any status: %s, All status: %s" % [GDTask.Status.keys()[any_task.status], GDTask.Status.keys()[all_task.status]])

func test_rpc_task() -> void:
	# Mock multiplayer setup (requires a test server or peer)
	var mock_node := Node.new()
	mock_node.set_script(preload("res://mock_rpc_node.gd")) # Assume a mock script with an RPC method
	add_child(mock_node)
	var task := GDTaskMgr.create_RPCTask(1, mock_node, "mock_rpc_method", [42], true)
	await task.run()
	var passed : bool = task.status == GDTask.Status.COMPLETED and task.product is GDTaskMgr.Response
	report_result("RPCTask", passed, "Expected COMPLETED with Response, got %s" % task.product)
	mock_node.queue_free()

func test_cancellation() -> void:
	var task := GDTask.new(func() -> String: await get_tree().create_timer(0.5).timeout; return "notreached")
	task.run()
	task.cancel()
	await task.finished
	var passed := task.status == GDTask.Status.CANCELLED
	report_result("Cancellation", passed, "Expected CANCELLED, got %s" % GDTask.Status.keys()[task.status])


func test_performance() -> void:
	var iterations := 1000
	var start_time := Time.get_ticks_msec()
	var start_memory := OS.get_static_memory_usage()

	# Test task creation and execution
	for i in iterations:
		var task1 := GDTask.new(func() -> int: return i)
		await task1.run()

	var task_time := (Time.get_ticks_msec() - start_time) / 1000.0
	var task_memory := (OS.get_static_memory_usage() - start_memory) / 1024.0
	report_result("Performance: Task Creation", true, "Time: %s s, Memory: %s KB for %d tasks" % [task_time, task_memory, iterations])

	# Test task chaining
	start_time = Time.get_ticks_msec()
	start_memory = OS.get_static_memory_usage()
	var task2 := GDTask.new(func() -> int: return 1)
	for i in iterations:
		task2 = task2.then(func(x:int) -> int: return x + 1)
	await task2.run()
	var chain_time := (Time.get_ticks_msec() - start_time) / 1000.0
	var chain_memory := (OS.get_static_memory_usage() - start_memory) / 1024.0
	report_result("Performance: Task Chaining", true, "Time: %s s, Memory: %s KB for %d chained tasks" % [chain_time, chain_memory, iterations])


func test_repeater_performance() -> void:
	var iterations := 100
	var counter := [0]
	var start_time := Time.get_ticks_msec()
	var start_memory := OS.get_static_memory_usage()
	var task := GDTask.Repeater.new(iterations, 0.01, func() -> void: counter[0] += 1)
	await task.run()
	var time := (Time.get_ticks_msec() - start_time) / 1000.0
	var memory := (OS.get_static_memory_usage() - start_memory) / 1024.0
	var passed : bool = counter[0] == iterations
	report_result("Performance: Repeater", passed, "Time: %s s, Memory: %s KB for %d repetitions" % [time, memory, iterations])

func test_repeater_infinite() -> void:
	var counter := [0]
	var task := GDTask.Repeater.new(-1, 0.1, func() -> void: counter[0] += 1)
	task.run()
	await get_tree().create_timer(0.35).timeout # Wait for ~3 iterations
	task.cancel()
	var passed : bool = counter[0] >= 2 and task.status == GDTask.Status.CANCELLED
	report_result("Repeater Infinite", passed, "Expected counter >= 2, got %s" % counter[0])

func test_delay2() -> void:
	var counter := [0]
	var start_time := Time.get_ticks_msec()
	var task := GDTask.Delay.new(0.2, func() -> String: counter[0] += 1; return "delayed")
	var completed_emitted : Array[bool] = [false]
	@warning_ignore('return_value_discarded')
	task.completed.connect(func(_product : String) -> void: completed_emitted[0] = true)
	await task.run()
	var elapsed := (Time.get_ticks_msec() - start_time) / 1000.0
	var passed : bool = task.status == GDTask.Status.COMPLETED and counter[0] == 1 and task.product == "delayed" and elapsed >= 0.2 and completed_emitted
	report_result("Delay Task", passed, "Expected counter=1, product='delayed', elapsed>=0.2s, completed emitted, got counter=%s, product=%s, elapsed=%s, completed=%s" % [counter[0], task.product, elapsed, completed_emitted])


func test_delay_performance() -> void:
	var iterations := 100
	var counter := [0]
	var start_time := Time.get_ticks_msec()
	var start_memory := OS.get_static_memory_usage()
	var tasks: Array[GDTask] = []
	for i in iterations:
		var task := GDTask.Delay.new(0.01, func() -> void: counter[0] += 1)
		tasks.append(task)
		task.run()
	for task in tasks:
		await task.finished
	var time := (Time.get_ticks_msec() - start_time) / 1000.0
	var memory := (OS.get_static_memory_usage() - start_memory) / 1024.0
	var passed : bool = counter[0] == iterations
	report_result("Performance: Delay", passed, "Time: %s s, Memory: %s KB for %d delays" % [time, memory, iterations])

func test_delay_cancel() -> void:
	var counter := [0]
	var task := GDTask.Delay.new(0.5, func() -> void: counter[0] += 1)
	task.run()
	await get_tree().create_timer(0.2).timeout
	task.cancel()
	await task.finished
	var passed : bool = task.status == GDTask.Status.CANCELLED and counter[0] == 0
	report_result("Delay Cancel", passed, "Expected counter=0, status=CANCELLED, got counter=%s, status=%s" % [counter[0], GDTask.Status.keys()[task.status]])
