import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class GreedyIterativeActivitySelector<T extends Comparable<T>> {

    private final List<Activity<T>> activities;

    public GreedyIterativeActivitySelector(List<Activity<T>> activities) {
        this.activities = activities;
    }

    public Set<Activity<T>> select() {

        if(activities.isEmpty()) {
            return new HashSet<>();
        }

        activities.sort(Comparator.comparing(Activity::finishTime));

        Set<Activity<T>> selectedActivities = new HashSet<>();
        selectedActivities.add(activities.get(0));
        int lastSelectedActivityIndex = 0;

        for (int index = 0; index < activities.size(); index++) {
            Activity<T> currentActivity = activities.get(index);
            if(activities.get(lastSelectedActivityIndex).finishTime().compareTo(currentActivity.startTime()) <= 0) {
                selectedActivities.add(currentActivity);
                lastSelectedActivityIndex = index;
            }
        }

        return selectedActivities;

    }

}