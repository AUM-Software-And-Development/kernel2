org 0x7c00

;;; ___Select disk___

mov dh, 0x0					; head
mov dl, 0x0					; drive
mov ch, 0x0					; cylinder

;;; ___Bytetable___

mov bx, 0x1000					; address to load to
mov es, bx					; mem segment
xor bx, bx					; for segment/mem offsets
mov cl, 0x02					; sector

	findbytetable:
mov ah, 0x02					; read setting
mov al, 1					; num sectors
int 0x13					; disk bios interrupt
jc findbytetable				; if carry flag then error/retry

;;; ___Kernel___

mov bx, 0x2000					; address to load to
mov es, bx					; mem segment
xor bx, bx					; for segment/mem offsets
mov cl, 0x03					; sector

	findkernel:
mov ah, 0x02					; read setting
mov al, 2					; num sectors
int 0x13					; disk bios interrupt
jc findkernel					; if carry flag then error/retry

;;; ___Start Apps___

mov ax, 0x2000
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax
jmp 0x2000:0x0

times 510-($-$$) db 0
dw 0xaa55
