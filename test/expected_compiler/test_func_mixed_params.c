#include <stdio.h>

float escolher(int cond, float a, float b);

float escolher(int cond, float a, float b) {
    if (cond) {
        return a;
    }
    return b;
}

int main() {
    float r;
    r = escolher(1, 10.0, 20.0);
    printf("%f\n", r);
    r = escolher(0, 10.0, 20.0);
    printf("%f\n", r);
    return 0;
}
