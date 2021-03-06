#!/bin/sh

###################################################################
#
# This script will check whether the currently installed version
# of Flash Player matches that available from Adobe's servers. If
# the versions differ, it will download the latest version and
# install it.
#
# The variable DOWNLOAD_URL should be provided with, if necessary
# a placeholder for ${major_version} which will be interpolated
# before download.
#
# Date: @@DATE
# Version: @@VERSION
# Origin: @@ORIGIN
# Released by JSS User: @@USER
#
##################################################################

## URL pointing to a direct download of the Flash Player disk image
DOWNLOAD_URL="${4}"

ME=$(basename "${0}")

installed_version="$(defaults read /Library/Internet\ Plug-Ins/Flash\ Player.plugin/Contents/version CFBundleShortVersionString)"

available_version="$(/usr/bin/curl --silent http://fpdownload2.macromedia.com/get/flashplayer/update/current/xml/version_en_mac_pl.xml |\
                 grep 'update version' | sed -E 's/.*update version="([0-9,]+)".*/\1/;s/,/./g')"
                 
major_version=$(echo ${available_version} | awk -F '.' '{print $1}')

install_flash() {
  # Create a temporary directory in which to mount the .dmg
  tmp_mount=`/usr/bin/mktemp -d /tmp/flashplayer.XXXX`
  
  # Attach the install DMG directly from Adobe's servers (ensuring HTTPS)
  hdiutil attach "$( eval echo "${DOWNLOAD_URL}" )" -nobrowse -quiet -mountpoint "${tmp_mount}"
  
  # The package has used some slightly different naming schemes
  pkg_path="$(/usr/bin/find ${tmp_mount} -maxdepth 1 \( -iname \*Flash*\.pkg -o -iname \*Flash*\.mpkg \))"
  
  # Install the package, logging as much as we can
  /usr/sbin/installer -dumplog -verbose -pkg "${pkg_path}" -target "/"
  
  # Let things settle down
  sleep 1
  
  # Detach the dmg and remove the temporary mountpoint
  hdiutil detach "${tmp_mount}" && /bin/rm -rf "${tmp_mount}"
}

# If the version installed differs at all from the available version
# then we want to update

case "${installed_version}" in
  "${available_version}")
    echo "$ME: Flash version checked OK (${available_version})"
    ;;
  *) 
    echo "$ME: Flash version differs - installed: ${installed_version} available ${available_version}"
    install_flash
    ;;
esac

exit 0;
