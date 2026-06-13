from memory.auto import Array3d
from output import cout

def main():
    var v = Array3d(1, 2, 3)
    cout << v.log() << endl