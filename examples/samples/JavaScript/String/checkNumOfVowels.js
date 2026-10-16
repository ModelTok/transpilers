 const checkNumOfVowels = (string) => {
     if(typeof string === 'string'){
     let regEx = /[aeiou]/gi;
     return string.match(regEx).length;
    }
    return 'not a string';
 }

 console.log(checkNumOfVowels('heEEEllo world'));
 console.log(checkNumOfVowels('hello world'));
 console.log(checkNumOfVowels(null));
 console.log(checkNumOfVowels(100));