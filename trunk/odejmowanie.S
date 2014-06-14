################################################
# Modul odejmujacy 2 liczby zmiennoprzecinkowe #
################################################

.data
czy_pierwszy_obieg:	.byte	0
jakie_zaokraglenie:	.long	0
iterator_1:			.long	0
iterator_2:			.long	0

czy_normalizowac:   .byte   0
czy_exp_rowny:		.byte	0

.text
.globl	odejmij
.type	odejmij, @function
odejmij:
	pushl	%ebp
	movl	%esp, %ebp
	movb	liczba1_sign, %al
	movb	liczba2_sign, %ah
	#cmpb	%al, %ah			# Jak takie same znaki to przechodzimy do dodawania
	#jz	zle_znaki
    cmpb    $0, %al
    jz  dobre_znaki
    cmpb    $0, %ah
    jnz zle_znaki
dobre_znaki:
	movl	$liczba1_exp, %esi
	movl	$liczba2_exp, %edi
    
    #sprawdzenie czy jedna z liczb nie jest NaNem
    cmpl    $0xFFFFFFFF, 4(%esi)
    jnz pierwsza_nie_NaN
    cmpl    $0xFFFFFFFF, (%esi) 
    jz  wystapil_NaN
pierwsza_nie_NaN:
    cmpl    $0xFFFFFFFF, 4(%edi) 
    jnz nie_ma_NaN
    cmpl    $0xFFFFFFFF, (%edi) 
    jnz nie_ma_NaN
wystapil_NaN:
    call    NaN
    jmp nie_zero
nie_ma_NaN:

    # Alokacja pamieci na wynik
	movl	liczba1_size, %eax
	movl	%eax, wynik_size
    movl    $4, %ebx
	mull	%ebx
	pushl	%eax
	call	malloc
	addl	$4, %esp
	movl	%eax, wynik_mts

	movl	(%edi), %eax
	movl	4(%edi), %edx
	cmpl	4(%esi), %edx
	jl	druga
	cmpl	4(%esi), %edx
	jg	pierwsza
	cmpl	(%esi), %eax
	jnb	pierwsza
	
druga:							# W wypadku gdy druga liczba jest mniejsza
	movb	liczba1_sign, %al
	movb	%al, wynik_sign		# Przepisujemy znak od wiekszej
    
    # Przepisanie eksponenty
    pushl   %edi
    pushl   %esi
    movl    $liczba1_exp, %esi
    movl    $wynik_exp, %edi
    movl    (%esi), %eax
    movl    %eax, (%edi)
    movl    4(%esi), %eax
    movl    %eax, 4(%edi)
    popl    %esi
    popl    %edi	

	movl	4(%esi), %eax

	pushl	%edi
	movl	$wynik_exp, %edi
	movl	%eax, 4(%edi)		# Przepisanie wiekszej eksponenty
	popl	%edi
	
	movl	4(%edi), %ebx
	subl	%ebx, %eax

	movl	(%esi), %ecx
	movl	%ecx, wynik_exp		# Druga czesc przepisania
	movl	(%edi), %edx
	sbbl	%edx, %ecx			# Wynik sumy w ecx:eax

	movl	liczba2_mts, %edi
	movl	%eax, iterator_1
	movl	%ecx, iterator_2
	movl	liczba2_size, %ecx
	xorl	%ebx, %ebx
	stc
	
shift_2:
	rcrl	$1, (%edi, %ebx, 4)
	incl	%ebx
	loop	shift_2
    jnc	nie_cf2
	movb	$1, bit_specjalny
	jmp	po_cf2
nie_cf2:
	movb	$0, bit_specjalny
po_cf2:
	decl	iterator_1
	cmpl	$0, iterator_1
	jnz	powtorz_2
	cmpl	$0, iterator_2
	jz po_ustawieniu
	
	# Zabranie z wyzszego
	decl	iterator_2
	movl	$0xFFFFFFFF, iterator_1
	
powtorz_2:
	movl	liczba2_size, %ecx
	xorl	%ebx, %ebx
	clc
	jmp	shift_2
	
koniec_shift_2:

