using System;

namespace Programming
{
    class Clazz
    {
        static void Main(string[] args)
        {
            ChildClazz childOne = new ChildClazz("Craig", 11);
            ChildClazz childTwo = new ChildClazz("Sally", 10);

            ChildClazz childThree = new ChildClazz();

            Console.Write("ChildOne: ");
            childOne.PrintChild();
            Console.Write("ChildTwo: ");
            childTwo.PrintChild();
            Console.Write("ChildThree: ");
            childThree.PrintChild();
        }
    }

    class ChildClazz
    {
        private int age;
        private string name;

        public ChildClazz()
        {
            name = "N/A";
        }

        public ChildClazz(string name, int age)
        {
            this.name = name;
            this.age = age;
        }

        public void PrintChild()
        {
            Console.WriteLine("{0}, {1} years old.", name, age);
        }
    }

}