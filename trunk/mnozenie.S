#############################################
# Modul mnozacy 2 liczby zmiennoprzecinkowe #
#############################################

BIAS_H = 0x7FFFFDFF
BIAS_L = 0xFFFFFFFF

MASKA_TEST = 0b10000000000000000000000000000000

.data
czy_pierwszy_obieg:	.byte	0
pamiec_pomoc:		.long	0
jakie_zaokraglenie:	.long	0

rozmiar_temp:		.long   0
ktore_przejscie:	.long	0

.text
.globl	mnoz
.type	mnoz, @function
mnoz:
	pushl	%ebp
	movl	%esp, %ebp
	
	movb	liczba1_sign, %al
	movb	liczba2_sign, %ah
	cmpb	%al, %ah			# Jak znaki sa rozne to wynik bedzie ujemny
	jz	bedzie_dodatni
	movb	$1, wynik_sign
    jmp po_zamianie_znakow
bedzie_dodatni:
	movb	$0, wynik_sign
po_zamianie_znakow:
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
    
druga:

    movl    4(%esi), %eax
    movl	4(%edi), %ebx
	subl	%ebx, %eax

	movl	(%esi), %ecx
	movl	(%edi), %edx
	sbbl	%edx, %ecx			# Wynik roznicy w ecx:eax
    
    #trzeba dodac roznice (w tym wypadku do wiekszej czyli do pierwszej)
    addl    %eax, 4(%esi)
    adcl    %ecx, (%esi)
    jno nie_ma_overflow1        #czy w wyniku dodawania wystapil overflow
    call    inf_plus
    jmp nie_zero                #konczymy
nie_ma_overflow1:
    #teraz przepisanie sumy
    pushl   %edi
    movl    $wynik_exp, %edi
    movl    4(%esi), %eax
    movl    %eax, 4(%edi)
    movl    (%esi), %eax
    movl    %eax, (%edi)
    popl    %edi
    
    jmp sprowadzone

pierwsza:

    movl	4(%edi), %eax
	movl	4(%esi), %ebx
	subl	%ebx, %eax

	movl	(%edi), %ecx
	movl	(%esi), %edx
	sbbl	%edx, %ecx			# Wynik roznicy w ecx:eax
    
    #trzeba dodac roznice (w tym wypadku do wiekszej czyli do drugiej)
    addl    %eax, 4(%edi)
    adcl    %ecx, (%edi)
    jno nie_ma_overflow2        #czy w wyniku dodawania wystapil overflow
    call    inf_plus
    jmp nie_zero                #konczymy
nie_ma_overflow2:
    #teraz przepisanie sumy
    pushl   %esi
    movl    $wynik_exp, %esi
    movl    4(%edi), %eax
    movl    %eax, 4(%esi)
    movl    (%edi), %eax
    movl    %eax, (%esi)
    popl    %esi

sprowadzone:
	#trzeba ujawinić jedynkę
	movl	liczba1_mts, %esi
	movl	liczba2_mts, %edi
	movl	liczba1_size, %ecx
	xorl	%ebx, %ebx
	stc
odkryj_jedynke1:
	rcrl	$1, (%esi, %ebx, 4)			#przesuwa pierwsza liczbe
	incl	%ebx
	loop    odkryj_jedynke1
	
	movl	liczba1_size, %ecx
	xorl	%ebx, %ebx
	stc
odkryj_jedynke2:						#przesuwa druga liczbe
	rcrl	$1, (%edi, %ebx, 4)
	incl	%ebx
	loop    odkryj_jedynke2

	# Alokacja pamieci na wynik
	movl	liczba1_size, %eax
	movl	%eax, wynik_size
	movl    $4*2, %ebx
	mull	%ebx				# Wynik jest 2 razy wiekszy
	pushl	%eax
	call	malloc
	addl	$4, %esp
	movl	%eax, wynik_mts
	
	movl    liczba2_size, %eax
	movl    $2, %ebx
	mull    %ebx
	movl    %eax, rozmiar_temp  # W ebx jest 2 razy rozmiar
	
	# Zerowanie
	movl	%eax, %ecx
	xorl	%eax, %eax
	movl	wynik_mts, %edi
	
