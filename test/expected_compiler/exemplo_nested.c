#include <stdio.h>

int main() {
    float x;
    x = 10.0;
    if ((x > 0.0)) {
        if ((x > 5.0)) {
            while ((x > 5.0)) {
                x = (x - 1.0);
            }
        }
    }
    printf("%f\n", x);
    return 0;
}
