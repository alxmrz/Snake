format ELF64

section '.data' writeable

include 'sdl.inc'
include 'constants.inc'

formatStr db "%s", 0
formatInt db '%d', 0
empty_string db " "

init_err_msg            db "SDL_Init Error: %s", 10, 0
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
exited_msg db "Good by!", 10, 0 

is_game_running db 0
is_game_over db 0
is_game_need_restart db 0

loop_counter dq 0
loop_counter_dd dd 0

snake_direction db DIRECTION_NONE
snake_parts dd 50 dup (-1,-1), 0 ; 200 bytes for 50 snake parts (0 - x, 1 - y), (2 - x, 3 - y)  ... etc
snake_parts_count dd 0
snake_movement_counter dq 0
snake_speed dq 500
snakeRect SDL_Rect 10,10,10,10

foodRect SDL_Rect 0, 0, 0, 0
foodX dd 0
foodY dd 0

window rq 1
renderer rq 1
mainRect SDL_Rect 0,0,0,0
window_title db "Snake", 0
event rq 256/8 

red_color SDL_Color 255, 0, 0, 0
blue_color SDL_Color 0, 0, 255, 0

font_path db "./resources/Sans.ttf", 0
start_message db "Press an <arrow key> to start", 0
game_over_message db "Game over", 0
press_space_message db "Press <space> to restart", 0
score_message db "Score: ", 0
print_message db ?
messageRect SDL_Rect 0,0,0,0
backgroundRect SDL_Rect 0,0,0,0
buf rb 250
; Code segment 
section ".text" executable

public main
extrn printf
extrn sprintf
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
extrn TTF_Init
extrn TTF_Quit
extrn TTF_OpenFont
extrn TTF_RenderText_Solid
extrn TTF_GetError
extrn TTF_CloseFont
extrn random
extrn srand
extrn time

main:
    push rsp

    mov rdi, SDL_INIT_EVERYTHING
	call SDL_Init
	cmp rax, 0
	jl init_err

	call TTF_Init
	cmp rax, 0
	jl init_err

	mov rdi, window_title
	mov rsi, WINDOW_X_POSITION
	mov rdx, WINDOW_Y_POSITION
	mov rcx, WINDOW_WIDTH
	mov r8, WINDOW_HEIGHT
	mov r9, SDL_WINDOW_SHOWN
	call SDL_CreateWindow
	cmp rax, 0
	je create_window_err

    mov [window], rax

	mov rdi, rax
	mov rsi, -1
	mov rdx, 6
	call SDL_CreateRenderer
	cmp rax, 0
	je create_renderer_err

    mov [renderer], rax

    mov rdi, [window]
    call SDL_GetWindowSurface
    cmp rax, 0
    je create_window_err

	call start_new_game
	mov [is_game_running], 1

game_loop:
	call update_game_state

	call handle_events

    mov rdi, [window]
    call SDL_UpdateWindowSurface
    cmp rax, 0
	jne update_window_surface_error
    
    call display_main_scene
    call display_snake
	call display_food
	call print_score

	cmp [snake_direction], DIRECTION_NONE
	jne .game_over_check
	call print_start_message

.game_over_check:

	cmp [is_game_over], 1
	jne .need_restart_check

	call print_game_over

.need_restart_check:
	cmp [is_game_need_restart], 1
	jne .render_part

	call start_new_game

.render_part:
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
	call TTF_Quit
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
handle_space_arrow_key:
	
	mov [is_game_need_restart], 1

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
    
	mov [loop_counter], 0

.foreach_snake_parts:
	mov rdi, [renderer]
	mov rsi, 255
	mov rdx, 0
	mov rcx, 0
	mov r8, 0
    call SDL_SetRenderDrawColor
    cmp rax, 0
	jne set_render_draw_color_error

	xor rcx, rcx;
	xor rdi, rdi;

	mov rcx, [loop_counter]
	mov edi, [snake_parts+rcx]
	mov [snakeRect.x], edi

	mov rcx, [loop_counter]
	mov edi,[snake_parts+rcx+4]
    mov [snakeRect.y], edi

    mov [snakeRect.w], 50
    mov [snakeRect.h], 50

    mov rdi, [renderer]
    mov rsi, snakeRect
    call SDL_RenderFillRect
	cmp rax, 0
	jne render_fill_error

	mov rdi, [renderer]
	mov rsi, 0
	mov rdx, 0
	mov rcx, 0
	mov r8, 0
    call SDL_SetRenderDrawColor
    cmp rax, 0
	jne set_render_draw_color_error


    mov rdi, [renderer]
    mov rsi, snakeRect
    call SDL_RenderDrawRect
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

update_game_state:
	cmp [is_game_over], 1
	je .end

	mov rax, [snake_speed]
	cmp [snake_movement_counter], rax
	jl .end_update_game_state

	mov [snake_movement_counter], 0

	cmp [snake_direction], DIRECTION_LEFT
	jne .not_left_direction

	call move_snake_left

	jmp .end_update_game_state
.not_left_direction:
	cmp [snake_direction], DIRECTION_RIGHT
	jne .not_right_direction
	call log_here_message
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
	je .end

	call set_game_over

.end:
	ret
create_snake:
	xor rax, rax
.foreach_snake_parts:
	cmp [snake_parts_count], 0
	je .create_new_body

	mov [snake_parts+rax], -1
	mov [snake_parts+rax+4], -1

	add rax, 8
	sub [snake_parts_count], 1
	jmp .foreach_snake_parts

.create_new_body:
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
	mov [is_game_over], 1

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
handle_events:
	push rdi

