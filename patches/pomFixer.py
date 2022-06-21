"""
This script provides functions to fix the poms of maven versions of defects4j projects v1.2.0.
"""

import os
import re
import shutil
import subprocess as sp
import xml.etree.ElementTree as et


def parseNamespace(element):
    m = re.match(r'\{.*\}', element.tag)
    return m.group(0) if m else None


def indent(elem, level=0):
    i = "\n" + level*"  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            indent(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i


def parsePom(pomPath:str):
    if not pomPath.endswith("pom.xml"):
        print("[ERROR] {} is not a pom file.".format(pomPath))
        return False
    elif not os.path.isfile(pomPath):
        print("[ERROR] {} does not exist.".format(pomPath))
        return False

    tree = et.parse(pomPath)
    root = tree.getroot()

    # to remove ns0 when printing
    ns = parseNamespace(root)
    et.register_namespace('', ns[1:-1])
    if ns is None:
        print("[ERROR] Can not parse namespace of {}.".format(pomPath))
        return None, None
    return tree, ns


def closureChangeMockitoDep(pomPath: str, outputPath: str):
    tree, ns = parsePom(pomPath)
    if not tree:
        return False
    root = tree.getroot()
    foundDep = False
    deps = root.find("./{}dependencies".format(ns))
    if deps is not None:
        for dep in deps.findall("./{}dependency".format(ns)):
            gid = dep.find("./{}groupId".format(ns))
            aid = dep.find("./{}artifactId".format(ns))
            if gid is not None and gid.text == 'mockito' and aid is not None and aid.text == 'mockito':
                foundDep = True
                deps.remove(dep)
                newMockitoDep = et.SubElement(deps, 'dependency')
                mktGid = et.SubElement(newMockitoDep, 'groupId')
                mktGid.text = 'org.mockito'
                mktAid = et.SubElement(newMockitoDep, 'artifactId')
                mktAid.text = 'mockito-all'
                mktVersion = et.SubElement(newMockitoDep, 'version')
                mktVersion.text = '1.10.19'
                indent(newMockitoDep, level=4)
                print('Mockito dependency changed: {}'.format(pomPath))
                break
    if not foundDep:
        print('Dependency mockito:mockito not found in {}'.format(pomPath))
    tree.write(outputPath, 'UTF-8')
    return True


def closureChangeProtobufDepToLocalJar(projectPath: str, pomPath: str, outputPath: str):
    tree, ns = parsePom(pomPath)
    if not tree:
        return False
    root = tree.getroot()

    localProtobufJarPath = None
    for file in os.listdir(os.path.join(projectPath, 'lib')):
        if file.endswith('.jar') and 'proto' in file:
            localProtobufJarPath = '${project.basedir}/lib/' + file
    if localProtobufJarPath is None:
        print('[WARNING] No protobuf jar found in {}'.format(os.path.join(projectPath, 'lib')))
        return True

    foundDep = False
    deps = root.find("./{}dependencies".format(ns))
    if deps is not None:
        for dep in deps.findall("./{}dependency".format(ns)):
            gid = dep.find("./{}groupId".format(ns))
            aid = dep.find("./{}artifactId".format(ns))
            if gid is not None and gid.text == 'com.google.protobuf' \
                    and aid is not None and aid.text == 'protobuf-java':
                foundDep = True
                if dep.find("./{}scope".format(ns)) is None\
                        and dep.find("./{}systemPath".format(ns)) is None:
                    scope = et.SubElement(dep, 'scope')
                    scope.text = 'system'
                    systemPath = et.SubElement(dep, 'systemPath')
                    systemPath.text = localProtobufJarPath
                    print('Protobuf dependency changed: {}'.format(pomPath))
                break
    if not foundDep:
        print('Dependency com.google.protobuf:protobuf-java not found in {}'.format(pomPath))
    tree.write(outputPath, 'UTF-8')
    return True


