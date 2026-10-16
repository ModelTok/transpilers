const CheckEvenOdd = (num) => {
  if (typeof num !== "number") {
    return "Not a Number";
  }
  if (num !== Math.floor(num)) {
    return "Not a Whole Number";
  }
  return num % 2 === 0 ? "Even" : "Odd";
};
console.log(CheckEvenOdd(2.2));
console.log(CheckEvenOdd("even"));
console.log(CheckEvenOdd(100));
console.log(CheckEvenOdd(9));
console.log(CheckEvenOdd(0));
