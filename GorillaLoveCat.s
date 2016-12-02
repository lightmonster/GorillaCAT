# syscall constants
PRINT_STRING = 4
PRINT_CHAR   = 11
PRINT_INT    = 1

# debug constants
PRINT_INT_ADDR   = 0xffff0080
PRINT_FLOAT_ADDR = 0xffff0084
PRINT_HEX_ADDR   = 0xffff0088

# spimbot constants
VELOCITY       = 0xffff0010
ANGLE          = 0xffff0014
ANGLE_CONTROL  = 0xffff0018
BOT_X          = 0xffff0020
BOT_Y          = 0xffff0024
OTHER_BOT_X    = 0xffff00a0
OTHER_BOT_Y    = 0xffff00a4
TIMER          = 0xffff001c
SCORES_REQUEST = 0xffff1018

TILE_SCAN       = 0xffff0024
SEED_TILE       = 0xffff0054
WATER_TILE      = 0xffff002c
MAX_GROWTH_TILE = 0xffff0030
HARVEST_TILE    = 0xffff0020
BURN_TILE       = 0xffff0058
GET_FIRE_LOC    = 0xffff0028
PUT_OUT_FIRE    = 0xffff0040

GET_NUM_WATER_DROPS   = 0xffff0044
GET_NUM_SEEDS         = 0xffff0048
GET_NUM_FIRE_STARTERS = 0xffff004c
SET_RESOURCE_TYPE     = 0xffff00dc
REQUEST_PUZZLE        = 0xffff00d0
SUBMIT_SOLUTION       = 0xffff00d4

# interrupt constants
BONK_MASK               = 0x1000
BONK_ACK                = 0xffff0060
TIMER_MASK              = 0x8000
TIMER_ACK               = 0xffff006c
ON_FIRE_MASK            = 0x400
ON_FIRE_ACK             = 0xffff0050
MAX_GROWTH_ACK          = 0xffff005c
MAX_GROWTH_INT_MASK     = 0x2000
REQUEST_PUZZLE_ACK      = 0xffff00d8
REQUEST_PUZZLE_INT_MASK = 0x800

.data
# data things go here
.align 2
tile_data: .space 1600
puzzle: .space 4096
solution: .space 328

.text
main:

############ USE OF REGISTERS ############

	# s0 = water resource
	# s1 = seed resource
	# s2 = fire resource
	# s3 = tile_data TILE_SCAN
	# s4 = x
	# s5 = y

############ ENABLE INTERRUPTS ############

	# enable interrupts
	li	$t0,	ON_FIRE_MASK
	or	$t0,	$t0,	1
	mtc0	$t0,	$12
	li	$t0,	MAX_GROWTH_INT_MASK
	or	$t0,	$t0,	1
	mtc0	$t0,	$12
	li	$t0,	REQUEST_PUZZLE_INT_MASK
	or	$t0,	$t0, 1
	mtc0	$t0,	$12

start:
	la	$s3,	tile_data
	sw	$s3,	TILE_SCAN

main_loop:

############ CHECK RESOURCES ############

	# (use t0, free t0)

	# 检查resource，没有的话request

	bge	$s0,	0,	has_water
	li	$t0,	0
	sw	$t0,	SET_RESOURCE_TYPE
	la	$t0,	puzzle_data
	sw	$t0,	REQUEST_PUZZLE

has_water:

	bge	$s1,	0,	has_seed
	li	$t0,	1
	sw	$t0,	SET_RESOURCE_TYPE
	la	$t0,	puzzle_data
	sw	$t0,	REQUEST_PUZZLE

has_seed:

	bge	$s2,	0,	has_fire
	li	$t0,	2
	sw	$t0,	SET_RESOURCE_TYPE
	la	$t0,	puzzle_data
	sw	$t0,	REQUEST_PUZZLE

has_fire:

