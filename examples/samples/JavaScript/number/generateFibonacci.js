const generateFibonacci = (num) => {
  if (typeof num !== "number") {
    return "Not a Number";
  }
  if (num) {
    let fibArray = [1];
    let a = 1,
      b,
      sum;
    for (let i = 1; i < num; i++) {
      if (i === 1) {
        fibArray.push(i);
        b = i;
      }
      else {
        sum = a + b;
        b = a;
        a = sum;
        fibArray.push(sum);
      }
    }
    return fibArray;
  }
  return undefined;
};
console.log(generateFibonacci(20));
