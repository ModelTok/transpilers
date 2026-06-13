from "../../environment import SETENV, GET_ENVIRONMENT_VARIABLE, get_environment_variable, GETENV, GETENVQQ, GET_ENV_VAR, SETENVQQ

def test_EnvironmentTest_GetEnvironmentVariable():
    {
        assert(SETENV("ObjexxFPL_Test_Env_Var", "GET_ENVIRONMENT_VARIABLE"))
        var val: String
        GET_ENVIRONMENT_VARIABLE("ObjexxFPL_Test_Env_Var", val)
        assert(val == "GET_ENVIRONMENT_VARIABLE")
    }
    {
        assert(SETENV("ObjexxFCL_Test_Env_Var", "get_environment_variable"))
        var val: String
        get_environment_variable("ObjexxFCL_Test_Env_Var", val)
        assert(val == "get_environment_variable")
    }

def test_EnvironmentTest_Getenv():
    assert(SETENV("ObjexxFCL_Test_Env_Var", "GETENV"))
    var val: String
    GETENV("ObjexxFCL_Test_Env_Var", val)
    assert(val == "GETENV")

def test_EnvironmentTest_Getenvqq():
    assert(SETENV("ObjexxFCL_Test_Env_Var", "GETENVQQ"))
    var val: String
    assert(GETENVQQ("ObjexxFCL_Test_Env_Var", val) == 8)
    assert(val == "GETENVQQ")

def test_EnvironmentTest_GetEnvVar():
    assert(SETENV("ObjexxFCL_Test_Env_Var", "GETENVQQ"))
    assert(GET_ENV_VAR("ObjexxFCL_Test_Env_Var") == "GETENVQQ")

def test_EnvironmentTest_Setenv():
    assert(SETENV("ObjexxFCL_Test_Env_Var", "SETENV"))
    assert(GET_ENV_VAR("ObjexxFCL_Test_Env_Var") == "SETENV")

def test_EnvironmentTest_Setenvqq():
    assert(SETENVQQ("ObjexxFCL_Test_Env_Var=SETENVQQ"))
    assert(GET_ENV_VAR("ObjexxFCL_Test_Env_Var") == "SETENVQQ")