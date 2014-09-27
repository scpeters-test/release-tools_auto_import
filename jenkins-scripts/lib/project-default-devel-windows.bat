REM Windows standard file to build Visual Studio projects

IF %PLATFORM_TO_BUILD% == x86 (
  echo "Using 32bits VS configuration"
  set VS_CMAKE_GEN=%VS32bits_CMAKE_GEN%
) ELSE (
  echo "Using 64bits VS configuration"
  set VS_CMAKE_GEN=%VS64bits_CMAKE_GEN%
)

REM Configure the VC++ compilation
"C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" %PLATFORM_TO_BUILD%

echo %WORKSPACE%
cd %WORKSPACE%
REM Reset the build directory if exists
if exist build ( rmdir build /s /q )
mkdir build
cd build
echo "Current directory: %cd%"

echo "cmake .. %VS_CMAKE_GEN% %VS_DEFAULT_CMAKE_FLAGS% %ARG_CMAKE_FLAGS%"
cmake .. %VS_CMAKE_GEN% %VS_DEFAULT_CMAKE_FLAGS% %ARG_CMAKE_FLAGS%

msbuild %VS_DEFAULT_MSBUILD_FLAGS% ALL_BUILD.vcxproj
