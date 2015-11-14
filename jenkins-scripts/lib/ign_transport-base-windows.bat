ENABLEEXTENSIONS
:echo on

set win_lib=%SCRIPT_DIR%\lib\windows_library.bat
set TEST_RESULT_PATH2=%WORKSPACE%\test_results

:: Call vcvarsall and all the friends
echo # BEGIN SECTION: configure the MSVC compiler
call %win_lib% :configure_msvc_compiler
echo # END SECTION

if "%IGN_CLEAN_WORKSPACE%" == "" set IGN_CLEAN_WORKSPACE=false
@if "%BUILD_TYPE%" == "" set BUILD_TYPE=Release

if %IGN_CLEAN_WORKSPACE% == true (
  echo # BEGIN SECTION: preclean of workspace
  IF exist workspace ( rmdir /s /q workspace ) || goto :error
  echo # END SECTION
) else (
  echo # BEGIN SECTION: delete old sources
  IF exist workspace\ign-transport ( rmdir /s /q workspace\ign-transport ) || goto :error
  echo # END SECTION
)

mkdir %WORKSPACE%\workspace || echo "The workspace already exists. Fine"
cd %WORKSPACE%\workspace || goto :error

echo # BEGIN SECTION: downloading ign-transport dependencies and unzip
call %win_lib% :wget http://packages.osrfoundation.org/win32/deps/cppzmq-noarch.zip cppzmq-noarch.zip
call %win_lib% :wget http://packages.osrfoundation.org/win32/deps/protobuf-2.6.0-win%BITNESS%-vc12.zip protobuf-2.6.0-win%BITNESS%-vc12.zip
call %win_lib% :wget http://packages.osrfoundation.org/win32/deps/zeromq-3.2.4-%PLATFORM_TO_BUILD%.zip zeromq-3.2.4-%PLATFORM_TO_BUILD%.zip

call %win_lib% :download_7za
call %win_lib% :unzip_7za cppzmq-noarch.zip > cppzmq_7z.log || goto :error
call %win_lib% :unzip_7za protobuf-2.6.0-win%BITNESS%-vc12.zip > protobuf_7z.log || goto :error
call %win_lib% :unzip_7za zeromq-3.2.4-%PLATFORM_TO_BUILD%.zip > zeromq_7z.log || goto :error

echo # BEGIN SECTION: move sources so we agree with configure.bat layout
:: Remove code copy
IF EXIST %WORKSPACE%\workspace\ign-transport ( rmdir /s /q %WORKSPACE%\workspace\ign-transport ) || goto :error
xcopy %WORKSPACE%\ign-transport %WORKSPACE%\workspace\ign-transport /s /i /e > xcopy.log || goto :error
echo # END SECTION

echo # BEGIN SECTION: add zeromq to PATH for dll load
REM Add path for zeromq dynamic library .ddl
set PATH=%PATH%;%WORKSPACE%\workspace\ZeroMQ 3.2.4\bin\
echo # END SECTION

echo # BEGIN SECTION: ign-transport compilation in %BUILD_TYPE%
cd %WORKSPACE%\workspace\ign-transport || goto :error
mkdir build
cd build
call "..\configure.bat" %BUILD_TYPE% %BITNESS% || goto :error

nmake || goto :error
echo # END SECTION

echo # BEGIN SECTION: ign-transport installation
nmake install || goto :error
echo # END SECTION


if NOT "%IGN_TEST_DISABLE%" == "TRUE" (
  echo # BEGIN SECTION: run tests
  REM nmake test is not working test/ directory exists and nmake is not
  REM able to handle it.
  REM ctest -C "%BUILD_TYPE%" --force-new-ctest-process -VV  || echo "tests failed"
  echo # END SECTION
  
  echo # BEGIN SECTION: export testing results
  set TEST_RESULT_PATH=%WORKSPACE%\test_results
  set TEST_RESULT_PATH_LEGACY=%WORKSPACE%\build\test_results
  echo "PATH: %TEST_RESULT_PATH%"
  echo "PATH2: %TEST_RESULT_PATH2%"
  rmdir /q /s %TEST_RESULT_PATH%
  rmdir /q /s "%WORKSPACE%\test_results"
  set TEST_RESULT_PATH_LEGACY=%WORKSPACE%\build\test_results
  if exist %TEST_RESULT_PATH_LEGACY% ( rmdir /q /s %TEST_RESULT_PATH_LEGACY% )
  mkdir %WORKSPACE%\build\
  xcopy test_results %TEST_RESULT_PATH% /s /i /e || goto :error
  xcopy %TEST_RESULT_PATH% %TEST_RESULT_PATH_LEGACY% /s /e /i
  echo # END SECTION
)

if NOT DEFINED KEEP_WORKSPACE (
   echo # BEGIN SECTION: clean up workspace
   cd %WORKSPACE%
   rmdir /s /q %WORKSPACE%\workspace || goto :error
   echo # END SECTION
)

goto :EOF

:error - error routine
::
echo Failed with error #%errorlevel%.
exit /b %errorlevel%
