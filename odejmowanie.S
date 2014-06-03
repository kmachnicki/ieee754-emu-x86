# Modul odejmujacy 2 liczby zmiennoprzecinkowe

MASKA_CF = 0b10000000

.data
czy_pierwszy_obieg:	.byte	0
jakie_zaokraglenie:	.long	0

.text
.globl	odejmij
.type	odejmij, @function
odejmij:
	pushl	%ebp
	movl	%esp, %ebp
	movb	liczba1_sign, %al
	movb	liczba2_sign, %ah
	cmpb	%al, %ah			#jak te same znaki to dodawanie
	jz	zle_znaki

	#movl	$0, %edx
	movl	$liczba1_exp, %esi
	movl	$liczba2_exp, %edi

	#movl	(%esi, %edx, 4), %eax
	#movl	(%edi, %edx, 4), %ebx
	#subl	%eax, %ebx			#rozniaca wykladnikow

	#incl	%edx
	#movl	(%esi, %edx, 4), %eax
	#movl	(%edi, %edx, 4), %edx
	#subl	%eax, %edx			#roznica mlodszych(starszych) czesci

	movl	(%edi), %eax
	movl	4(%edi), %edx
	cmpl	4(%esi), %edx
	jl	druga
	cmpl	4(%esi), %edx
	jg	pierwsza
	cmpl	(%esi), %eax
	jb	druga
	
druga:							#druga liczba jest wieksza
	movl	liczba2_sign, %eax
	movl	%eax, wynik_sign	#od razu przepisujemy znak od wiekszej	

	movl	4(%esi), %eax

	pushl	%edi
	movl	$wynik_exp, %edi
	movl	%eax, 4(%edi)		#przepisanie wiekszej exponenty
	popl	%edi
	
	movl	4(%edi), %ebx
	subl	%ebx, %eax

	movl	(%esi), %ecx
	movl	%ecx, wynik_exp		#druga czesc przepisania
	movl	(%edi), %edx
	sbbl	%edx, %ecx			# ecx:eax roznica

	movb	$1, czy_pierwszy_obieg	#zeby ujawnic jedynke

	movl	liczba2_mts, %edi
przesuwanie:
	decl	%eax
	xorl	%ebx, %ebx
	clc							#usun CF zeby nie przenioslo z konca przniesienia na poczatek
	cmpb	$1, czy_pierwszy_obieg
	jnz	shift_mts2				#jezeli to kolejne przjscie to nie ustawiaj CF
	stc							#zostanie przeniesiony w shr bit z CF czyli utajniona jedynka z 1.00f -> 0.10f
shift_mts2:
	shrl	$1, (%edi, %ebx, 4)
	incl	%ebx
	cmpl	liczba2_size ,%ebx
	jnz	shift_mts2				#po kolei kazdy przsuwa po jednym (wykonuje jeden pelny shift)
	movb	$0, czy_pierwszy_obieg

	cmpl	$0, %eax			#czy jednosci rowne 0
	jnz	przesuwanie

	cmpl	$0, %ecx			#czy juz wszystko przesuniete
	jz	sprowadzone
	
	decl	%ecx
	movl	$0xFFFFFF, %eax		#jak przekroczony to zabieramy z wyzszego

	jmp	przesuwanie

pierwsza:						#piersza liczba jest wieksza badz rowna
	movl	liczba1_sign, %eax
	movl	%eax, wynik_sign	#od razu przepisujemy znak od wiekszej	
	
	movl	4(%edi), %eax
	movl	4(%esi), %ebx
	subl	%ebx, %eax

	movl	(%edi), %ecx
	movl	(%esi), %edx
	sbbl	%edx, %ecx			# ecx:eax roznica
	
	movb	$1, czy_pierwszy_obieg	#zeby ujawnic jedynke

	movl	liczba1_mts, %edi
przesuwanie_1:
	decl	%eax
	xorl	%ebx, %ebx
	clc
	cmpb	$1, czy_pierwszy_obieg
	jnz	shift_mts2				#jezeli to kolejne przjscie to nie ustawiaj CF
	stc							#zostanie przeniesiony w shr bit z CF czyli utajniona jedynka z 1.00f -> 0.10f
shift_mts1:
	shrl	$1, (%edi, %ebx, 4)
	incl	%ebx
	cmpl	liczba1_size ,%ebx
	jnz	shift_mts1				#po kolei kazdy przsuwa po jednym (wykonuje jeden pelny shift)
	movb	$0, czy_pierwszy_obieg

	cmpl	$0, %eax			#czy jednosci rowne 0
	jnz	przesuwanie_1

	cmpl	$0, %ecx			#czy juz wszystko przesuniete
	jz	sprowadzone
	
	decl	%ecx
	movl	$0xFFFFFF, %eax		#jak przekroczony to zabieramy z wyzszego

	jmp	przesuwanie_1
sprowadzone:
jnc	po_ustawieniu
	movb	$1, bit_specjalny
po_ustawieniu:
	#trzeba zaalokowac pamiec na wynik
	movl	liczba1_size, %eax
	movl	%eax, wynik_size
	imull	$4, %eax
	pushl	%eax
	call	malloc
	addl	$4, %esp
	movl	%eax, wynik_mts

	#liczby sprowadzone do jednego wspolnej potegi (teraz odejmowanie)
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

	cmpl	$0, %edx				#czy juz wsio odjete
	jnz	odjecie_mantysy

	#trzeba sprawdzic ukryta jedynke (czy wystapilo przeniesienie)
	#xorl	%eax, %eax
	#shrb	$1, %al					#przesun CF tutaj
	#test	$MASKA_CF, %al
	#jz	koniec
    
    jnc koniec
    call    normalizacja
    
    movl	jakie_zaokraglenie, %eax
	call	zaokraglenie
	
zle_znaki:
	#movl	$-1, %eax			#kod bledu -1
	call	dodaj

koniec:
	leave
	ret

