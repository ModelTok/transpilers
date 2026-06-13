from gtest import *
from EnergyPlus.Construction import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.OutputReportPredefined import *
from .Fixtures.EnergyPlusFixture import *

using EnergyPlus.
using EnergyPlus.Construction.

@fixture
def EnergyPlusFixture_Construction_reportLayers(state):
    using EnergyPlus.OutputReportPredefined.
    var c = state.dataConstruction
    var m = state.dataMaterial
    var orp = state.dataOutRptPredefined
    var mata = Material.MaterialBase()
    mata.Name = "mat a"
    m.materials.append(mata)
    var matb = Material.MaterialBase()
    matb.Name = "mat b"
    m.materials.append(matb)
    var matc = Material.MaterialBase()
    matc.Name = "mat c"
    m.materials.append(matc)
    var matd = Material.MaterialBase()
    matd.Name = "mat d"
    m.materials.append(matd)
    var mate = Material.MaterialBase()
    mate.Name = "mat e"
    m.materials.append(mate)
    var matf = Material.MaterialBase()
    matf.Name = "mat f"
    m.materials.append(matf)
    var matg = Material.MaterialBase()
    matg.Name = "mat g"
    m.materials.append(matg)
    var math = Material.MaterialBase()
    math.Name = "mat h"
    m.materials.append(math)
    c.Construct.allocate(3)
    c.Construct[0].Name = "ConsB"
    c.Construct[0].TotLayers = 1
    c.Construct[0].LayerPoint[0] = 2
    c.Construct[0].reportLayers(state)
    c.Construct[1].Name = "ConsCEGAH"
    c.Construct[1].TotLayers = 5
    c.Construct[1].LayerPoint[0] = 3
    c.Construct[1].LayerPoint[1] = 5
    c.Construct[1].LayerPoint[2] = 7
    c.Construct[1].LayerPoint[3] = 1
    c.Construct[1].LayerPoint[4] = 8
    c.Construct[1].reportLayers(state)
    c.Construct[2].Name = "ConsDA"
    c.Construct[2].TotLayers = 2
    c.Construct[2].LayerPoint[0] = 4
    c.Construct[2].LayerPoint[1] = 1
    c.Construct[2].reportLayers(state)
    EXPECT_EQ("mat b", RetrievePreDefTableEntry(state, orp.pdchOpqConsLayCol[0], "ConsB"))
    EXPECT_EQ("NOT FOUND", RetrievePreDefTableEntry(state, orp.pdchOpqConsLayCol[1], "ConsB"))
    EXPECT_EQ("mat c", RetrievePreDefTableEntry(state, orp.pdchOpqConsLayCol[0], "ConsCEGAH"))
    EXPECT_EQ("mat e", RetrievePreDefTableEntry(state, orp.pdchOpqConsLayCol[1], "ConsCEGAH"))
    EXPECT_EQ("mat g", RetrievePreDefTableEntry(state, orp.pdchOpqConsLayCol[2], "ConsCEGAH"))
    EXPECT_EQ("mat a", RetrievePreDefTableEntry(state, orp.pdchOpqConsLayCol[3], "ConsCEGAH"))
    EXPECT_EQ("mat h", RetrievePreDefTableEntry(state, orp.pdchOpqConsLayCol[4], "ConsCEGAH"))
    EXPECT_EQ("NOT FOUND", RetrievePreDefTableEntry(state, orp.pdchOpqConsLayCol[5], "ConsCEGAH"))
    EXPECT_EQ("mat d", RetrievePreDefTableEntry(state, orp.pdchOpqConsLayCol[0], "ConsDA"))
    EXPECT_EQ("mat a", RetrievePreDefTableEntry(state, orp.pdchOpqConsLayCol[1], "ConsDA"))
    EXPECT_EQ("NOT FOUND", RetrievePreDefTableEntry(state, orp.pdchOpqConsLayCol[2], "ConsDA"))