REM Windows standard file

call "c:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat"
echo %WORKSPACE%
cd %WORKSPACE%
mkdir build
cd build
REM Remeber to pass the generator for a proper Win64 built
cmake .. -G"Visual Studio 12 Win64" -DCMAKE_BUILD_TYPE:STRING="Release" -DBOOST_ROOT:STRING="C:\local\boost_1_55_0" -DBOOST_LIBRARYDIR:STRING="C:\local\boost_1_55_0\lib64-msvc-12.0"

msbuild ALL_BUILD.vcxproj

REM Need to find a way of running test from msbuild passing ARGS=-VV
ctest -C "Release" --extra-verbose || true
