#include <stdio.h>

int main() {
    int r;
    r = (1 || (0 && 0));
    printf("%f\n", r);
    r = (0 || (1 && 1));
    printf("%f\n", r);
    return 0;
}
