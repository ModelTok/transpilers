

#include <stdio.h>
int main()
{
    char *a = (char *)malloc(100), *b = (char *)malloc(100);
    while (scanf("%s%s", a, b) != -1)
    {
        int big, carry = 0, temp, small;
        int aa = strlen(a) >= strlen(b) ? strlen(a) : strlen(b);

        char *sum = (char *)malloc(aa + 1);
        if (strlen(a) >= strlen(b))
        {
            big = strlen(a);
            small = strlen(b);
        }
        else if (strlen(a) < strlen(b))
        {
            big = strlen(b);
            small = strlen(a);
            char *tem = a;
            a = b;
            b = tem;
        }
        for (int i = big - 1, j = small - 1; i >= 0; i--, j--)
        {
            if (j < 0)
            {
                temp = a[i] + carry - 48;
                if (temp >= 0 && temp <= 9)
                {
                    sum[i] = temp + 48;
                    carry = 0;
                }
                else
                {
                    sum[i] = (temp - 10) + 48;
                    carry = 1;
                }
            }

            else
            {
                temp = a[i] + b[j] + carry - 96;

                if (temp >= 0 && temp <= 9)
                {
                    sum[i] = temp + 48;
                    carry = 0;
                }
                else
                {
                    sum[i] = (temp - 10) + 48;
                    carry = 1;
                }
            }
        }
        sum[aa] = '\0';
        if (carry == 1)
        {
            printf("1");
        }
        printf("%s\n", sum);
    }
    return 0;
}
