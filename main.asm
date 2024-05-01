format ELF64


section '.data' writeable

    include 'sdl.inc'


hello db 'Hello, +++++', 0
world db ' world!', 0
formatStr db "%s", 0
formatInt db '%d', 10, 0

empty_string db " "

concated rb 16
init_err_msg            db "SDL_Init Error: %s", 10, 0
create_window_arg0      db "Hello World!", 0
create_window_err_msg   db "SDL_CreateWindow Error: %s", 10, 0
create_renderer_err_msg db "SDL_CreateRenderer Error: %s", 10, 0
render_fill_error_msg db "SDL_RenderFillRect Error: %s", 10, 0
update_window_surface_error_msg db "SDL_UpdateWindowSurface Error: %s", 10, 0
set_render_draw_color_error_msg db "SDL_SetRenderDrawColor Error: %s", 10, 0 
log_here_msg db "Logged here", 10, 0 
left_arrow_pressed_msg db "left_arrow_pressed_msg", 10, 0 
right_arrow_pressed_msg db "right_arrow_pressed_msg", 10, 0 
up_arrow_pressed_msg db "up_arrow_pressed_msg", 10, 0 
down_arrow_pressed_msg db "down_arrow_pressed_msg", 10, 0 
exited_msg db "exited", 10, 0 
is_game_running db 0

loop_counter dq 0
loop_counter_dd dd 0

snake_direction db 2
snake_parts dd 50 dup (-1,-1) ; 100 bytes for 50 snake parts (0 - x, 1 - y), (2 - x, 3 - y)  ... etc
snake_parts_count dd 0
event db 56 dup (?) ; SDL_Event type
sdl_eventbuf rq 256/8

mainRect SDL_Rect 0,0,0,0
snakeRect SDL_Rect 10,10,10,10

foodRect SDL_Rect 0, 0, 0, 0
foodX dd 0
foodY dd 0

snake_x dq 0
snake_y dq 0

snake_speed dq 500

window rq 1
renderer rq 1

snake_movement_counter dq 0

GAME_AREA_WIDTH = 500
GAME_AREA_HEIGHT = 500

DIRECTION_LEFT = 1
DIRECTION_RIGHT = 2
DIRECTION_UP = 3
DIRECTION_DOWN = 4

SEED_X = 100
SEED_Y = 200

; Code segment 
section ".text" executable

public main
extrn printf
extrn SDL_Init
extrn SDL_CreateWindow
extrn SDL_CreateRenderer
extrn SDL_LoadBMP_RW
extrn SDL_RWFromFile
extrn SDL_CreateTextureFromSurface
extrn SDL_FreeSurface
extrn SDL_RenderClear
extrn SDL_RenderCopy
extrn SDL_RenderPresent
extrn SDL_Delay	
extrn SDL_DestroyTexture
extrn SDL_DestroyRenderer
extrn SDL_DestroyWindow
extrn SDL_Quit
extrn SDL_GetError
extrn SDL_UpdateWindowSurface
extrn SDL_SetRenderDrawColor
extrn SDL_RenderFillRect
extrn SDL_RenderDrawRect
extrn SDL_GetWindowSurface
extrn SDL_PollEvent
extrn random
extrn srand
extrn time

main:
    push rsp
	;mov rbp, rsp; for correct debugging
    ;and rsp, -16

	;call log_here_message

    mov rdi, 62001
	call SDL_Init
	cmp rax, 0
	jl init_err

	mov rdi, create_window_arg0
	mov rsi, 100
	mov rdx, 100
	mov rcx, 960
	mov r8, 720
	mov r9, 4
	call SDL_CreateWindow
	cmp rax, 0
	je create_window_err

	mov r12, rax ; window pointer
    mov [window], r12

	mov rdi, rax
	mov rsi, -1
	mov rdx, 6
	call SDL_CreateRenderer
	cmp rax, 0
	je create_renderer_err

	mov r13, rax ; renderer pointer
    mov [renderer], r13

    mov rdi, [window]
    call SDL_GetWindowSurface
    cmp rax, 0
    je create_window_err

	call create_food
	call create_snake

	mov [is_game_running], 1

game_loop:

eventHandlingLoop:
	mov rdi,sdl_eventbuf
	call SDL_PollEvent

	cmp rax, 0
	je afterEventHandling

	mov rax, sdl_eventbuf
	cmp dword[rax], 0x0100 ; SDL_QUIT
	jne .not_quit
	
	mov [is_game_running], 0
	jmp afterEventHandling

.not_quit:
	cmp dword[rax], 0x0300; SDL_KEYDOWN
	jne eventHandlingLoop

	;call log_here_message
	;call log_here_message
	xor rdi, rdi
	;mov rdi, qword[rax+20]

	mov edi, dword [rax+20]  ; kev.keysym.sym

	cmp rdi, 1073741904 ; left arrow
	jne .not_left
	
	call handle_left_arrow_key
	jmp afterEventHandling

