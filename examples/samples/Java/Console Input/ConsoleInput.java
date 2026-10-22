import java.util.Scanner;

public class ConsoleInput {

    public static void main(String[] args) {

        Scanner consoleInput = new Scanner(System.in);

        System.out.println("Console Input");
        System.out.println();

        System.out.print("Enter an integer: ");
        int IntegerFromConsole = consoleInput.nextInt();
        System.out.println("Integer entered = " + IntegerFromConsole);
        System.out.println();

        System.out.print("Enter a floating point number: ");
        float FloatFromConsole = consoleInput.nextFloat();
        System.out.println("Floating point number entered = " + FloatFromConsole);
        System.out.println();

        System.out.print("Enter a double precision number: ");
        double DoubleFromConsole = consoleInput.nextDouble();
        System.out.println("Double precision number entered = " + DoubleFromConsole);
        System.out.println();

        System.out.print("Enter a word: ");
        String WordFromConsole = consoleInput.next();
        System.out.println("Word entered = " + WordFromConsole);
        System.out.println();

        consoleInput.nextLine();

        System.out.print("Enter a string: ");
        String StringFromConsole = consoleInput.nextLine();
        System.out.println("String entered = " + StringFromConsole);
        System.out.println();

    }

}