############ CHECK STATUS ############

	lw	$s4,	BOT_X
	lw	$s5,	BOT_Y
	mul	$t0,	$s4,	10
	add	$t0,	$t0,	$s5	# t0 = index

	# struct TileInfo {
	#	int state; // Either 0 for EMPTY, 1 for GROWING
	#	int owning_bot; // 0 for owned by SPIMbot, 1 for owned by cohabitating bot
	#	int growth;
	#	int water;
	# };

	lw	$t1,	0($t0)	# t1 = state
	lw	$t2,	4($t0)	# t2 = owning_bot
	lw	$t3,	8($t0)	# t3 = growth
	lw	$t4,	12($t0)	# t4 = water

	# 对每一格check
	# if state == 0 & seed > 0 plant
	# if state == 1 & own == 0 & water > 0 water
	# if state == 1 & own == 1 & fire > 0 fire

	bge	$t1,	0,	state_1

state_0:
	beq	$s1,	0,	finish_action
action_plant:
	sw	$0,	SEED_TILE
	j	finish_action

state_1:
	bge	$t2,	0,	others_plant

my_plant:
	beq	$s0,	0,	finish_action
action_water:
	li	$t0,	10	# Dump 10 units of water
	sw	$t0,	WATER_TILE
	j	finish_action

others_plant:
	beq	$s2,	0,	finish_action
action_fire:
	sw	$0,	BURN_TILE
	j	finish_action

finish_action:

############ DETERMINE DIRECTION ############

	# 根据坐标，确定走的方向，走到下一格
	# s4 = x, s5 = y

	# if (x == 0) {
	#	if (y == 0) x++;
	#	else y--;
	# }
	# else if (y%2 == 0) {
	#	if (x == 9) y++;
	#	else x++;
	# }
	# else {
	#	if (x == 1) y++;
	#	else x--
	# }

	li	$t0,	10
	sw	$t0,	VELOCITY

	beq	$s4,	0,	location_if_1
	rem	$t1,	$s5,	2
	beq	$t1,	0,	location_if_2
	beq	$s4,	1,	y_increase
	j	x_decrease

location_if_1:
	beq	$s5,	0,	x_increase
	j	y_decrease

location_if_2:
	beq	$s4,	9,	y_increase
	j	x_increase

x_increase:
	li	$t0,	180
	sw	$t0,	ANGLE
	li	$t0,	1
	sw	$t2,	ANGLE_CONTROL
	add	$t0,	$s4,	1
x_increase_loop:
	lw	$s4,	BOT_X
	blt	$s4,	0xf,	main_loop
	ble	$s4,	$t0,	main_loop
	j	x_increase_loop

x_decrease:
	li	$t0,	0
	sw	$t0,	ANGLE
	li	$t0,	1
	sw	$t2,	ANGLE_CONTROL
	sub	$t0,	$s4,	1
x_decrease_loop:
	lw	$s4,	BOT_X
	bgt	$s4,	0x11d,	main_loop
	bge	$s4,	$t0,	main_loop
	j	x_decrease_loop

y_increase:
	li	$t0,	270
	sw	$t0,	ANGLE
	li	$t0,	1
	sw	$t2,	ANGLE_CONTROL
	add	$t0,	$s5,	1
y_increase_loop:
	lw	$s5,	BOT_Y
	blt	$s5,	0xf,	main_loop
	ble	$s5,	$t0,	main_loop
	j	y_increase_loop

y_decrease:
	li	$t0,	90
	sw	$t0,	ANGLE
	li	$t0,	1
	sw	$t2,	ANGLE_CONTROL
	sub	$t0,	$s5,	1
y_decrease_loop:
	lw	$s5,	BOT_Y
	bgt	$s5,	0x11d,	main_loop
	bge	$s5,	$t0,	main_loop
	j	y_decrease_loop

############ BACK TO MAIN LOOP ############

finish_walking: # 前面已经跳到 main_loop 了，所以这块其实没用

	j	main_loop

############ END OF PROGRAM ############

ret:
	jr	$ra

############ INTERRUPTS ############

fire_interrupt:

max_growth_interrupt:

request_puzzle_interrupt:
