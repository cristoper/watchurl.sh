#!/bin/bash
set -o pipefail

PROGNAME=$(basename "$0")

usage() {
	printf "%s\n" "$PROGNAME [--ping <healthchecks.io ID>] <url> <grep regex>"
}

case "$1" in
	-h|--help)
		usage
		exit 0
		;;
	-p|--ping)
		ping="$2"
		shift
		shift
		;;
	-*)
		echo "Invalid option '$1'. Use --help to see the valid options" >&2
		exit 1
		;;
esac

url=$1
regex=$2

if [[ -z $url ]]; then
    printf "Missing URL of page to check. Usage:\n"
    usage
    exit 1
fi

if [[ -z $regex ]]; then
    printf "Missing grep-compatible regex to check against URL's contents. Usage:\n"
    usage
    exit 1
fi

html=$(curl -sf "$url")
curlret=$?
if [[ $curlret -ne 0 ]]; then
    echo "curl error: $curlret" 1>&2
    if [[ -n "$ping" ]]; then
        curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/"${ping}"
    fi
    exit $?
fi

# Using herestring because piping to grep with set -o pipefail causes inconsistent results
# see https://github.com/koalaman/shellcheck/issues/665
if  grep -q "${regex}" <<<"${html}" ; then
    #echo "Found!" 1>&2
    if [[ -n "$ping" ]]; then
        curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/"${ping}"
    fi
    exit 0
else
    if [[ -n "$ping" ]]; then
        curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/"${ping}"/fail
    fi
    exit 1
fi
