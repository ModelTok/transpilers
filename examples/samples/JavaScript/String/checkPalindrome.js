const CheckPalindrome = (str) => {
  if (typeof str !== "string") {
    return "Not a String";
  }
  if (str.length === 0) {
    return "Empty String";
  }
  let strCopy = str;
  let strCopyArr = strCopy.split("");
  let strCopyArrRev = strCopyArr.reverse();
  let reverseStr = strCopyArrRev.join("");
  return reverseStr === str ? true : false;
};
console.log(CheckPalindrome("hello world"));
console.log(CheckPalindrome("lol"));
