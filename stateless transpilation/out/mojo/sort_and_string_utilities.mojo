# EXTERNAL DEPS (to wire in glue):
# - DataGlobals.MaxNameLength: from DataGlobals module (Fortran), defines max string buffer size

fn setup_and_sort(inout alphas: List[String], inout i_alphas: List[Int]):
    """Set up and call sort routine for Alphas"""
    for loop in range(len(alphas)):
        i_alphas[loop] = loop + 1
    
    qsort_c(alphas, i_alphas)

fn qsort_c(inout alphas: List[String], inout i_alphas: List[Int]):
    """Recursive quicksort implementation"""
    if len(alphas) > 1:
        let iq = qsort_partition(alphas, i_alphas)
        let left_alphas = alphas[0:iq-1]
        let left_i_alphas = i_alphas[0:iq-1]
        let right_alphas = alphas[iq-1:]
        let right_i_alphas = i_alphas[iq-1:]
        
        qsort_c(left_alphas, left_i_alphas)
        qsort_c(right_alphas, right_i_alphas)

fn qsort_partition(inout alphas: List[String], inout i_alphas: List[Int]) -> Int:
    """Partition arrays for quicksort"""
    let cpivot = alphas[0]
    var i: Int = 0
    var j: Int = len(alphas) + 1
    
    while True:
        j -= 1
        while alphas[j - 1] > cpivot:
            j -= 1
        i += 1
        while alphas[i - 1] < cpivot:
            i += 1
        
        if i < j:
            let temp_a = alphas[i - 1]
            alphas[i - 1] = alphas[j - 1]
            alphas[j - 1] = temp_a
            
            let temp_i = i_alphas[i - 1]
            i_alphas[i - 1] = i_alphas[j - 1]
            i_alphas[j - 1] = temp_i
        elif i == j:
            return i + 1
        else:
            return i
