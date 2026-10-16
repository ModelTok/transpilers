const checkPerfectSquare = (num) =>{
    if(typeof num !== 'number'){
        return 'not a number'
    }
    return Math.cbrt(num) === Math.round(Math.cbrt(num));
} 
console.log(checkPerfectSquare(2197));
console.log(checkPerfectSquare(2));
console.log(checkPerfectSquare(8));
console.log(checkPerfectSquare(-8));