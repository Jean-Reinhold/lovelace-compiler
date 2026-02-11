#include <stdio.h>

float soma(float a, float b);
float fatorial(float n);
int ehPositivo(float x);

float soma(float a, float b) {
    return (a + b);
}

float fatorial(float n) {
    float resultado;
    resultado = 1.0;
    while ((n > 1.0)) {
        resultado = (resultado * n);
        n = (n - 1.0);
    }
    return resultado;
}

int ehPositivo(float x) {
    if ((x > 0.0)) {
        return 1;
    }
    return 0;
}

int main() {
    float a;
    float b;
    float total;
    float fat;
    int positivo;
    a = 5.0;
    b = 3.0;
    total = soma(a, b);
    printf("%f\n", total);
    fat = fatorial(5.0);
    printf("%f\n", fat);
    positivo = ehPositivo(total);
    printf("%f\n", positivo);
    if ((positivo && (total > 0.0))) {
        printf("%f\n", 1.0);
    }
    scanf("%f", &a);
    if (ehPositivo(a)) {
        printf("%f\n", soma(a, b));
    }
    return 0;
}