.not_left:
	cmp rdi, 1073741903 ; right arrow
	jne .not_right

	call handle_right_arrow_key
	jmp afterEventHandling

.not_right:
	cmp rdi, 1073741906 ; up arrow
	jne .not_up
	
	call handle_up_arrow_key
	jmp afterEventHandling

.not_up:
	cmp rdi, 1073741905 ; down arrow
	jne eventHandlingLoop

	call handle_down_arrow_key
	jmp afterEventHandling

afterEventHandling:
	call updage_game_state

    mov rdi, [window]
    call SDL_UpdateWindowSurface
    cmp rax, 0
	jne update_window_surface_error
    
    call display_main_scene

    call display_snake
	call display_food

    mov rdi, [renderer]
    call SDL_RenderPresent

    mov rdi, 10
	call SDL_Delay
	add [snake_movement_counter], 10

	cmp [is_game_running], 0
	jne game_loop

    mov rdi, [renderer]
	call SDL_DestroyRenderer
	mov rdi, [window]
	call SDL_DestroyWindow
	call SDL_Quit
	mov rdi, 0
	jmp exit
exit:
	mov rdi, exited_msg
	call printMessage

	pop rsp
	xor rax, rax

    ret

init_err:
	call SDL_GetError
	mov rsi, rax
	mov rdi, init_err_msg
	call printf
	mov rdi, 8
	jmp exit

create_window_err:
	call SDL_GetError
	mov rsi, rax
	mov rdi, create_window_err_msg
	call printf
	mov rdi, 8
	jmp exit    

create_renderer_err:
	call SDL_GetError
	mov rsi, rax
	mov rdi, create_renderer_err_msg
	call printf
	mov rdi, r12
	call SDL_DestroyWindow
	call SDL_Quit
	mov rdi, 8
	jmp exit

render_fill_error:
	call SDL_GetError
	mov rsi, rax
	mov rdi, render_fill_error_msg
	call printf
	mov rdi, r12
	call SDL_DestroyWindow
	call SDL_Quit
	mov rdi, 8
	jmp exit

update_window_surface_error:
	call SDL_GetError
	mov rsi, rax
	mov rdi, update_window_surface_error_msg
	call printf
	mov rdi, r12
	call SDL_DestroyWindow
	call SDL_Quit
	mov rdi, 8
	jmp exit
set_render_draw_color_error:
	call SDL_GetError
	mov rsi, rax
	mov rdi, set_render_draw_color_error_msg
	call printf
	mov rdi, r12
	call SDL_DestroyWindow
	call SDL_Quit
	mov rdi, 8 ; TODO: maybe delete this?
	jmp exit
log_here_message:
	mov rbp, rsp; for correct debugging
	and rsp, -16

	mov rdi, formatStr
	mov rsi, log_here_msg
	call printf
	
	mov rsp, rbp
	xor rax, rax

	ret
printMessage:
	mov rbp, rsp; for correct debugging
	and rsp, -16

	;mov rdi, formatStr
	;mov rsi, log_here_msg
	call printf
	
	mov rsp, rbp
	xor rax, rax

	ret

printInteger:
	mov rbp, rsp; for correct debugging
	and rsp, -16

	mov rdi, formatInt
	;mov rsi, 50
	call printf

	mov rsp, rbp
	xor rax, rax

	ret

handle_left_arrow_key:
	cmp [snake_direction], DIRECTION_RIGHT
	je .end

	mov [snake_direction], DIRECTION_LEFT

	mov rdi, left_arrow_pressed_msg
	call printMessage
.end:
	ret
handle_right_arrow_key:
	cmp [snake_direction], DIRECTION_LEFT
	je .end

	mov [snake_direction], DIRECTION_RIGHT

	mov rdi, right_arrow_pressed_msg
	call printMessage
.end:
	ret
handle_up_arrow_key:
	cmp [snake_direction], DIRECTION_DOWN
	je .end

	mov [snake_direction], DIRECTION_UP

	mov rdi, up_arrow_pressed_msg
	call printMessage
.end:
	ret
handle_down_arrow_key:
	cmp [snake_direction], DIRECTION_UP
	je .end

	mov [snake_direction], DIRECTION_DOWN

	mov rdi, down_arrow_pressed_msg
	call printMessage
.end:
	ret
