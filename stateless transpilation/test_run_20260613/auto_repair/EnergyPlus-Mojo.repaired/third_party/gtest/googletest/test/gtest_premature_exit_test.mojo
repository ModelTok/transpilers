from gtest.gtest import InitGoogleTest, Test, GetEnv, Stat, StatStruct
from stdio import printf

@value
class PrematureExitTest(Test):
    var premature_exit_file_path_: Pointer[UInt8]

    @staticmethod
    def FileExists(filepath: Pointer[UInt8]) -> Bool:
        var stat: StatStruct
        return Stat(filepath, stat) == 0

    def __init__(self):
        self.premature_exit_file_path_ = GetEnv("TEST_PREMATURE_EXIT_FILE")
        if self.premature_exit_file_path_ == None:
            self.premature_exit_file_path_ = ""

    def PrematureExitFileExists(self) -> Bool:
        return PrematureExitTest.FileExists(self.premature_exit_file_path_)

alias PrematureExitDeathTest = PrematureExitTest

def test_PrematureExitDeathTest_FileExistsDuringExecutionOfDeathTest(self: PrematureExitDeathTest):
    if self.premature_exit_file_path_[0] == '\0':
        return
    EXPECT_DEATH_IF_SUPPORTED({
        if self.PrematureExitFileExists():
            exit(1)
    }, "")

def test_PrematureExitTest_PrematureExitFileExistsDuringTestExecution(self: PrematureExitTest):
    if self.premature_exit_file_path_[0] == '\0':
        return
    EXPECT_TRUE(self.PrematureExitFileExists()) \
        << " file " << self.premature_exit_file_path_ \
        << " should exist during test execution, but doesn't."

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    InitGoogleTest(argc, argv)
    let exit_code = RUN_ALL_TESTS()
    let filepath = GetEnv("TEST_PREMATURE_EXIT_FILE")
    if filepath != None and filepath[0] != '\0':
        if PrematureExitTest.FileExists(filepath):
            printf(
                "File %s shouldn't exist after the test program finishes, but does.",
                filepath)
            return 1
    return exit_code