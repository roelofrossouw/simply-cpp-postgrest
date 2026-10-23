#!/bin/bash
#~~~~~~~~~~
# Downloads the pinned PostgREST release (its official static Linux build), checks it against
# SHA256.txt, packages it as the simply-cpp-postgrest .deb, and publishes it into the apt repo for
# every distribution. The binary is statically linked, so one build covers jammy/noble/resolute
# alike - run this on any one build server (deploy.sh defaults to build-noble).
#
# Run this in the directory deploy.sh synced it to (/var/www/build/sc-postgrest).

set -euo pipefail

version=$(tr -d ' \t\n' < VERSION.txt)
checksum=$(tr -d ' \t\n' < SHA256.txt)
tarball="postgrest-v${version}-linux-static-x86-64.tar.xz"
url="https://github.com/PostgREST/postgrest/releases/download/v${version}/${tarball}"
licence_url="https://raw.githubusercontent.com/PostgREST/postgrest/v${version}/LICENSE"
package="simply-cpp-postgrest"
# A packaging revision (REVISION.txt) when the same upstream version is packaged again:
# 13.0.7-1 sorts after 13.0.7.
revision=$( [ -f REVISION.txt ] && tr -d ' \t\n' < REVISION.txt || true)
package_version="${version}${revision:+-$revision}"
deb_file="${package}_${package_version}_amd64.deb"

mkdir -p work
if [ ! -f "work/$tarball" ]; then
    echo "Downloading $url"
    wget -q -O "work/$tarball.part" "$url"
    mv "work/$tarball.part" "work/$tarball"
fi
# The release as published, or nothing: SHA256.txt is the checksum of the tarball that was checked
# when VERSION.txt was set.
if ! echo "$checksum  work/$tarball" | sha256sum -c --quiet -; then
    echo "$tarball doesn't match SHA256.txt: not packaged" >&2
    rm -f "work/$tarball"
    exit 1
fi
if [ ! -f "work/LICENSE-$version" ]; then
    wget -q -O "work/LICENSE-$version" "$licence_url"
fi

rm -rf pkg work/extracted
mkdir -p pkg/DEBIAN pkg/usr/bin work/extracted
tar xJf "work/$tarball" -C work/extracted
install -m 755 work/extracted/postgrest pkg/usr/bin/postgrest

cat > pkg/DEBIAN/control <<EOF
Package: $package
Version: $package_version
Architecture: amd64
Section: database
Priority: optional
Maintainer: Roelof Rossouw
Homepage: https://postgrest.org
Description: PostgREST, a REST API for a PostgreSQL database, packaged for apt
 PostgREST $version's official static Linux build, installed as /usr/bin/postgrest,
 so it can be installed like any other package instead of copied by hand. It
 serves a PostgreSQL database's schema as a REST API; give it a configuration
 file: postgrest /etc/postgrest.conf.
EOF

# copyright: upstream's licence, which it asks to ship with the binary, where Debian keeps one
# (/usr/share/doc/<package>/copyright).
install -d "pkg/usr/share/doc/$package"
{
    echo "$package packages PostgREST $version (https://github.com/PostgREST/postgrest), licensed under MIT."
    echo "The packaging scripts (https://github.com/roelofrossouw/simply-cpp-postgrest) are Apache-2.0."
    echo
    echo "----- PostgREST: LICENSE -----"
    cat "work/LICENSE-$version"
} > "pkg/usr/share/doc/$package/copyright"

# The binary runs: a broken download or a build for another machine stops here.
pkg/usr/bin/postgrest --version

dpkg-deb --build --root-owner-group pkg "$deb_file"

pushd /var/www/build/repo >/dev/null
export GNUPGHOME=/var/www/build/signing
for dist in jammy noble resolute; do
    if reprepro list "$dist" | grep -q "$package .*$package_version"; then
        echo "$dist: $package $package_version already published"
    else
        echo "$dist: publishing $package $package_version"
        reprepro remove "$dist" "$package" || true
        reprepro includedeb "$dist" "/var/www/build/sc-postgrest/$deb_file"
    fi
done
popd >/dev/null

echo "Done."