display_main_scene:
	mov rdi, [renderer]
	mov rsi, 160
	mov rdx, 160
	mov rcx, 160
	mov r8, 0
    call SDL_SetRenderDrawColor
    cmp rax, 0
	jne set_render_draw_color_error ; TODO: fix this message, it will throw segfault on error because of stack

    mov [mainRect.x], 0
    mov [mainRect.y], 0
    mov [mainRect.w], GAME_AREA_WIDTH
    mov [mainRect.h], GAME_AREA_HEIGHT

    mov rdi, [renderer]
    mov rsi, mainRect
    call SDL_RenderFillRect
	cmp rax, 0
	jne render_fill_error	

	ret
display_snake:
	mov rdi, [renderer]
	mov rsi, 255
	mov rdx, 0
	mov rcx, 0
	mov r8, 0
    call SDL_SetRenderDrawColor
    cmp rax, 0
	jne set_render_draw_color_error
    
	mov [loop_counter], 0

.foreach_snake_parts:
	xor rcx, rcx;
	xor rdi, rdi;

	mov rcx, [loop_counter]
	mov edi, [snake_parts+rcx]
	mov [snakeRect.x], edi

	;mov rsi, [loop_counter]
	;call printInteger
	;call log_here_message

	mov rcx, [loop_counter]
	mov edi,[snake_parts+rcx+4]
    mov [snakeRect.y], edi

    mov [snakeRect.w], 50
    mov [snakeRect.h], 50

	;xor rdi, rdi

    mov rdi, [renderer]
    mov rsi, snakeRect
    call SDL_RenderFillRect
	cmp rax, 0
	jne render_fill_error

	add [loop_counter], 8

	mov rcx, [loop_counter]
	cmp [snake_parts+rcx], -1
	jne .foreach_snake_parts

	ret	

display_food:
	mov rdi, [renderer]
	mov rsi, 255
	mov rdx, 0
	mov rcx, 255
	mov r8, 0
    call SDL_SetRenderDrawColor
    cmp rax, 0
	jne set_render_draw_color_error
    
	mov [loop_counter], 0

	mov edi, [foodX]
	mov esi, [foodY]

	mov [foodRect.x], edi
    mov [foodRect.y], esi
    mov [foodRect.w], 50
    mov [foodRect.h], 50

    mov rdi, [renderer]
    mov rsi, foodRect
    call SDL_RenderFillRect
	cmp rax, 0
	jne render_fill_error

	ret	

updage_game_state:
	mov rax, [snake_speed]
	cmp [snake_movement_counter], rax
	jne .end_update_game_state

	mov [snake_movement_counter], 0

	cmp [snake_direction], DIRECTION_LEFT
	jne .not_left_direction

	call move_snake_left

	jmp .end_update_game_state
.not_left_direction:
	cmp [snake_direction], DIRECTION_RIGHT
	jne .not_right_direction

	call move_snake_right

	jmp .end_update_game_state	
.not_right_direction:	
	cmp [snake_direction], DIRECTION_UP
	jne .not_up_direction

	call move_snake_up

	jmp .end_update_game_state
.not_up_direction:	
	cmp [snake_direction], DIRECTION_DOWN
	jne .end_update_game_state

	call move_snake_down

.end_update_game_state:
	
	call is_snake_collided_food
	cmp rax, 0
	je .not_collided

	call speed_up_snake
	call add_snake_part
	call create_food

.not_collided:

	call is_snake_collided_itself
	cmp rax, 0
	je .snake_not_collided_itself

	call set_game_over

.snake_not_collided_itself:
	ret
create_snake:
	mov [snake_parts], 100
	mov [snake_parts+4], 50
	
	mov [snake_parts+8], 50
	mov [snake_parts+12], 50

	mov [snake_parts+16], 0
	mov [snake_parts+20], 50

	mov [snake_parts_count], 3

	ret

add_snake_part:
	mov rax, qword[snake_parts_count]
	mov rdx, 8

	mul rdx

	mov edi, [snake_parts+rax-8]
	mov [snake_parts+rax], edi

	mov edi, [snake_parts+rax-4]
	mov [snake_parts+rax+4], edi

	inc [snake_parts_count]

	ret

move_snake_left:
	xor rdi, rdi
	xor rsi, rsi
	xor r12, r12

	mov edi, [snake_parts]
	mov esi, [snake_parts+4]

	sub dword[snake_parts], 50
	
	cmp dword[snake_parts], 0
	jge .left_move_body

	mov dword[snake_parts], GAME_AREA_WIDTH-50

.left_move_body:
	call move_snake_body

	ret

move_snake_right:
	xor rdi, rdi
	xor rsi, rsi
	xor r12, r12

	mov edi, [snake_parts]
	mov esi, [snake_parts+4]

	add dword[snake_parts], 50

	cmp dword[snake_parts], GAME_AREA_WIDTH
	jl .right_move_body

	mov dword[snake_parts], 0

.right_move_body:

	call move_snake_body

	ret

