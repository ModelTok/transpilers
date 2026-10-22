#include <stdio.h>
#include <stdlib.h>

unsigned rounds;
double pi = 1.0;

int main()
{
    FILE *infile = fopen("rounds.txt", "r");
    if (infile == NULL) {
        perror("open file");
        return EXIT_FAILURE;
    }
    if (fscanf(infile, "%u", &rounds) != 1) {
        perror("read file");
        return EXIT_FAILURE;
    }
    fclose(infile);

    rounds += 2u;

    for (unsigned i=2u; i < rounds; ++i)
    {
        double x = -1.0 + 2.0 * (i & 0x1);
        pi += (x / (2u * i - 1u));
    }

    pi *= 4;
    printf("%.16f\n", pi);
    return EXIT_SUCCESS;
}
