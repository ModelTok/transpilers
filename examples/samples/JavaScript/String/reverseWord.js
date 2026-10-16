const ReverseWord = (str) => {
  if (typeof str !== "string") {
    return "Not a String";
  }
  if (str.length === 0) {
    return "Empty String";
  }
  const strArr = str.split("");
  const reverseArr = strArr.reverse();
  return reverseArr.join("");
};
console.log(ReverseWord("koddi"));
