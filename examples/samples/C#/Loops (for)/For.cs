using System;

namespace Programming
{
    class For
    {
        static void Main(string[] args)
        {
            for (int i = 1; i <= 5; i++)
            {
                Console.WriteLine("Hello, world!");
            }
            Console.WriteLine();

            for (int i = 2; i <= 8; i++)
            {
                Console.WriteLine(i);
            }
            Console.WriteLine();

            int iOuter = 48;
            int isPositive = -400;
            for (; isPositive < 0; )
            {
                Console.WriteLine("Inside the loop : isPositive = {0}", isPositive);
                isPositive += iOuter;
                iOuter += 48;
            }
            Console.WriteLine();

            for (int iA = 4, iB = 16; iA < iB; iA++, iB--)
            {
                Console.WriteLine("iA = {0}, iB = {1}", iA, iB);
            }
            Console.WriteLine();
        }
    }
}