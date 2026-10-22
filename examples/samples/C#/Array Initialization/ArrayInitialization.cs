namespace Programming
{
    class ArrayInitialization
    {
        static void Main(string[] args)
        {

            int[] numbersOne = new int[5] { 1, 2, 3, 4, 5 };
            string[] namesOne = new string[3] { "Matt", "Joanne", "Robert" };


            int[] numbersTwo = new int[] { 1, 2, 3, 4, 5 };
            string[] namesTwo = new string[] { "Matt", "Joanne", "Robert" };

            int[] numbersThree = { 1, 2, 3, 4, 5 };
            string[] namesThree = { "Matt", "Joanne", "Robert" };


            int[,] valuesOne = new int[3, 2] { { 1, 2 }, { 3, 4 }, { 5, 6 } };
            string[,] siblingsOne = new string[2, 2] { { "Mike", "Amy" }, { "Mary", "Albert" } };

            int[,] valuesTwo = new int[,] { { 1, 2 }, { 3, 4 }, { 5, 6 } };
            string[,] siblingsTwo = new string[,] { { "Mike", "Amy" }, { "Mary", "Albert" } };

            int[,] valuesThree = { { 1, 2 }, { 3, 4 }, { 5, 6 } };
            string[,] siblingsThree = { { "Mike", "Amy" }, { "Mary", "Albert" } };


            int[][] jaggedOne = new int[2][] { new int[] { 2, 3, 4 }, new int[] { 5, 6, 7, 8, 9 } };

            int[][] jaggedTwo = new int[][] { new int[] { 2, 3, 4 }, new int[] { 5, 6, 7, 8, 9 } };

            int[][] jaggedThree = { new int[] { 2, 3, 4 }, new int[] { 5, 6, 7, 8, 9 } };
        }
    }
}