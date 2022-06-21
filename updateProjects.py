"""
This versions of defects4j projects are kind of outdated. The newest defects4j has commented out some flaky tests. For example, com.google.javascript.jscomp.CrossModuleMethodMotionTest#testTwoMethods in Closure-1 is commented out by defects4j, and only an empty block of that test method is left.

This script tries to replace all the existing projects with the newest defects4j version, keeping the pom.xml only.
"""

import os
import shutil

d4j_projects_dir_path = '/home/yicheng/apr/d4jProj/'

for pid in os.listdir('Projects'):
    if not os.path.isdir('Projects/{}'.format(pid)):
        continue
    # print(pid)
    for bid in os.listdir('Projects/{}'.format(pid)):
        if not os.path.isdir('Projects/{}/{}'.format(pid, bid)):
            continue
        # print(bid)
        print("processing Projects/{}/{}".format(pid, bid))
        os.rename('Projects/{}/{}/pom.xml'.format(pid, bid), '/tmp/{}-{}.pom.xml'.format(pid, bid))
        shutil.rmtree('Projects/{}/{}'.format(pid, bid))
        shutil.copytree('{}/{}/{}'.format(d4j_projects_dir_path, pid, bid), 'Projects/{}/{}'.format(pid, bid))
        os.rename('/tmp/{}-{}.pom.xml'.format(pid, bid), 'Projects/{}/{}/pom.xml'.format(pid, bid))
        shutil.rmtree('Projects/{}/{}/.git'.format(pid, bid))
        
