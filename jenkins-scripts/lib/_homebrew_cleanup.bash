#/bin/bash +x
set -e

BREW_BINARY_DIR=/usr/local/bin
BREW_BINARY=${BREW_BINARY_DIR}/brew
${BREW_BINARY} up

# Clear all installed homebrew packages, links, taps, and kegs
BREW_LIST=$(${BREW_BINARY} list)
if [[ -n "${BREW_LIST}" ]]; then
  ${BREW_BINARY} remove --force ${BREW_LIST}
fi
rm -rf /usr/local/lib/python2.7/site-packages
# redirect error to /dev/null to avoid temporal problems detected by
# brew tap
for t in $(${BREW_BINARY} tap 2>/dev/null | grep -v '^homebrew/core$'); do
  ${BREW_BINARY} untap $t
done

pushd $(brew --prefix)/Homebrew/Library 2> /dev/null
git stash && git clean -d -f
popd 2> /dev/null

# test-bot needs variables and does not work just with config not sure why
export GIT_AUTHOR_NAME="OSRF Build Bot"
export GIT_COMMITTER_NAME=${GIT_AUTHOR_NAME}
export GIT_AUTHOR_EMAIL="osrfbuild@osrfoundation.org"
export GIT_COMMITTER_EMAIL=${GIT_AUTHOR_EMAIL}
git config --global user.name "${GIT_AUTHOR_NAME}"
git config --global user.email "${GIT_AUTHOR_EMAIL}"
