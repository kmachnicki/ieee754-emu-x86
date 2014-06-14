##############################################
# Modul dodajacy 2 liczby zmiennoprzecinkowe #
##############################################

.data
czy_pierwszy_obieg:	.byte	0
jakie_zaokraglenie:	.long	0
iterator_1:			.long	0
iterator_2:			.long	0

czy_normalizowac:   .byte   0

.text
.globl	dodaj
.type	dodaj, @function
dodaj:
	pushl	%ebp
	movl	%esp, %ebp
	
	movl	%eax, jakie_zaokraglenie
	movb	liczba1_sign, %al
	movb	liczba2_sign, %ah
	cmpb	%al, %ah			# Jak rozne znaki to przechodzimy do odejmowania
	jnz	zle_znaki

	movb	%al, wynik_sign

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

	movl	(%edi), %eax
	movl	4(%edi), %edx
	cmpl	4(%esi), %edx
	jl	druga
	cmpl	4(%esi), %edx
	jg	pierwsza
	cmpl	(%esi), %eax
	jnb	pierwsza
	
druga:							# W wypadku gdy druga liczba jest mniejsza
	movl	4(%esi), %eax

	pushl	%edi
	movl	$wynik_exp, %edi
	movl	%eax, 4(%edi)		# Przepisanie wiekszej eksponenty
	popl	%edi
    
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
	
	movl	4(%edi), %ebx
	subl	%ebx, %eax

	movl	(%esi), %ecx
	movl	%ecx, wynik_exp		# Druga czesc przepisania
	movl	(%edi), %edx
	sbbl	%edx, %ecx			# Wynik roznicy w ecx:eax

	# Wyliczenie mantysy
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
    jnc nie_cf2
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
    jmp po_ustawieniu

pierwsza:						# W wypadku gdy pierwsza liczba jest mniejsza lub rowna
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
	sbbl	%edx, %ecx			# Wynik roznicy w ecx:eax
    
    cmpl    $0, %eax
    jnz nie_rowne_zero_ecxeax
    cmpl    $0, %ecx
    jz  po_ustawieniu
	
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
	# Alokacja pamieci na wynik
	movl	liczba1_size, %eax
	movl	%eax, wynik_size
	imull	$4, %eax
	pushl	%eax
	call	malloc
	addl	$4, %esp
	movl	%eax, wynik_mts

	# Liczby sprowadzone do wspolnej potegi (teraz dodawanie)
	movl	liczba1_mts, %esi
	movl	liczba2_mts, %edi
	movl	liczba1_size, %edx
	clc
	
dodanie_mantysy:
	decl	%edx
	movl	(%esi, %edx, 4), %eax
	movl	(%edi, %edx, 4), %ebx
	adcl	%eax, %ebx
    jnc dodaj_dalej
    movb    $1, czy_normalizowac
    jmp dodaj_kolejny
dodaj_dalej:
    movb    $0, czy_normalizowac
dodaj_kolejny:
	pushl	%edi
	movl	wynik_mts, %edi
	movl	%ebx, (%edi, %edx, 4)
	popl	%edi

	cmpl	$0, %edx				# Czy juz wszystko zostalo dodane
	jnz	dodanie_mantysy

    cmpb    $0, czy_normalizowac    # W wypadku gdy nie trzeba znormalizowac
    jz  koniec
    call    normalizacja
	jmp koniec
zle_znaki:
	call	odejmij					# Wywolanie odejmowania

koniec:
    movl	jakie_zaokraglenie, %eax
	call	zaokraglenie
    
    # Sprawdzenie czy nie wyszlo zero
	movl	wynik_mts, %edi
	movl	wynik_size, %ecx
	xorl	%edx, %edx
czy_zero:
	movl	(%edi, %edx, 4), %eax
	incl	%edx
	cmpl	$0, %eax
	jnz	nie_zero
	loop	czy_zero
	
	call ZeroNumb
	
nie_zero:
	leave
	ret
