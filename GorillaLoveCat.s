# syscall constants
PRINT_STRING = 4 ###### AND OTHER ADDRESS ######
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
puzzle_data: .space 4096
solution: .space 328

.text

################	Lab 7 & 8 ################
.globl is_single_value_domain ####### CODE OF LAB 7 & 8
  is_single_value_domain:
      beq    $a0, $0, isvd_zero     # return 0 if domain == 0
      sub    $t0, $a0, 1	          # (domain - 1)
      and    $t0, $t0, $a0          # (domain & (domain - 1))
      bne    $t0, $0, isvd_zero     # return 0 if (domain & (domain - 1)) != 0
      li     $v0, 1
      jr	   $ra

  isvd_zero:
      li	   $v0, 0
      jr	   $ra
  ##################################
  .globl get_domain_for_subtraction
  get_domain_for_subtraction:
      li     $t0, 1
      li     $t1, 2
      mul    $t1, $t1, $a0            # target * 2
      sll    $t1, $t0, $t1            # 1 << (target * 2)
      or     $t0, $t0, $t1            # t0 = base_mask
      li     $t1, 0                   # t1 = mask

  gdfs_loop:
      beq    $a2, $0, gdfs_loop_end
      and    $t2, $a2, 1              # other_domain & 1
      beq    $t2, $0, gdfs_if_end

      sra    $t2, $t0, $a0            # base_mask >> target
      or     $t1, $t1, $t2            # mask |= (base_mask >> target)

  gdfs_if_end:
      sll    $t0, $t0, 1              # base_mask <<= 1
      sra    $a2, $a2, 1              # other_domain >>= 1
      j      gdfs_loop

  gdfs_loop_end:
      and    $v0, $a1, $t1            # domain & mask
      jr	   $ra
  ###################################
  .globl get_domain_for_addition
  get_domain_for_addition:
      sub    $sp, $sp, 20
      sw     $ra, 0($sp)
      sw     $s0, 4($sp)
      sw     $s1, 8($sp)
      sw     $s2, 12($sp)
      sw     $s3, 16($sp)
      move   $s0, $a0                     # s0 = target
      move   $s1, $a1                     # s1 = num_cell
      move   $s2, $a2                     # s2 = domain

      move   $a0, $a2
      jal    convert_highest_bit_to_int
      move   $s3, $v0                     # s3 = upper_bound

      sub    $a0, $0, $s2	                # -domain
      and    $a0, $a0, $s2                # domain & (-domain)
      jal    convert_highest_bit_to_int   # v0 = lower_bound

      sub    $t0, $s1, 1                  # num_cell - 1
      mul    $t0, $t0, $v0                # (num_cell - 1) * lower_bound
      sub    $t0, $s0, $t0                # t0 = high_bits
      bge    $t0, 0, gdfa_skip0

      li     $t0, 0

  gdfa_skip0:
      bge    $t0, $s3, gdfa_skip1

      li     $t1, 1
      sll    $t0, $t1, $t0                # 1 << high_bits
      sub    $t0, $t0, 1                  # (1 << high_bits) - 1
      and    $s2, $s2, $t0                # domain & ((1 << high_bits) - 1)

  gdfa_skip1:
      sub    $t0, $s1, 1                  # num_cell - 1
      mul    $t0, $t0, $s3                # (num_cell - 1) * upper_bound
      sub    $t0, $s0, $t0                # t0 = low_bits
      ble    $t0, $0, gdfa_skip2

      sub    $t0, $t0, 1                  # low_bits - 1
      sra    $s2, $s2, $t0                # domain >> (low_bits - 1)
      sll    $s2, $s2, $t0                # domain >> (low_bits - 1) << (low_bits - 1)

  gdfa_skip2:
      move   $v0, $s2                     # return domain
      lw     $ra, 0($sp)
      lw     $s0, 4($sp)
      lw     $s1, 8($sp)
      lw     $s2, 12($sp)
      lw     $s3, 16($sp)
      add    $sp, $sp, 20
      jr     $ra
  ###################################
  .globl convert_highest_bit_to_int
  convert_highest_bit_to_int:
      move  $v0, $0   	      # result = 0

  chbti_loop:
      beq   $a0, $0, chbti_end
      add   $v0, $v0, 1         # result ++
      sra   $a0, $a0, 1         # domain >>= 1
      j     chbti_loop

  chbti_end:
      jr	  $ra
  ##################################
  .globl get_unassigned_position
  get_unassigned_position:
    li    $v0, 0            # unassigned_pos = 0
    lw    $t0, 0($a1)       # puzzle->size
    mul  $t0, $t0, $t0     # puzzle->size * puzzle->size
    add   $t1, $a0, 4       # &solution->assignment[0]
  get_unassigned_position_for_begin:
    bge   $v0, $t0, get_unassigned_position_return  # if (unassigned_pos < puzzle->size * puzzle->size)
    mul  $t2, $v0, 4
    add   $t2, $t1, $t2     # &solution->assignment[unassigned_pos]
    lw    $t2, 0($t2)       # solution->assignment[unassigned_pos]
    beq   $t2, 0, get_unassigned_position_return  # if (solution->assignment[unassigned_pos] == 0)
    add   $v0, $v0, 1       # unassigned_pos++
    j   get_unassigned_position_for_begin
  get_unassigned_position_return:
    jr    $ra
  ##################################
  .globl is_complete
  is_complete:
    lw    $t0, 0($a0)       # solution->size
    lw    $t1, 0($a1)       # puzzle->size
    mul   $t1, $t1, $t1     # puzzle->size * puzzle->size
    move	$v0, $0
    seq   $v0, $t0, $t1
    j     $ra
  ##################################
  .globl forward_checking
  forward_checking:
    sub   $sp, $sp, 24
    sw    $ra, 0($sp)
    sw    $a0, 4($sp)
    sw    $a1, 8($sp)
    sw    $s0, 12($sp)
    sw    $s1, 16($sp)
    sw    $s2, 20($sp)
    lw    $t0, 0($a1)     # size
    li    $t1, 0          # col = 0
  fc_for_col:
    bge   $t1, $t0, fc_end_for_col  # col < size
    div   $a0, $t0
    mfhi  $t2             # position % size
    mflo  $t3             # position / size
    beq   $t1, $t2, fc_for_col_continue    # if (col != position % size)
    mul   $t4, $t3, $t0
    add   $t4, $t4, $t1   # position / size * size + col
    mul   $t4, $t4, 8
    lw    $t5, 4($a1) # puzzle->grid
    add   $t4, $t4, $t5   # &puzzle->grid[position / size * size + col].domain
    mul   $t2, $a0, 8   # position * 8
    add   $t2, $t5, $t2 # puzzle->grid[position]
    lw    $t2, 0($t2) # puzzle -> grid[position].domain
    not   $t2, $t2        # ~puzzle->grid[position].domain
    lw    $t3, 0($t4) #
    and   $t3, $t3, $t2
    sw    $t3, 0($t4)
    beq   $t3, $0, fc_return_zero # if (!puzzle->grid[position / size * size + col].domain)
  fc_for_col_continue:
    add   $t1, $t1, 1     # col++
    j     fc_for_col
  fc_end_for_col:
    li    $t1, 0          # row = 0
  fc_for_row:
    bge   $t1, $t0, fc_end_for_row  # row < size
    div   $a0, $t0
    mflo  $t2             # position / size
    mfhi  $t3             # position % size
    beq   $t1, $t2, fc_for_row_continue
    lw    $t2, 4($a1)     # puzzle->grid
    mul   $t4, $t1, $t0
    add   $t4, $t4, $t3
    mul   $t4, $t4, 8
    add   $t4, $t2, $t4   # &puzzle->grid[row * size + position % size]
    lw    $t6, 0($t4)
    mul   $t5, $a0, 8
    add   $t5, $t2, $t5
    lw    $t5, 0($t5)     # puzzle->grid[position].domain
    not   $t5, $t5
    and   $t5, $t6, $t5
    sw    $t5, 0($t4)
    beq   $t5, $0, fc_return_zero
  fc_for_row_continue:
    add   $t1, $t1, 1     # row++
    j     fc_for_row
  fc_end_for_row:

    li    $s0, 0          # i = 0
  fc_for_i:
    lw    $t2, 4($a1)
    mul   $t3, $a0, 8
    add   $t2, $t2, $t3
    lw    $t2, 4($t2)     # &puzzle->grid[position].cage
    lw    $t3, 8($t2)     # puzzle->grid[position].cage->num_cell
    bge   $s0, $t3, fc_return_one
    lw    $t3, 12($t2)    # puzzle->grid[position].cage->positions
    mul   $s1, $s0, 4
    add   $t3, $t3, $s1
    lw    $t3, 0($t3)     # pos
    lw    $s1, 4($a1)
    mul   $s2, $t3, 8
    add   $s2, $s1, $s2   # &puzzle->grid[pos].domain
    lw    $s1, 0($s2)
    move  $a0, $t3
    jal get_domain_for_cell
    lw    $a0, 4($sp)
    lw    $a1, 8($sp)
    and   $s1, $s1, $v0
    sw    $s1, 0($s2)     # puzzle->grid[pos].domain &= get_domain_for_cell(pos, puzzle)
    beq   $s1, $0, fc_return_zero
  fc_for_i_continue:
    add   $s0, $s0, 1     # i++
    j     fc_for_i
  fc_return_one:
    li    $v0, 1
    j     fc_return
  fc_return_zero:
    li    $v0, 0
  fc_return:
    lw    $ra, 0($sp)
    lw    $a0, 4($sp)
    lw    $a1, 8($sp)
    lw    $s0, 12($sp)
    lw    $s1, 16($sp)
    lw    $s2, 20($sp)
    add   $sp, $sp, 24
    jr    $ra
  #################################
  .globl recursive_backtracking
  recursive_backtracking:
    sub   $sp, $sp, 680
    sw    $ra, 0($sp)
    sw    $a0, 4($sp)     # solution
    sw    $a1, 8($sp)     # puzzle
    sw    $s0, 12($sp)    # position
    sw    $s1, 16($sp)    # val
    sw    $s2, 20($sp)    # 0x1 << (val - 1)
                          # sizeof(Puzzle) = 8
                          # sizeof(Cell [81]) = 648

    jal   is_complete
    bne   $v0, $0, recursive_backtracking_return_one
    lw    $a0, 4($sp)     # solution
    lw    $a1, 8($sp)     # puzzle
    jal   get_unassigned_position
    move  $s0, $v0        # position
    li    $s1, 1          # val = 1
  recursive_backtracking_for_loop:
    lw    $a0, 4($sp)     # solution
    lw    $a1, 8($sp)     # puzzle
    lw    $t0, 0($a1)     # puzzle->size
    add   $t1, $t0, 1     # puzzle->size + 1
    bge   $s1, $t1, recursive_backtracking_return_zero  # val < puzzle->size + 1
    lw    $t1, 4($a1)     # puzzle->grid
    mul   $t4, $s0, 8     # sizeof(Cell) = 8
    add   $t1, $t1, $t4   # &puzzle->grid[position]
    lw    $t1, 0($t1)     # puzzle->grid[position].domain
    sub   $t4, $s1, 1     # val - 1
    li    $t5, 1
    sll   $s2, $t5, $t4   # 0x1 << (val - 1)
    and   $t1, $t1, $s2   # puzzle->grid[position].domain & (0x1 << (val - 1))
    beq   $t1, $0, recursive_backtracking_for_loop_continue # if (domain & (0x1 << (val - 1)))
    mul   $t0, $s0, 4     # position * 4
    add   $t0, $t0, $a0
    add   $t0, $t0, 4     # &solution->assignment[position]
    sw    $s1, 0($t0)     # solution->assignment[position] = val
    lw    $t0, 0($a0)     # solution->size
    add   $t0, $t0, 1
    sw    $t0, 0($a0)     # solution->size++
    add   $t0, $sp, 32    # &grid_copy
    sw    $t0, 28($sp)    # puzzle_copy.grid = grid_copy !!!
    move  $a0, $a1        # &puzzle
    add   $a1, $sp, 24    # &puzzle_copy
    jal   clone           # clone(puzzle, &puzzle_copy)
    mul   $t0, $s0, 8     # !!! grid size 8
    lw    $t1, 28($sp)

    add   $t1, $t1, $t0   # &puzzle_copy.grid[position]
    sw    $s2, 0($t1)     # puzzle_copy.grid[position].domain = 0x1 << (val - 1);
    move  $a0, $s0
    add   $a1, $sp, 24
    jal   forward_checking  # forward_checking(position, &puzzle_copy)
    beq   $v0, $0, recursive_backtracking_skip

    lw    $a0, 4($sp)     # solution
    add   $a1, $sp, 24    # &puzzle_copy
    jal   recursive_backtracking
    beq   $v0, $0, recursive_backtracking_skip
    j     recursive_backtracking_return_one # if (recursive_backtracking(solution, &puzzle_copy))
  recursive_backtracking_skip:
    lw    $a0, 4($sp)     # solution
    mul   $t0, $s0, 4
    add   $t1, $a0, 4
    add   $t1, $t1, $t0
    sw    $0, 0($t1)      # solution->assignment[position] = 0
    lw    $t0, 0($a0)
    sub   $t0, $t0, 1
    sw    $t0, 0($a0)     # solution->size -= 1
  recursive_backtracking_for_loop_continue:
    add   $s1, $s1, 1     # val++
    j     recursive_backtracking_for_loop
  recursive_backtracking_return_zero:
    li    $v0, 0
    j     recursive_backtracking_return
  recursive_backtracking_return_one:
    li    $v0, 1
  recursive_backtracking_return:
    lw    $ra, 0($sp)
    lw    $a0, 4($sp)
    lw    $a1, 8($sp)
    lw    $s0, 12($sp)
    lw    $s1, 16($sp)
    lw    $s2, 20($sp)
    add   $sp, $sp, 680
    jr    $ra
  ##################################
  .globl get_domain_for_cell
  get_domain_for_cell:
      # save registers
      sub $sp, $sp, 36
      sw $ra, 0($sp)
      sw $s0, 4($sp)
      sw $s1, 8($sp)
      sw $s2, 12($sp)
      sw $s3, 16($sp)
      sw $s4, 20($sp)
      sw $s5, 24($sp)
      sw $s6, 28($sp)
      sw $s7, 32($sp)

      li $t0, 0 # valid_domain
      lw $t1, 4($a1) # puzzle->grid (t1 free)
      sll $t2, $a0, 3 # position*8 (actual offset) (t2 free)
      add $t3, $t1, $t2 # &puzzle->grid[position]
      lw  $t4, 4($t3) # &puzzle->grid[position].cage
      lw  $t5, 0($t4) # puzzle->grid[posiition].cage->operation

      lw $t2, 4($t4) # puzzle->grid[position].cage->target

      move $s0, $t2   # remain_target = $s0  *!*!
      lw $s1, 8($t4) # remain_cell = $s1 = puzzle->grid[position].cage->num_cell
      lw $s2, 0($t3) # domain_union = $s2 = puzzle->grid[position].domain
      move $s3, $t4 # puzzle->grid[position].cage
      li $s4, 0   # i = 0
      move $s5, $t1 # $s5 = puzzle->grid
      move $s6, $a0 # $s6 = position
      # move $s7, $s2 # $s7 = puzzle->grid[position].domain

      bne $t5, 0, gdfc_check_else_if

      li $t1, 1
      sub $t2, $t2, $t1 # (puzzle->grid[position].cage->target-1)
      sll $v0, $t1, $t2 # valid_domain = 0x1 << (prev line comment)
      j gdfc_end # somewhere!!!!!!!!

  gdfc_check_else_if:
      bne $t5, '+', gdfc_check_else

  gdfc_else_if_loop:
      lw $t5, 8($s3) # puzzle->grid[position].cage->num_cell
      bge $s4, $t5, gdfc_for_end # branch if i >= puzzle->grid[position].cage->num_cell
      sll $t1, $s4, 2 # i*4
      lw $t6, 12($s3) # puzzle->grid[position].cage->positions
      add $t1, $t6, $t1 # &puzzle->grid[position].cage->positions[i]
      lw $t1, 0($t1) # pos = puzzle->grid[position].cage->positions[i]
      add $s4, $s4, 1 # i++

      sll $t2, $t1, 3 # pos * 8
      add $s7, $s5, $t2 # &puzzle->grid[pos]
      lw  $s7, 0($s7) # puzzle->grid[pos].domain

      beq $t1, $s6 gdfc_else_if_else # branch if pos == position



      move $a0, $s7 # $a0 = puzzle->grid[pos].domain
      jal is_single_value_domain
      bne $v0, 1 gdfc_else_if_else # branch if !is_single_value_domain()
      move $a0, $s7
      jal convert_highest_bit_to_int
      sub $s0, $s0, $v0 # remain_target -= convert_highest_bit_to_int
      addi $s1, $s1, -1 # remain_cell -= 1
      j gdfc_else_if_loop
  gdfc_else_if_else:
      or $s2, $s2, $s7 # domain_union |= puzzle->grid[pos].domain
      j gdfc_else_if_loop

  gdfc_for_end:
      move $a0, $s0
      move $a1, $s1
      move $a2, $s2
      jal get_domain_for_addition # $v0 = valid_domain = get_domain_for_addition()
      j gdfc_end

  gdfc_check_else:
      lw $t3, 12($s3) # puzzle->grid[position].cage->positions
      lw $t0, 0($t3) # puzzle->grid[position].cage->positions[0]
      lw $t1, 4($t3) # puzzle->grid[position].cage->positions[1]
      xor $t0, $t0, $t1
      xor $t0, $t0, $s6 # other_pos = $t0 = $t0 ^ position
      lw $a0, 4($s3) # puzzle->grid[position].cage->target

      sll $t2, $s6, 3 # position * 8
      add $a1, $s5, $t2 # &puzzle->grid[position]
      lw  $a1, 0($a1) # puzzle->grid[position].domain
      # move $a1, $s7

      sll $t1, $t0, 3 # other_pos*8 (actual offset)
      add $t3, $s5, $t1 # &puzzle->grid[other_pos]
      lw $a2, 0($t3)  # puzzle->grid[other_pos].domian

      jal get_domain_for_subtraction # $v0 = valid_domain = get_domain_for_subtraction()
      # j gdfc_end
  gdfc_end:
  	# restore registers

      lw $ra, 0($sp)
      lw $s0, 4($sp)
      lw $s1, 8($sp)
      lw $s2, 12($sp)
      lw $s3, 16($sp)
      lw $s4, 20($sp)
      lw $s5, 24($sp)
      lw $s6, 28($sp)
      lw $s7, 32($sp)
      add $sp, $sp, 36
      jr $ra
  #################################
  .globl clone
  clone:

      lw  $t0, 0($a0)
      sw  $t0, 0($a1)

      mul $t0, $t0, $t0
      mul $t0, $t0, 2 # two words in one grid

      lw  $t1, 4($a0) # &puzzle(ori).grid
      lw  $t2, 4($a1) # &puzzle(clone).grid

      li  $t3, 0 # i = 0;
  clone_for_loop:
      bge  $t3, $t0, clone_for_loop_end
      sll $t4, $t3, 2 # i * 4
      add $t5, $t1, $t4 # puzzle(ori).grid ith word
      lw   $t6, 0($t5)

      add $t5, $t2, $t4 # puzzle(clone).grid ith word
      sw   $t6, 0($t5)

      addi $t3, $t3, 1 # i++

      j    clone_for_loop
  clone_for_loop_end:

      jr  $ra
