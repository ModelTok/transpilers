
class Point {
public:
    int x;
    int y;

    int sum() {
        return this->x + this->y;
    }

    int scale(int factor) {
        return this->x * factor + this->y * factor;
    }
};

int compute() {
    Point p;
    p.x = 3;
    p.y = 4;
    return p.sum();
}

int scaled(int factor) {
    Point p;
    p.x = 1;
    p.y = 2;
    return p.scale(factor);
}
