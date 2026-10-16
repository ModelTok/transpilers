public class Activity <T extends Comparable<T>> {

    private final T startTime;
    private final T finishTime;

    public Activity(T startTime, T finishTime) {
        this.startTime = startTime;
        this.finishTime = finishTime;
    }

    public T startTime() {
        return startTime;
    }

    public T finishTime() {
        return finishTime;
    }

}