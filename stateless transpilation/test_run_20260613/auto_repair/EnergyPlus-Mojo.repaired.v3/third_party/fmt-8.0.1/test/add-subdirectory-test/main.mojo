from sys import argv as sys_argv

def main():
    var argc = len(sys_argv)
    var argv = sys_argv
    for i in range(argc):
        print(f"{i}: {argv[i]}")