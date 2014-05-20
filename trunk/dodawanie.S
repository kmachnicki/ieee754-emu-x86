# Modul dodajacy 2 liczby zmiennoprzecinkowe

.text
.globl	dodaj
.type	dodaj, @function
dodaj:
	pushl	%ebp
	movl	%esp, %ebp
	movb	liczba1_sign, %al
	movb	liczba2_sign, %ah
	cmpb	%al, %ah			#jak rozne znaki to wychodzimy (wlasciwie powinno odejmowanie)
	jnz	zle_znaki

	movb	%al, wynik_sign

	movl	$0, %edx
	movl	$liczba1_exp, %esi
	movl	$liczba2_exp, %edi

	movl	(%esi, %edx, 4), %eax
	movl	(%edi, %edx, 4), %ebx
	subl	%eax, %ebx			#rozniaca wykladnikow
	jz	sprowadzone
	jng	pierwsza

druga:
	
	jmp	sprowadzone

pierwsza:

sprowadzone:
	
zle_znaki:
	movl	$-1, %eax			#kod bledu -1

koniec:
	leave
	ret

