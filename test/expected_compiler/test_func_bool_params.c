#include <stdio.h>

int negar(int v);

int negar(int v) {
    if (v) {
        return 0;
    }
    return 1;
}

int main() {
    int r;
    r = negar(1);
    printf("%f\n", r);
    r = negar(0);
    printf("%f\n", r);
    return 0;
}
