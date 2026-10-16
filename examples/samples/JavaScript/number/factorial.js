const factorial = (num) => {
    if(typeof num !== 'number' || num < 0){
        return `sorry we can't do factorial in ${num}`;
    }
    let product = 1;
    for(let i = num; i >=1; i--){
        product *=i;
    }
    return product
}
console.log(factorial(-10));
console.log(factorial(0));
console.log(factorial(10));
console.log(factorial('hello world'));