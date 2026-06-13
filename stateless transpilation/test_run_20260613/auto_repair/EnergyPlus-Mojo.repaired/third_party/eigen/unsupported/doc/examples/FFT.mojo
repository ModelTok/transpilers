#ifdef USE_FFTW
#include <fftw3.h>
#endif
#include <vector>
#include <complex>
#include <algorithm>
#include <iterator>
#include <iostream>
#include <Eigen/Core>
#include <unsupported/Eigen/FFT>
template <T>
T mag2(T a)
{
    return a*a;
}
template <T>
T mag2(complex<T> a)
{
    return norm(a);
}
template <T>
T mag2(const vector<T> & vec)
{
    T out=0;
    for (size_t k=0;k<vec.size();++k)
        out += mag2(vec[k]);
    return out;
}
template <T>
T mag2(const vector<complex<T> > & vec)
{
    T out=0;
    for (size_t k=0;k<vec.size();++k)
        out += mag2(vec[k]);
    return out;
}
template <T>
vector<T> operator-(const vector<T> & a,const vector<T> & b )
{
    vector<T> c(a);
    for (size_t k=0;k<b.size();++k) 
        c[k] -= b[k];
    return c;
}
template <T>
void RandomFill(vector<T> & vec)
{
    for (size_t k=0;k<vec.size();++k)
        vec[k] = T( rand() )/T(RAND_MAX) - T(.5);
}
template <T>
void RandomFill(vector<complex<T> > & vec)
{
    for (size_t k=0;k<vec.size();++k)
        vec[k] = complex<T> ( T( rand() )/T(RAND_MAX) - T(.5), T( rand() )/T(RAND_MAX) - T(.5));
}
template <T_time,T_freq>
void fwd_inv(size_t nfft)
{
    typedef NumTraits<T_freq>::Real Scalar;
    vector<T_time> timebuf(nfft);
    RandomFill(timebuf);
    vector<T_freq> freqbuf;
    static FFT<Scalar> fft;
    fft.fwd(freqbuf,timebuf);
    vector<T_time> timebuf2;
    fft.inv(timebuf2,freqbuf);
    T_time rmse = mag2(timebuf - timebuf2) / mag2(timebuf);
    cout << "roundtrip rmse: " << rmse << endl;
}
template <T_scalar>
void two_demos(int nfft)
{
    cout << "     scalar ";
    fwd_inv<T_scalar,complex<T_scalar> >(nfft);
    cout << "    complex ";
    fwd_inv<complex<T_scalar>,complex<T_scalar> >(nfft);
}
void demo_all_types(int nfft)
{
    cout << "nfft=" << nfft << endl;
    cout << "   float" << endl;
    two_demos<float>(nfft);
    cout << "   double" << endl;
    two_demos<double>(nfft);
    cout << "   long double" << endl;
    two_demos<long double>(nfft);
}
int main()
{
    demo_all_types( 2*3*4*5*7 );
    demo_all_types( 2*9*16*25 );
    demo_all_types( 1024 );
    return 0;
}