################################

main:

############ ENABLE INTERRUPTS ############

	# enable interrupts
	li	$t0,	BONK_MASK
	or	$t0,	$t0,	1
	mtc0	$t0,	$12
	li	$t0,	ON_FIRE_MASK
	or	$t0,	$t0,	1
	mtc0	$t0,	$12
	li	$t0,	MAX_GROWTH_INT_MASK
	or	$t0,	$t0,	1
	mtc0	$t0,	$12
	li	$t0,	REQUEST_PUZZLE_INT_MASK
	or	$t0,	$t0,	1
	mtc0	$t0,	$12

	add	$s7,	$0,	0
	add	$a3,	$0,	0

	# 校准位置
init_x_check:
	lw	$s4,	BOT_X
	div	$t1,	$s4,	30
	mul	$t1,	$t1,	30
	add	$t1,	$t1,	15
	beq	$s4,	$t1,	init_y_check
	bgt	$s4,	$t1,	init_x_decrease
	j	init_x_increase

init_x_decrease:
	li	$t0,	180
	sw	$t0,	ANGLE
	li	$t0,	1
	sw	$t0,	ANGLE_CONTROL
init_x_decrease_loop:
	lw	$s4,	BOT_X
	blt	$s4,	0xf,	init_y_check
	ble	$s4,	$t1,	init_y_check
	j	init_x_decrease_loop

