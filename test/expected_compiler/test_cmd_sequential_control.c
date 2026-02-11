#include <stdio.h>

int main() {
    float x;
    float y;
    x = 5.0;
    y = 10.0;
    if ((x > 0.0)) {
        printf("%f\n", x);
    }
    if ((y > 0.0)) {
        printf("%f\n", y);
    }
    while ((x > 0.0)) {
        x = (x - 1.0);
    }
    while ((y > 5.0)) {
        y = (y - 1.0);
    }
    printf("%f\n", x);
    printf("%f\n", y);
    return 0;
}
