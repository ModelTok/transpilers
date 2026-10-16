const factorial = (num) => {
    if(typeof num !== 'number' || num < 0){
        return `sorry we can't do factorial in ${num}`;
    }
    let product = 1;
    if(num){
        product = num*factorial(num-1)
    }
    return product
}
console.log(factorial(-10));
console.log(factorial(1));
console.log(factorial(10));
console.log(factorial('hello world'));