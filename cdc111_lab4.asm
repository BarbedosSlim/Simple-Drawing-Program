#Cole Caron cdc111

# it is very important that you do not put any code or variables

# before this .include line. you can put comments, but nothing else.
.include "display_2244_0203.asm"
.include "lab4_graphics.asm"

.eqv MODE_NOTHING 0
.eqv MODE_BRUSH   1
.eqv MODE_COLOR   2

.eqv PALETTE_X  32
.eqv PALETTE_Y  56
.eqv PALETTE_X2 96
.eqv PALETTE_Y2 72

.data
	drawmode: .word MODE_NOTHING
	last_x:   .word -1
	last_y:   .word -1
	color:    .word 0b111111 # 3,3,3 (white)
.text

.global main
main:
	#display_init(15, 1, 0)
	li a0, 15
	li a1, 1
	li a2, 0
	jal display_init
	
	#load_graphics
	jal load_graphics
	
	_infinite:
		#jal check_input
		jal draw_cursor
		jal check_input
		jal display_finish_frame
		
		j _infinite

load_graphics:
push ra

	#display_load_sprite_gfx, Cursor_tile , N_cursor_tiles
	la a0, cursor_gfx
	li a1, CURSOR_TILE
	li a2 N_CURSOR_TILES
	jal display_load_sprite_gfx
	
	la a0, palette_sprite_gfx
	li a1, PALETTE_TILE
	li a2, N_PALETTE_TILES
	jal display_load_sprite_gfx

pop ra
jr ra

draw_cursor:
push ra
	la t1, display_spr_table
	
	#sprite x
	lw t0, display_mouse_x
	sub t0, t0, 3
	sb t0, 0(t1)
	
	#sprite y
	lw t0, display_mouse_y
	sub t0, t0, 3
	sb t0, 1(t1)
	
	#sprite tile number
	li t0, CURSOR_TILE
	sb t0, 2(t1)
	
	#sprite flags
	li t0, 0x41
	sb t0, 3(t1)

pop ra
jr ra

check_input:
push ra
	#If left button
	lw t0, drawmode
	bne t0, MODE_NOTHING, _endif_modenothing
	jal drawmode_nothing
	
	j _end
	
	_endif_modenothing:
	bne t0, MODE_BRUSH, _endif_modebrush
	jal drawmode_brush
	
	j _end 
	
	_endif_modebrush:
	bne t0, MODE_COLOR, _endif_modecolor
	jal drawmode_color
	
	_endif_modecolor:
	
	_end:
	
pop ra
jr ra

#--------------------------------------------
drawmode_brush:
push ra
	
	#check if button was released or went off screen
	lw t0, display_mouse_released
	and t0, t0, MOUSE_LBUTTON
	bne t0, 0, _setnothing
	
	lw t1, display_mouse_x
	lw t2, display_mouse_y
	blt t1, 0, _setnothing
	bgt t1, 127, _setnothing
	blt t2, 0, _setnothing
	bgt t2, 127, _setnothing
	j _else
	_setnothing:
	li t0, MODE_NOTHING
	sw t0, drawmode
	j _end_drawmode_brush
	
	
	_else:
	
	
	#else if
	lw t0, display_mouse_x
	lw t1, last_x
	bne t0, t1, _drawline
	
	lw t0, display_mouse_y
	lw t1, last_y
	bne t0, t1, _drawline
	j _end_drawmode_brush
	#draw line
	_drawline:
	lw a0, last_x
	lw a1, last_y
	lw a2, display_mouse_x
	lw a3, display_mouse_y
	lw v1, color
	jal display_draw_line
	
	#save last x/y
	lw t0, display_mouse_x
	sw t0, last_x
	
	lw t0, display_mouse_y
	sw t0, last_y
	
	j _end_drawmode_brush
	
	
	_end_drawmode_brush:
pop ra
jr ra

#--------------------------------------------
drawmode_color:
push ra
	
	
	#check to see if x is in range
	lw t1, display_mouse_x
	lw t2, display_mouse_y
	
	blt t1, PALETTE_X, _endif_color
	bge t1, PALETTE_X2, _endif_color
	blt t2, PALETTE_Y, _endif_color
	bge t2, PALETTE_Y2, _endif_color
	
	lw t0, display_mouse_pressed
	and t0, t0, MOUSE_LBUTTON
	beq t0, 0, _endif_color
	
	#convert to color
	lw t0, display_mouse_x
	lw t1, display_mouse_y
	
	sub t0, t0, PALETTE_X
	div t0, t0, 4
	
	sub t1, t1, PALETTE_Y
	div t1, t1, 4
	mul t1, t1, 16
	
	add t0, t0, t1
	sw t0, color
	
	li t4, 1
	_color_loop:
		mul t9, t4, 4
		#calculate flags
		li t0, 0
		sb zero, display_spr_table + 3(t9)
		
		#increment
		
	
		add t4, t4, 1
		blt t4, 17, _color_loop
	
	li t0, MODE_NOTHING
	sw t0, drawmode
	_endif_color:
	
