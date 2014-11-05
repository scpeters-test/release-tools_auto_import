set win_lib=%SCRIPT_DIR%\lib\windows_library.bat

:: Call vcvarsall and all the friends
call %win_lib% :configure_msvc_compiler

IF exist workspace ( rmdir /s /q workspace ) || goto %win_lib% :error
mkdir workspace 
cd workspace

echo "Download libraries"
call %win_lib% :wget http://packages.osrfoundation.org/win32/deps/cppzmq-noarch.zip cppzmq-noarch.zip
call %win_lib% :wget http://packages.osrfoundation.org/win32/deps/protobuf-2.6.0-win%BITNESS%-vc12.zip protobuf-2.6.0-win%BITNESS%-vc12.zip
call %win_lib% :wget http://packages.osrfoundation.org/win32/deps/zeromq-3.2.4-%PLATFORM_TO_BUILD%.zip zeromq-3.2.4-%PLATFORM_TO_BUILD%.zip

echo "Uncompressing libraries"
call %win_lib% :create_unzip_script
call %win_lib% :unzip cppzmq-noarch.zip
call %win_lib% :unzip protobuf-2.6.0-win%BITNESS%-vc12.zip
call %win_lib% :unzip zeromq-3.2.4-%PLATFORM_TO_BUILD%.zip

REM Note that your jenkins job should put source in %WORKSPACE%/ign-transport
echo "Move sources so we agree with configure.bat layout"
move %WORKSPACE%\ign-transport .
cd ign-transport

echo "Compiling"
mkdir build
cd build
call "..\configure.bat" Release %BITNESS% || goto %win_lib% :error
nmake || goto %win_lib% :error
nmake install || goto %win_lib% :error

if "%IGN_TEST_DISABLE%" == "TRUE" (
  echo "Running tests"
  REM Need to find a way of running test from the standard make test (not working)
  ctest -C "Release" --verbose --extra-verbose || exit 0
)
