from collections import List
from pathlib import Path
import time
import sys

# EXTERNAL DEPS (to wire in glue):
# None - this is a standalone conversion utility

struct ConvType:
    var siUnit: String
    var ipUnit: String
    var mult: Float64
    var offset: Float64
    
    fn __init__(inout self):
        self.siUnit = ""
        self.ipUnit = ""
        self.mult = 0.0
        self.offset = 0.0

struct WildType:
    var matchStr: String
    var siUnit: String
    var ipUnit: String
    var convPt: Int
    
    fn __init__(inout self):
        self.matchStr = ""
        self.siUnit = ""
        self.ipUnit = ""
        self.convPt = 0

struct VariType:
    var varName: String
    var siUnit: String
    var ipUnit: String
    var convPt: Int
    
    fn __init__(inout self):
        self.varName = ""
        self.siUnit = ""
        self.ipUnit = ""
        self.convPt = 0

struct DictionType:
    var isValid: Bool
    var isPassThru: Bool
    var convPt: Int
    
    fn __init__(inout self):
        self.isValid = False
        self.isPassThru = False
        self.convPt = 0

struct ESOtoIPConverter:
    var errorCounter: Int
    var processingESO: Bool
    var conv: List[ConvType]
    var numConv: Int
    var sizeConv: Int
    var wild: List[WildType]
    var numWild: Int
    var sizeWild: Int
    var vari: List[VariType]
    var numVari: Int
    var sizeVari: Int
    var diction: List[DictionType]
    var dictionNum: Int
    var sizeDiction: Int
    var file2: Optional[FileDescriptor]
    var file3: Optional[FileDescriptor]
    var file4: Optional[FileDescriptor]
    
    fn __init__(inout self):
        self.errorCounter = 0
        self.processingESO = False
        self.conv = List[ConvType]()
        self.numConv = 0
        self.sizeConv = 0
        self.wild = List[WildType]()
        self.numWild = 0
        self.sizeWild = 0
        self.vari = List[VariType]()
        self.numVari = 0
        self.sizeVari = 0
        self.diction = List[DictionType]()
        self.dictionNum = 0
        self.sizeDiction = 0
        self.file2 = None
        self.file3 = None
        self.file4 = None
    
    fn makeLowerCase(self, phraseIn: String) -> String:
        return phraseIn.lower()
    
    fn split(self, string: String, delimiter: String) -> List[String]:
        var parts = List[String]()
        if len(string) == 0:
            return parts
        
        var current = String()
        for char in string:
            if char == delimiter[0]:
                parts.append(current)
                current = String()
            else:
                current += char
        
        if len(current) > 0:
            parts.append(current)
        
        return parts
    
    fn getFileExt(inout self, filename: String) -> String:
        var pos = filename.rfind(".")
        if pos != -1:
            return filename[pos+1:]
        else:
            _ = self.file4.write(f"filename={filename}, no extension found\n")
            self.errorCounter += 1
            return ""
    
    fn inttostr(self, intin: Int) -> String:
        return str(intin)
    
    fn incrementConv(inout self):
        self.numConv += 1
        if self.numConv > self.sizeConv:
            self.sizeConv = self.sizeConv * 2
            while len(self.conv) < self.sizeConv:
                self.conv.append(ConvType())
    
    fn incrementWild(inout self):
        self.numWild += 1
        if self.numWild > self.sizeWild:
            self.sizeWild = self.sizeWild * 2
            while len(self.wild) < self.sizeWild:
                self.wild.append(WildType())
    
    fn incrementVari(inout self):
        self.numVari += 1
        if self.numVari > self.sizeVari:
            self.sizeVari = self.sizeVari * 2
            while len(self.vari) < self.sizeVari:
                self.vari.append(VariType())
    
    fn resizeDiction(inout self, newSize: Int):
        if newSize > self.sizeDiction:
            self.sizeDiction = newSize + 5000
            while len(self.diction) < self.sizeDiction:
                self.diction.append(DictionType())
    
    fn lookUpConv(self, siMatch: String, ipMatch: String) -> Int:
        var found = 0
        for i in range(self.numConv):
            if siMatch == self.conv[i].siUnit:
                if ipMatch == self.conv[i].ipUnit:
                    found = i + 1
                    break
        return found
    
    fn reportError(inout self, errorString: String):
        self.errorCounter += 1
        if self.errorCounter <= 5:
            self.WriteStdOut(errorString)
        elif self.errorCounter == 6:
            self.WriteStdOut("Too many error detected in input file, see err file")
        _ = self.file4.write(f"{self.inttostr(self.errorCounter)}: {errorString}\n")
    
    fn WriteStdOut(self, outText: String):
        print(outText)
    
    fn readESOtoIPfile(inout self):
        var fileexist = True
        try:
            with open("convert.txt", "r") as f:
                var lineOfFile = String()
                while True:
                    try:
                        lineOfFile = f.readline()
                        if len(lineOfFile) == 0:
                            break
                    except:
                        break
                    
                    lineOfFile = lineOfFile.strip()
                    if len(lineOfFile) > 0:
                        lineOfFile = lineOfFile.lstrip()
                        if len(lineOfFile) > 0 and lineOfFile[0] != '!':
                            var parts = self.split(lineOfFile, ",")
                            var cmd = self.makeLowerCase(parts[0]) if len(parts) > 0 else ""
                            if cmd == "conv":
                                self.incrementConv()
                                if len(parts) > 1:
                                    self.conv[self.numConv-1].siUnit = parts[1]
                                if len(parts) > 2:
                                    self.conv[self.numConv-1].ipUnit = parts[2]
                                if len(parts) > 3:
                                    try:
                                        self.conv[self.numConv-1].mult = atof(parts[3])
                                    except:
                                        pass
                                if len(parts) > 4:
                                    try:
                                        self.conv[self.numConv-1].offset = atof(parts[4])
                                    except:
                                        pass
                            elif cmd == "wild":
                                self.incrementWild()
                                if len(parts) > 1:
                                    self.wild[self.numWild-1].matchStr = parts[1]
                                if len(parts) > 2:
                                    self.wild[self.numWild-1].siUnit = parts[2]
                                if len(parts) > 3:
                                    self.wild[self.numWild-1].ipUnit = parts[3]
                            elif cmd == "vari":
                                self.incrementVari()
                                if len(parts) > 1:
                                    self.vari[self.numVari-1].varName = parts[1]
                                if len(parts) > 2:
                                    self.vari[self.numVari-1].siUnit = parts[2]
                                if len(parts) > 3:
                                    self.vari[self.numVari-1].ipUnit = parts[3]
        except:
            _ = self.file4.write("convert.txt not available.  convertESOMTR terminates.\n")
            return
        
        for i in range(self.numVari):
            self.vari[i].convPt = self.lookUpConv(self.vari[i].siUnit, self.vari[i].ipUnit)
            if self.vari[i].convPt == 0:
                self.reportError(f"Lookup of si/ip on vari {self.vari[i].varName} not found.")
        
        for i in range(self.numWild):
            self.wild[i].convPt = self.lookUpConv(self.wild[i].siUnit, self.wild[i].ipUnit)
            if self.wild[i].convPt == 0:
                self.reportError(f"Lookup of si/ip on wild {self.wild[i].matchStr} not found.")
    
    fn readESOdictionary(inout self):
        var lineOfESO = String()
        try:
            lineOfESO = self.file2.readline()
            _ = self.file3.write(lineOfESO)
        except:
            return
        
        while True:
            try:
                lineOfESO = self.file2.readline()
            except:
                break
            
            if len(lineOfESO) == 0:
                break
            
            lineOfESO = lineOfESO.rstrip("\n\r")
            if lineOfESO == "End of Data Dictionary":
                break
            
            var dNum = self.AddToDictionary(lineOfESO)
            if dNum == 0:
                self.reportError(f"Line of data dictionary cannot be parsed: {lineOfESO}")
            elif dNum <= len(self.diction) and self.diction[dNum-1].isPassThru:
                _ = self.file3.write(f"{lineOfESO}\n")
            else:
                var newLineOfESO = self.ConvertDictionLine(lineOfESO, dNum)
                _ = self.file3.write(f"{newLineOfESO}\n")
        
        if lineOfESO != "End of Data Dictionary":
            self.reportError("Entire ESO file treated as data dictionary - check for End of Data Dictionary line.")
            return
        else:
            _ = self.file3.write(f"{lineOfESO}\n")
    
    fn AddToDictionary(inout self, inputLine: String) -> Int:
        var explPos = inputLine.find("!")
        var lineNoComment = String()
        if explPos > 0:
            lineNoComment = inputLine[0:explPos]
        else:
            lineNoComment = inputLine
        
        var parts = self.split(lineNoComment, ",")
        var numParts = len(parts)
        
        if numParts == 0:
            self.reportError(f"Invalid dictionary line - no commas found: {inputLine}")
            return 0
        
        var dictionIndex = 0
        try:
            dictionIndex = atoi(parts[0])
        except:
            self.reportError(f"Invalid dictionary line - first field is not a number: {inputLine}")
            return 0
        
        self.dictionNum = max(self.dictionNum, dictionIndex)
        self.resizeDiction(dictionIndex)
        
        if dictionIndex == 0:
            self.reportError(f"Invalid dictionary line - first field is not a number: {inputLine}")
            return 0
        elif dictionIndex > 0 and dictionIndex <= len(self.diction) and self.diction[dictionIndex-1].isValid:
            self.reportError(f"Invalid dictionary line - first field value previously used: {inputLine}")
            return 0
        elif dictionIndex <= 5:
            if dictionIndex <= len(self.diction):
                self.diction[dictionIndex-1].isValid = True
                self.diction[dictionIndex-1].isPassThru = True
            return dictionIndex
        else:
            if dictionIndex <= len(self.diction):
                self.diction[dictionIndex-1].isValid = True
            
            var convIndex = 0
            if self.processingESO:
                if numParts == 4:
                    convIndex = self.lookUpVariWildConv(parts[3])
                else:
                    convIndex = self.lookUpVariWildConv(parts[2])
            else:
                if len(parts) > 2:
                    convIndex = self.lookUpVariWildConv(parts[2])
            
            if convIndex == 0:
                if dictionIndex <= len(self.diction):
                    self.diction[dictionIndex-1].isPassThru = True
            else:
                if dictionIndex <= len(self.diction):
                    self.diction[dictionIndex-1].isPassThru = False
                    self.diction[dictionIndex-1].convPt = convIndex
            
            return dictionIndex
    
    fn lookUpVariWildConv(self, unVariName: String) -> Int:
        var unVariNoUnits = String()
        var unUnits = String()
        self.breakOutUnits(unVariName, unVariNoUnits, unUnits)
        
        var convIndex = self.lookUpInVariList(unVariNoUnits, unUnits)
        if convIndex == 0:
            convIndex = self.lookUpUsingWild(unVariNoUnits, unUnits)
            if convIndex == 0:
                convIndex = self.lookupDefaultUnit(unUnits)
        
        return convIndex
    
    fn breakOutUnits(self, stringIn: String, inout preUnitOut: String, inout unitOut: String):
        var stringInTrim = stringIn
        var leftBracket = stringInTrim.find("[")
        var rightBracket = stringInTrim.find("]")
        
        preUnitOut = ""
        unitOut = ""
        
        if leftBracket >= 1 and rightBracket >= 3:
            if rightBracket > leftBracket + 1:
                preUnitOut = stringInTrim[0:leftBracket]
                unitOut = stringInTrim[leftBracket+1:rightBracket]
            elif leftBracket > 0:
                preUnitOut = stringInTrim[0:leftBracket]
                unitOut = " "
            else:
                preUnitOut = stringInTrim
                unitOut = " "
        else:
            preUnitOut = stringInTrim
            unitOut = " "
    
    fn lookUpInVariList(self, nameOfVar: String, nameOfUnit: String) -> Int:
        var found = 0
        for i in range(self.numVari):
            if self.makeLowerCase(nameOfVar) == self.makeLowerCase(self.vari[i].varName):
                if i < len(self.conv) and self.vari[i].convPt > 0 and self.vari[i].convPt <= len(self.conv):
                    if self.makeLowerCase(nameOfUnit) == self.makeLowerCase(self.conv[self.vari[i].convPt-1].siUnit):
                        found = i + 1
                        break
        
        if found > 0:
            return self.vari[found-1].convPt
        else:
            return 0
    
    fn lookUpUsingWild(self, nameOfVar: String, nameOfUnit: String) -> Int:
        var found = 0
        for i in range(self.numWild):
            var locOfString = self.makeLowerCase(nameOfVar).find(self.makeLowerCase(self.wild[i].matchStr))
            if locOfString >= 0:
                if self.wild[i].convPt > 0 and self.wild[i].convPt <= len(self.conv):
                    if self.makeLowerCase(nameOfUnit) == self.makeLowerCase(self.conv[self.wild[i].convPt-1].siUnit):
                        found = i + 1
                        break
        
        if found > 0:
            return self.wild[found-1].convPt
        else:
            return 0
    
    fn lookupDefaultUnit(self, nameOfUnit: String) -> Int:
        var found = 0
        for i in range(self.numConv):
            if self.makeLowerCase(nameOfUnit) == self.makeLowerCase(self.conv[i].siUnit):
                found = i + 1
                break
        return found
    
    fn ConvertDictionLine(self, esoLine: String, indexDiction: Int) -> String:
        if indexDiction <= 0 or indexDiction > len(self.diction):
            return esoLine
        
        var convIndex = self.diction[indexDiction-1].convPt
        if convIndex <= 0 or convIndex > len(self.conv):
            return esoLine
        
        var findString = "[" + self.conv[convIndex-1].siUnit + "]"
        var replaceString = "[" + self.conv[convIndex-1].ipUnit + "]"
        
        var newesoline = esoLine
        var found = newesoline.find(findString)
        while found >= 0:
            var part1Line = newesoline[0:found]
            var part2Line = newesoline[found+len(findString):]
            newesoline = part1Line + replaceString + part2Line
            found = newesoline.find(findString)
        
        return newesoline
    
    fn convertEPLUSOUTESO(inout self):
        while True:
            var lineOfESO = String()
            try:
                lineOfESO = self.file2.readline()
            except:
                break
            
            if len(lineOfESO) == 0:
                break
            
            lineOfESO = lineOfESO.rstrip("\n\r")
            if lineOfESO == "End of Data":
                _ = self.file3.write(f"{lineOfESO}\n")
                try:
                    lineOfESO = self.file2.readline()
                    if len(lineOfESO) > 0:
                        lineOfESO = lineOfESO.rstrip("\n\r")
                        _ = self.file3.write(f"{lineOfESO}\n")
                except:
                    pass
                break
            
            var oldParts = self.split(lineOfESO, ",")
            var numParts = len(oldParts)
            
            var dictionIndex = 0
            try:
                dictionIndex = atoi(oldParts[0])
            except:
                dictionIndex = 0
            
            if dictionIndex < self.sizeDiction:
                if dictionIndex > 0 and dictionIndex <= self.dictionNum and dictionIndex <= len(self.diction) and self.diction[dictionIndex-1].isValid:
                    if self.diction[dictionIndex-1].isPassThru:
                        _ = self.file3.write(f"{lineOfESO}\n")
                    else:
                        var convIndex = self.diction[dictionIndex-1].convPt
                        var newParts = List[String]()
                        for i in range(numParts):
                            newParts.append(oldParts[i])
                        
                        if numParts == 2:
                            newParts[1] = self.convertPart(oldParts[1], convIndex)
                        elif numParts == 6:
                            newParts[1] = self.convertPart(oldParts[1], convIndex)
                            newParts[2] = self.convertPart(oldParts[2], convIndex)
                            newParts[4] = self.convertPart(oldParts[4], convIndex)
                        elif numParts == 8:
                            newParts[1] = self.convertPart(oldParts[1], convIndex)
                            newParts[2] = self.convertPart(oldParts[2], convIndex)
                            newParts[5] = self.convertPart(oldParts[5], convIndex)
                        elif numParts == 10:
                            newParts[1] = self.convertPart(oldParts[1], convIndex)
                            newParts[2] = self.convertPart(oldParts[2], convIndex)
                            newParts[6] = self.convertPart(oldParts[6], convIndex)
                        elif numParts == 12:
                            newParts[1] = self.convertPart(oldParts[1], convIndex)
                            newParts[2] = self.convertPart(oldParts[2], convIndex)
                            newParts[7] = self.convertPart(oldParts[7], convIndex)
                        
                        var outLine = String()
                        for i in range(len(newParts)):
                            if i > 0:
                                outLine += ","
                            outLine += newParts[i]
                        _ = self.file3.write(f"{outLine}\n")
                else:
                    self.reportError(f"Invalid dictionary reference on line: {lineOfESO}")
            else:
                self.reportError(f"Unknown dictionary reference on line: {lineOfESO}")
    
    fn convertPart(self, numAsString: String, indexConv: Int) -> String:
        try:
            var oldNumAsReal = atof(numAsString)
            if indexConv > 0 and indexConv <= len(self.conv):
                var newNumAsReal = oldNumAsReal * self.conv[indexConv-1].mult + self.conv[indexConv-1].offset
                return str(newNumAsReal)
            else:
                return numAsString
        except:
            return numAsString
    
    fn run(inout self):
        var time_start = now()
        
        var numcmdargs = len(sys.argv) - 1
        var filename1 = "eplusout.eso"
        var filename2 = "eplusout.mtr"
        
        if numcmdargs >= 1:
            filename1 = sys.argv[1]
        if numcmdargs >= 2:
            filename2 = sys.argv[2]
        
        var file1exist = True
        var file2exist = True
        
        self.processingESO = True
        self.sizeConv = 100
        for _ in range(self.sizeConv):
            self.conv.append(ConvType())
        self.sizeWild = 100
        for _ in range(self.sizeWild):
            self.wild.append(WildType())
        self.sizeVari = 100
        for _ in range(self.sizeVari):
            self.vari.append(VariType())
        
        var convertread = False
        
        try:
            self.file4 = open("ip.err", "w")
        except:
            print("could not open ip.err")
            return
        
        if file1exist:
            var file1ok = True
            var errcount = self.errorCounter
            var ext1 = self.getFileExt(filename1)
            if errcount != self.errorCounter:
                return
            
            try:
                self.file2 = open(filename1, "r")
            except:
                _ = self.file4.write(f"could not open file={filename1}\n")
                file1ok = False
            
            try:
                self.file3 = open(f"ip.{ext1}", "w")
            except:
                _ = self.file4.write(f"could not open file=ip.{ext1}\n")
                file1ok = False
            
            if file1ok:
                self.sizeDiction = 50000
                for _ in range(self.sizeDiction):
                    self.diction.append(DictionType())
                self.readESOtoIPfile()
                convertread = True
                
                self.readESOdictionary()
                self.convertEPLUSOUTESO()
        
        self.processingESO = False
        self.diction = List[DictionType]()
        
        var time_finish = now()
        var elapsed_time = (time_finish - time_start)
        
        var hours = int(elapsed_time / 3600.0)
        elapsed_time = elapsed_time - Float64(hours) * 3600.0
        var minutes = int(elapsed_time / 60.0)
        elapsed_time = elapsed_time - Float64(minutes) * 60.0
        var seconds = elapsed_time
        
        var elapsed_str = f"{hours:02}hr {minutes:02}min {seconds:05.2}sec"
        print(f"convertESOMTR Run Time={elapsed_str} file={filename1}")
        
        time_start = now()
        
        self.dictionNum = 0
        self.sizeDiction = 20000
        self.diction = List[DictionType]()
        for _ in range(self.sizeDiction):
            self.diction.append(DictionType())
        
        if file2exist:
            var file2ok = True
            errcount = self.errorCounter
            var ext2 = self.getFileExt(filename2)
            if errcount != self.errorCounter:
                return
            
            try:
                self.file2 = open(filename2, "r")
            except:
                _ = self.file4.write(f"could not open file={filename2}\n")
                file2ok = False
            
            try:
                self.file3 = open(f"ip.{ext2}", "w")
            except:
                _ = self.file4.write(f"could not open file=ip.{ext2}\n")
                file2ok = False
            
            if file2ok:
                if not convertread:
                    self.readESOtoIPfile()
                self.readESOdictionary()
                self.convertEPLUSOUTESO()
        
        time_finish = now()
        elapsed_time = (time_finish - time_start)
        
        hours = int(elapsed_time / 3600.0)
        elapsed_time = elapsed_time - Float64(hours) * 3600.0
        minutes = int(elapsed_time / 60.0)
        elapsed_time = elapsed_time - Float64(minutes) * 60.0
        seconds = elapsed_time
        
        elapsed_str = f"{hours:02}hr {minutes:02}min {seconds:05.2}sec"
        print(f"convertESOMTR Run Time={elapsed_str} file={filename2}")
        
        if self.errorCounter == 0:
            try:
                _ = Path("ip.err").remove()
            except:
                pass

fn main():
    var converter = ESOtoIPConverter()
    converter.run()
