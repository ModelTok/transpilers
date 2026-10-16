
int climb_stairs(int stairs) {
    if (stairs == 1) {
        return 1;
    }

    int previous = 1;
    int current = 2;
    for (int stair = 3; stair <= stairs; stair++) {
        int next = previous + current;
        previous = current;
        current = next;
    }

    return current;
}