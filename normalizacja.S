########################################
# Modul wykonujacy normalizacje wyniku #
########################################

.text
.globl  normalizacja
.type   normalizacja, @function
normalizacja:
    pushl   %ebp
    movl    %esp, %ebp
    
    # Dodanie ukrytej jedynki
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
    # W przypadku gdy wystapi overflow
    cmpb    $1, wynik_sign
    jz  minus_inf
    call    inf_plus
    jmp koniec
	
minus_inf:
    call    inf_minus
	
koniec:    
    leave
    ret
    

.globl  normalizacjaOdejmowanie
.type   normalizacjaOdejmowanie, @function
normalizacjaOdejmowanie:
    pushl   %ebp
    movl    %esp, %ebp
    
    # Usunieceie ukrytej jedynki
	movl	wynik_mts, %edi
    movl    wynik_size, %ecx
	movl    %ecx, %ebx
	clc
	
shift_wynik2:
    decl    %ebx
	rcll	$1, (%edi, %ebx, 4)
	loop    shift_wynik2
		
zmiejszenie_mantysy:
	movl	$wynik_exp, %edi
	movl	4(%edi), %eax
	movl	(%edi), %ebx
	subl	$1, %eax
	sbbl	$0, %ebx
    jc  underflow
	movl	%ebx, (%edi)
	movl	%eax, 4(%edi)
    jmp koniec2
	
underflow:
    # W przypadku gdy wystapi underflow
    cmpb    $1, wynik_sign
    jz  minus_inf2
    call    inf_plus
    jmp koniec2
	
minus_inf2:
    call    inf_minus
	
koniec2:    
    leave
    ret
