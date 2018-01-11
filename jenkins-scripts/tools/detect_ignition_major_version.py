#!/usr/bin/env python
from __future__ import print_function
import re
import sys

if len(sys.argv) != 2:
    print('need to specify location of CMakeLists.txt', file=sys.stderr)
    exit()
fileName = sys.argv[1]

f = open(fileName, 'r')
txt = f.read()
f.close()

old_version = re.search('set *\( *PROJECT_MAJOR_VERSION +(\d+)', txt)
ign_cmake_version = re.search('project *\( *ignition-[a-z\-]+(\d+)', txt)
if old_version:
    print(old_version.group(1) )
elif ign_cmake_version:
    print(ign_cmake_version.group(1))
else:
    sys.exit("could not detect the major version")
