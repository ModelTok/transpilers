from gtest import Test, TestFixture, EXPECT_TRUE
from EnergyPlus.DataSystemVariables import CheckForActualFilePath
from EnergyPlus.FileSystem import makeNativePath, getParentDirectoryPath, getAbsolutePath
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from pathlib import Path

@register_test(EnergyPlusFixture)
def File_Not_Found_ERR_Output():
    var filePath: Path = makeNativePath("./NonExistentFile.txt")
    var expectedError: String = getParentDirectoryPath(getAbsolutePath(filePath)).string()
    var contextString: String = "Test File_Not_Found_ERR_Output"
    var fullPath: Path = CheckForActualFilePath(this.state, filePath, contextString)
    EXPECT_TRUE(fullPath.empty())
    EXPECT_TRUE(match_err_stream(expectedError))