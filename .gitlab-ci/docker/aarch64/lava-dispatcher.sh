#!/bin/sh

set -e

if [ "$1" = "setup" ]
then
  set -x
  docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
  apk add git python3
else
  set -x

  # Build the image tag
  if [ -n "$CI_COMMIT_TAG" ]
  then
    IMAGE_TAG="$IMAGE_TAG:$CI_COMMIT_TAG"
  else
    IMAGE_TAG="$IMAGE_TAG:$(./version.py)-$CI_COMMIT_REF_SLUG"
  fi

  git clone https://git.lavasoftware.org/lava/pkg/docker.git
  pkg_lxc=$(find _build -name "lava-lxc-mocker_*.deb")
  pkg_common=$(find _build -name "lava-common_*.deb")
  pkg_dispatcher=$(find _build -name "lava-dispatcher_*arm64.deb")
  cp $pkg_lxc docker/aarch64/lava-dispatcher/lava-lxc.deb
  cp $pkg_common docker/aarch64/lava-dispatcher/lava-common.deb
  cp $pkg_dispatcher docker/aarch64/lava-dispatcher/lava-dispatcher.deb
  docker build -t $IMAGE_TAG docker/aarch64/lava-dispatcher

  # Push only for tags or master
  if [ "$CI_COMMIT_REF_SLUG" = "master" -o -n "$CI_COMMIT_TAG" ]
  then
    docker push $IMAGE_TAG
  fi
fi
