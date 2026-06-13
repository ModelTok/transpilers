from python import Python
# Equivalent to #include <string>, <sstream>, <iostream>, <fstream>, <iomanip>, <map>, <list>
# Mojo provides built-in types: String, Dict, List, etc.
# For file I/O, use Python's open function.
let open = Python.open
let print = Python.print  # but we can use mojo's built-in print

def contributor_name(line: String) -> String:
    var result: String
    if line.find("markb@localhost.localdomain") != -1:
        return "Mark Borgerding"
    if line.find("kayhman@contact.intra.cea.fr") != -1:
        return "Guillaume Saupin"
    var position_of_email_address = line.find_first_of('<')
    if position_of_email_address != -1:
        if line.find("hauke.heibel") != -1:
            result = "Hauke Heibel"
        else:
            result = line.substr(0, position_of_email_address)
    else:
        if line.find("convert-repo") != -1:
            result = ""
        else:
            result = line
    var length = result.length()
    while length >= 1 and result[length-1] == ' ':
        result.erase(--length)
    return result

def contributors_map_from_churn_output(filename: String) -> Dict[String, Int]:
    var contributors_map: Dict[String, Int] = Dict[String, Int]()
    var line: String
    let churn_out = open(filename, "r")
    while True:
        line = churn_out.readline()
        if not line:
            break
        # trim newline? In C++ getline strips newline. In Python readline keeps newline. We'll remove trailing newline.
        if line.endswith("\n"):
            line = line[:-1]
        var first_star = line.find_first_of('*')
        if first_star != -1:
            line.erase(first_star)
        var length = line.length()
        while length >= 1 and line[length-1] == ' ':
            line.erase(--length)
        var last_space = line.find_last_of(' ')
        var number: Int = 0
        # C++ istringstream(line.substr(last_space+1)) >> number
        number = int(line.substr(last_space+1))
        line.erase(last_space)
        var name = contributor_name(line)
        var it = contributors_map.get(name)
        if it is None:
            contributors_map[name] = number
        else:
            contributors_map[name] = it.value() + number
    churn_out.close()
    return contributors_map

def lastname(name: String) -> String:
    var last_space = name.find_last_of(' ')
    if last_space >= name.length()-1:
        return name
    else:
        return name.substr(last_space+1)

struct contributor:
    var name: String
    var changedlines: Int
    var changesets: Int
    var url: String
    var misc: String
    def __init__(inout self):
        self.changedlines = 0
        self.changesets = 0
        self.name = ""
        self.url = ""
        self.misc = ""
    def __lt__(self, other: contributor) -> Bool:
        return lastname(self.name) < lastname(other.name)

def add_online_info_into_contributors_list(inout contributors_list: List[contributor], filename: String):
    var line: String
    let online_info = open(filename, "r")
    while True:
        line = online_info.readline()
        if not line:
            break
        if line.endswith("\n"):
            line = line[:-1]
        var hgname: String
        var realname: String
        var url: String
        var misc: String
        var last_bar = line.find_last_of('|')
        if last_bar == -1:
            continue
        if last_bar < line.length():
            misc = line.substr(last_bar+1)
        line.erase(last_bar)
        last_bar = line.find_last_of('|')
        if last_bar == -1:
            continue
        if last_bar < line.length():
            url = line.substr(last_bar+1)
        line.erase(last_bar)
        last_bar = line.find_last_of('|')
        if last_bar == -1:
            continue
        if last_bar < line.length():
            realname = line.substr(last_bar+1)
        line.erase(last_bar)
        hgname = line
        if hgname.find("MercurialName") != -1:
            continue
        var it: Int = 0
        for i in range(len(contributors_list)):
            if contributors_list[i].name == hgname:
                it = i
                break
        else:
            it = len(contributors_list)
        if it == len(contributors_list):
            var c: contributor
            c.name = realname
            c.url = url
            c.misc = misc
            contributors_list.append(c)
        else:
            contributors_list[it].name = realname
            contributors_list[it].url = url
            contributors_list[it].misc = misc
    online_info.close()

def main():
    var contributors_map_for_changedlines = contributors_map_from_churn_output("churn-changedlines.out")
    var contributors_list: List[contributor] = List[contributor]()
    for (name, lines) in contributors_map_for_changedlines.items():
        var c: contributor
        c.name = name
        c.changedlines = lines
        c.changesets = 0
        contributors_list.append(c)
    add_online_info_into_contributors_list(contributors_list, "online-info.out")
    # Sort using __lt__
    contributors_list.sort()

    print("{| cellpadding=\"5\"")
    print("!")
    print("! Lines changed")
    print("!")
    var i: Int = 0
    for itc in contributors_list:
        if len(itc.name) == 0:
            continue
        if i % 2:
            print("|-")
        else:
            print("|- style=\"background:#FFFFD0\"")
        if len(itc.url) != 0:
            print("| [" + itc.url + " " + itc.name + "]")
        else:
            print("| " + itc.name)
        if itc.changedlines != 0:
            print("| " + String(itc.changedlines))
        else:
            print("| (no information)")
        print("| " + itc.misc)
        i += 1
    print("|}")