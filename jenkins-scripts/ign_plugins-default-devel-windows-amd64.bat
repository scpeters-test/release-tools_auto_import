set SCRIPT_DIR="%~dp0"

set VCS_DIRECTORY=ign-plugins
set PLATFORM_TO_BUILD=x86_amd64
set IGN_CLEAN_WORKSPACE=true

set DEPEN_PKGS="qt5 tinyxml2"
set COLCON_PACKAGE=ignition-plugins
set COLCON_AUTO_MAJOR_VERSION=true

call "%SCRIPT_DIR%/lib/generic-default-devel-windows.bat"
