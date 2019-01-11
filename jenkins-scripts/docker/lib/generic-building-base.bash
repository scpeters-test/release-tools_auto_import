echo '# BEGIN SECTION: setup the testing enviroment'
# Define the name to be used in docker
DOCKER_JOB_NAME="building_job"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh
echo '# END SECTION'

# Could be empty, just fine
if [[ "${BUILDING_PKG_DEPENDENCIES_VAR_NAME}" != "" ]]; then
  eval ARCHIVE_PROJECT_DEPENDECIES=\$${BUILDING_PKG_DEPENDENCIES_VAR_NAME}
fi

OSRF_REPOS_TO_USE=${BUILDING_JOB_REPOSITORIES}
DEPENDENCY_PKGS="${BASE_DEPENDENCIES} ${ARCHIVE_PROJECT_DEPENDECIES} ${BUILDING_DEPENDENCIES}"

[[ -z ${BUILD_IGN_MATH} ]] && BUILD_IGN_MATH=false
if $BUILD_IGN_MATH; then
  DEPENDENCY_PKGS="${DEPENDENCY_PKGS} ${IGN_MATH_DEPENDENCIES}"
fi

[[ -z ${BUILD_IGN_MSGS} ]] && BUILD_IGN_MSGS=false
if $BUILD_IGN_MSGS; then
  DEPENDENCY_PKGS="${DEPENDENCY_PKGS} ${IGN_MSGS_DEPENDENCIES}"
fi

[[ -z ${BUILD_IGN_TRANSPORT} ]] && BUILD_IGN_TRANSPORT=false
if $BUILD_IGN_TRANSPORT; then
  DEPENDENCY_PKGS="${DEPENDENCY_PKGS} ${IGN_TRANSPORT_DEPENDENCIES}"
fi

[[ -z ${BUILD_IGN_GAZEBO} ]] && BUILD_IGN_GAZEBO=false
if $BUILD_IGN_GAZEBO; then
  DEPENDENCY_PKGS="${DEPENDENCY_PKGS} ${IGN_GAZEBO_DEPENDENCIES}"
fi

[[ -z ${BUILD_IGN_GUI} ]] && BUILD_IGN_GUI=false
if $BUILD_IGN_GUI; then
  DEPENDENCY_PKGS="${DEPENDENCY_PKGS} ${IGN_GUI_DEPENDENCIES}"
fi

[[ -z ${BUILD_IGN_COMMON} ]] && BUILD_IGN_COMMON=false
if $BUILD_IGN_COMMON; then
  DEPENDENCY_PKGS="${DEPENDENCY_PKGS} ${IGN_COMMON_DEPENDENCIES}"
fi

[[ -z ${BUILD_IGN_SENSORS} ]] && BUILD_IGN_SENSORS=false
if $BUILD_IGN_SENSORS; then
  DEPENDENCY_PKGS="${DEPENDENCY_PKGS} ${IGN_SENSORS_DEPENDENCIES}"
fi

[[ -z ${BUILD_IGN_RENDERING} ]] && BUILD_IGN_RENDERING=false
if $BUILD_IGN_RENDERING; then
  DEPENDENCY_PKGS="${DEPENDENCY_PKGS} ${IGN_RENDERING_DEPENDENCIES}"
fi

[[ -z ${BUILD_SDFORMAT} ]] && BUILD_SDFORMAT=false
if $BUILD_SDFORMAT; then
  DEPENDENCY_PKGS="${DEPENDENCY_PKGS} ${SDFORMAT_BASE_DEPENDENCIES}"
fi

SOFTWARE_DIR="${BUILDING_SOFTWARE_DIRECTORY}"

. ${SCRIPT_DIR}/lib/_generic_linux_compilation_build.sh.bash

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
