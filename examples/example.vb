Function Add(a As Integer, b As Integer) As Integer
    Return a + b
End Function

Function Factorial(n As Integer) As Integer
    Dim result As Integer = 1
    Dim i As Integer = 1
    While i <= n
        result = result * i
        i = i + 1
    End While
    Return result
End Function

Function Max2(a As Integer, b As Integer) As Integer
    If a > b Then
        Return a
    Else
        Return b
    End If
End Function

Function SumTo(n As Integer) As Integer
    Dim total As Integer = 0
    Dim i As Integer
    For i = 0 To n - 1
        total = total + i
    Next
    Return total
End Function
