#############################################
# Modul mnozacy 2 liczby zmiennoprzecinkowe #
#############################################

BIAS_H = 0x7FFFFFFF
BIAS_L = 0xFFFFFFFF

MASKA_TEST = 0b10000000000000000000000000000000

OVER_TEST = 0b00000000000000000000000000000001

ROZMIAR_PAKIETU = 8

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
    
    #sprawdzenie czy obie EXP dodatnie
    
    movl	$liczba1_exp, %esi
	movl	$liczba2_exp, %edi
	
    movl	(%esi), %eax
    test	$MASKA_TEST, %eax
    jz	ujemna1
    movl	(%edi), %eax
    test	$MASKA_TEST, %eax
    jz	ujemna2
    
dodatnia:
	#odjeci BIAS od pierwszej EXP
	subl	$BIAS_L, 4(%esi)
	sbbl	$BIAS_H, (%esi)
	
	#odjecie BIAS od drugiej EXP
	subl	$BIAS_L, 4(%edi)
	sbbl	$BIAS_H, (%edi)
	
	#dodanie exp1 + exp2
	movl	4(%esi), %eax
	addl	4(%edi), %eax
	movl	(%esi), %ebx
	adcl	(%edi), %ebx
	
	#dodanie BIAS od ebx:eax
	addl	$BIAS_L, %eax
	adcl	$BIAS_H, %ebx
	jc	overflow
	
	#przeniesienie od wyniku
	pushl	%edi
	movl	$wynik_exp, %edi
	movl	%eax, 4(%edi)
	movl	%ebx, (%edi)
	popl	%edi
	
	jmp	sprowadzone
	
overflow:
	call	inf_plus
	jmp	nie_zero

ujemna1:
	#trzeba sprawdzić czy druga tez nie ujemna
	movl	(%edi), %eax
    test	$MASKA_TEST, %eax
    jz	ujemne
    
    #pierwsza ujemna, druga dodatnia
    #od BIAS odjac EXP1
    movl	$BIAS_L, %eax
    movl	$BIAS_H, %ebx
    subl	4(%esi), %eax
    sbbl	(%esi), %ebx				#wynik ebx:eax
    #od EXP2 odjac BIAS
    subl	$BIAS_L, 4(%edi)
    sbbl	$BIAS_H, (%edi)				#wynik w EXP2
    
    #odjac w NB od drugiej pierwsza (EXP - ebx:eax)
    subl	%eax, 4(%edi)
    sbbl	%ebx, (%edi)				#wynik w EXP2
    
    #do wyniku dodac BIAS
    addl	$BIAS_L, 4(%edi)
    adcl	$BIAS_H, (%edi)
    jc	overflow
    
    #wynik przeniesc do wynik_exp
    pushl	%esi
    movl	$wynik_exp, %esi
    movl	4(%edi), %eax
    movl	(%edi), %ebx
    movl	%eax, 4(%esi)
    movl	%ebx, (%esi)
    popl	%esi
    
	jmp	sprowadzone
	
ujemna2:
	#pierwsza dodatnia, druga ujemna
	#od EXP1 odjac BIAS
    subl	$BIAS_L, 4(%esi)
    sbbl	$BIAS_H, (%esi)				#wynik w EXP1
    
    #od BIAS odjac EXP2
    movl	$BIAS_L, %eax
    movl	$BIAS_H, %ebx
    subl	4(%edi), %eax
    sbbl	(%edi), %ebx				#wynik ebx:eax
    
    #odjac w NB od pierwszej druga (EXP1 - ebx:eax)
    subl	%eax, 4(%esi)
    sbbl	%ebx, (%esi)				#wynik w EXP1
    
    #do wyniku dodac BIAS
    addl	$BIAS_L, 4(%esi)
    adcl	$BIAS_H, (%esi)
    jc	overflow
    
    #wynik przeniesc do wynik_exp
    pushl	%edi
    movl	$wynik_exp, %edi
    movl	4(%esi), %eax
    movl	(%esi), %ebx
    movl	%eax, 4(%edi)
    movl	%ebx, (%edi)
    popl	%edi
	jmp	sprowadzone
	
ujemne:
	#obie ujemne
	
	#od BIAS odjac EXP1
    movl	$BIAS_L, %eax
    movl	$BIAS_H, %ebx
    subl	4(%esi), %eax
    sbbl	(%esi), %ebx				#wynik ebx:eax
    
    #od BIAS odjac EXP2
    movl	$BIAS_L, %ecx
    movl	$BIAS_H, %edx
    subl	4(%edi), %ecx
    sbbl	(%edi), %edx				#wynik edx:ecx
    
    #dodac obie liczby
    addl	%ecx, %eax
    adcl	%edx, %ebx					#wynik ebx:eax
    
    #dodac BIAS do wyniku
	addl	$BIAS_L, %eax
	adcl	$BIAS_H, %ebx
	jc	overflow
	
	#zanegowac caly wynik
	notl	%eax
	notl	%ebx
	
	#odjac 1
	subl	$1, %eax
	sbbl	$0, %ebx
	
	#wynik przeniesc do wynik_exp
    pushl	%edi
    movl	$wynik_exp, %edi
    movl	%eax, 4(%edi)
    movl	%ebx, (%edi)
    popl	%edi

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
		
#zwiekszenie_mantysy:
#	movl	$wynik_exp, %edi
#	movl	4(%edi), %eax
#	movl	(%edi), %ebx
#	addl	$1, %eax
#	adcl	$0, %ebx
#	movl	%ebx, (%edi)
#	movl	%eax, 4(%edi)
	
	#sprawdzanie czy overflow + przesuniecie wyniku o jeden pakiet
	movl	wynik_mts, %esi
	movl	(%esi), %eax
	test	$OVER_TEST, %eax
	jz	nie_ma_ov
	#jest ov to trzeba dodac 1 do exp
	movl	$wynik_exp, %esi
	addl	$1, 4(%esi)
	adcl	$0, (%esi)
	#czy overflow
	jc	overflow
	
nie_ma_ov:
	#przesuniecie
	movl	wynik_mts, %edi
    #movl	$ROZMIAR_PAKIETU, %edx
    #movl	rozmiar_temp, %edx
	movl rozmiar_temp, %eax
	movl $32, %ebx
	mull %ebx
	movl %eax, %edx
wyr_caly_pkt:
	movl    wynik_size, %ecx
	movl    %ecx, %ebx
	movl	(%edi), %eax
	test	$MASKA_TEST, %eax			#sprawdza czy jest jeden na poczatku
	jnz	koniec
	clc
wyrownaj_pakiet:
	decl    %ebx
	rcll	$1, (%edi, %ebx, 4)
	loop    wyrownaj_pakiet
	decl	%edx
	cmpl	$0, %edx
	jnz	wyr_caly_pkt
	#jeszcze raz zeby ukryc te jedynke
	movl	wynik_size, %ecx
	xorl	%ebx, %ebx
	clc
wyrownaj_pakiet2:
	decl    %ebx
	rcll	$1, (%edi, %ebx, 4)
	loop    wyrownaj_pakiet2
	
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