move_snake_up:
	xor rdi, rdi
	xor rsi, rsi
	xor r12, r12

	mov edi, [snake_parts]
	mov esi, [snake_parts+4]

	sub dword[snake_parts+4], 50

	cmp dword[snake_parts+4], 0
	jge .up_move_body

	mov dword[snake_parts+4], GAME_AREA_HEIGHT-50

.up_move_body:
	call move_snake_body

	ret

move_snake_down:
	xor rdi, rdi
	xor rsi, rsi
	xor r12, r12

	mov edi, [snake_parts]
	mov esi, [snake_parts+4]

	add dword[snake_parts+4], 50

	cmp dword[snake_parts+4], GAME_AREA_HEIGHT
	jl .down_move_body

	mov dword[snake_parts+4], 0

.down_move_body:

	call move_snake_body

	ret

move_snake_body:
	mov [loop_counter], 8 ; snake body starts from 8 byte
.for_every_part:
	mov r12, [loop_counter]

	mov r8d, [snake_parts+r12]   ; current body x
	mov r9d, [snake_parts+r12+4] ; current body y
	
	mov [snake_parts+r12], edi
	mov [snake_parts+r12+4], esi

	mov edi, r8d   ; prev body x to next
	mov esi, r9d   ; prev body y to next
	
	add [loop_counter], 8
	mov r12, [loop_counter]

	cmp [snake_parts+r12], -1
	jne .for_every_part

	ret
create_food:
.start_food_creation:
	mov rdi, SEED_X
	call get_random_coord

	mov [foodX], eax

	mov rdi, SEED_Y
	call get_random_coord

	mov [foodY], eax

	call is_food_created_on_snake
	cmp rax, 1
	je .start_food_creation

	ret	

get_random_coord:

	push rdi ; rdi - passed seed for random

	mov rdi, 0x00
	call time

	pop rdi
	add rax, rdi

	mov rdi, rax
	call srand
.random:
	call random

	mov rcx, GAME_AREA_WIDTH
	mov rdx, 0
	div rcx

	mov r8, rdx

	mov rax, r8
	mov rcx, 50 ; check that random_coord % 50 equal to 0 for correct snake and food colision
	mov rdx, 0
	div rcx

	cmp rdx, 0
	jne .random

	mov rax, r8

	ret
is_snake_collided_food:
	mov edi, [foodX]
	cmp [snake_parts], edi
	jne .snake_not_collided

	mov edi, [foodY]
	cmp [snake_parts+4], edi
	jne .snake_not_collided

.snake_collided:
	mov rax, 1
	jmp .end
.snake_not_collided:
	mov rax, 0
.end:
	ret	
is_snake_collided_itself:
	xor rax, rax

	mov [loop_counter_dd], 1
.foreach_snake_parts_1:
	xor rax, rax
	xor rdx, rdx
	xor rdi, rdi

	mov r8d, [snake_parts]
	mov r9d, [snake_parts+4]

	mov eax, [loop_counter_dd]
	mov edx, 8

	mul edx

	mov edi, [snake_parts+eax]
	cmp edi, r8d
	jne .incrementor

	mov edi, [snake_parts+eax+4]
	cmp edi, r9d
	je .snake_collided_itself

.incrementor:
	add [loop_counter_dd], 1

	mov edi, [snake_parts_count]
	mov edx, [loop_counter_dd]
	cmp edx, edi
	jle .foreach_snake_parts_1
	
	jmp .snake_not_collided_itself

.snake_collided_itself:
	mov rax, 1
	jmp .end
.snake_not_collided_itself:
	mov rax, 0
.end:
	ret
set_game_over:
	mov [is_game_running], 0

	ret
is_food_created_on_snake:

	mov [loop_counter_dd], 0
.foreach_snake_parts_1:
	xor rax, rax
	xor rdx, rdx
	xor rdi, rdi

	mov r8d, [foodX]
	mov r9d, [foodY]

	mov eax, [loop_counter_dd]
	mov edx, 8

	mul edx

	mov edi, [snake_parts+eax]
	cmp edi, r8d
	jne .incrementor

	mov edi, [snake_parts+eax+4]
	cmp edi, r9d
	je .wrong_creation

.incrementor:
	add [loop_counter_dd], 1

	mov edi, [snake_parts_count]
	mov edx, [loop_counter_dd]
	cmp edx, edi
	jle .foreach_snake_parts_1
	
	jmp .good_creation

.wrong_creation:
	; TODO: too often wrong creation, need fix coords' randomnes
	mov rax, 1
	jmp .end
.good_creation:
	mov rax, 0
.end:
	ret
speed_up_snake:
	cmp [snake_speed], 50
	jle .end

	sub [snake_speed], 10

.end:
	ret	