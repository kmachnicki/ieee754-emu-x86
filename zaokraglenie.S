# Modul wynokujacy zaokraglenie wyniku
#mozliwe argumenty
#0 - przez obciecie
#1 - do gory
#2 - do najblizszej parzystej

LSB_1 = 0b00000001

.text
.globl  zaokraglenie				#parametr w EAX
.type   zaokraglenie, @function
zaokraglenie:
    pushl   %ebp
    movl    %esp, %ebp
	cmpb	$0, bit_specjalny
	jz	koniec						#jak nie ma nic do zaokraglania to nic nie robimy
	cmpl	$1, %eax
	jz	do_gory
	cmpl	$2, %eax
	jnz	koniec						#jezeli warotsci rowna 0 to nic nie robimy
do_parzystej:
	movl	wynik_mts, %edi
	movl	wynik_size, %edx
	decl	%edx
	movl	(%edi, %edx, 4), %ebx	#zawartosc ostatniego fragmetu mantysy
	testb	$LSB_1, %bl				#interesuje nas sama koncowka
	jz	koniec						#jak na koncu 0 to nic nie robimy
	addl	$1, (%edi, %edx, 4)		#dodaj 1 na koncu
dodaj_przeniesienie:
	decl	%edx
	adcl	$0, (%edi, %edx, 4)
	cmpl	$0, %edx
	jge	dodaj_przeniesienie
	jnc	koniec						#jak nie ma przeniesienia to koniec, a jak jest to trza przesunac wynik
	
    call    normalizacja

	jmp	koniec

do_gory:
	movl	wynik_mts, %edi
	movl	wynik_size, %edx
	decl	%edx
	addl	$1, (%edi, %edx, 4)		#dodaj 1 na koncu
	jmp dodaj_przeniesienie

koniec:
    leave
    ret
