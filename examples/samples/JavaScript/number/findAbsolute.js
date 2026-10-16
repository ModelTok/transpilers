

const findAbsolute = (num) => Math.abs(num);

const findAbsoluteAlgorithm = (num) => {
    if(num<0){
        return -num;
    }
    return num;
}
console.log(findAbsoluteAlgorithm(-10));
console.log(findAbsoluteAlgorithm(10));
console.log(findAbsolute(-10));
console.log(findAbsolute(10));