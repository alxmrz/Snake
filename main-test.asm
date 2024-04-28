format ELF64

section '.data' writeable
    hello db 'Hello, +++++', 0
    world db ' world!', 0
    formatStr db "%s", 0
    formatInt db "%d", 0
    concated rb 16

; Code segment 
section ".text" executable

public main
extrn printf

concat:
    ; rdi - first argument, rsi - second argument, rax - out
    mov rcx, 0
    reader:
    mov al, [rdi+rcx]
    mov [concated+rcx], al
    add rcx, 1
    cmp byte[rdi+rcx], 0x00
    jne reader

    sub rcx, 1

    mov r8, 0
    reader1:
    mov al, [rsi+r8]
    mov [concated+rcx+r8], al
    add r8, 1
    cmp byte[rsi+r8], 0x00
    jne reader1


    mov [concated+rcx+r8+1], 0x00

    ret

main:
    mov rbp, rsp; for correct debugging
    and rsp, -16

    mov rdi, hello
    mov rsi, world
    call concat

    mov rdi, formatInt
    mov rsi, rcx
    call printf

    mov rdi, formatStr
    mov rsi, concated
    call printf



    mov rsp, rbp
    xor rax, rax

    ret

