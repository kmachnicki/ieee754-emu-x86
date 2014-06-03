# Modul wykonujacy normalizacje wyniku

.text
.globl  normalizacja
.type   normalizacja, @function
normalizacja:
    pushl   %ebp
    movl    %esp, %ebp
    
    #trzeba dodac te jednyke
	movl	wynik_mts, %edi
	xorl	%ebx, %ebx
	stc	
shift_wynik:
	shrl	$1, (%edi, %ebx, 4)
	incl	%ebx
	cmpl	wynik_size ,%ebx
	jnz	shift_wynik					#po kolei kazdy przsuwa po jednym (wykonuje jeden pelny shift)
		
zwiekszenie_mantysy:
	movl	$wynik_exp, %edi
	movl	4(%edi), %eax
	movl	(%edi), %ebx
	addl	$1, %eax
	adcl	$0, %ebx
	movl	%ebx, (%edi)
	movl	%eax, 4(%edi)
	xorl	%eax, %eax
    
    jnc koniec
    #wystapil overflow
    cmpb    $1, wynik_sign
    jz  minus_inf
    call    inf_plus
    jmp koniec
minus_inf:
    call    inf_minus
	
koniec:    
    leave
    ret
