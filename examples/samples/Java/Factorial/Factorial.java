
import java.math.BigInteger;


public class Factorial {

    public BigInteger factorial(Integer number) {
        BigInteger factorial = BigInteger.ONE;
        while (number > 0) {
            factorial = factorial.multiply(BigInteger.valueOf(number));
            number = number - 1;
        }
        return factorial;
    }

}