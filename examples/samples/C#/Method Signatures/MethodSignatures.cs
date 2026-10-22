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

    class MethodSignatures
    {
        static void Main(string[] args)
        {
        }
    }
}