init_x_increase:
	li	$t0,	0
	sw	$t0,	ANGLE
	li	$t0,	1
	sw	$t0,	ANGLE_CONTROL
init_x_increase_loop:
	lw	$s4,	BOT_X
	bgt	$s4,	0x11d,	init_y_check
	bge	$s4,	$t1,	init_y_check
	j	init_x_increase_loop

init_y_check:
	lw	$s5,	BOT_Y
	div	$t1,	$s5,	30
	mul	$t1,	$t1,	30
	add	$t1,	$t1,	15
	beq	$s5,	$t1,	main_loop
	bgt	$s5,	$t1,	init_y_decrease
	j	init_y_increase

init_y_decrease:
	li	$t0,	270
	sw	$t0,	ANGLE
	li	$t0,	1
	sw	$t0,	ANGLE_CONTROL
init_y_decrease_loop:
	lw	$s5,	BOT_Y
	blt	$s5,	0xf,	main_loop
	ble	$s5,	$t1,	main_loop
	j	init_y_decrease_loop

init_y_increase:
	li	$t0,	90
	sw	$t0,	ANGLE
	li	$t0,	1
	sw	$t0,	ANGLE_CONTROL
init_y_increase_loop:
	lw	$s5,	BOT_Y
	bgt	$s5,	0x11d,	main_loop
	bge	$s5,	$t1,	main_loop
	j	init_y_increase_loop

