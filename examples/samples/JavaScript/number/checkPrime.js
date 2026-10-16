const CheckPrime = (num) => {
  if (typeof num !== "number") {
    return "Not a Number";
  }
  if(num < 2 || num % 2 == 0 && num !== 2){
    return "not a prime";
  }
  let squareRootOfNum = Math.ceil(Math.sqrt(num));
  for(let divisor = 3; divisor <= squareRootOfNum; divisor += 2){
    if(num % divisor == 0){
      return "not a prime";
    }
  }
  return "prime";
};
console.log(CheckPrime(1049));
