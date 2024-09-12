#!/usr/bin/env sh
# Built with Any Install v1.0.2
# shellcheck shell=dash
# shellcheck disable=SC2039

set -eu

main() {

  install_dir="${ANY_INSTALL_EXAMPLE_INSTALL:-"${HOME}/.any-install-example"}"
  anyi_info "install_dir=${install_dir}"
  
  anyi_verify_install_dir "${install_dir}"
  
  url="https://raw.githubusercontent.com/opsbr/any-install-example/main/getting-started/example.sh"
  anyi_info "url=${url}"
  
  asset="${temp_dir}/example.sh"
  anyi_info "asset=${asset}"
  
  anyi_download "${url}" "${asset}"
  
  anyi_mkdir_p "${install_dir}"
  
  anyi_install_executable "${asset}" "${install_dir}/any-install-example"

}

# The following code is derived from Any Install.
# Copyright 2024 OpsBR Software Technology Inc. and contributors
# SPDX-License-Identifier: Apache-2.0


anyi_mktemp_d() {
  mktemp -d
}

anyi_rm_fr() {
  rm -fr "${1}"
}

anyi_info() {
  echo >&2 "${1}"
}

anyi_warn() {
  if [ -t 1 ]; then
    printf "%b" "\033[33m${1}\033[m\n" >&2
  else
    echo >&2 "${1}"
  fi
}

anyi_panic() {
  if [ -t 1 ]; then
    printf "%b" "\033[31m${1}\033[m\n" >&2
  else
    echo >&2 "${1}"
  fi
  exit 1
}

anyi_mkdir_p() {
  mkdir -p "${1}"
}

anyi_verify_install_dir() {
  local target_dir="${1}"
  local parent_dir
  parent_dir="$(dirname "${target_dir}")"
  if ! [ -e "${parent_dir}" ]; then
    anyi_panic "Install directory can't be created as its parent doesn't exist. Please create the parent directory first: ${parent_dir}"
  elif [ -e "${target_dir}" ]; then
    anyi_panic "Install directory already exits. Please make sure it's removed first: ${target_dir}"
  fi
}

anyi_get_os() {
  case "$(uname -s)" in
    'Darwin')
      echo 'macos'
      ;;
    'MINGW'*)
      echo 'windows'
      ;;
    'CYGWIN'*)
      echo 'windows'
      ;;
    *)
      echo 'linux'
      ;;
  esac
}

anyi_get_arch() {
  case "$(uname -m)" in
    'arm64' | 'aarch64')
      echo 'arm64'
      ;;
    *)
      echo 'x64'
      ;;
  esac
}

anyi_check_command() {
  ${1} > /dev/null 2> /dev/null
  return $?
}

anyi_download() {
  local url="${1}"
  local outfile="${2}"
  anyi_info "Downloading ${url} to ${outfile}"
  curl --fail --location --progress-bar --output "${outfile}" "${url}" \
    || anyi_panic "Failed to download from ${url}"
}

anyi_extract_zip() {
  unzip -q -o "${1}" -d "${2}" 1>&2
}

anyi_extract_tar_gz() {
  tar -xzf "${1}" -C "${2}" 1>&2
}

anyi_extract_tar_xz() {
  tar -xJf "${1}" -C "${2}" 1>&2
}

anyi_install_executable() {
  local src="${1}"
  local dst="${2}"
  local parent
  parent="$(dirname "${dst}")"
  [ -e "${src}" ] || anyi_panic "Source doesn't exist: ${src}"
  [ -e "${dst}" ] && anyi_panic "Destination exists: ${dst}"
  [ -e "${parent}" ] || anyi_panic "Destination's parent doesn't exist: ${parent}"
  cp -p "${src}" "${dst}"
  chmod +x "${dst}"
}

anyi_install_directory() {
  local src="${1}"
  local dst="${2}"
  local parent
  parent="$(dirname "${dst}")"
  [ -e "${src}" ] || anyi_panic "Source doesn't exist: ${src}"
  [ -e "${dst}" ] && anyi_panic "Destination exists: ${dst}"
  [ -e "${parent}" ] || anyi_panic "Destination's parent doesn't exist: ${parent}"
  cp -pr "${src}" "${dst}"
}

anyi_find_stripped_path() {
  local root="${1}"
  local depth="${2}"
  local i=0
  local children=0
  local stripped="${root%/}"
  child() { find "${stripped}" -maxdepth 1 -mindepth 1; }
  while [ "${i}" -lt "${depth}" ]; do
    i=$((i + 1))
    children=$(child | wc -l)
    if [ "${children}" -gt 1 ]; then
      anyi_panic "Too many children: \n$(child)"
    elif [ "${children}" -eq 0 ]; then
      anyi_panic "No more children at ${stripped}"
    fi
    stripped="${stripped}/$(basename "$(child)")"
  done
  echo "${stripped}"
}

temp_dir="$(anyi_mktemp_d)"
anyi_info "temp_dir=${temp_dir}"
trap 'anyi_rm_fr "${temp_dir}"' EXIT

main