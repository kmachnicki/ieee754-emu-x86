# Modul mnozy 2 liczby zmiennoprzecinkowe

MASKA_CF = 0b10000000
BIAS_H = 0x7FFFFDFF
BIAS_L = 0xFFFFFFFF

.data
czy_pierwszy_obieg:	.byte	0
pamiec_pomoc:	.long	0
jakie_zaokraglenie:	.long	0

rozmiar_temp:	.long   0
ktore_przejscie:	.long	0

.text
.globl	mnoz
.type	mnoz, @function
mnoz:
	pushl	%ebp
	movl	%esp, %ebp
	movb	liczba1_sign, %al
	movb	liczba2_sign, %ah
	cmpb	%al, %ah			#jak rozne znaki to bedzie ujemna
	jz	po_zamianie_znakow

	movb	$1, wynik_sign

po_zamianie_znakow:

	movb	%al, wynik_sign

	#movl	$0, %edx
	movl	$liczba1_exp, %esi
	movl	$liczba2_exp, %edi

	movl	4(%esi), %eax		#mlodsza czesc
	subl	$BIAS_L, %eax
	movl	%eax, %ebx
	movl	(%esi), %eax
	sbbl	$BIAS_H, %eax
	movl	%eax, %ecx			#pierwsza liczba ecx:ebx

	movl	4(%edi), %eax
	subl	$BIAS_L, %eax
	movl	(%edi), %edx
	sbbl	$BIAS_H, %edx		#druga liczba edx:eax

	#trzeba dodac wykladniki
	addl	%ebx, %eax
	adcl	%ecx, %edx			#wynik w edx:eax

	#trzeba dodac BIAS
	addl	$BIAS_L, %eax
	adcl	$BIAS_H, %edx
	
	#mogl wystapic overflow
	#jno brak_over
	#cmpb    $1, wynik_sign
	#jz  exc_ujemna
	#call    inf_minus
	#jmp koniec
exc_ujemna:
	#call    inf_minus
	#jmp koniec
brak_over:
	#wpisanie wartosci do pamieci
	movl	$wynik_exp, %edi	
	movl	%eax, 4(%edi)
	movl	%edx, (%edi)		

	#movl	(%esi, %edx, 4), %eax
	#movl	(%edi, %edx, 4), %ebx
	#subl	%eax, %ebx			#rozniaca wykladnikow

	#incl	%edx
	#movl	(%esi, %edx, 4), %eax
	#movl	(%edi, %edx, 4), %edx
	#subl	%eax, %edx			#roznica mlodszych(starszych) czesci

sprowadzone:
	#trzeba zaalokowac pamiec na wynik
	movl	liczba1_size, %eax
	movl	%eax, wynik_size
	movl    $4*2, %ebx
	mull	%ebx				#musi byc 2 razy tyle miejsca
	pushl	%eax
	call	malloc
	addl	$4, %esp
	movl	%eax, wynik_mts
	
	movl    liczba2_size, %eax
	movl    $2, %ebx
	mull    %ebx
	movl    %eax, rozmiar_temp  #ebx to 2x rozmiar
	
	
	#zerowanie
	movl	%eax, %ecx
	xorl	%eax, %eax
	movl	wynik_mts, %edi
zeruj:
	movl	$0, (%edi, %eax, 4)
	incl	%eax
	cmpl	rozmiar_temp, %eax
	jnz	zeruj

	#mnozenie
#mnozenie:
#	movl	liczba1_size, %eax
#	movl	%eax, %edx
#	mull	%edx				#nowa tablica ma x2 dlugosci
#    movl    %eax, %edx
#	movl	liczba1_mts, %esi
#	movl	liczba2_mts, %edi
#	decl	%edx
#	pushl	%ebp
#	movl	%edx, %ebp
#petla_mnozenie:
#	decl	%ecx
#	movl	(%esi, %ecx, 4), %eax
#	movl	(%edi, %ecx, 4), %ebx
#	mull	%ebx
#	pushl	%edi
#	movl	wynik_mts, %edi
#	movl	%eax, (%edi, %ebp, 4)
#	decl	%ebp
#	movl	%edx, (%edi, %ebp, 4)
#	popl	%edi
#	cmpl	$0, %ecx
#	jnz	petla_mnozenie
#	popl	%ebp

	#mnozenie
	movl    liczba1_mts, %edi
	movl    liczba2_mts, %esi
	movl	liczba2_size, %ecx
	#movl    rozmiar_temp, %ebx 		#ebx to 2x rozmiar
	movl	$0, ktore_przejscie
petla_mnoz:
	clc
	#decl    %ebx
	decl	%ecx
	movl    liczba1_size, %edx
	movl    rozmiar_temp, %ebx
	decl	%ebx
	subl	ktore_przejscie, %ebx
petla2_mnoz:
	decl    %edx
	movl    (%edi, %edx, 4), %eax
	pushl	%edx					#zostanie nadpisany przy mnozeniu
	mull    (%esi, %ecx, 4)         #obliczenie czastokowego iloczynu
	pushl   %edi
	#subl	ktore_przejscie, %ebx
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

	#trzeba sprawdzic ukryta jedynke
	#xorl	%eax, %eax
	#shrb	$1, %al					#przesun CF tutaj
	#test	$MASKA_CF, %al
	#jz	koniec
	
	jnc koniec
	call    normalizacja
	
	movl	jakie_zaokraglenie, %eax
	call	zaokraglenie

koniec:
	#przy koncu trzeba zwrocic znowu taki sam rozmiar jak na poczatku (nastepuje obciecie)
	movl	wynik_size, %eax
	imull	$4, %eax
	pushl	%eax
	call	malloc
	addl	$4, %esp
	movl	%eax, pamiec_pomoc

	#przepisanie tablicy
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
	movl	%eax, wynik_mts			#zamiana wskaznikow
	
	#sprawdz czy nie wyszlo zero
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

