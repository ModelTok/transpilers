# EXTERNAL DEPS (to wire in glue):
# - DataGlobals.MaxNameLength: from DataGlobals module (Fortran), defines max string buffer size

def setup_and_sort(alphas, i_alphas):
    """Set up and call sort routine for Alphas"""
    for loop in range(len(alphas)):
        i_alphas[loop] = loop + 1
    
    qsort_c(alphas, i_alphas)

def qsort_c(alphas, i_alphas):
    """Recursive quicksort implementation"""
    if len(alphas) > 1:
        iq = qsort_partition(alphas, i_alphas)
        qsort_c(alphas[:iq-1], i_alphas[:iq-1])
        qsort_c(alphas[iq-1:], i_alphas[iq-1:])

def qsort_partition(alphas, i_alphas):
    """Partition arrays for quicksort"""
    cpivot = alphas[0]
    i = 0
    j = len(alphas) + 1
    
    while True:
        j -= 1
        while alphas[j-1] > cpivot:
            j -= 1
        i += 1
        while alphas[i-1] < cpivot:
            i += 1
        
        if i < j:
            alphas[i-1], alphas[j-1] = alphas[j-1], alphas[i-1]
            i_alphas[i-1], i_alphas[j-1] = i_alphas[j-1], i_alphas[i-1]
        elif i == j:
            return i + 1
        else:
            return i
