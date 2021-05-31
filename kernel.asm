	Boot:
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

;__________Returns & halts__________;

        halt:
cli
hlt

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
mov ah, 0x0e                                    ; teletype
        displaydiloop:
mov al, [di]
cmp al, ']'
jz exitdisplaydiloop
int 0x10
inc di
jmp displaydiloop

	exitdisplaydiloop:
	exitdisplaydi:
ret

;__________Display utility__________;

	nextrow:
mov di, !dropline
        call displaydi
mov di, !return
        call displaydi
	
	exitnextrow:
ret

;__________Display binary From bx__________;

        displaybxinbinary:
mov di, !0binarystring
mov ax, 256
mov cx, 2
xor dx, dx

	binaryloop:
div cx
inc di
cmp ax, 1
jz exitbinaryloop
mov byte [di], '0'
cmp bx, ax
jl binaryloop
dec di
call bityes
sub bx, ax
je exitbinaryloop
inc di
jmp binaryloop

	bityes:
mov byte [di], '1'
ret

	exitbinaryloop:
cmp ax, 1
jg binaryloop
cmp bx, 1
jnz exitdisplaybxinbinary
dec di
	call bityes
	exitdisplaybxinbinary:
mov di, !0binarystring
	call displaydi
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
jz openapp
mov byte [di], ']'
mov al, [!0string]				; start at address chars were stored
	callchain:
cmp al, '1'
jz callreboot
cmp al, '2'
jz callbegindisplayingregisters
cmp al, 'a'
jz calldisplayallocations
cmp al, 'o'
jz callopen
jnz keystore					; if not available start over

	callreboot:
jmp reboot
	
	callbegindisplayingregisters:
	call begindisplayingregisters
xor dx, dx					; dx = 0, will return to keystore function.
jmp bus

	calldisplayallocations:
	call nextrow
	call displayallocations
xor dx, dx					; dx = 0, will return to keystore function.
jmp bus

	callopen:
	call open
xor dx, dx					; dx = 0, will return to keystore function.
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

;__________Display the binaries in the abcd registers__________;

	begindisplayingregisters:
pusha						; save reg states
	call nextrow
mov dword [!0string], 'bx:]'
mov di, !0string
	call displaydi
popa
pusha						; get and save beginning reg states
	call displaybxinbinary	

	displayregisters:
	call nextrow
mov dword [!0string], 'cx:]' 
mov di, !0string
	call displaydi
popa
pusha						; get and save beginning reg states
mov bx, cx
	call displaybxinbinary
	call nextrow
popa						; get beginning reg states	
xor cx, cx
mov cl, 2
mov dword ebx, 'dx:]'
	
	outsideregs:				; Code falls through until enough general purpose registers become
cmp cl, 2					; available for use.
mov dword [!0string], ebx			; At this point, it puts dx into a string to print
mov di, !0string				; and prints dx as whichever location is placed via cl
mov bx, dx
jz regsloop
cmp cl, 3
mov bx, ax
jz regsloop

	regsloop:
pusha						; save current reg states (cl is now in use)
	call displaydi
popa
pusha						; get and save reg states
	call displaybxinbinary
	call nextrow
popa
inc cl
cmp cl, 3
mov dword ebx, 'ax:]'
jz outsideregs
	
	exitdisplayoutsideregs:
	exitdisplayregisters:
ret

;__________Open applications from the filetable__________;

	open:
	call nextrow
mov di, !openfileinst
	call displaydi
	call nextrow
mov dx, 'a'
jmp keystore

	openapp:
xor dx, dx
xor cx, cx
xor bx, bx
xor ax, ax

	applocations:
mov ax, 0x1000
mov es, ax
mov di, !...ok
	call displaydi
	call nextrow
mov di, !0string
	
	stringloop:
mov al, [es:bx]
cmp al, ']'
jz notfound
cmp al, 48
jge tablesearchstart
jl findappmore

	stringloopsection2:
cmp dx, 1
jz getsector
cmp al, [di]
jz foundapp
jne findappmore

	tablesearchstart:
cmp al, 57
jg findappmore
jle stringloopsection2

	findappmore:
inc bx
jmp stringloop

	notfound:
mov di, !appnotfound
	call displaydi
	call nextrow
jmp keystore

	foundapp:
mov di, !appfound
	call displaydi
	call nextrow

	loadsector:
mov dx, 1
inc bx
	jmp stringloop

	getsector:
mov di, !0string
mov [di], al
inc di
mov byte [di], ']'
mov di, !0string
push ax						; store al, which holds the sector holding the application line
	call displaydi
mov di, !...ok
	call displaydi
	call nextrow
pop ax						; restore al to get the sector
sub al, 48					; removes char value at offset 0 to convert char : decimal to int : decimal
mov cl, al					; sets cl to carry sector from al
mov ah, 0x00					; ah 0 + int 13h resets disk sys
mov dl, 0x00
int 0x13
mov ax, 0x6000					; memory location to load program
mov es, ax
xor bx, bx					; for segment/memory offsets
mov ah, 0x02					; ah 2 + int 13h reads sectors to mem
mov al, 0x02					; num sectors
mov ch, 0x00					; track num
mov dh, 0x00					; head num
mov dl, 0x00					; drive num
int 0x13
jnc loadapp					; if the carry flag isn't set, then nothing went wrong
	
	loadapp:
mov ax, 0x6000					; reload ax since it was changed		
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax
jmp 0x6000:0x0					; change pointer to this location (use ax)

;__________Count a string__________;

	countdi:
xor cx, cx
xor ax, ax
mov di, !0string				; seemingly not entirely neccessary, but here to be safe with si index.
	countdiloop:
mov al, [di]
cmp al, ']'
jz exitcountdiloop
inc cx
inc di
jmp countdiloop

	exitcountdiloop:
	exitcountdi:
ret

;__________Print

; End of instructions

;__________Values__________;

!open:		db 'Hi.', ']'			; ] to terminate.
!dropline:	db 0xa, ']'
!return:	db 0xd, ']'
!menu:		db 'Depressing the a key will open the menu.', 0xd, 0xa, \
		'the o key will open instructions from the menu.', 0xd, 0xa, \
		'the 1 key will restart you.', 0xd, 0xa, \
		'the 2 key will display the contents of registers a, b, c, and d.', ']'
!openfileinst:	db 'Please type the app name and then depress the enter key.', ']'
!...ok:		db '...ok', ']'
!appnotfound:	db 'app not found', ']'
!appfound:      db '...app did locate', ']'
!0binarystring:	db '00000000', ']'
!0string: 	db '0x0000', ']'

times 1024-($-$$) db 0
