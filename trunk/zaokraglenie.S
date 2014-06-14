########################################
# Modul wynokujacy zaokraglenie wyniku #
########################################
# Mozliwe argumenty:
# 0 - Przez obciecie
# 1 - Do gory
# 2 - Do najblizszej parzystej

LSB_1 = 0b00000001

.text
.globl  zaokraglenie				# Parametr znajduje sie w eax
.type   zaokraglenie, @function
zaokraglenie:
    pushl   %ebp
    movl    %esp, %ebp
	cmpb	$0, bit_specjalny
	jz	koniec						# Jak nie ma nic do zaokraglania to nie jest wykonana zadna operacja
	cmpl	$1, %eax
	jz	do_gory
	cmpl	$2, %eax
	jnz	koniec						# Jezeli warotsc rowna sie 0 to nie jest wykonywana zadna operacja
	
do_parzystej:
	movl	wynik_mts, %edi
	movl	wynik_size, %edx
	decl	%edx
	movl	(%edi, %edx, 4), %ebx	# Zawartosc ostatniego fragmetu mantysy
	testb	$LSB_1, %bl				# Interesuje nas sama koncowka
	jz	koniec						# Jak na koncu 0 to nic nie robimy
	addl	$1, (%edi, %edx, 4)		# Dodaj 1 na koncu
	
dodaj_przeniesienie:
	decl	%edx
	adcl	$0, (%edi, %edx, 4)
	cmpl	$0, %edx
	jge	dodaj_przeniesienie
	jnc	koniec						# Jak nie ma przeniesienia to zakonczenie, a jak jest przeniesienie to nastepuje przesuniecie wyniku
	
    call    normalizacja

	jmp	koniec

do_gory:
	movl	wynik_mts, %edi
	movl	wynik_size, %edx
	decl	%edx
	addl	$1, (%edi, %edx, 4)		# Dodanie 1 na koncu
	jmp dodaj_przeniesienie

koniec:
    leave
    ret
