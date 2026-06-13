import sys
import time
import os
from dataclasses import dataclass, field
from typing import List, Optional

# EXTERNAL DEPS (to wire in glue):
# None - this is a standalone conversion utility

@dataclass
class ConvType:
    siUnit: str = ''
    ipUnit: str = ''
    mult: float = 0.0
    offset: float = 0.0

@dataclass
class WildType:
    matchStr: str = ''
    siUnit: str = ''
    ipUnit: str = ''
    convPt: int = 0

@dataclass
class VariType:
    varName: str = ''
    siUnit: str = ''
    ipUnit: str = ''
    convPt: int = 0

@dataclass
class DictionType:
    isValid: bool = False
    isPassThru: bool = False
    convPt: int = 0

class ESOtoIPConverter:
    def __init__(self):
        self.errorCounter = 0
        self.processingESO = False
        self.conv: List[ConvType] = []
        self.numConv = 0
        self.sizeConv = 0
        self.wild: List[WildType] = []
        self.numWild = 0
        self.sizeWild = 0
        self.vari: List[VariType] = []
        self.numVari = 0
        self.sizeVari = 0
        self.diction: List[DictionType] = []
        self.dictionNum = 0
        self.sizeDiction = 0
        self.file1 = None
        self.file2 = None
        self.file3 = None
        self.file4 = None
    
    def makeLowerCase(self, phraseIn: str) -> str:
        return phraseIn.lower()
    
    def split(self, string: str, delimiter: str) -> List[str]:
        if not string:
            return []
        parts = string.split(delimiter)
        return [p for p in parts if len(p) > 0 or delimiter in string]
    
    def getFileExt(self, filename: str) -> str:
        pos = filename.rfind('.')
        if pos != -1:
            return filename[pos+1:]
        else:
            self.file4.write(f'filename={filename}, no extension found\n')
            self.errorCounter += 1
            return ''
    
    def inttostr(self, intin: int) -> str:
        return str(intin)
    
    def incrementConv(self):
        self.numConv += 1
        if self.numConv > self.sizeConv:
            self.sizeConv = self.sizeConv * 2
            while len(self.conv) < self.sizeConv:
                self.conv.append(ConvType())
    
    def incrementWild(self):
        self.numWild += 1
        if self.numWild > self.sizeWild:
            self.sizeWild = self.sizeWild * 2
            while len(self.wild) < self.sizeWild:
                self.wild.append(WildType())
    
    def incrementVari(self):
        self.numVari += 1
        if self.numVari > self.sizeVari:
            self.sizeVari = self.sizeVari * 2
            while len(self.vari) < self.sizeVari:
                self.vari.append(VariType())
    
    def resizeDiction(self, newSize: int):
        if newSize > self.sizeDiction:
            self.sizeDiction = newSize + 5000
            while len(self.diction) < self.sizeDiction:
                self.diction.append(DictionType())
    
    def lookUpConv(self, siMatch: str, ipMatch: str) -> int:
        found = 0
        for i in range(self.numConv):
            if siMatch == self.conv[i].siUnit:
                if ipMatch == self.conv[i].ipUnit:
                    found = i + 1
                    break
        return found
    
    def reportError(self, errorString: str):
        self.errorCounter += 1
        if self.errorCounter <= 5:
            self.WriteStdOut(errorString)
        elif self.errorCounter == 6:
            self.WriteStdOut('Too many error detected in input file, see err file')
        self.file4.write(f'{self.inttostr(self.errorCounter)}: {errorString}\n')
    
    def WriteStdOut(self, outText: str):
        print(outText)
    
    def readESOtoIPfile(self):
        try:
            with open('convert.txt', 'r') as f:
                for lineOfFile in f:
                    lineOfFile = lineOfFile.strip()
                    if len(lineOfFile) > 0:
                        lineOfFile = lineOfFile.lstrip()
                        if lineOfFile[0:1] != '!':
                            parts = self.split(lineOfFile, ',')
                            cmd = self.makeLowerCase(parts[0]) if parts else ''
                            if cmd == 'conv':
                                self.incrementConv()
                                self.conv[self.numConv-1].siUnit = parts[1] if len(parts) > 1 else ''
                                self.conv[self.numConv-1].ipUnit = parts[2] if len(parts) > 2 else ''
                                try:
                                    self.conv[self.numConv-1].mult = float(parts[3]) if len(parts) > 3 else 0.0
                                except:
                                    pass
                                try:
                                    self.conv[self.numConv-1].offset = float(parts[4]) if len(parts) > 4 else 0.0
                                except:
                                    pass
                            elif cmd == 'wild':
                                self.incrementWild()
                                self.wild[self.numWild-1].matchStr = parts[1] if len(parts) > 1 else ''
                                self.wild[self.numWild-1].siUnit = parts[2] if len(parts) > 2 else ''
                                self.wild[self.numWild-1].ipUnit = parts[3] if len(parts) > 3 else ''
                            elif cmd == 'vari':
                                self.incrementVari()
                                self.vari[self.numVari-1].varName = parts[1] if len(parts) > 1 else ''
                                self.vari[self.numVari-1].siUnit = parts[2] if len(parts) > 2 else ''
                                self.vari[self.numVari-1].ipUnit = parts[3] if len(parts) > 3 else ''
        except FileNotFoundError:
            self.file4.write('convert.txt not available.  convertESOMTR terminates.\n')
            sys.exit(1)
        except Exception as e:
            self.file4.write(f'error during open of convert.txt.  convertESOMTR terminates.\n')
            sys.exit(1)
        
        for i in range(self.numVari):
            self.vari[i].convPt = self.lookUpConv(self.vari[i].siUnit, self.vari[i].ipUnit)
            if self.vari[i].convPt == 0:
                self.reportError(f'Lookup of si/ip on vari {self.vari[i].varName} not found.')
        
        for i in range(self.numWild):
            self.wild[i].convPt = self.lookUpConv(self.wild[i].siUnit, self.wild[i].ipUnit)
            if self.wild[i].convPt == 0:
                self.reportError(f'Lookup of si/ip on wild {self.wild[i].matchStr} not found.')
    
    def readESOdictionary(self):
        lineOfESO = self.file2.readline()
        self.file3.write(lineOfESO)
        
        while True:
            lineOfESO = self.file2.readline()
            if not lineOfESO:
                break
            lineOfESO = lineOfESO.rstrip('\n\r')
            if lineOfESO == 'End of Data Dictionary':
                break
            dNum = self.AddToDictionary(lineOfESO)
            if dNum == 0:
                self.reportError(f'Line of data dictionary cannot be parsed: {lineOfESO}')
            elif self.diction[dNum-1].isPassThru:
                self.file3.write(lineOfESO + '\n')
            else:
                newLineOfESO = self.ConvertDictionLine(lineOfESO, dNum)
                self.file3.write(newLineOfESO + '\n')
        
        if lineOfESO != 'End of Data Dictionary':
            self.reportError('Entire ESO file treated as data dictionary - check for End of Data Dictionary line.')
            sys.exit(1)
        else:
            self.file3.write(lineOfESO + '\n')
    
    def AddToDictionary(self, inputLine: str) -> int:
        explPos = inputLine.find('!')
        if explPos > 0:
            lineNoComment = inputLine[0:explPos]
        else:
            lineNoComment = inputLine
        
        parts = self.split(lineNoComment, ',')
        numParts = len(parts)
        
        if numParts == 0:
            self.reportError(f'Invalid dictionary line - no commas found: {inputLine}')
            return 0
        
        try:
            dictionIndex = int(parts[0])
        except:
            self.reportError(f'Invalid dictionary line - first field is not a number: {inputLine}')
            return 0
        
        self.dictionNum = max(self.dictionNum, dictionIndex)
        self.resizeDiction(dictionIndex)
        
        if dictionIndex == 0:
            self.reportError(f'Invalid dictionary line - first field is not a number: {inputLine}')
            return 0
        elif self.diction[dictionIndex-1].isValid:
            self.reportError(f'Invalid dictionary line - first field value previously used: {inputLine}')
            return 0
        elif dictionIndex <= 5:
            self.diction[dictionIndex-1].isValid = True
            self.diction[dictionIndex-1].isPassThru = True
            return dictionIndex
        else:
            self.diction[dictionIndex-1].isValid = True
            if self.processingESO:
                if numParts == 4:
                    convIndex = self.lookUpVariWildConv(parts[3])
                else:
                    convIndex = self.lookUpVariWildConv(parts[2])
            else:
                convIndex = self.lookUpVariWildConv(parts[2])
            
            if convIndex == 0:
                self.diction[dictionIndex-1].isPassThru = True
            else:
                self.diction[dictionIndex-1].isPassThru = False
                self.diction[dictionIndex-1].convPt = convIndex
            return dictionIndex
    
    def lookUpVariWildConv(self, unVariName: str) -> int:
        unVariNoUnits, unUnits = self.breakOutUnits(unVariName)
        convIndex = self.lookUpInVariList(unVariNoUnits, unUnits)
        if convIndex == 0:
            convIndex = self.lookUpUsingWild(unVariNoUnits, unUnits)
            if convIndex == 0:
                convIndex = self.lookupDefaultUnit(unUnits)
        return convIndex
    
    def breakOutUnits(self, stringIn: str) -> tuple:
        stringInTrim = stringIn
        leftBracket = stringInTrim.find('[')
        rightBracket = stringInTrim.find(']')
        
        preUnitOut = ''
        unitOut = ''
        
        if leftBracket >= 1 and rightBracket >= 3:
            if rightBracket > leftBracket + 1:
                preUnitOut = stringInTrim[0:leftBracket]
                unitOut = stringInTrim[leftBracket+1:rightBracket]
            elif leftBracket > 0:
                preUnitOut = stringInTrim[0:leftBracket]
                unitOut = ' '
            else:
                preUnitOut = stringInTrim
                unitOut = ' '
        else:
            preUnitOut = stringInTrim
            unitOut = ' '
        
        return preUnitOut, unitOut
    
    def lookUpInVariList(self, nameOfVar: str, nameOfUnit: str) -> int:
        found = 0
        for i in range(self.numVari):
            if self.makeLowerCase(nameOfVar) == self.makeLowerCase(self.vari[i].varName):
                if self.makeLowerCase(nameOfUnit) == self.makeLowerCase(self.conv[self.vari[i].convPt-1].siUnit):
                    found = i + 1
                    break
        
        if found > 0:
            return self.vari[found-1].convPt
        else:
            return 0
    
    def lookUpUsingWild(self, nameOfVar: str, nameOfUnit: str) -> int:
        found = 0
        for i in range(self.numWild):
            locOfString = self.makeLowerCase(nameOfVar).find(self.makeLowerCase(self.wild[i].matchStr))
            if locOfString >= 0:
                if self.makeLowerCase(nameOfUnit) == self.makeLowerCase(self.conv[self.wild[i].convPt-1].siUnit):
                    found = i + 1
                    break
        
        if found > 0:
            return self.wild[found-1].convPt
        else:
            return 0
    
    def lookupDefaultUnit(self, nameOfUnit: str) -> int:
        found = 0
        for i in range(self.numConv):
            if self.makeLowerCase(nameOfUnit) == self.makeLowerCase(self.conv[i].siUnit):
                found = i + 1
                break
        return found
    
    def ConvertDictionLine(self, esoLine: str, indexDiction: int) -> str:
        convIndex = self.diction[indexDiction-1].convPt
        findString = '[' + self.conv[convIndex-1].siUnit + ']'
        replaceString = '[' + self.conv[convIndex-1].ipUnit + ']'
        
        newesoline = esoLine
        found = newesoline.find(findString)
        while found >= 0:
            part1Line = newesoline[0:found]
            part2Line = newesoline[found+len(findString):]
            newesoline = part1Line + replaceString + part2Line
            found = newesoline.find(findString)
        
        return newesoline
    
    def convertEPLUSOUTESO(self):
        while True:
            lineOfESO = self.file2.readline()
            if not lineOfESO:
                break
            lineOfESO = lineOfESO.rstrip('\n\r')
            if lineOfESO == 'End of Data':
                self.file3.write(lineOfESO + '\n')
                lineOfESO = self.file2.readline()
                if lineOfESO:
                    lineOfESO = lineOfESO.rstrip('\n\r')
                    self.file3.write(lineOfESO + '\n')
                break
            
            oldParts = self.split(lineOfESO, ',')
            numParts = len(oldParts)
            
            try:
                dictionIndex = int(oldParts[0])
            except:
                dictionIndex = 0
            
            if dictionIndex < self.sizeDiction:
                if dictionIndex > 0 and dictionIndex <= self.dictionNum and self.diction[dictionIndex-1].isValid:
                    if self.diction[dictionIndex-1].isPassThru:
                        self.file3.write(lineOfESO + '\n')
                    else:
                        convIndex = self.diction[dictionIndex-1].convPt
                        newParts = oldParts.copy()
                        
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
                        
                        lineOfESO = ','.join(newParts)
                        self.file3.write(lineOfESO + '\n')
                else:
                    self.reportError(f'Invalid dictionary reference on line: {lineOfESO}')
            else:
                self.reportError(f'Unknown dictionary reference on line: {lineOfESO}')
    
    def convertPart(self, numAsString: str, indexConv: int) -> str:
        try:
            oldNumAsReal = float(numAsString)
        except:
            return numAsString
        
        newNumAsReal = oldNumAsReal * self.conv[indexConv-1].mult + self.conv[indexConv-1].offset
        return str(newNumAsReal)
    
    def run(self):
        time_start = time.time()
        
        numcmdargs = len(sys.argv) - 1
        filename1 = 'eplusout.eso'
        filename2 = 'eplusout.mtr'
        
        if numcmdargs >= 1:
            filename1 = sys.argv[1]
        if numcmdargs >= 2:
            filename2 = sys.argv[2]
        
        file1exist = os.path.exists(filename1)
        file2exist = os.path.exists(filename2)
        
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
        
        convertread = False
        
        try:
            self.file4 = open('ip.err', 'w')
        except:
            print('could not open ip.err')
            sys.exit(1)
        
        if file1exist:
            file1ok = True
            errcount = self.errorCounter
            ext1 = self.getFileExt(filename1)
            if errcount != self.errorCounter:
                self.file4.close()
                sys.exit(1)
            
            try:
                self.file2 = open(filename1, 'r')
            except:
                self.file4.write(f'could not open file={filename1}\n')
                file1ok = False
            
            try:
                self.file3 = open('ip.' + ext1, 'w')
            except:
                self.file4.write(f'could not open file=ip.{ext1}\n')
                file1ok = False
            
            if file1ok:
                self.sizeDiction = 50000
                for _ in range(self.sizeDiction):
                    self.diction.append(DictionType())
                self.readESOtoIPfile()
                convertread = True
                
                self.readESOdictionary()
                self.convertEPLUSOUTESO()
                self.file3.close()
                self.file2.close()
        
        self.processingESO = False
        self.diction = []
        
        time_finish = time.time()
        elapsed_time = time_finish - time_start
        
        hours = int(elapsed_time / 3600.0)
        elapsed_time = elapsed_time - hours * 3600
        minutes = int(elapsed_time / 60.0)
        elapsed_time = elapsed_time - minutes * 60
        seconds = elapsed_time
        
        elapsed_str = f'{hours:02d}hr {minutes:02d}min {seconds:05.2f}sec'
        print(f'convertESOMTR Run Time={elapsed_str} file={filename1}')
        
        time_start = time.time()
        
        self.dictionNum = 0
        self.sizeDiction = 20000
        self.diction = []
        for _ in range(self.sizeDiction):
            self.diction.append(DictionType())
        
        if file2exist:
            file2ok = True
            errcount = self.errorCounter
            ext2 = self.getFileExt(filename2)
            if errcount != self.errorCounter:
                self.file4.close()
                sys.exit(1)
            
            try:
                self.file2 = open(filename2, 'r')
            except:
                self.file4.write(f'could not open file={filename2}\n')
                file2ok = False
            
            try:
                self.file3 = open('ip.' + ext2, 'w')
            except:
                self.file4.write(f'could not open file=ip.{ext2}\n')
                file2ok = False
            
            if file2ok:
                if not convertread:
                    self.readESOtoIPfile()
                self.readESOdictionary()
                self.convertEPLUSOUTESO()
                self.file3.close()
                self.file2.close()
        
        time_finish = time.time()
        elapsed_time = time_finish - time_start
        
        hours = int(elapsed_time / 3600.0)
        elapsed_time = elapsed_time - hours * 3600
        minutes = int(elapsed_time / 60.0)
        elapsed_time = elapsed_time - minutes * 60
        seconds = elapsed_time
        
        elapsed_str = f'{hours:02d}hr {minutes:02d}min {seconds:05.2f}sec'
        print(f'convertESOMTR Run Time={elapsed_str} file={filename2}')
        
        if self.errorCounter == 0:
            try:
                os.remove('ip.err')
            except:
                pass
        
        self.file4.close()

if __name__ == '__main__':
    converter = ESOtoIPConverter()
    converter.run()