solve_puzzle:
	sw	$0,	VELOCITY
	la	$t0,	solution
	add	$t1,	$t0,	328
zero_loop:
	bge	$t0,	$t1,	done_zero
	sw	$0,	0($t0)
	add	$t0,	$t0,	4
	j	zero_loop
done_zero:
	la	$a0,	solution
	jal	recursive_backtracking
	sw	$a0,	SUBMIT_SOLUTION
	add	$s7,	$0,	0
	j	request

main_loop:

	la	$s3,	tile_data
	sw	$s3,	TILE_SCAN

############ CHECK RESOURCES ############

check_request_status:

	beq	$s7,	1,	solve_puzzle
	beq	$s7,	2,	has_fire

request:

	lw	$s0,	GET_NUM_WATER_DROPS
	lw	$s1,	GET_NUM_SEEDS
	lw	$s2,	GET_NUM_FIRE_STARTERS

	# 检查resource，没有的话request

	bgt	$s0,	0,	has_water
	li	$t0,	0
	sw	$t0,	SET_RESOURCE_TYPE
	la	$a1,	puzzle_data
	sw	$a1,	REQUEST_PUZZLE
	add	$s7,	$0,	2
	j	has_fire

has_water:

	bgt	$s1,	0,	has_seed
	li	$t0,	1
	sw	$t0,	SET_RESOURCE_TYPE
	la	$a1,	puzzle_data
	sw	$a1,	REQUEST_PUZZLE
	add	$s7,	$0,	2
	j	has_fire

