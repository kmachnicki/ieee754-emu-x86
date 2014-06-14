####################################
# Modul wpisujacy w liczbe wyjatek #
####################################
# Dostepne wyjatki:
# NaN
# +Inf
# -Inf
# +0
# -0

.text
.globl  inf_plus
.type   inf_plus, @function
inf_plus:
    pushl   %ebp
    movl    %esp, %ebp

	movb	$0, wynik_sign
	movl	$wynik_exp, %edi
	movl	$0xFFFFFFFF, 4(%edi)
	movl	$0xFFFFFFFF, (%edi)
	
	call	zeruj_mantyse

    leave
    ret

.globl  inf_minus
.type   inf_minus, @function
inf_minus:
    pushl   %ebp
    movl    %esp, %ebp

	movb	$1, wynik_sign
	movl	$wynik_exp, %edi
	movl	$0xFFFFFFFF, 4(%edi)
	movl	$0xFFFFFFFF, (%edi)
	
	call	zeruj_mantyse

    leave
    ret

.globl  NaN
.type   NaN, @function
NaN:
    pushl   %ebp
    movl    %esp, %ebp

	movl	$wynik_exp, %edi
	movl	$0xFFFFFFFF, 4(%edi)
	movl	$0xFFFFFFFF, (%edi)
	
	call	zeruj_mantyse

	# Kod bledu 1
	movl	wynik_mts, %edi
	movl	wynik_size, %edx
	decl	%edx
	
	movl	$1, (%edi, %edx, 4)

    leave
    ret
    
.globl  ZeroNumb
.type   ZeroNumb, @function
ZeroNumb:
    pushl	%ebp
	movl	%esp, %ebp
    movl	$wynik_exp, %edi
	movl	$0, 4(%edi)
	movl	$0, (%edi)
	
    call    zeruj_mantyse
	
    leave
    ret

.globl	zeruj_mantyse
.type	zeruj_mantyse, @function
zeruj_mantyse:
	pushl	%ebp
	movl	%esp, %ebp
	movl	wynik_mts, %edi
	movl	wynik_size, %ecx
	xorl	%edx, %edx
	
zeruj:
	movl	$0, (%edi, %edx, 4)
	incl	%edx
	loop	zeruj
	
	leave
	ret
