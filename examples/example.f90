function add(a, b) result(r)
    integer :: a, b, r
    r = a + b
end function

function factorial(n) result(r)
    integer :: n, r, i
    r = 1
    i = 1
    do while (i <= n)
        r = r * i
        i = i + 1
    end do
end function

function sum_to(n) result(total)
    integer :: n, total, i
    total = 0
    do i = 0, n - 1
        total = total + i
    end do
end function

function max2(a, b) result(r)
    integer :: a, b, r
    if (a > b) then
        r = a
    else
        r = b
    end if
end function