has_seed:

	bgt	$s2,	0,	has_fire
	li	$t0,	2
	sw	$t0,	SET_RESOURCE_TYPE
	la	$a1,	puzzle_data
	sw	$a1,	REQUEST_PUZZLE
	add	$s7,	$0,	2

has_fire:

############ CHECK STATUS ############

	lw	$s4,	BOT_X
	div	$s4,	$s4,	30
	lw	$s5,	BOT_Y
	div	$s5,	$s5,	30
	mul	$s6,	$s5,	10
	add	$s6,	$s6,	$s4
	mul $s6,	$s6,	16
	add	$s6,	$s6,	$s3

	# struct TileInfo {
	#	int state; // Either 0 for EMPTY, 1 for GROWING
	#	int owning_bot; // 0 for owned by SPIMbot, 1 for owned by cohabitating bot
	#	int growth;
	#	int water;
	# };

	lw	$t1,	0($s6)	# t1 = state
	lw	$t2,	4($s6)	# t2 = owning_bot
	lw	$t3,	8($s6)	# t3 = growth
	lw	$t4,	12($s6)	# t4 = water

	# 对每一格check
	# if state == 0 & seed > 0 plant
	# if state == 1 & own == 0 & water > 0 water
	# if state == 1 & own == 1 & fire > 0 fire

	bgt	$t1,	0,	state_1

