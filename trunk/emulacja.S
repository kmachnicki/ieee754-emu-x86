# Tu bedzie modul glowny

# Deklaracja stalych
EXIT = 1
SYSCALL = 0x80

.data

.globl	bit_specjalny
bit_specjalny:	.byte	0	#potrzebne do informacji o zaokragleniu

rodzaj_zaokraglenia:	.long	0

.globl	liczba1_sign
.globl	liczba1_exp
.globl	liczba1_mts
.globl	liczba1_size

liczba1_sign:	.byte	0
liczba1_exp:	.quad	0
liczba1_mts:	.long	0	#to przechowuje adres to tablicy gdzie znajudje sie mantyssa
liczba1_size:	.long	0	#rozmiar tablicy (musi byc wyrownany do 4 bajtow)

.globl	liczba2_sign
.globl	liczba2_exp
.globl	liczba2_mts
.globl	liczba2_size
liczba2_sign:	.byte	0
liczba2_exp:	.quad	0
liczba2_mts:	.long	0	#to przechowuje adres to tablicy gdzie znajudje sie mantyssa
liczba2_size:	.long	0	#rozmiar tablicy (musi byc wyrownany do 4 bajtow)

.globl	wynik_sign
.globl	wynik_exp
.globl	wynik_mts
.globl	wynik_size
wynik_sign:	.byte	0
wynik_exp:	.quad	0
wynik_mts:	.long	0	#to przechowuje adres to tablicy gdzie znajudje sie mantyssa
wynik_size:	.long	0	#rozmiar tablicy (musi byc wyrownany do 4 bajtow)

.include "przyklad.inc"

menu:	.ascii	"Wybierz operacje z menu: \n1. Dodawanie\n2. Odejmowanie\n3. Mnozenie\n\0"
zaok:	.ascii	"Wybierz sposob zaokraglania: \n0 - przez obciecie\n1 - do \"gory\"\n2 - do najblizszej parzystej\n\0"
wybor:	.long	0
wybor_fmt:	.ascii	"%d\0"

# Zaczynamy kod
.text
.globl	main	#bedzie kompilowane pod gcc dla wygody
main:

	#dane z przykladu laduja tutaj (liczba 1)
	movb	SIGN1, %al
	movb	%al, liczba1_sign
	movl	$1, %edi
	movl	EXP1, %eax
	movl	%eax, liczba1_exp( ,%edi, 4)
	#sarl	$32, liczba1_exp
	#movl	$1, %edi
	movl	EXP1(, %edi, 4), %eax
	movl	%eax, liczba1_exp
	movl    ROZM1, %eax
	movl	%eax, liczba1_size
	movl    $4, %ebx
	mul     %ebx
	pushl	%eax
	call	malloc
	addl	$4, %esp
	movl	%eax, liczba1_mts
	#przepisanie tablicy (mantysy)
	movl	liczba1_size, %ecx
	xorl	%edx, %edx
	movl	$mantyssa1, %esi
	movl	liczba1_mts, %edi
przepisanie_mant_1:
	movl	(%esi, %edx, 4), %eax
	movl	%eax, (%edi, %edx, 4)
	incl	%edx
	cmpl	liczba1_size, %edx
	jz	koniec_liczba1
	loop	przepisanie_mant_1
koniec_liczba1:
	#pierwsza liczba juz w pamieci

	#dane z przykladu laduja tutaj (liczba 2)
	movb	SIGN2, %al
	movb	%al, liczba2_sign
	movl	$1, %edi
	movl	EXP2, %eax
	movl	%eax, liczba2_exp( ,%edi, 4)
	#sarl	$32, liczba2_exp
	#movl	$1, %edi
	movl	EXP2(, %edi, 4), %eax
	movl	%eax, liczba2_exp
	movl    ROZM2, %eax
	movl    %eax, liczba2_size
	movl    $4, %ebx
	mull    %ebx
	pushl	%eax
	call	malloc
	addl	$4, %esp
	movl	%eax, liczba2_mts
	#przepisanie tablicy (mantysy)
	movl	liczba2_size, %ecx
	xorl	%edx, %edx
	movl	$mantyssa2, %esi
	movl	liczba2_mts, %edi
przepisanie_mant_2:
	movl	(%esi, %edx, 4), %eax
	movl	%eax, (%edi, %edx, 4)
	incl	%edx
	cmpl	liczba2_size, %edx
	jz	koniec_liczba2
	loop	przepisanie_mant_2
koniec_liczba2:
	#druga liczba juz w pamieci

	#rodzaj zaokraglania
	pushl	$zaok
	call	printf
	addl	$4, %esp

	pushl	$rodzaj_zaokraglenia
	pushl	$wybor_fmt
	call	scanf
	addl	$4*2, %esp

	#menu
	pushl	$menu
	call	printf
	addl	$4, %esp

	pushl	$wybor
	pushl	$wybor_fmt
	call	scanf
	addl	$4 * 2, %esp

	cmpl	$1, wybor
	jz wybor_dodawanie
	cmpl	$2, wybor
	jz wybor_odejmowanie
	cmpl	$3, wybor
	jnz	po_operacjach

	movl	rodzaj_zaokraglenia, %eax			#parametr funkcji

wybor_mnozenie:
	call	mnoz
	jmp	po_operacjach

wybor_odejmowanie:
	call	odejmij
	jmp	po_operacjach

wybor_dodawanie:
	call	dodaj	

po_operacjach:
	#zwalnianie pamieci
	pushl	liczba1_mts
	call	free
	addl	$4, %esp

	pushl	liczba2_mts
	call	free
	addl	$4, %esp

	cmpl	$0, wynik_mts
	jz	koniec
	#jak zaalokowano to zwolnij pamiec tez tutaj
	pushl	wynik_mts
	call	free
	addl	$4, %esp

koniec:
	pushl	$0
	call	exit			#much portable wow

# Cos juz jest