pierwsza:						# W wypadku gdy pierwsza liczba jest miejsza lub rowna
	movb	liczba2_sign, %al
	movb	%al, wynik_sign	# Przepisujemy znak od wiekszej
    
    # Przepisanie eksponenty
    pushl   %edi
    pushl   %esi
    movl    $liczba2_exp, %esi
    movl    $wynik_exp, %edi
    movl    (%esi), %eax
    movl    %eax, (%edi)
    movl    4(%esi), %eax
    movl    %eax, 4(%edi)
    popl    %esi
    popl    %edi
	
	movl	4(%edi), %eax
	movl	4(%esi), %ebx
	subl	%ebx, %eax

	movl	(%edi), %ecx
	movl	(%esi), %edx
	sbbl	%edx, %ecx			# Wynik sumy w ecx:eax
    
    cmpl    $0, %eax
    jnz nie_rowne_zero_ecxeax
    cmpl    $0, %ecx
    jnz  nie_rowne_zero_ecxeax
    
    movb	$1, czy_exp_rowny
    
    #czy liczby takie same
    movl    liczba1_mts, %esi
    movl    liczba2_mts, %edi
    movl    liczba1_size, %ecx
    xorl    %edx, %edx
czy_zero1:
	movl	(%edi, %edx, 4), %eax
    movl    (%esi, %edx, 4), %ebx
    cmpl    %eax, %ebx
    jnz odejmij_exp               #mantysy nie rowne
	incl	%edx
	loop	czy_zero1
	
	call ZeroNumb
	jmp nie_zero
    
odejmij_exp:
    movl	$wynik_exp, %edi
	movl	4(%edi), %eax
	movl	(%edi), %ebx
	subl	$1, %eax
	sbbl	$0, %ebx
	movl	%ebx, (%edi)
	movl	%eax, 4(%edi)
	
	jmp	po_ustawieniu
	
nie_rowne_zero_ecxeax:
	movl	liczba1_mts, %edi
	movl	%eax, iterator_1
	movl	%ecx, iterator_2
	movl	liczba1_size, %ecx
	xorl	%ebx, %ebx
	stc
	
shift_1:
	rcrl	$1, (%edi, %ebx, 4)
	incl	%ebx
	loop	shift_1
    jnc	nie_cf1
	movb	$1, bit_specjalny
	jmp	po_cf1
nie_cf1:
	movb	$0, bit_specjalny
po_cf1:
	decl	iterator_1
	cmpl	$0, iterator_1
	jnz	powtorz_1
	cmpl	$0, iterator_2
	jz koniec_shift_1
	
	# Zabranie z wyzszego
	decl	iterator_2
	movl	$0xFFFFFFFF, iterator_1
	
powtorz_1:
	movl	liczba1_size, %ecx
	xorl	%ebx, %ebx
	clc
	jmp	shift_1
	
koniec_shift_1:
	
po_ustawieniu:
	

	# Liczby sprowadzone do wspolnej potegi (teraz odejmowanie)
	movl	liczba1_mts, %esi
	movl	liczba2_mts, %edi
	movl	liczba1_size, %edx
	movl liczba1_size, %ecx
	clc
	
odjecie_mantysy:
	decl	%edx
	movl	(%esi, %edx, 4), %eax
	movl	(%edi, %edx, 4), %ebx
	sbbl	%ebx, %eax
    jnc odejmij_dalej
    movb    $1, czy_normalizowac
    jmp odejmij_kolejny
odejmij_dalej:
    movb    $0, czy_normalizowac
odejmij_kolejny:
	pushl	%edi
	movl	wynik_mts, %edi
	movl	%eax, (%edi, %edx, 4)
	popl	%edi

	loop odjecie_mantysy
	
	cmpb	$1, czy_exp_rowny
	jnz	normal
	#trzeba przesunac jeszcze raz
	movl	wynik_mts, %edi
    movl    wynik_size, %ecx
	movl    %ecx, %ebx
	clc
	
shift_wynik2:
    decl    %ebx
	rcll	$1, (%edi, %ebx, 4)
	loop    shift_wynik2
	
normal:    
    #cmpb    $0, czy_normalizowac    # W wypadku gdy nie trzeba znormalizowac
    #jz  koniec
    call    normalizacjaOdejmowanie             #normalizuj
	jmp koniec
	
zle_znaki:
	call	dodaj					# Wywolanie dodawania

koniec:
    movl	jakie_zaokraglenie, %eax
	call	zaokraglenie

	
nie_zero:
	leave
	ret