def mockitoChangeFestDepVersion(projectPath: str, pomPath: str, outputPath: str):
    tree, ns = parsePom(pomPath)
    if not tree:
        return False
    root = tree.getroot()

    festVersion = None
    for file in os.listdir(os.path.join(projectPath, 'lib', 'test')):
        if file.endswith('.jar') and 'fest-assert' in file:
            festVersion = file[12:-4]
    if festVersion is None:
        print('[WARNING] No fest-assert jar found in {}'.format(os.path.join(projectPath, 'lib')))
        return True

    foundDep = False
    deps = root.find("./{}dependencies".format(ns))
    if deps is not None:
        for dep in deps.findall("./{}dependency".format(ns)):
            gid = dep.find("./{}groupId".format(ns))
            aid = dep.find("./{}artifactId".format(ns))
            if gid is not None and gid.text == 'org.easytesting' \
                    and aid is not None and aid.text == 'fest-assert':
                foundDep = True
                version = dep.find("./{}version".format(ns))
                if version is None:
                    version = et.SubElement(dep, 'version')
                version.text = festVersion
                print('fest-assert dependency changed: {}'.format(pomPath))
                break
    if not foundDep:
        print('Dependency org.easytesting:fest-assert not found in {}'.format(pomPath))
    tree.write(outputPath, 'UTF-8')
    return True

def changePomOutputDirAsSameAsD4j(projectPath: str, pomPath: str, outputPath: str):

    tree, ns = parsePom(pomPath)
    if not tree:
        return False
    root = tree.getroot()

    classesTargetDirPath = sp.check_output("defects4j export -p dir.bin.classes 2> /dev/null", shell=True, cwd=projectPath, universal_newlines=True).strip()
    testsTargetDirPath = sp.check_output("defects4j export -p dir.bin.tests 2> /dev/null", shell=True, cwd=projectPath, universal_newlines=True).strip()

    build = root.find("./{}build".format(ns))
    outputDir = build.find("./{}outputDirectory".format(ns))
    testOutputDir = build.find("./{}testOutputDirectory".format(ns))
    if outputDir is None:
        outputDir = et.SubElement(build, 'outputDirectory')
    if testOutputDir is None:
        testOutputDir = et.SubElement(build, 'testOutputDirectory')
    print('===== {} ====='.format(pomPath))
    changed = False
    if outputDir.text != classesTargetDirPath:
        print('Changing outputDirectory from {} to {}'.format(outputDir.text, classesTargetDirPath))
        outputDir.text = classesTargetDirPath
        changed = True
    if testOutputDir.text != testsTargetDirPath:
        print('Changing testOutputDirectory from {} to {}'.format(testOutputDir.text, testsTargetDirPath))
        testOutputDir.text = testsTargetDirPath
        changed = True
    if changed:
        tree.write(outputPath, 'UTF-8')
    return True

if __name__ == '__main__':
    # closureChangeMockitoDep('closure-107.pom.xml', 'closure-107.pom.xml.out')

    # change the outputDir in poms for all projects
    d4j_mvn_projects_dir_path = '/home/yicheng/apr/d4jMvn/Projects/'
    for pid in os.listdir(d4j_mvn_projects_dir_path):
        if not os.path.isdir('{}/{}'.format(d4j_mvn_projects_dir_path, pid)):
            continue
        # if pid != 'Mockito':
        #     continue
        for bid in os.listdir('{}/{}'.format(d4j_mvn_projects_dir_path, pid)):
            if not os.path.isdir('{}/{}/{}'.format(d4j_mvn_projects_dir_path, pid, bid)):
                continue
            projectPath = '{}/{}/{}/'.format(d4j_mvn_projects_dir_path, pid, bid)
            pomPath = '{}/{}/{}/pom.xml'.format(d4j_mvn_projects_dir_path, pid, bid)
            if not os.path.isfile(pomPath + '.bak'):
                shutil.copy(pomPath, pomPath + '.bak')
            else:
                shutil.copy(pomPath + '.bak', pomPath)
            changePomOutputDirAsSameAsD4j(projectPath, pomPath, pomPath)
