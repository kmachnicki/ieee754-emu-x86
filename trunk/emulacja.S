# Tu bedzie modul glowny

# Deklaracja stalych
EXIT = 1
SYSCALL = 0x80

# Zaczynamy kod
.text
.globl	main	#bedzie kompilowane pod gcc dla wygody
main:
	movl	$0, %ebx
	movl	$EXIT, %eax
	int	$SYSCALL

# Cos juz jest

