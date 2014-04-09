#
# This script should be run on a fork of gazebo3_ros_pkgs-release repository
# and will modify control.em bloom templates for:
#
#   - Rename the Package name to $(Package)3
#   - Define a conflict on the same $(Package)
#
# It will commit and push the hydro and groovy branches

PKGS="gazebo_plugins gazebo_msgs gazebo_ros gazebo_ros_control gazebo_ros_pkgs"
DISTROS="groovy hydro"

for pkg in ${PKGS}; do
    for distro in ${DISTROS}; do
	if [[ $pkg == "gazebo_ros_control" ]] && [[ $distro == "groovy" ]]; then
	    continue
	fi
	echo " - Processing $pkg in $distro"
        git checkout debian/$distro/$pkg
	# Modify package name
	sed -i -e "s/Package: @(Package)/Package: @(Package.replace('gazebo-','gazebo3-'))/" debian/control.em
	git commit debian/control.em -m "Patch name to release -3 version"
	# Include conflict with same package (not current)
	sed -i -e '/^Depends/aConflicts: @(Package), @(Package)-current' debian/control.em
	git commit debian/control.em -m "Set up a conflict with standard ROS pkg and -current version"
	git push origin debian/$distro/$pkg
    done
done
