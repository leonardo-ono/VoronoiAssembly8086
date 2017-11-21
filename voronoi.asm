; voronoi diagram (very naive / inefficient / brute force method) 8086/87 (using 13h vga graphic mode)
; written by Leonardo Ono (ono.leo@gmail.com)
; 20/11/2017
; target os: DOS (.COM file extension)
; use: nasm voronoi.asm -o voronoi.com -f bin

	bits 16
	org 100h

	POINTS_COUNT equ 50
	
section .data
	start:
			finit
			call start_graphic_mode
			call create_random_points
			call draw_voronoi
			call draw_points

	wait_for_key:
			mov ah, 0
			int 16h

	exit_process:
			mov ah, 4ch
			int 21h

	; --- 
			
	draw_voronoi:
			; al = color index
			; bx = y
			; cx = x
			mov al, 1
			mov cx, 0
			mov bx, 0
		.next_pixel:
			call compute_closest_point
			
			pusha
			add al, 30
			shl al, 1
			call pset
			popa
			
			inc cx
			cmp cx, 320
			jne .next_pixel
			mov cx, 0
			inc bx
			cmp bx, 200
			jne .next_pixel
			ret;
			
	; *note: very naive / inefficient / brute force method
	;  in: bx = y
	;      cx = x
	; out: al = point index
	compute_closest_point:
			mov al, 0
			push bx
			push cx
			mov word [.cx], cx
			mov word [.cy], bx
			mov byte [.closest_index], 0
			mov word [.current_distance], 0ffffh
			mov word [.closest_distance], 0ffffh
			mov cx, POINTS_COUNT
			mov di, 0
		.next:
			push cx
			
			fild word [ds:points + di + 2] ; 1
			fild word [.cy] ; 0
			fsub st0, st1
			fmul st0, st0
			
			fild word [ds:points + di] ; 1
			fild word [.cx] ; 0
			fsub st0, st1
			fmul st0, st0
			
			fadd st0, st2
			fsqrt
			
			fild word [.v100] ; 0
			fmul st0, st1
			
			fistp word [.current_distance]
			ffree st0
			ffree st1
			ffree st2
			ffree st3
			
			mov cx, [.current_distance]
			mov bx, [.closest_distance]
			cmp cx, bx
			jnb .continue
			
		.set_new_closest_point:
			mov [.closest_distance], cx
			mov [.closest_index], al
			
		.continue:
			add di, 4
			pop cx
			inc al
			loop .next
			
			pop cx
			pop bx
			inc byte [.closest_index]
			mov al, [.closest_index]
			ret
		.cx dw 0
		.cy dw 0
		.v100 dw 100;
		.closest_index db 0
		.closest_distance dw 0
		.current_distance dw 0
		
	draw_points:
			mov cx, POINTS_COUNT
			mov di, 0
		.next:
			push cx
			mov al, 0
			mov cx, word [points + di]
			mov bx, word [points + di + 2]
			add di, 4
			
			pusha
			call pset
			popa
			
			pusha
			inc cx
			call pset
			popa
			
			pusha
			inc bx
			call pset
			popa
			
			pusha
			inc bx
			inc cx
			call pset
			popa
			
			pop cx
			loop .next
			ret
			
	create_random_points:
			mov cx, POINTS_COUNT
			mov di, 0
		.next:
			push cx
			
			mov bx, 320
			call generate_random_number
			mov word [points + di], dx
			add di, 2
			
			mov bx, 200
			call generate_random_number
			mov word [points + di], dx
			add di, 2
			
			pop cx
			loop .next
			ret

	;  in: bx = max number
	; out: dx = random number
	generate_random_number:
			mov ah, 0
			int 1ah ; cx = hi dx = low
			push cx
			push dx
			
			mov ax, dx
			mul cx
			xor ax, [.seed]
			xor dx, dx
			div bx ; dx = rest of division
			
			pop bx
			pop cx
			add [.seed], bx
			add [.seed], cx
			ret
		.seed dw 0
		
	start_graphic_mode:
			mov ax, 0a000h
			mov es, ax
			mov ah, 0
			mov al, 13h
			int 10h
			ret
			
	; al = color index
	; bx = row
	; cx = col
	pset:
			pusha
			xor dx, dx
			push ax
			mov ax, 320
			mul bx
			add ax, cx
			mov bx, ax
			pop ax
			mov byte [es:bx], al
			popa
			ret
	
section .bss
	points resw POINTS_COUNT * 2
	