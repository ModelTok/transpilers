from Eigen import Vector2f, JacobiRotation
from iostream import cout, endl

var v = Vector2f.Random()
var G = JacobiRotation[float]()
G.makeGivens(v.x(), v.y())
cout << "Here is the vector v:" << endl << v << endl
v.applyOnTheLeft(0, 1, G.adjoint())
cout << "Here is the vector J' * v:" << endl << v << endl