# parameters:
# - TAP_PREFIX
# - BRANCH
# - PACKAGE_ALIAS
# - VERSION

# Can be defined outside the script. if not, default value is set
PR_URL_export_file=${PR_URL_export_file:-${WORKSPACE}/pull_request_created.properties}

echo '# BEGIN SECTION: check variables'
if [ -z "${BRANCH}" ]; then
  echo BRANCH not specified
  exit -1
fi
if [ -z "${PACKAGE_ALIAS}" ]; then
  echo PACKAGE_ALIAS not specified
  exit -1
fi
if [ -z "${TAP_PREFIX}" ]; then
  echo TAP_PREFIX not specified
  exit -1
fi
if [ -z "${VERSION}" ]; then
  echo VERSION not specified
  exit -1
fi
echo '# END SECTION'

GIT="git -C ${TAP_PREFIX}"

DIFF_LENGTH=`${GIT} diff | wc -l`
if [ ${DIFF_LENGTH} -eq 0 ]; then
  echo No formula modifications found, aborting
  exit -1
fi
echo ==========================================================
${GIT} diff
echo ==========================================================
echo '# END SECTION'

echo
echo '# BEGIN SECTION: commit and pull request creation'
${GIT} config user.name "OSRF Build Bot"
${GIT} config user.email "osrfbuild@osrfoundation.org"
${GIT} remote -v
# check if branch already exists
if git rev-parse --verify ${BRANCH} ; then
  ${GIT} checkout ${BRANCH}
else
  ${GIT} checkout -b ${BRANCH}
fi
${GIT} commit ${FORMULA_PATH} -m "${PACKAGE_ALIAS} ${VERSION}"
echo
${GIT} status
echo
${GIT} show HEAD
echo
${GIT} push -u fork ${BRANCH}


# Check for hub command
HUB=hub
if ! which ${HUB} ; then
  if [ ! -s hub-linux-amd64-2.2.3.tgz ]; then
    echo
    echo Downloading hub...
    wget -q https://github.com/github/hub/releases/download/v2.2.3/hub-linux-amd64-2.2.3.tgz
    echo Downloaded
  fi
  HUB=`tar tf hub-linux-amd64-2.2.3.tgz | grep /hub$`
  tar xf hub-linux-amd64-2.2.3.tgz ${HUB}
  HUB=${PWD}/${HUB}
fi

PR_URL=$(${HUB} -C ${TAP_PREFIX} pull-request \
  -b osrf:master \
  -h osrfbuild:${BRANCH} \
  -m "${PACKAGE_ALIAS} ${VERSION}${COMMIT_MESSAGE_SUFFIX}")

echo "Pull request created: ${PR_URL}"
# Exporting URL as an artifact (it will be used in other jobs)
echo "PULL_REQUEST_URL=${PR_URL}" > ${PR_URL_export_file}
echo "BRANCH=${BRANCH}" >> ${PR_URL_export_file}
echo '# END SECTION'
