using System;

namespace Programming
{
    class Character
    {
        static void Main(string[] args)
        {
            char[] chars = new char[4];

            chars[0] = 'X';
            chars[1] = '\x0058';
            chars[2] = (char)88;
            chars[3] = '\u0058';

            foreach (char c in chars)
            {
                Console.Write(c + "\n");
            }
        }
    }
}