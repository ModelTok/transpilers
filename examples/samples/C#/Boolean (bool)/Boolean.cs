using System;

namespace Programming
{
    class Boolean
    {
        static void Main(string[] args)
        {
            bool b = true;

            Console.WriteLine(b);

            int today = DateTime.Now.DayOfYear;

            b = (today % 2 == 0);

            if (b)
            {
                Console.WriteLine("today: {0} (Day Of Year) is even.", today);
            }
            else
            {
                Console.WriteLine("today: {0} (Day Of Year) is odd.", today);
            }
        }
    }
}