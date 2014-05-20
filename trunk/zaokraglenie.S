# Modul wynokujacy zaokraglenie wyniku

.text
.globl  zaokraglenie
.type   zaokraglenie, @function
zaokraglenie:
    pushl   %ebp
    movl    %esp, %ebp



    movl    $0, %eax
    leave
    ret