zeruj:
	movl	$0, (%edi, %eax, 4)
	incl	%eax
	cmpl	rozmiar_temp, %eax
	jnz	zeruj

	# Mnozenie
	movl    liczba1_mts, %edi
	movl    liczba2_mts, %esi
	movl	liczba2_size, %ecx
	movl	$0, ktore_przejscie
	
petla_mnoz:
	clc
	decl	%ecx
	movl    liczba1_size, %edx
	movl    %edx, %ebx
    incl    %ebx
	subl	ktore_przejscie, %ebx
	
petla2_mnoz:
	decl    %edx
	movl    (%edi, %edx, 4), %eax
	pushl	%edx					# Zostanie nadpisany przy mnozeniu
	mull    (%esi, %ecx, 4)         # Obliczenie czastokowego iloczynu
	pushl   %edi
	movl   	wynik_mts, %edi
	adcl	%eax, (%edi, %ebx, 4)
	pushl	%ebx
	decl	%ebx
	adcl	%edx, (%edi, %ebx, 4)
	popl	%ebx 
	popl	%edi  	
	popl	%edx
	cmpl	$0, %edx
	jnz	petla2_mnoz
	incl	ktore_przejscie
	cmpl	$0, %ecx
	jnz	petla_mnoz
	
	#jnc koniec
	#call    normalizacja
	
	#chwilowo tutaj normalizacja
	movl	wynik_mts, %edi
    movl    wynik_size, %ecx
	movl    %ecx, %ebx
	clc
	
shift_wynik2:
    decl    %ebx
	rcll	$1, (%edi, %ebx, 4)
	loop    shift_wynik2
		
zwiekszenie_mantysy:
	movl	$wynik_exp, %edi
	movl	4(%edi), %eax
	movl	(%edi), %ebx
	addl	$1, %eax
	adcl	$0, %ebx
	movl	%ebx, (%edi)
	movl	%eax, 4(%edi)

koniec:
	# Sprawdzenie czy jest co zaokraglac
	movl	wynik_size, %ecx
	movl	wynik_mts, %edi
	movl	(%edi, %ecx, 4), %eax
	test	$MASKA_TEST, %eax
	jz	nie_ustawiac
	movb	$1, bit_specjalny
	jmp	okr
	
nie_ustawiac:
	movb	$0, bit_specjalny

okr:
	movl	jakie_zaokraglenie, %eax
	call	zaokraglenie

	# Przy koncu trzeba zwrocic znowu taki sam rozmiar jak na poczatku (nastepuje obciecie)
	movl	wynik_size, %eax
	movl	$4, %ebx
	mull	%ebx
	pushl	%eax
	call	malloc
	addl	$4, %esp
	movl	%eax, pamiec_pomoc

	# Przepisanie tablicy
	movl	wynik_mts, %esi
	movl	pamiec_pomoc, %edi
	xorl	%ecx, %ecx
	
przepisz_petla:
	movl	(%esi, %ecx, 4), %eax
	movl	%eax, (%edi, %ecx, 4)
	incl	%ecx
	cmpl	wynik_size, %ecx
	jnz	przepisz_petla	

	pushl	wynik_mts
	call	free
	addl	$4, %esp

	movl	pamiec_pomoc, %eax
	movl	%eax, wynik_mts			# Zamiana wskaznikow
	
	# Sprawdzenie czy nie wyszlo zero
	movl	wynik_mts, %edi
	movl	wynik_size, %ecx
	xorl	%edx, %edx
	
#czy_zero:
#	movl	(%edi, %edx, 4), %eax
#	incl	%edx
#	cmpl	$0, %eax
#	jnz	nie_zero
#	loop	czy_zero
#	
#	call ZeroNumb
	
nie_zero:
	leave
	ret