state_0:
	beq	$s1,	0,	finish_action
action_plant:
	add	$a3,	$a3,	1
	rem	$t0,	$a3,	5
	bne	$t0,	0,	finish_action
	sw	$0,	SEED_TILE
	sub	$s1,	$s1,	1
	j	finish_action

state_1:
	bgt	$t2,	0,	others_plant

my_plant:
	beq	$s0,	0,	finish_action
action_water:
	li	$t0,	10	# Dump 10 units of water
	sw	$t0,	WATER_TILE
	sub	$s0,	$s0,	1
	j	finish_action

others_plant:
	beq	$s2,	0,	finish_action
action_fire:
	sw	$0,	BURN_TILE
	sub	$s2,	$s2,	1
	j	finish_action

finish_action:

############ DETERMINE DIRECTION ############

	# 根据坐标，确定走的方向，走到下一格
	# s4 = x, s5 = y

	# if (x == 0) {
	# 	if (y == 0) x++;
	# 	else y--;
	# }
	# else if (y == 9) x--;
	# else if (y%2 == 0) {
	# 	if (x == 9) y++;
	# 	else x++;
	# }
	# else {
	# 	if (x == 1) y++;
	# 	else x--
	# }

	li	$t0,	10
	sw	$t0,	VELOCITY

	lw	$s4,	BOT_X
	div	$s4,	$s4,	30
	lw	$s5,	BOT_Y
	div	$s5,	$s5,	30
	beq	$s4,	0,	location_if_1
	beq $s5,	9,	x_decrease
	rem	$t5,	$s5,	2
	beq	$t5,	0,	location_if_2
	beq	$s4,	1,	y_increase
	j	x_decrease

location_if_1:
	beq	$s5,	0,	x_increase
	j	y_decrease

location_if_2:
	beq	$s4,	9,	y_increase
	j	x_increase

x_decrease:
	mul	$t1,	$s4,	30
	sub	$t1,	$t1,	15
x_decrease_loop:
	li	$t0,	180
	sw	$t0,	ANGLE
	li	$t0,	1
	sw	$t0,	ANGLE_CONTROL
	lw	$s4,	BOT_X
	blt	$s4,	0xf,	main_loop
	ble	$s4,	$t1,	main_loop
	j	x_decrease_loop