pop ra
jr ra
#--------------------------------------------
drawmode_nothing:
push ra

	#check if left button was pressed
	lw t0, display_mouse_pressed
	and t0, t0, MOUSE_LBUTTON
	beq t0, 0, _endif_lbutton
	
	display_is_key_held t0, KEY_ALT
	beq t0, 0, _start_mode_brush
	
	#set color
	lw a0, display_mouse_x
	lw a1, display_mouse_y
	jal display_get_pixel
	
	sw v0, color
	
	j _endif_lbutton
	
	_start_mode_brush:
	#set to mode brush
	li t0, MODE_BRUSH
	sw t0, drawmode
	
	#start draw line
	display_is_key_held t0, KEY_SHIFT
	beq t0, 0, _normal_line
	
	#draw straight
	lw a0, last_x
	lw a1, last_y
	j _finish_draw_line
	
	_normal_line:
	#draw single pixel
	lw a0, display_mouse_x
	lw a1, display_mouse_y
	
	_finish_draw_line:
	lw a2, display_mouse_x
	lw a3, display_mouse_y
	lw v1, color
	jal display_draw_line
	
	#set last x/y coordinates
	
	lw t0, display_mouse_x
	sw t0, last_x
	
	lw t0, display_mouse_y
	sw t0, last_y
	
	#jump to end of function
	j _end_drawmode_nothing
	
	_endif_lbutton:
	
	
	li t0, KEY_C
	sw t0, display_key_pressed
	lw t0, display_key_pressed
	beq t0, 0, _endif_Ckey
	
	li t1, MODE_COLOR
	sw t1, drawmode	
	
	#Draw tile map
	la t9, display_spr_table
	add t9, t9, 4
	
	#y axis counter
	li s0, 0
	_loop_outside:
		#x axis counter
		li s1, 0
		_loop_inside:
		#calculate x
		mul t8, s1, 8
		add t0, t8, PALETTE_X
		sb t0, 0(t9)
		
		#calculate y
		mul t8, s0, 8
		add t0, t8, PALETTE_Y
		sb t0, 1(t9)
		
		#calcutate pallate tile
		
		mul t0, s0, 8
		add t0, t0, s1
		add t0, t0, PALETTE_TILE
		sb t0, 2(t9)
		
		#calculate flags
		li t0, 1
		sb t0, 3(t9)
		
		#increment
		add t9, t9, 4
		add s1, s1, 1
		ble s1, 7, _loop_inside
	
	
	add s0, s0, 1
	ble s0, 2, _loop_outside
	j _end_drawmode_nothing
	_endif_Ckey:
	
	#Flood Fill
	li t0, KEY_F
	sw t0, display_key_pressed
	lw t0, display_key_pressed
	beq t0, 0, _endif_Fkey
	
	lw a0, display_mouse_x
	lw a1, display_mouse_y
	jal display_get_pixel
	
	lw a0, display_mouse_x
	lw, a1, display_mouse_y
	move a2, v0
	lw a3, color
	jal flood_fill_rec
	
	_endif_Fkey:
	
	
	
	
	_end_drawmode_nothing:
	

pop ra
jr ra
#------------------------------------------
display_get_pixel:
push ra
	sll t0, a1, DISPLAY_W_SHIFT
	add t0, t0, a0
	lb v0, display_fb_ram(t0)
pop ra
jr  ra

#-----------------------------------------
#a0 = display_mouse_x
#a1 = display_mouse_y
#a2 = target
#a3 = repl
flood_fill_rec:
push ra
push s0
push s1
push s2
push s3
	
	#set arguments to saved
	move s0, a0
	move s1, a1
	move s2, a2
	move s3, a3
	
	jal display_get_pixel
	
	beq v0, s3, _return
	bne v0, s2 _return
	
	move a0, s0
	move a1, s1
	move a2, s3
	jal display_set_pixel
	
	ble s0, 0, _end_xgt
		move a0, s0
		sub a0, a0, 1
		move a1, s1
		move a2, s2
		move a3, s3
		jal flood_fill_rec
	_end_xgt:
	
	bge s0, 127, _end_xlt
		move a0, s0
		add a0, a0, 1
		move a1, s1
		move a2, s2
		move a3, s3
		jal flood_fill_rec
	_end_xlt:
	
	ble s1, 0, _end_ygt
		move a0, s0
		move a1, s1
		sub a1, a1, 1
		move a2, s2
		move a3, s3
		jal flood_fill_rec
	_end_ygt:
	
	bge s1, 127, _end_ylt
		move a0, s0
		move a1, s1
		add a1, a1, 1
		move a2, s2
		move a3, s3
		jal flood_fill_rec
	_end_ylt:
	
	_return:
pop s3
pop s2
pop s1
pop s0
pop ra
jr ra



