
public class RecursiveFibonacciNumber {

    public int fibonacciNumber(int number) {
        int fibonacciNumber = recurse(Math.abs(number));
        return number < 0 ? (int) Math.pow(-1, number + 1) * fibonacciNumber : fibonacciNumber;
    }

    private int recurse(int number) {
        return number > 1 ? recurse(number - 1) + recurse(number - 2) : number;
    }

}