x_increase:
	mul	$t1,	$s4,	30
	add	$t1,	$t1,	45
x_increase_loop:
	li	$t0,	0
	sw	$t0,	ANGLE
	li	$t0,	1
	sw	$t0,	ANGLE_CONTROL
	lw	$s4,	BOT_X
	bgt	$s4,	0x11d,	main_loop
	bge	$s4,	$t1,	main_loop
	j	x_increase_loop

y_decrease:
	mul	$t1,	$s5,	30
	sub	$t1,	$t1,	15
y_decrease_loop:
	li	$t0,	270
	sw	$t0,	ANGLE
	li	$t0,	1
	sw	$t0,	ANGLE_CONTROL
	lw	$s5,	BOT_Y
	blt	$s5,	0xf,	main_loop
	ble	$s5,	$t1,	main_loop
	j	y_decrease_loop

y_increase:
	mul	$t1,	$s5,	30
	add	$t1,	$t1,	45
y_increase_loop:
	li	$t0,	90
	sw	$t0,	ANGLE
	li	$t0,	1
	sw	$t0,	ANGLE_CONTROL
	lw	$s5,	BOT_Y
	bgt	$s5,	0x11d,	main_loop
	bge	$s5,	$t1,	main_loop
	j	y_increase_loop

############ BACK TO MAIN LOOP ############

finish_walking: # 前面已经跳到 main_loop 了，所以这块其实没用

	j	main_loop

############ END OF PROGRAM ############

ret:
	jr	$ra

############ INTERRUPTS ############

.kdata
chunkIH:	.space 8
non_intrpt_str:	.asciiz	"Non-interrupt exception\n"
unhandled_str:	.asciiz	"Unhandled interrupt type\n"

.ktext 0x80000180

interrupt_handler:
.set	noat
	move	$k1, $at	# Save $at
.set	at
	la	$k0,	chunkIH
	sw	$a0,	0($k0)	# Get some free registers
	sw	$a1,	4($k0)	# by storing them to a global variable

	mfc0	$k0,	$13	# Get Cause register
	srl	$a0,	$k0,	2
	and	$a0,	$a0,	0xf	# ExcCode field
	bne	$a0,	0,	non_intrpt

interrupt_dispatch:	# Interrupt:

	mfc0	$k0,	$13	# Get Cause register, again
	beq	$k0,	0,	done	# handled all outstanding interrupts

	and	$a0,	$k0,	BONK_MASK
	bne	$a0,	0,	bonk_interrupt

	# add dispatch for other interrupt types here.
	and	$a0,	$k0,	ON_FIRE_MASK
	bne	$a0,	0,	fire_interrupt

	and	$a0,	$k0,	MAX_GROWTH_INT_MASK
	bne	$a0,	0,	max_growth_interrupt

	and	$a0,	$k0,	REQUEST_PUZZLE_INT_MASK
	bne	$a0,	0,	request_puzzle_interrupt

	li	$v0,	PRINT_STRING	# Unhandled interrupt types
	la	$a0,	unhandled_str
	syscall
	j	done

bonk_interrupt:

	sw	$a1,	BONK_ACK
	li	$a1,	10
	lw	$a0,	TIMER
	and	$a0,	$a0,	1
	bne	$a0,	$zero,	bonk_skip
	li	$a1,	-10
bonk_skip:
	sw	$a1,	0xffff0010($zero)
	j	interrupt_dispatch
############ FIRE INTERRUPTS ############

fire_interrupt: ## from lab 10.2

	sw	$a1,	ON_FIRE_ACK	# acknowledge interrupt
	lw	$t8,	GET_FIRE_LOC
	and	$t7,	$t8,	0xffff
	mul	$t7,	$t7,	30
	add	$t7,	$t7,	15 	# t7: y
	srl	$t8,	$t8,	16
	mul	$t8,	$t8,	30
	add	$t8,	$t8,	15 	# t8: x

	li	$t2,	1	# t2 = 1
	li	$t3,	10
	sw	$t3,	VELOCITY

	li	$t3,	0
	li	$t4,	90
	li	$t5,	180
	li	$t6,	270

find:
	lw	$t9,	BOT_X
	beq	$t9,	$t8,	x_equal
	bgt	$t9,	$t8,	x_big
	j	x_small

x_big:
	sw	$t5,	ANGLE
	sw	$t2,	ANGLE_CONTROL
x_big_loop:
	lw	$t9,	BOT_X
	blt	$t9,	0xf,	x_equal
	ble	$t9,	$t8,	x_equal
	j	x_big_loop

