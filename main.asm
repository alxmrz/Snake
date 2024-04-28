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

mainRect SDL_Rect 0,0,0,0
window rq 1
renderer rq 1


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

main:
    mov rbp, rsp; for correct debugging
    and rsp, -16

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

    mov rdi, [window]
    call SDL_UpdateWindowSurface
    cmp rax, 0
	jne update_window_surface_error
    
    mov rdi, [renderer]
	mov rsi, 160
	mov rdx, 0
	mov rcx, 0
	mov r8, 0
    call SDL_SetRenderDrawColor
    cmp rax, 0
	jne set_render_draw_color_error

    mov [mainRect.x], 0
    mov [mainRect.y], 0
    mov [mainRect.w], 480
    mov [mainRect.h], 480

    mov rdi, [renderer]
    mov rsi, [mainRect]
    call SDL_RenderFillRect
	cmp rax, 0
	jne render_fill_error

    mov rdi, [renderer]
    call SDL_RenderPresent

    mov rdi, 2000
	call SDL_Delay

    mov rdi, r13
	call SDL_DestroyRenderer
	mov rdi, r12
	call SDL_DestroyWindow
	call SDL_Quit
	mov rdi, 0
	jmp exit
exit:
    mov rsp, rbp
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
	mov rdi, 8
	jmp exit