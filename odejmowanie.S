################################################
# Modul odejmujacy 2 liczby zmiennoprzecinkowe #
################################################

.data
czy_pierwszy_obieg:	.byte	0
jakie_zaokraglenie:	.long	0
iterator_1:			.long	0
iterator_2:			.long	0

.text
.globl	odejmij
.type	odejmij, @function
odejmij:
	pushl	%ebp
	movl	%esp, %ebp
	movb	liczba1_sign, %al
	movb	liczba2_sign, %ah
	cmpb	%al, %ah			# Jak takie same znaki to przechodzimy do dodawania
	jz	zle_znaki

	movl	$liczba1_exp, %esi
	movl	$liczba2_exp, %edi

	movl	(%edi), %eax
	movl	4(%edi), %edx
	cmpl	4(%esi), %edx
	jl	druga
	cmpl	4(%esi), %edx
	jg	pierwsza
	cmpl	(%esi), %eax
	jb	druga
	
druga:							# W wypadku gdy druga liczba jest wieksza
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
	decl	iterator_1
	cmpl	$0, iterator_1
	jnz	powtorz_2
	cmpl	$0, iterator_2
	jz koniec_shift_2
	
	# Zabranie z wyzszego
	decl	iterator_2
	movl	$0xFFFFFFFF, iterator_1
	
powtorz_2:
	movl	liczba2_size, %ecx
	xorl	%ebx, %ebx
	clc
	jmp	shift_2
	
koniec_shift_2:

pierwsza:						# W wypadku gdy pierwsza liczba jest wieksza lub rowna
	movl	liczba2_sign, %eax
	movl	%eax, wynik_sign	# Przepisujemy znak od wiekszej
    
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

sprowadzone:
	jnc	po_ustawieniu
	movb	$1, bit_specjalny
	
po_ustawieniu:
	# Alokacja pamieci na wynik
	movl	liczba1_size, %eax
	movl	%eax, wynik_size
	imull	$4, %eax
	pushl	%eax
	call	malloc
	addl	$4, %esp
	movl	%eax, wynik_mts

	# Liczby sprowadzone do wspolnej potegi (teraz odejmowanie)
	movl	liczba1_mts, %esi
	movl	liczba2_mts, %edi
	movl	liczba1_size, %edx
	clc
	
odjecie_mantysy:
	decl	%edx
	movl	(%esi, %edx, 4), %eax
	movl	(%edi, %edx, 4), %ebx
	sbbl	%eax, %ebx
	pushl	%edi
	movl	wynik_mts, %edi
	movl	%ebx, (%edi, %edx, 4)
	popl	%edi

	cmpl	$0, %edx				# Czy juz wszystko zostalo odjete
	jnz	odjecie_mantysy
    
    jnc koniec						# W wypadku gdy nie trzeba znormalizowac
    call    normalizacja
    
    movl	jakie_zaokraglenie, %eax
	call	zaokraglenie
	
zle_znaki:
	call	dodaj					# Wywolanie dodawania

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
