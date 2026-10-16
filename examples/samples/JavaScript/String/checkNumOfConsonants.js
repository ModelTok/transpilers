 const checkNumOfConsonants = (string) => {
     if(typeof string === 'string'){
     let regEx = /[^aeiou\s\W\d]/gi;
     return string.match(regEx).length;
    }
    return "not a string";
 }

 console.log(checkNumOfConsonants("heLl!!!!!o world"));
 console.log(checkNumOfConsonants("heLl!!!!!o world12345"));
 console.log(checkNumOfConsonants("heLlo world"));
 console.log(checkNumOfConsonants(null));
 console.log(checkNumOfConsonants(100));