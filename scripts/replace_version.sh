#!/bin/bash

last_release=$(git describe --tags --abbrev=0 main)

version_without_v="${last_release#v}"

IFS='+' read -r version base_increment <<< "$version_without_v"

IFS='.' read -r major minor patch <<< "$version"

next_patch=$((patch + 1))

new_version_no_build="v$major.$minor.$next_patch"

new_version_with_build="$new_version_no_build+$base_increment"

echo "version calculated: $new_version_no_build"

echo "VERSION=$new_version_no_build" >> $GITHUB_ENV

sed -i "s/^version: .*/version: $new_version_with_build/" pubspec.yaml
