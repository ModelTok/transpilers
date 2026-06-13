from third_party.eigen.doc.snippets.MatrixBase_template_int_start import RowVector4i
from third_party.eigen.doc.snippets.MatrixBase_template_int_start import cout
from third_party.eigen.doc.snippets.MatrixBase_template_int_start import endl

var v = RowVector4i.Random()
cout << "Here is the vector v:" << endl << v << endl
cout << "Here is v.head(2):" << endl << v.head<2>() << endl
v.head<2>().setZero()
cout << "Now the vector v is:" << endl << v << endl