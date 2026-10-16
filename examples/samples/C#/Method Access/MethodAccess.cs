using System;

namespace Programming
{
    abstract class Motorcycle
    {
        public void StartEngine()
        {
        }

        protected void AddGas(int gallons)
        {
        }

        public virtual int Drive(int miles, int speed)
        {
            return 1;
        }

        public abstract double GetTopSpeed();
    }

    class TestMotorcycle : Motorcycle
    {

        public override double GetTopSpeed()
        {
            return 246.81;
        }
    }

    class MethodAccess
    {
        static void Main(string[] args)
        {
            TestMotorcycle myMotorcycle = new TestMotorcycle();

            myMotorcycle.StartEngine();


            myMotorcycle.Drive(5, 20);
            double speed = myMotorcycle.GetTopSpeed();

            Console.WriteLine("My top speed is {0}", speed);
        }
    }
}