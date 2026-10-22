namespace Programming
{
    class MethodParametersAndArguements
    {
        static void Main(string[] args)
        {
            int numA = 4;
            int productA = Square(numA);

            int numB = 32;
            int productB = Square(numB);

            int productC = Square(12);

            productC = Square(productA * 3);
        }

        static int Square(int i)
        {
            int input = i;
            return input * input;
        }
    }
}