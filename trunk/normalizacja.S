# Modul wykonujacy normalizacje wyniku

.text
.globl  normalizacja
.type   normalizacja, @function
normalizacja:
    pushl   %ebp
    movl    %esp, %ebp


    movl    $0, %eax
    leave
    ret
