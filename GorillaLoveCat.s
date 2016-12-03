sw	$a1,	ON_FIRE_ACK	# acknowledge interrupt
lw	$t8,	GET_FIRE_LOC
and 	$t7,	$t8,	0xffff
mul		$t7,	$t7,	30
add 	$t7,	$t7,	15
srl		$t8,	$t8,	16
mul		$t8,	$t8,	30
add 	$t8,	$t8,	15

li 		$t2,	1 			# t2 = 1
li	 	$t3,	2
sw		$t3,	VELOCITY	# VELOCITY = 2

li 		$t3,	0
li 		$t4,	90
li 		$t5,	180
li 		$t6,	270

find:
lw		$t9,	BOT_X
beq		$t9,	$t8,	x_equal
bgt		$t9, 	$t8,	x_big
j 		x_small

x_big:
sw		$t5,	ANGLE
sw		$t2,	ANGLE_CONTROL
x_big_loop:
lw		$t9,	BOT_X
blt		$t9,	0xf,	x_equal
ble		$t9,	$t8,	x_equal
j 		x_big_loop

x_small:
sw		$t3,	ANGLE
sw		$t2,	ANGLE_CONTROL
x_small_loop:
lw		$t9,	BOT_X
bgt		$t9,	0x11d,	x_equal
bge		$t9,	$t8,	x_equal
j 		x_small_loop

x_equal:

lw 		$t9,	BOT_Y		# t9 = y
beq		$t9,	$t7,	y_equal
bgt		$t9, 	$t7,	y_big
j 		y_small

y_big:
sw		$t6,	ANGLE
sw		$t2,	ANGLE_CONTROL
y_big_loop:
lw		$t9,	BOT_Y
blt		$t9,	0xf,	y_equal
ble		$t9,	$t7,	y_equal
j 		y_big_loop

y_small:
sw		$t4,	ANGLE
sw		$t2,	ANGLE_CONTROL
y_small_loop:
lw		$t9,	BOT_Y
bgt		$t9,	0x11d,	y_equal
bge		$t9,	$t7,	y_equal
j 		y_small_loop

y_equal:

sw		$t2,	PUT_OUT_FIRE
sw		$0,		VELOCITY		# drive

j		interrupt_dispatch
