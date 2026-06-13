def Factorial(n: Int) -> Int:
  var result: Int = 1
  for i in range(1, n + 1):
    result *= i
  return result

def IsPrime(n: Int) -> Bool:
  if n <= 1: return False
  if n % 2 == 0: return n == 2
  var i: Int = 3
  while True:
    if i > n // i: break
    if n % i == 0: return False
    i += 2
  return True