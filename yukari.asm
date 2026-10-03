[bits 64]

org 65536

%define nop2 db 0x66, 0x90
%define nop3 db 0x0f, 0x1f, 0x00
%define nop4 db 0x0f, 0x1f, 0x40, 0x00

; big thanks to tmp.out for the banger idea
; loop 89-123 from tmpout.sh/5/4.html
; check them out in tmpout.sh
;

; header
db 0x7f, "ELF"             ; e_ident
db 2, 1, 1, 0              ; e_ident
db 0, 0, 0, 0, 0, 0, 0, 0  ; e_ident
dw 2                       ; e_type
dw 0x3e                    ; e_machine
dd 1                       ; e_version
dq entry                   ; e_entry
dq 64                      ; e_phoff
dq 0                       ; e_shoff
dd 0                       ; e_flags
dw 64                      ; e_ehsize
dw 0x38                    ; e_phentsize
dw 1                       ; e_phnum
dw 0                       ; e_shentsize
dw 0                       ; e_shnum
dw 0                       ; e_shstrndx

; program header
dd 1                       ; p_type
dd 5                       ; p_flags
dq 0                       ; p_offset
dq $$                      ; p_vaddr
dq $$                      ; p_paddr
dq real_end                ; p_filesz 
dq real_end                ; p_memsz
dq 0                       ; p_align

db 0x70, 0x5e, 0xff, 0x00  ; 
header_size:               ; 

entry:
    ; creat
    mov ax, 85                 ; rax = creat
    mov si, 0x1ff              ; rsi = mode 0777
    mov rbx, rsp               ;
    nop
    not r13w                   ;

    mov byte [rsp], 0          ; 
    mov byte [rbx + 1], 1      ; 
    mov byte [rbx + 2], 2      ; 
    mov byte [rbx + 3], 3      ; 

    mov byte [rbx + 6], "t"    ;
    mov byte [rbx + 7], 0x00   ;
    lea rdi, [rbx + 6]         ;
    lea r12, [r13 + 125]       ;


    syscall                    ; 
    nop2
    lea r14, [r13 + 127]       ;
    mov dx, 124                ;
    nop4


    mov rdi, rax               ;
    nop
    add r14, 110               ;
    lea rsi, [r13 + 1]         ;
    lea rbx, [rdx - 121]       ;

    mov ax, 1                  ; 
    lea r15, [r14 + 96]        ;
    rdrand r13                 ;
    nop4

    ;
    syscall                    ; write(fd, origin, 124)
    nop2
    nop4
    nop4
    nop4

loop:
    and r13, rbx ; r13 = random(0, j)
    nop
    lea rsi, [r12 + 4 * rbp]
    mov ax, 1 ; write
    mov dx, 4

    cmp rbx, 0
    mov r9b, byte [rsp + r13]
    mov r10b, byte [rsp + rbx]
    mov r11, rbx
    nop

    cmovle rbp, rcx ; rbp += 4 if rbx <=0
    cmovle rbx, rdx ; rbx = 4 if rbx <= 0
    lea rsi, [rsi + 4 * r9]
    mov [rsp + r11], r9b

    syscall                                     ; write permuted instruction to file
    nop2

    cmp rbp, 68 ; (payload - header_size) / 4  (272 / 4)
    mov r8, r14
    nop
    nop4

    cmovge r8, r15
    mov [rsp + r13], r10b
    lea rcx, [rbp + 4]
    lea rbx, [rbx - 1]

    jmp r8
    nop
    rdrand r13
    rdrand r13
    rdrand r13

continue:
    lea r8, [r15 + 64]             ; r8 = payload addr (continue + 64 = trampoline size)
    mov dx, (real_end - payload)   ; rdx = tail length
    mov ax, 1                      ; rax = write
    nop4

    mov rsi, r8                    ; rsi = payload addr
    nop
    nop4
    nop4
    nop4

    syscall                        ; write(fd, payload, tail_len)
    nop2
    nop4
    nop4
    nop4

    jmp r8                         ; 
    nop
    nop4
    nop4
    nop4


payload:
    mov rbx, rsp                   
    mov eax, 3
    syscall                        
    mov eax, 82
    lea rdi, [rbx + 6]             
    mov rsi, [rbx + 8]             
    syscall

    ; open(".", O_RDONLY)
    mov byte [rbx + 4], '.'
    mov byte [rbx + 5], 0
    mov eax, 2
    lea rdi, [rbx + 4]
    xor esi, esi
    syscall                        
    mov r9, rax                   

    ; getdents64(dirfd, buf, 1024)
    mov eax, 217
    mov rdi, r9
    lea rsi, [rbx + 64]            
    mov edx, 1024
    syscall                        
    lea r10, [rbx + 64]           
    lea r12, [r10 + rax]           
.next:
    cmp r10, r12
    jae .done
    lea rsi, [r10 + 19]            
    mov rcx, rsi
.scan:
    cmp byte [rcx], 0              
    je .gotlen
    inc rcx
    jmp .scan
.gotlen:
    mov rdx, rcx
    sub rdx, rsi                   
    mov eax, 1
    mov edi, 1
    syscall                      
    mov byte [rbx + 3], 0x0a       ;
    lea rsi, [rbx + 3]
    mov edx, 1
    mov eax, 1
    mov edi, 1
    syscall                        

    movzx edx, word [r10 + 16]     
    add r10, rdx                  
    jmp .next
.done:
    mov eax, 60
    xor edi, edi
    syscall                        ; exit(0)

real_end:
