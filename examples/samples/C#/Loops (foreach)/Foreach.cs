using System;

namespace Programming
{
    class Foreach
    {
        static void Main(string[] args)
        {
            int[] fibarray = new int[] { 0, 1, 1, 2, 3, 5, 8, 13 };
            foreach (int element in fibarray)
            {
                Console.WriteLine(element);
            }
            Console.WriteLine();


            for (int i = 0; i < fibarray.Length; i++)
            {
                Console.WriteLine(fibarray[i]);
            }
            Console.WriteLine();


            int count = 0;
            foreach (int element in fibarray)
            {
                count += 1;
                Console.WriteLine("Element #{0}: {1}", count, element);
            }
            Console.WriteLine("Number of elements in the array: {0}", count);
        }
    }
}