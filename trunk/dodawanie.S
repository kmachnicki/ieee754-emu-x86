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
	
zle_znaki:
	movl	$-1, %eax			#kod bledu -1
	leave
	ret

