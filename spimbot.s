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

# struct TileInfo {
# 	int state; // Either 0 for EMPTY, 1 for GROWING
# 	int owning_bot; // 0 for owned by SPIMbot, 1 for owned by cohabitating bot
# 	int growth;
# 	int water;
# };

.text
main:

# s0 = seed resource
# s1 = water resource
# s2 = fire resource
# s3 = tile_data TILE_SCAN

	# enable interrupts
	li		$t0,	ON_FIRE_MASK
	or		$t0, 	$t0, 1
	mtc0	$t0, 	$12
	li		$t0,	MAX_GROWTH_INT_MASK
	or		$t0, 	$t0, 1
	mtc0	$t0, 	$12
	li		$t0,	REQUEST_PUZZLE_INT_MASK
	or		$t0, 	$t0, 1
	mtc0	$t0, 	$12

start:
	la		$s3,	tile_data
	sw		$s3,	TILE_SCAN

loop:

	# 检查resource，没有的话request

	bge		$s0,	0,		has_water
	li		$t0, 	0
	sw 		$t0,	SET_RESOURCE_TYPE
	la		$t0,	puzzle_data
	sw 		$t0, 	REQUEST_PUZZLE	# t0结束使用

has_water:

	bge		$s1,	0,		has_seed
	li		$t0, 	1
	sw 		$t0,	SET_RESOURCE_TYPE
	la		$t0,	puzzle_data
	sw 		$t0, 	REQUEST_PUZZLE

has_seed:

	bge		$s2,	0,		has_fire
	li		$t0, 	2
	sw 		$t0,	SET_RESOURCE_TYPE
	la		$t0,	puzzle_data
	sw 		$t0, 	REQUEST_PUZZLE

has_fire:

	# 根据坐标，确定走的方向，走到下一格

	# TODO www

	# 对每一格check
	# if state == 0 & seed > 0	plant
	# if state == 1 & own == 0 & water > 0	water
	# if state == 1 & own == 1 & fire > 0	fire

	# TODO

_state_0:

	# TODO

_state_1:

	# TODO

_my_plant:

	# TODO

_others_plant:

	# TODO

action_plant:

	# TODO

	j 		loop

action_water:

	# TODO

	j 		loop

_fire:

	# TODO

	j 		loop

ret:
	jr		$ra

fire_interrupt:

max_growth_interrupt:

request_puzzle_interrupt:
