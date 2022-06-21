"""
This script is to fix the maven version of the d4j v1.2.0 projects
"""

import os
import shutil
import subprocess as sp
from tkinter.tix import Tree
import pomFixer

d4jMvnProjDir = '/home/yicheng/apr/d4jMvn/Projects/'
pids = ['Chart', 'Lang', 'Math', 'Time', 'Closure', 'Mockito']

def logStart(pid, bid):
    print("================ Fixing {}-{} ================".format(pid, bid))

def applyPatch(pid, bid, projectPath: str, patchPath: str, fileToBackup: str):
    """All arguments should be absolute path"""
    if os.path.isfile(fileToBackup) and not os.path.isfile(fileToBackup + '.bak'):
        shutil.copy(fileToBackup, fileToBackup + '.bak')
    elif os.path.isfile(fileToBackup + '.bak') and os.path.isfile(fileToBackup):
        shutil.copy(fileToBackup + '.bak', fileToBackup)
    process = sp.Popen('cd {} && patch -N -p1 < {}'.format(projectPath, os.path.abspath(patchPath)),
                       shell=True, stderr=sp.PIPE, stdout=sp.PIPE, universal_newlines=True)
    stdout, stderr = process.communicate()
    exitCode = process.poll()
    succeed = True
    if exitCode != 0:
        print('[ERROR] Failed to fix {}-{}'.format(pid, bid))
        succeed = False
    print(stdout)
    print(stderr)
    print("\nRe-compiling...")
    reCompile(pid, bid, projectPath)
    return succeed


def reCompile(pid, bid, projectPath: str):
    sp.run('cd {} && mvn clean'.format(projectPath), shell=True, check=False)
    if pid == 'Closure' and bid == '106':
        process = sp.Popen('cd {} && mvn test-compile'.format(projectPath),
                       shell=True, stderr=sp.PIPE, stdout=sp.PIPE, universal_newlines=True)
    else:
        process = sp.Popen('cd {} && defects4j compile'.format(projectPath),
                        shell=True, stderr=sp.PIPE, stdout=sp.PIPE, universal_newlines=True)
    stdout, stderr = process.communicate()
    exitCode = process.poll()
    if exitCode != 0:
        print('[ERROR] Failed to re-compile {}-{}'.format(pid, bid))
    print(stdout)
    print(stderr)


def main():
    for pid in pids:
        pidDir = os.path.join(d4jMvnProjDir, pid)
        for bid in os.listdir(pidDir):
            projectPath = os.path.join(pidDir, bid)
            if not os.path.isdir(projectPath):
                continue
            if pid == 'Lang':
                logStart(pid, bid)
                targetFile = os.path.join(projectPath, 'src/test/org/apache/commons/lang/builder/StandardToStringStyleTest.java')
                applyPatch(pid, bid, projectPath, os.path.abspath('lang.patch'), targetFile)
                if bid == '64':
                    applyPatch(pid, bid, projectPath, os.path.abspath('lang64.patch'), targetFile)
            if pid == 'Math':
                logStart(pid, bid)
                targetFile = os.path.join(projectPath, 'src/test/java/org/apache/commons/math3/genetics/UniformCrossoverTest.java')
                suceed = applyPatch(pid, bid, projectPath, os.path.abspath('math.patch'), targetFile)
                if not suceed:
                    suceed = applyPatch(pid, bid, projectPath, os.path.abspath('math2.patch'), targetFile)
            if pid == 'Time':
                logStart(pid, bid)
                targetFile = os.path.join(projectPath, 'src/test/java/org/joda/time/TestDateTime_Basics.java')
                applyPatch(pid, bid, projectPath, os.path.abspath('time.patch'), targetFile)
            if pid == 'Closure':
                logStart(pid, bid)
                pomPath = os.path.join(projectPath, 'pom.xml')
                pomFixer.closureChangeMockitoDep(pomPath, pomPath)
                pomFixer.closureChangeProtobufDepToLocalJar(projectPath, pomPath, pomPath)
            if pid == 'Mockito':
                logStart(pid, bid)
                pomPath = os.path.join(projectPath, 'pom.xml')
                pomFixer.mockitoChangeFestDepVersion(projectPath, pomPath, pomPath)


if __name__ == '__main__':
    main()
    sp.run("cd /home/yicheng/apr/UniaprD4jConsistency/1.2.0/testConsistency && bash checkConsistency.sh &> checkConsistency.log", shell=True, check=False)
