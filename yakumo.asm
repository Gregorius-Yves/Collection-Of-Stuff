[bits] 64

; multibyte no-ops
%define nop2 db 0x66, 0x90 
%define nop3 db 0x0f, 0x1f, 0x00
%define nop4 db 0x0f, 0x1f, 0x40, 0x00

%define origin 65536

; elf header
db 0x7f, "ELF"            ; e_ident
db 2, 1, 1, 0             ; e_ident
db 0, 0, 0, 0, 0, 0, 0, 0 ; e_ident
dw 2                      ; e_type
dw 0x3e                   ; e_machine
dd 1                      ; e_version
dq origin + header_size   ; e_entry
dq 64                     ; e_phoff
dq 0                      ; e_shoff
dd 0                      ; e_flags
dw 64                     ; e_ehsize
dw 0x38                   ; e_phentsize
dw 1                      ; e_phnum
dw 0                      ; e_shentsize
dw 0                      ; e_shnum
dw 0                      ; e_shstrndx

; program header
dd 1                      ; p_type
dd 5                      ; p_flags
dq 0                      ; p_offset
dq origin                 ; p_vaddr
dq origin                 ; p_paddr
dq file_size              ; p_filesz
dq file_size              ; p_memsz
dq 0                      ; p_align

header_size: ; 120

; code segment

mov ax, 85                ;  create
mov si, 0x1ff 
mov rbx, rsp 
nop
mov byte [rsp], 0

mov byte [rbx + 6], "t"
mov byte [rbx + 7], 0x00
lea rdi, [rbx + 6] 

not r13w ; r13 = 65535 = origin - 1
syscall ; create file
nop2

mov dx, 120 ; header_size
mov byte [rbx + 1], 1
mov byte [rbx + 2], 2
mov rdi, rax

nop
lea rsi, [r13 + 1] ; origin
lea r14, [r13 + 127]
mov byte [rbx + 3], 3

mov ax, 1 ; write
lea rbx, [rdx - 117] ; rbx = 3
lea r12, [r13 + 121] ; entry
add r14, 90 ; loop = 0xd8 = 216 = 127 + 89 

syscall ; write headers to file
nop2
lea r15, [r14 + 95] ; continue = 0x138 = 312 = loop + 95
rdrand r13
nop4

loop: ; 216
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

  syscall ; write permuted instruction to file
  nop2
  cmp rbp, 80 ; program_size / 4
  mov r8, r14 ; loop
  nop
  nop4

  cmovge r8, r15 ; r8 = continue if rbp * 4 > program_size else loop
  mov [rsp + r13], r10b
  lea rcx, [rbp + 4] 
  lea rbx, [rbx - 1] 

  jmp r8
  nop
  rdrand r13
  rdrand r13
  rdrand r13
continue: ; 312

mov ax, 3 ; close
mov rbx, rsp
nop

mov dx, 8 
mov byte [rsp], "t"
syscall ; close file
nop

nop
mov byte [rbx + 1], "m"
mov byte [rbx + 2], "p"
mov byte [rbx + 3], "."

mov ax, 82 ; rename
mov rsi, [rbx + 8] ; rsi = argv[0]
lea rdi, [rbx + 6] ; rdi = "t"

nop4

syscall ; overwrite calling file
nop2
mov byte [rbx + 4], "0"
mov byte [rbx + 5], "u"
nop4

mov ax, 1 ; write
lea rdi, [rdx - 7] ; rdi = 1 = stdout
mov rsi, rsp
nop
mov byte [rbx + 7], 0xa

syscall ; execute payload
nop2
nop4
nop4
nop4

mov ax, 60 ; exit 
xor rdi, rdi
nop
nop4
nop4

syscall ; exit politely
nop2
nop4
nop4
nop4

file_size: ; 440