x_small:
	sw	$t3,	ANGLE
	sw	$t2,	ANGLE_CONTROL
x_small_loop:
	lw	$t9,	BOT_X
	bgt	$t9,	0x11d,	x_equal
	bge	$t9,	$t8,	x_equal
	j	x_small_loop

x_equal:

	lw	$t9,	BOT_Y	# t9 = y
	beq	$t9,	$t7,	y_equal
	bgt	$t9,	$t7,	y_big
	j	y_small

y_big:
	sw	$t6,	ANGLE
	sw	$t2,	ANGLE_CONTROL
y_big_loop:
	lw	$t9,	BOT_Y
	blt	$t9,	0xf,	y_equal
	ble	$t9,	$t7,	y_equal
	j	y_big_loop

y_small:
	sw	$t4,	ANGLE
	sw	$t2,	ANGLE_CONTROL
y_small_loop:
	lw	$t9,	BOT_Y
	bgt	$t9,	0x11d,	y_equal
	bge	$t9,	$t7,	y_equal
	j	y_small_loop

y_equal:

	sw	$t2,	PUT_OUT_FIRE
	sw	$0,	VELOCITY	# drive

	j	interrupt_dispatch

############ MAX GROWTH INTERRUPTS ############

max_growth_interrupt:

	sw	$zero,	MAX_GROWTH_ACK	#GROW acknoledge
	lw	$t9,	MAX_GROWTH_TILE	#location of the tile
	and	$t0,	$t9,	0xffff0000
	srl	$t0,	$t0,	16	#Store x_index to $t0
	and	$t1,	$t9,	0x0000ffff	#Store y_index to $t1
	mul	$t0,	$t0,	30
	mul	$t1,	$t1,	30
	add	$t0,	$t0,	15	#Convert x_index to location
	add	$t1,	$t1,	15	#Convert y_index to location

go_to_harvest:
check_y_har:
	lw	$t5,	BOT_Y #read bot-Y
	beq	$t1,	$t5,	find_y_har #beq $t7, 0, find_y
	bgt	$t1,	$t5,	move_downward_har
move_upward_har:
	li	$t8,	270 #temp, store angle
	sw	$t8,	ANGLE #set angle to 90, upward
	li	$t9,	1
	sw	$t9,	ANGLE_CONTROL
	add	$t8,	$zero, 10 #set v to -1
	sw	$t8,	VELOCITY #set velocity to 1
	j	check_y_har

move_downward_har:
	li	$t8,	90	#temp, store angle
	sw	$t8,	ANGLE	#set angle to 90, downward
	li	$t9,	1
	sw	$t9,	ANGLE_CONTROL
	li	$t8,	10	#temp, store velocity
	sw	$t8,	VELOCITY	#set velocity to 1
	j	check_y_har

find_y_har:
	#stop
	li	$t8,	0	#temp, store velocity
	sw	$t8,	VELOCITY	#set velocity to 0

check_x_har:
	lw	$t5,	BOT_X
	beq	$t0,	$t5,	On_har_loc
	bgt	$t0,	$t5,	move_right_fire	#distance-X, move right if >0

move_left_fire:
	li	$t8,	180 #temp, store angle
	sw	$t8,	ANGLE #set angle to 90, upward
	li	$t9,	1
	sw	$t9,	ANGLE_CONTROL
	add	$t8,	$zero, 10 #temp, store velocity
	sw	$t8,	VELOCITY #set velocity to 1
	j	check_x_har

move_right_fire:
	li	$t8,	0 #temp, store angle
	sw	$t8,	ANGLE #set angle to 90, upward
	li	$t9,	1
	sw	$t9,	ANGLE_CONTROL
	li	$t8,	10 #temp, store velocity
	sw	$t8,	VELOCITY #set velocity to -1
	j	check_x_har

On_har_loc:
	# li $t8, 0 	#temp, store velocity
	# sw $t8, VELOCITY 	#set velocity to -1
	sw	$t9,	HARVEST_TILE	#Put out the fire

	j	interrupt_dispatch


request_puzzle_interrupt:

	sw	$a1,	REQUEST_PUZZLE_ACK	# acknowledge interrupt
	add	$s7,	$0,	1

	j	interrupt_dispatch

############ END OF INTERRUPTS ############

non_intrpt:	# was some non-interrupt
	li	$v0,	PRINT_STRING
	la	$a0,	non_intrpt_str
	syscall	# print out an error message
	# fall through to done

done:
	la	$k0,	chunkIH
	lw	$a0,	0($k0)	# Restore saved registers
	lw	$a1,	4($k0)
.set noat
	move	$at,	$k1	# Restore $at
.set at
	eret
