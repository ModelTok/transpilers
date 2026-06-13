from testing import *
from ObjexxFCL.time import ITIME, GETTIM, TIME, CLOCK, CPU_TIME, IDATE, IDATE4, JDATE, GETDAT, DATE, DATE4, date_and_time, SLEEP
from ObjexxFCL.char.functions import is_digit, is_alpha
from ObjexxFCL import Array1D, Array1D_int
from time import now, Duration, duration_cast, milliseconds

@test
struct TimeTest:
    def Itime(self):
        var timearray = Array1D[Int32](3)
        ITIME(timearray)
        assert_eq(timearray.size(), 3)
        assert_true(0 <= timearray[0])
        assert_true(timearray[0] < 24)
        assert_true(0 <= timearray[1])
        assert_true(timearray[1] < 60)
        assert_true(0 <= timearray[2])
        assert_true(timearray[2] < 60)

    def Gettim(self):
        # First block
        var h: Int64
        var m: Int64
        var s: Int64
        var c: Int64
        GETTIM(h, m, s, c)
        assert_true(0 <= h)
        assert_true(h < 24)
        assert_true(0 <= m)
        assert_true(m < 60)
        assert_true(0 <= s)
        assert_true(s < 60)
        assert_true(0 <= c)
        assert_true(c < 100)

        # Second block
        var h2: Int32
        var m2: Int32
        var s2: Int32
        var c2: Int32
        GETTIM(h2, m2, s2, c2)
        assert_true(0 <= h2)
        assert_true(h2 < 24)
        assert_true(0 <= m2)
        assert_true(m2 < 60)
        assert_true(0 <= s2)
        assert_true(s2 < 60)
        assert_true(0 <= c2)
        assert_true(c2 < 100)

        # Third block
        var h3: Int16
        var m3: Int16
        var s3: Int16
        var c3: Int16
        GETTIM(h3, m3, s3, c3)
        assert_true(0 <= h3)
        assert_true(h3 < 24)
        assert_true(0 <= m3)
        assert_true(m3 < 60)
        assert_true(0 <= s3)
        assert_true(s3 < 60)
        assert_true(0 <= c3)
        assert_true(c3 < 100)

    def Time(self):
        var t: Int64 = TIME()
        assert_true(1498458577 < t)
        var ts: String
        TIME(ts)
        assert_eq(ts.length(), 8)
        assert_true(is_digit(ts[0]))
        assert_true(is_digit(ts[1]))
        assert_eq(ts[2], ':')
        assert_true(is_digit(ts[3]))
        assert_true(is_digit(ts[4]))
        assert_eq(ts[5], ':')
        assert_true(is_digit(ts[6]))
        assert_true(is_digit(ts[7]))

    def Clock(self):
        var ts: String = CLOCK()
        assert_eq(ts.length(), 8)
        assert_true(is_digit(ts[0]))
        assert_true(is_digit(ts[1]))
        assert_eq(ts[2], ':')
        assert_true(is_digit(ts[3]))
        assert_true(is_digit(ts[4]))
        assert_eq(ts[5], ':')
        assert_true(is_digit(ts[6]))
        assert_true(is_digit(ts[7]))

    def CpuTime(self):
        var time: Float64
        CPU_TIME(time)
        assert_true(0.0 <= time)

    def Idate(self):
        var datearray = Array1D[Int32](3)
        IDATE(datearray)
        assert_eq(datearray.size(), 3)
        assert_true(1 <= datearray[0])
        assert_true(datearray[0] <= 31)
        assert_true(1 <= datearray[1])
        assert_true(datearray[1] <= 12)
        assert_true(2000 <= datearray[2])
        assert_true(datearray[2] <= 9999)

        # First block
        var m: Int64
        var d: Int64
        var y: Int64
        IDATE(m, d, y)
        assert_true(1 <= m)
        assert_true(m <= 12)
        assert_true(1 <= d)
        assert_true(d <= 31)
        assert_true(0 <= y)
        assert_true(y <= 99)

        # Second block
        var m2: Int32
        var d2: Int32
        var y2: Int32
        IDATE(m2, d2, y2)
        assert_true(1 <= m2)
        assert_true(m2 <= 12)
        assert_true(1 <= d2)
        assert_true(d2 <= 31)
        assert_true(0 <= y2)
        assert_true(y2 <= 99)

        # Third block
        var m3: Int16
        var d3: Int16
        var y3: Int16
        IDATE(m3, d3, y3)
        assert_true(1 <= m3)
        assert_true(m3 <= 12)
        assert_true(1 <= d3)
        assert_true(d3 <= 31)
        assert_true(0 <= y3)
        assert_true(y3 <= 99)

    def Idate4(self):
        var datearray = Array1D[Int32](3)
        IDATE4(datearray)
        assert_eq(datearray.size(), 3)
        assert_true(1 <= datearray[0])
        assert_true(datearray[0] <= 31)
        assert_true(1 <= datearray[1])
        assert_true(datearray[1] <= 12)
        assert_true(2000 <= datearray[2])
        assert_true(datearray[2] <= 9999)

        # First block
        var m: Int64
        var d: Int64
        var y: Int64
        IDATE4(m, d, y)
        assert_true(1 <= m)
        assert_true(m <= 12)
        assert_true(1 <= d)
        assert_true(d <= 31)
        assert_true(100 <= y)
        assert_true(y <= 9999)

        # Second block
        var m2: Int32
        var d2: Int32
        var y2: Int32
        IDATE4(m2, d2, y2)
        assert_true(1 <= m2)
        assert_true(m2 <= 12)
        assert_true(1 <= d2)
        assert_true(d2 <= 31)
        assert_true(100 <= y2)
        assert_true(y2 <= 9999)

        # Third block
        var m3: Int16
        var d3: Int16
        var y3: Int16
        IDATE4(m3, d3, y3)
        assert_true(1 <= m3)
        assert_true(m3 <= 12)
        assert_true(1 <= d3)
        assert_true(d3 <= 31)
        assert_true(100 <= y3)
        assert_true(y3 <= 9999)

    def Jdate(self):
        var j: String = JDATE()
        assert_eq(j.length(), 5)
        for i in range(5):
            assert_true(is_digit(j[i]))

    def Getdat(self):
        # First block
        var y: Int64
        var m: Int64
        var d: Int64
        GETDAT(y, m, d)
        assert_true(2000 <= y)
        assert_true(y <= 9999)
        assert_true(1 <= m)
        assert_true(m <= 12)
        assert_true(1 <= d)
        assert_true(d <= 31)

        # Second block
        var y2: Int32
        var m2: Int32
        var d2: Int32
        GETDAT(y2, m2, d2)
        assert_true(2000 <= y2)
        assert_true(y2 <= 9999)
        assert_true(1 <= m2)
        assert_true(m2 <= 12)
        assert_true(1 <= d2)
        assert_true(d2 <= 31)

        # Third block
        var y3: Int16
        var m3: Int16
        var d3: Int16
        GETDAT(y3, m3, d3)
        assert_true(2000 <= y3)
        assert_true(y3 <= 9999)
        assert_true(1 <= m3)
        assert_true(m3 <= 12)
        assert_true(1 <= d3)
        assert_true(d3 <= 31)

    def Date(self):
        # First block
        var d: String = DATE()
        assert_eq(d.length(), 8)
        assert_true(is_digit(d[0]))
        assert_true(is_digit(d[1]))
        assert_eq(d[2], '/')
        assert_true(is_digit(d[3]))
        assert_true(is_digit(d[4]))
        assert_eq(d[5], '/')
        assert_true(is_digit(d[6]))
        assert_true(is_digit(d[7]))

        # Second block
        var d2: String
        DATE(d2)
        assert_eq(d2.length(), 9)
        assert_true(is_digit(d2[0]))
        assert_true(is_digit(d2[1]))
        assert_eq(d2[2], '-')
        assert_true(is_alpha(d2[3]))
        assert_true(is_alpha(d2[4]))
        assert_true(is_alpha(d2[5]))
        assert_eq(d2[6], '-')
        assert_true(is_digit(d2[7]))
        assert_true(is_digit(d2[8]))

    def Date4(self):
        var d: String
        DATE4(d)
        assert_eq(d.length(), 11)
        assert_true(is_digit(d[0]))
        assert_true(is_digit(d[1]))
        assert_eq(d[2], '-')
        assert_true(is_alpha(d[3]))
        assert_true(is_alpha(d[4]))
        assert_true(is_alpha(d[5]))
        assert_eq(d[6], '-')
        assert_true(is_digit(d[7]))
        assert_true(is_digit(d[8]))
        assert_true(is_digit(d[9]))
        assert_true(is_digit(d[10]))

    def DateAndTime(self):
        var d: String
        var t: String
        var z: String
        var v = Array1D_int(8)
        date_and_time(d, t, z, v)
        assert_eq(d.length(), 8)
        for i in range(8):
            assert_true(is_digit(d[i]))
        assert_eq(t.length(), 10)
        assert_true(is_digit(t[0]))
        assert_true(is_digit(t[1]))
        assert_true(is_digit(t[2]))
        assert_true(is_digit(t[3]))
        assert_true(is_digit(t[4]))
        assert_true(is_digit(t[5]))
        assert_eq(t[6], '.')
        assert_true(is_digit(t[7]))
        assert_true(is_digit(t[8]))
        assert_true(is_digit(t[9]))
        assert_eq(z.length(), 5)
        assert_true((z[0] == '+') or (z[0] == '-'))
        assert_true(is_digit(z[1]))
        assert_true(is_digit(z[2]))
        assert_true(is_digit(z[3]))
        assert_true(is_digit(z[4]))
        assert_true(2000 <= v[0])
        assert_true(v[0] <= 9999)
        assert_true(1 <= v[1])
        assert_true(v[1] <= 12)
        assert_true(1 <= v[2])
        assert_true(v[2] <= 31)
        assert_true(v[3] <= 840) # +14 h offset is max
        assert_true(0 <= v[4])
        assert_true(v[4] <= 59)
        assert_true(0 <= v[5])
        assert_true(v[5] <= 59)
        assert_true(0 <= v[6])
        assert_true(v[6] <= 999)

    def Sleep(self):
        var t0 = now()
        SLEEP(0.01)
        var t1 = now()
        var msd = int(duration_cast[milliseconds](t1 - t0).count() % 1000) # msec
        assert_true(msd >= 9)