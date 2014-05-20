# Tu bedzie modul glowny

# Deklaracja stalych
EXIT = 1
SYSCALL = 0x80

.data

liczba1_sign:	.byte	0
liczba1_exp:	.quad	0
liczba1_mts:	.long	0	#to przechowuje adres to tablicy gdzie znajudje sie mantyssa
liczba1_size:	.long	0	#rozmiar tablicy (musi byc wyrownany do 4 bajtow)

liczba2_sign:	.byte	0
liczba2_exp:	.quad	0
liczba2_mts:	.long	0	#to przechowuje adres to tablicy gdzie znajudje sie mantyssa
liczba2_size:	.long	0	#rozmiar tablicy (musi byc wyrownany do 4 bajtow)

wynik_sign:	.byte	0
wynik_exp:	.quad	0
wynik_mts:	.long	0	#to przechowuje adres to tablicy gdzie znajudje sie mantyssa
wynik_size:	.long	0	#rozmiar tablicy (musi byc wyrownany do 4 bajtow)

.include "przyklad.inc"

# Zaczynamy kod
.text
.globl	main	#bedzie kompilowane pod gcc dla wygody
main:

	#dane z przykladu laduja tutaj (liczba 1)
	movb	SIGN1, %al
	movb	%al, liczba1_sign
	movl	EXP1, %eax
	movl	%eax, liczba1_exp
	#sarl	$32, liczba1_exp
	movl	$1, %edi
	movl	EXP1(, %edi, 4), %eax
	movl	%eax, liczba1_exp(, %edi, 4)
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
	movl	EXP2, %eax
	movl	%eax, liczba2_exp
	#sarl	$32, liczba2_exp
	movl	$1, %edi
	movl	EXP2(, %edi, 4), %eax
	movl	%eax, liczba2_exp(, %edi, 4)
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


	pushl	liczba1_mts
	call	free
	addl	$4, %esp

	pushl	liczba2_mts
	call	free
	addl	$4, %esp

	movl	$0, %ebx
	movl	$EXIT, %eax
	int	$SYSCALL

# Cos juz jest

