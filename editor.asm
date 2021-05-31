	Start:
	call setteletype
	options:
mov di, !open
	call displaydi
	call nextrow
mov di, !menu
	call displaydi
	call nextrow

;__________Bus__________;
	
	bus:
cmp dx, 0
jz keystore
cmp dx, 1
jz editorexit

;__________OSAddress__________;

	editorexit:
xor ax, ax
xor bx, bx
xor cx, cx
xor dx, dx

mov ax, 0x2000
mov es, ax
mov ds, ax
mov fs, ax
mov gs, ax
mov ss, ax

jmp 0x2000:0x0

;__________Display values__________;		; ( Instructions: )

        setteletype:
mov ah, 0x00                                    ; video
mov al, 0x03                                    ; text
int 0x10

mov ah, 0x0b                                    ; color
mov bh, 0x00
mov bl, 0x03
int 0x10
ret

;__________Display chars from di__________;

        displaydi:
xor ax, ax
mov ah, 0x0e
	displaydiloop:
mov al, [di]
cmp al, ']'
jz exitdisplaydiloop
int 0x10
inc di
jmp displaydiloop

	exitdisplaydiloop:
ret

;__________Display utility__________;

	nextrow:
mov di, !dropline
        call displaydi
mov di, !return
        call displaydi
	
	exitnextrow:
ret
	
;__________Open input from keyboard with screen output__________;

	keystore:
mov di, !0string

	openkeys:
mov ax, 0x00
int 0x16					; opens registers to catch keys
mov ah, 0x0e
cmp al, 0xd
je findkey
int 0x10
mov [di], al
inc di
jmp openkeys

	findkey:
cmp dx, 'a'
jz allocateinstructions
mov byte [di], ']'
mov al, [!0string]				; start at address chars were stored
	callchain:
cmp al, '1'
jz callreboot
cmp al, 'a'
jz calldisplayallocations
cmp al, 'o'
jz callopen
cmp al, 'e'
jz callexiteditor
jnz keystore					; if not available start over

	callreboot:
jmp reboot

	calldisplayallocations:
	call nextrow
	call displayallocations
xor dx, dx					; dx = 0, will return to keystore function.
jmp bus

	callopen:
	call open
xor dx, dx					; dx = 0, will return to keystore function.
jmp bus

	callexiteditor:
mov dx, 1
jmp bus

;__________Reboot the pc__________;

	reboot:
jmp 0xFFFF:0x0000

;__________Print the allocations in the filetable__________;

	displayallocations:

mov ax, 0x1000					; location of file table
mov es, ax					; puts ax into readable extra segment
xor bx, bx					; bx is the offset holder
mov ah, 0x0e					; enable ability to print
	
	displayallloop:
mov al, [es:bx]
int 0x10
inc bx
cmp al, ')'
jz printtonextrow
cmp al, ']'
jnz displayallloop
jmp exitdisplayallloop

	printtonextrow:
	call nextrow
jmp displayallloop

	exitdisplayallloop:
	exitdisplayallocations:
ret

;__________Open an application to edit__________;

	open:
	call nextrow
mov di, !openfileinst
	call displaydi
	call nextrow
mov dx, 'a'
jmp keystore

	allocateinstructions:
xor dx, dx
xor cx, cx
xor bx, bx
xor ax, ax

	bytetablelocation:
mov ax, 0x1000					; puts the bytetable address into register ax
mov es, ax					; puts the address into es for pointing
mov di, !...ok
	call displaydi
	call nextrow
mov di, !0string

	findinstructionsloop:
mov al, [es:bx]					; puts first char at bytable address into al
cmp al, ']'
jz instructionsnotfound
cmp al, 48
jl inctokeeplooking

	starttablesearch:
	cmp al, 57
jg inctokeeplooking

	searchsectiontwo:
cmp dx, 1
jz foundinstructionssector
cmp al, [di]
jz foundinstructions

	inctokeeplooking:
inc bx
jmp findinstructionsloop

	instructionsnotfound:
mov di, !appnotfound
	call displaydi
	call nextrow

	exitinstructionssearch:
ret

	foundinstructions:
mov di, !appfound
	call displaydi
	call nextrow

	findsector:
mov dx, 1					; flags dx to end search when next num is found
inc bx						; this is based on the ordered convention in the bytetable
jmp findinstructionsloop

	foundinstructionssector:
mov di, !0string
mov [di], al
inc di
mov byte [di], ']'
mov di, !0string
push ax
	call displaydi
mov di, !...ok
	call displaydi
	call nextrow
pop ax
ret	

;__________Values__________;
				;
!open:		db '^^^^^^^^^^', 0xa, 0xd, 'Editor.', ']'
!dropline:	db 0xa, ']'
!return:	db 0xd, ']'
!menu:		db 'Depressing the a key will open the menu.', 0xd, 0xa, \
		'the o key will open instructions from the menu in editing mode.', 0xd, 0xa, \
		'the e key will take you back to the beginning map.', 0xd, 0xa, \
		'the 1 key will restart you.', ']' 
!openfileinst:	db 'Please type the app name and then depress the enter key.', ']'
!...ok:		db '...ok', ']'
!appnotfound:	db 'app not found', ']'
!appfound:      db '...app did locate', ']'
!0string:	db '0x0000', ']'

times 1024-($-$$) db 0
