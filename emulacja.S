# Modul glowny

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

menu:	.ascii	"Wybierz operacje z menu: \n1. Dodawanie\n2. Odejmowanie\n3. Mnozenie\n\0"
zaok:	.ascii	"Wybierz sposob zaokraglania: \n0 - przez obciecie\n1 - do \"gory\"\n2 - do najblizszej parzystej\n\0"
wybor:	.long	0
wybor_fmt:	.ascii	"%d\0"

wynik_file:	.long	0	#wskaznik na strukture FILE biblioteki C do obslugi plikow
wynik_tryb:	.ascii	"w+\0"
wynik_name:	.ascii	"wynik.txt\0"	#nazwa pliku wynikowego

zrodlo_file:	.long	0
zrodlo_tryb:	.ascii	"r\0"
zrodlo_name:	.ascii	"liczby.txt\0"

jaki_rozmiar:	.long	0		#pierwsza zmienna w pliku oznacza jaki rozmiar zmiennych bedzie w pliku

rozmiar_fmt:	.ascii	"%u\0"
dane_fmt:	.ascii	"%u %016llx\0"
dane_mnt:	.ascii	" %08x\0" 

brak_plk:	.ascii	"Nie znaleziono pliku liczby.txt\0"
brak_pam:	.ascii	"Nie mozna zaalokowac potrzebnej pamieci\0"
blad_zapis:	.ascii	"Nie mozna utoworzyc pliku\0"

# Zaczynamy kod
.text
.globl	main	#bedzie kompilowane pod gcc dla wygody
main:

	#wczytywanie danych z pliku
	pushl	$zrodlo_tryb
	pushl	$zrodlo_name
	call	fopen
	addl	$4*2, %esp
	movl	%eax, zrodlo_file	#wskaznik na FILE teraz w zrodlo_file
	cmpl	$0, %eax
	jz	brak_pliku					#jak nie ma pliku to nie konczymy
	
	#pobierz wielosc liczb
	pushl	$jaki_rozmiar
	pushl	$rozmiar_fmt
	pushl	zrodlo_file
	call	fscanf
	addl	$4*3, %esp
	movl	jaki_rozmiar, %eax
	movl	%eax, liczba1_size
	movl	%eax, liczba2_size
	
	#alokacja rozmiaru mantyss dla obydwu liczb
	movl	$4, %ebx			#long ma rozmiar 4 bajty, czyli do zaalokowania 4 * rozmiar mantysy
	mull	%ebx
	pushl	%eax
	call	malloc
	addl	$4, %esp
	cmpl	$0, %eax
	jz	brak_pamieci					#nie przydzielono pamieci to nie ma co robic
	movl	%eax, liczba1_mts	#przypisanie pierwszego wskaznika
	
	movl	liczba2_size, %eax
	movl	$4, %ebx
	mull	%ebx
	pushl	%eax
	call	malloc
	addl	$4, %esp
	cmpl	$0, %eax
	jz	brak_pamieci					#nie przydzielono pamieci to nie ma co robic
	movl	%eax, liczba2_mts	#przypisanie drugiego wskaznika
	
	#wczytaj pierwsza liczbe
	pushl	$liczba1_exp
	pushl	$liczba1_sign
	pushl	$dane_fmt
	pushl	zrodlo_file
	call	fscanf
	addl	$4*4, %esp
	
	#zamiana exp
	movl	$liczba1_exp, %edi
	movl	(%edi), %eax
	movl	4(%edi), %ebx
	movl	%ebx, (%edi)
	movl	%eax, 4(%edi)
	
	#wczytaj pierwsza mantyse
	movl	liczba1_mts, %edi
	xorl	%ecx, %ecx
wczytaj1_mts:
	pushl	%ecx				#zachowaj licznik
	
	#movl	liczba1_mts( ,%ecx, 4), %esi	#powinno zwrocic adres a nie liczbe
	
	pushl	%edi
	pushl	$dane_mnt
	pushl	zrodlo_file
	call	fscanf
	addl	$4*3, %esp
	
	popl	%ecx
	addl	$4, %edi
	incl	%ecx
	cmpl	liczba1_size, %ecx
	jnz	wczytaj1_mts
	
	#wczytaj druga liczbe
	pushl	$liczba2_exp
	pushl	$liczba2_sign
	pushl	$dane_fmt
	pushl	zrodlo_file
	call	fscanf
	addl	$4*4, %esp
	
	#zamiana exp
	movl	$liczba2_exp, %edi
	movl	(%edi), %eax
	movl	4(%edi), %ebx
	movl	%ebx, (%edi)
	movl	%eax, 4(%edi)
	
	#wczytaj druga mantyse
	movl	liczba2_mts, %edi
	xorl	%ecx, %ecx
wczytaj2_mts:
	pushl	%ecx				#zachowaj licznik
	
	#movl	liczba2_mts( ,%ecx, 4), %esi	#powinno zwrocic adres a nie liczbe
	pushl	%edi
	pushl	$dane_mnt
	pushl	zrodlo_file
	call	fscanf
	addl	$4*3, %esp
	
	popl	%ecx
	addl	$4, %edi
	incl	%ecx
	cmpl	liczba2_size, %ecx
	jnz	wczytaj2_mts
	
	#liczby wczytane, trzeba zwolnic uchwyt FILE
	pushl	zrodlo_file
	call	fclose
	addl	$4, %esp
	
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
	#zamiana przed zapisem
	movl	$wynik_exp, %edi
	movl	(%edi), %eax
	movl	4(%edi), %ebx
	movl	%ebx, (%edi)
	movl	%eax, 4(%edi)
	
zapisz_do_pliku:
	pushl	$wynik_tryb
	pushl	$wynik_name
	call	fopen
	addl	$4*2, %esp
	movl	%eax, wynik_file
	cmpl	$0, %eax
	jz	blad_zapisu
	
	movl	$1, %eax
	
	movl	wynik_exp( ,%eax, 4), %edi
	pushl	%edi
	pushl	wynik_exp
	xorl	%eax, %eax
	movb	wynik_sign, %al
	pushl	%eax
	pushl	$dane_fmt
	pushl	wynik_file
	call	fprintf
	addl	$4*5, %esp
	
	movl	wynik_mts, %esi
	xorl	%ecx, %ecx
petla_wpisujaca:
	movl	(%esi, %ecx, 4), %eax
	
	pushl	%ecx
	
	pushl	%eax
	pushl	$dane_mnt
	pushl	wynik_file
	call	fprintf
	addl	$4*3, %esp
	
	popl	%ecx
	incl	%ecx
	cmpl	wynik_size, %ecx
	jnz	petla_wpisujaca
	
	#zamknij plik
	pushl	wynik_file
	call	fclose
	addl	$4, %esp


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
	call	exit
	
	ret	
	
#oblsuga bledow	
brak_pliku:
	pushl	$brak_plk
	call	puts
	addl	$4, %esp
	jmp	koniec
	
brak_pamieci:
	pushl	$brak_pam
	call	puts
	addl	$4, %esp
	jmp	koniec
	
blad_zapisu:
	pushl	$blad_zapis
	call	puts
	addl	$4, %esp
	jmp	koniec


