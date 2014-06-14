# Modul wykonujacy normalizacje wyniku

.text
.globl  normalizacja
.type   normalizacja, @function
normalizacja:
    pushl   %ebp
    movl    %esp, %ebp
    
    #trzeba dodac te jednyke
	movl	wynik_mts, %edi
    movl    wynik_size, %ecx
	xorl	%ebx, %ebx
	stc	
shift_wynik:
	rcrl	$1, (%edi, %ebx, 4)
	incl	%ebx
	loop    shift_wynik
		
zwiekszenie_mantysy:
	movl	$wynik_exp, %edi
	movl	4(%edi), %eax
	movl	(%edi), %ebx
	addl	$1, %eax
	adcl	$0, %ebx
    jc  overflow
	movl	%ebx, (%edi)
	movl	%eax, 4(%edi)
	xorl	%eax, %eax
    jmp koniec
overflow:
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
