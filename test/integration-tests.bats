in_container() {
  args=($*)
  docker exec -it "$CONTAINER" bash -l -c "${args[*]@Q}"
}

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'

  MY_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  SRCROOT=$(dirname "$MY_DIR")

  TAG="asdf-nodeapp-integration-bionic"
  CONTAINER="${TAG}-container"

  DOCKER_BUILDKIT=0 docker build \
    -f docker/bionic/Dockerfile \
    -t "$TAG" \
    "$SRCROOT" || return 1
  docker run --rm -d -it --init --name "$CONTAINER" "$TAG"
  in_container mkdir /root/.asdf/plugins || true
}

teardown() {
  docker stop "$CONTAINER"

  # wait for container to be _removed_
  # https://stackoverflow.com/a/57631771/4468
  while docker container inspect "$CONTAINER" >/dev/null 2>&1; do sleep 1; done
}

@test "install with system node no asdf" {

  # asdf nodejs is baked into the container, remove it first
  in_container asdf plugin remove nodejs || true

  run in_container which node
  assert_output --partial /usr/bin/node

  in_container asdf plugin add prettier /root/asdf-nodeapp
  in_container asdf install prettier 3.0.0
  in_container asdf global prettier 3.0.0
  in_container prettier --version

  run in_container ls /root/.asdf/installs/prettier/3.0.0/npm/bin/
  assert_output --partial prettier
}

@test "install with system node via asdf" {

  in_container asdf global nodejs system

  run in_container which node
  assert_output --partial /root/.asdf/shims/node

  in_container asdf plugin add prettier /root/asdf-nodeapp
  in_container asdf install prettier 3.0.0
  in_container asdf global prettier 3.0.0
  in_container prettier --version

  run in_container ls /root/.asdf/installs/prettier/3.0.0/npm/bin/
  assert_output --partial prettier
}

@test "install with asdf nodejs 18.17.0" {

  in_container asdf global nodejs 18.17.0

  run in_container which node
  assert_output --partial /root/.asdf/shims/node

  in_container asdf plugin add prettier /root/asdf-nodeapp
  in_container asdf install prettier 3.0.0
  in_container asdf global prettier 3.0.0
  in_container prettier --version

  run in_container ls /root/.asdf/installs/prettier/3.0.0/npm/bin/
  assert_output --partial prettier
}

@test "install with old nodejs version" {
  # we require node >= 16. asdf-nodeapp should detect that

  in_container asdf global nodejs 14.21.3

  run in_container which node
  assert_output --partial /root/.asdf/shims/node

  in_container asdf plugin add prettier /root/asdf-nodeapp

  run in_container asdf install prettier 3.0.0
  assert_output --partial "Failed to find node >= 16"
}

@test "check latest versions" {

  in_container asdf global nodejs 18.17.0

  in_container asdf plugin add prettier /root/asdf-nodeapp
  run in_container asdf list all prettier
  # TODO: "asdf list all" seems to mask return codes. It exits 0 even if we
  # exit nonzero in our function. So just check output for errors for now...
  refute_output --partial "asdf-nodeapp: [ERROR]"
}

@test "install bash-language-server" {

  in_container asdf global nodejs 18.17.0

  in_container asdf plugin add bash-language-server /root/asdf-nodeapp
  in_container asdf install bash-language-server latest
  in_container asdf global bash-language-server latest

  run in_container bash-language-server --help
  assert_success
}

@test "install scoped package @angular/cli" {

  in_container asdf global nodejs 18.17.0

  in_container asdf plugin add @angular/cli /root/asdf-nodeapp
  in_container asdf install @angular/cli latest
  in_container asdf global @angular/cli latest

  run in_container ng version
  assert_success
}
