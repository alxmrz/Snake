format ELF64


section '.data' writeable

    include 'sdl.inc'


hello db 'Hello, +++++', 0
world db ' world!', 0
formatStr db "%s", 0
formatInt db "%d", 0
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

snake_direction db 2
snake_parts db 50 dup (-1,-1) ; 100 bytes for 50 snake parts (0 - x, 1 - y), (2 - x, 3 - y)  ... etc

event db 56 dup (?) ; SDL_Event type
sdl_eventbuf rq 256/8

mainRect SDL_Rect 0,0,0,0
snakeRect SDL_Rect 10,10,10,10

snake_x dq 0
snake_y dq 0

window rq 1
renderer rq 1

snake_movement_counter dq 0

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

	call add_snake_part

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
	jne afterEventHandling

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
	mov [snake_direction], 1

	mov rdi, left_arrow_pressed_msg
	call printMessage

	ret
handle_right_arrow_key:
	mov [snake_direction], 2

	mov rdi, right_arrow_pressed_msg
	call printMessage

	ret
handle_up_arrow_key:
	mov [snake_direction], 3

	mov rdi, up_arrow_pressed_msg
	call printMessage

	ret
handle_down_arrow_key:
	mov [snake_direction], 4

	mov rdi, down_arrow_pressed_msg
	call printMessage

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
    mov [mainRect.w], 480
    mov [mainRect.h], 480

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
	mov dil, [snake_parts+rcx]
	mov [snakeRect.x], edi

	;mov rsi, [loop_counter]
	;call printInteger
	;call log_here_message

	mov rcx, [loop_counter]
	mov dil,[snake_parts+rcx+1]
    mov [snakeRect.y], edi

    mov [snakeRect.w], 50
    mov [snakeRect.h], 50

	;xor rdi, rdi

    mov rdi, [renderer]
    mov rsi, snakeRect
    call SDL_RenderFillRect
	cmp rax, 0
	jne render_fill_error

	add [loop_counter], 2

	mov rcx, [loop_counter]
	cmp byte[snake_parts+rcx], -1
	jne .foreach_snake_parts

	ret	
updage_game_state:
	cmp [snake_movement_counter], 500
	jne .end_update_game_state

	mov [snake_movement_counter], 0

	cmp [snake_direction], 1
	jne .not_left_direction

	sub [snake_x], 10
	jmp .end_update_game_state
.not_left_direction:
	cmp [snake_direction], 2
	jne .not_right_direction

	add [snake_x], 10
	jmp .end_update_game_state	
.not_right_direction:	
	cmp [snake_direction], 3
	jne .not_up_direction

	sub [snake_y], 10
	jmp .end_update_game_state
.not_up_direction:	
	cmp [snake_direction], 4
	jne .end_update_game_state

	add [snake_y], 10

.end_update_game_state:
	
	ret
add_snake_part:
	mov [snake_parts], 100
	mov [snake_parts+1], 50
	
	mov [snake_parts+2], 50
	mov [snake_parts+3], 50

	mov [snake_parts+4], 0
	mov [snake_parts+5], 50

	ret