masm
model small
stack 256
.386
.data
handle  dw  0
file_name db 'in.txt',0
file_size dw 0
file_contents  db 201 dup('$')
level db  0
error_message db 'Error, terminating program$'
prompt  db 10, 'Please input command: $'
output_name db 'out.txt',0
output_handle dw 0
file_saved db 10, 'File saved$'
message_is_decrypted db 10, 'Message is not encrypted$'
message_is_encrypted db 10, 'Message is fully encrypted to lvl 4$'
.code
main:
  mov ax, @data
  mov ds, ax
  mov ah, 3Dh;open file
  mov al, 0;read
  mov dx, offset file_name
  int 21h
  jc  error;exit on error
  mov handle, ax; handle to file
  mov ah, 3Fh;read file
  mov bx, handle
  mov cx, 200; read 200 bytes
  mov dx, offset file_contents
  int 21h
  jc error;exit on error
  mov file_size, ax
  mov ah, 3Eh;close file
  int 21h
  jc error;exit on error
input:;loop input
  mov ah, 09h
  mov dx, offset prompt
  int 21h
  mov ah, 01h
  int 21h
  cmp al, '1'; encrypt one level
  je encrypt
  cmp al, '2'; decrypt one level
  je decrypt
  cmp al, '3'; save current state of the text in out.txt
  je save
  cmp al, '4'; exit
  je exit
  jmp input
encrypt:
  cmp level, 4
  je level4
  inc level
  cmp level, 1
  je reverse; level 1 = reverse encryption (weakest)
  cmp level, 2
  je encryptletters; level 2 = arithmetic encryption
  cmp level, 3
  je encryptrotate; level 3 = ROL/ROR encryption
  jmp xorstring; level 4 = XOR encryption (strongest)
decrypt:
  cmp level, 0
  je level0
  dec level
  cmp level, 0
  je reverse; level 1 = reverse encryption (weakest)
  cmp level, 1
  je decryptletters; level 2 = arithmetic encryption
  cmp level, 2
  je decryptrotate; level 3 = ROL/ROR encryption
  jmp xorstring; level 4 = XOR encryption (strongest)
level4:;string is fully encrypted
  mov ah, 09h
  mov dx, offset message_is_encrypted
  int 21h
  jmp printstring
level0:;string is fully decrypted
  mov ah, 09h
  mov dx, offset message_is_decrypted
  int 21h
  jmp printstring
reverse:; reverse string, most basic encryption
  mov cx, file_size
  xor si, si
  mov di, cx
  dec di
  shr cx, 1
  rl:;loop
    mov ah, file_contents[di]
    mov al, file_contents[si]
    mov file_contents[si], ah
    mov file_contents[di], al
    inc si
    dec di
    loop rl
  jmp printstring
encryptletters:; encrypt adding 95 to the character value mapping letters to │▄╓╣ and such
    xor bx, bx
    mov cx, file_size
  lenl:;loop
    add file_contents[bx], 95
    inc bx
    loop lenl
  jmp printstring
decryptletters:; decrypt subtracting 95 from the character value
    xor bx, bx
    mov cx, file_size
  ldel:;loop
    sub file_contents[bx], 95
    inc bx
    loop ldel
    jmp printstring
encryptrotate:;encrypt using ror 5
  xor bx, bx
  mov cx, file_size
lens:
  mov ah, file_contents[bx]
  ror file_contents[bx], 5
  inc bx
  loop lens
  jmp printstring
decryptrotate:;decrypt using rol 5
  xor bx, bx
  mov cx, file_size
ldes:
  mov ah, file_contents[bx]
  rol file_contents[bx], 5
  inc bx
  loop ldes
jmp printstring
xorstring:;encode/decode xor
  mov al, 0B7h; encrypt/decrypt with B7
  xor bx, bx
  mov cx, file_size
loopxor:
  mov ah, file_contents[bx]
  xor file_contents[bx], 0B7h
  inc bx
  loop loopxor
  jmp printstring
printstring:;print modified string
  mov ah, 02h
  mov dl, 10
  int 21h
  mov ah, 09h
  mov dx, offset file_contents
  int 21h
  jmp input
save:;save modified file
  mov ah, 3Ch;create file
  xor cx, cx; standard file
  mov dx, offset output_name
  int 21h
  jc  error
  mov output_handle, ax; handle to file
  mov ah, 40h;write file
  mov bx, output_handle
  mov cx, file_size;
  mov dx, offset file_contents
  int 21h
  jc error
  mov ah, 3Eh;close file
  int 21h
  jc error;exit on error
  mov ah, 09h
  mov dx, offset file_saved
  int 21h
  jmp input
error:;error handling
  mov ah, 09h
  mov dx, offset error_message
  int 21h
  jmp exit
exit:;exit program
  mov ax, 4c00h
  int 21h
end main
