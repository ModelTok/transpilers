const checkPerfectSquare = (num) =>{
    if(typeof num !== 'number'){
        return 'not a number'
    }
    return Math.pow(Math.sqrt(num), 2) === num;
} 
console.log(checkPerfectSquare(0));
console.log(checkPerfectSquare(100));
console.log(checkPerfectSquare(6));