.eventHandlingLoop:
	mov rdi,event
	call SDL_PollEvent
	cmp rax, 0
	je .afterEventHandling

	mov rax, event
	cmp dword[rax], SDL_QUIT
	jne .not_quit
	
	mov [is_game_running], 0
	jmp .afterEventHandling

.not_quit:
	cmp dword[rax], SDL_KEYDOWN
	jne .eventHandlingLoop

	xor rdi, rdi

	mov edi, dword [rax+20]  ; key.keysym.sym

	cmp rdi, SDL_LEFT_ARROW_KEY ; left arrow
	jne .not_left
	
	call handle_left_arrow_key
	jmp .afterEventHandling

.not_left:
	cmp rdi, SDL_RIGHT_ARROW_KEY ; right arrow
	jne .not_right

	call handle_right_arrow_key
	jmp .afterEventHandling

.not_right:
	cmp rdi, SDL_UP_ARROW_KEY ; up arrow
	jne .not_up
	
	call handle_up_arrow_key
	jmp .afterEventHandling

.not_up:
	cmp rdi, SDL_DOWN_ARROW_KEY ; down arrow
	jne .not_down

	call handle_down_arrow_key
	jmp .afterEventHandling

.not_down:
	cmp rdi, SDLK_SPACE
	jne .eventHandlingLoop

	call handle_space_arrow_key
	jmp .afterEventHandling

.afterEventHandling:
	pop rdi

	ret	

print_start_message:
	push rdi

	mov rdi, [renderer]
	mov rsi, 0
	mov rdx, 108
	mov rcx, 0
	mov r8, 0
    call SDL_SetRenderDrawColor

    mov [backgroundRect.x], 90
    mov [backgroundRect.y], 190
    mov [backgroundRect.w], 310
    mov [backgroundRect.h], 110

    mov rdi, [renderer]
    mov rsi, backgroundRect
    call SDL_RenderFillRect

	mov [messageRect.x], 100
	mov [messageRect.y], 200
	mov [messageRect.w], 300
	mov [messageRect.h], 100

	mov rdi, messageRect
	mov rsi, blue_color
	mov rdx, start_message
	call print_text

	pop rdi
	ret

print_game_over:
	push rdi

	mov rdi, [renderer]
	mov rsi, 0
	mov rdx, 0
	mov rcx, 0
	mov r8, 0
    call SDL_SetRenderDrawColor

    mov [backgroundRect.x], 80
    mov [backgroundRect.y], 180
    mov [backgroundRect.w], 350
    mov [backgroundRect.h], 250

    mov rdi, [renderer]
    mov rsi, backgroundRect
    call SDL_RenderFillRect

	mov [messageRect.x], 100
	mov [messageRect.y], 200
	mov [messageRect.w], 300
	mov [messageRect.h], 100

	mov rdi, messageRect
	mov rsi, red_color
	mov rdx, game_over_message
	call print_text


	mov [messageRect.x], 100
	mov [messageRect.y], 300
	mov [messageRect.w], 300
	mov [messageRect.h], 100

	mov rdi, messageRect
	mov rsi, red_color
	mov rdx, press_space_message
	call print_text

	pop rdi
	ret

print_score:
	push rdi

mov rdi, [renderer]
	mov rsi, 0
	mov rdx, 0
	mov rcx, 0
	mov r8, 0
    call SDL_SetRenderDrawColor

    mov [backgroundRect.x], 500
    mov [backgroundRect.y], 0
    mov [backgroundRect.w], 350
    mov [backgroundRect.h], WINDOW_HEIGHT

    mov rdi, [renderer]
    mov rsi, backgroundRect
    call SDL_RenderFillRect

	mov [messageRect.x], 550
	mov [messageRect.y], 100
	mov [messageRect.w], 200
	mov [messageRect.h], 100

	mov rdi, messageRect
	mov rsi, blue_color
	mov rdx, score_message
	call print_text

	mov [messageRect.x], 750
	mov [messageRect.y], 120
	mov [messageRect.w], 80
	mov [messageRect.h], 80

	mov rax, qword[snake_parts_count]
	sub rax, 3
	mov rdx, 100
	mul rdx

    mov rdi, buf
    mov rsi, formatInt
    mov rdx, rax
    call sprintf

	mov rdi, messageRect
	mov rsi, blue_color
	mov rdx, buf
	call print_text

	pop rdi
	ret

print_text:
	push rdi
	mov r14, rdx ;  message text
	mov r15, rdi ; message rect
	mov rbp, rsi ; message text color

	xor rdi, rdi
	xor rsi, rsi
	
	mov rdi, font_path
	mov rsi, 24
	call TTF_OpenFont

	cmp rax, 0
	je .no_font

	mov r12, rax ; FONT sans in r12

	mov rdi, r12
	mov rsi, r14
	mov rdx, [rbp]
	call TTF_RenderText_Solid
	
	cmp rax, 0
	je .no_font

	mov r13, rax ; surfaceMessage in r13

	mov rdi, [renderer]
	mov rsi, r13
	call SDL_CreateTextureFromSurface

	cmp rax, 0
	je .no_font

	mov r14, rax ; SDL_Texture message

	mov rdi, [renderer]
	mov rsi, r14
	mov rdx, 0
	mov rcx, r15
	call SDL_RenderCopy

	mov rdi, r12
	call TTF_CloseFont

	mov rdi, r14
	call SDL_DestroyTexture

	mov rdi, r13
	call SDL_FreeSurface

	jmp .end
.no_font:
	call SDL_GetError
	mov rsi, rax
	mov rdi, formatStr
	call printf

	jmp .end
.end:
	pop rdi
	ret	

start_new_game:
	call create_snake
	call create_food

	mov [is_game_over], 0
	mov [is_game_need_restart], 0
	mov [snake_direction], DIRECTION_NONE
	mov [snake_speed], 500

	ret