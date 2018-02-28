#!/bin/sh

CONFDIR="/etc/conf.d"
LIBEXECDIR="/lib/netifrc/sh"
INITDIR="/etc/init.d"
INIT=systemd

usage() {
  echo "netifrc systemd wrapper"
  echo "Usage:"
  echo "  systemd-wrapper.sh -i <interface> <command>"
  echo "  where command is start|stop"
}

die() {
  echo "$@"
  exit 1
}

while getopts "i:" opt; do
  case $opt in
	i)
		RC_IFACE=$OPTARG;;
  esac
done
shift $((OPTIND -1))

[ -z "$RC_IFACE" ] && die "Missing Parameter Interface"

RC_SVCPREFIX="net"
RC_SVCNAME="$RC_SVCPREFIX"."$RC_IFACE"
RC_UNAME=$(uname)
# XXX Find out the systemd way of doing this
RC_GOINGDOWN=no

# In Openrc systems this has value /run/openrc
SVCDIR="/run/netifrc"
# OpenRC saves values in $SVCDIR/options/$SVCNAME/$OPTION
# In non OpenRC setting this is saved in /run/netifrc/options/$SVCNAME/$OPTION
OPTIONSDIR="${SVCDIR}/options/${RC_SVCNAME}"
STATEDIR="${SVCDIR}/${RC_SVCNAME}"

# Source the config file
if [ -f "$CONFDIR/$RC_SVCPREFIX" ]; then
	. "$CONFDIR/$RC_SVCPREFIX"
fi

# Source the actual runscript
if [ -f "$INITDIR/${RC_SVCPREFIX}.lo" ]; then
	. "$INITDIR/${RC_SVCPREFIX}.lo"
else
	die "$INITDIR/${RC_SVCPREFIX}.lo : Init file missing or invalid path"
fi

netifrc_init() {
	# Ensure OPTIONSDIR is present and writeable
	mkdir -p "$OPTIONSDIR"
	if [ ! -w "$OPTIONSDIR" ]; then
		eerror "${OPTIONSDIR} does not exist or is not writeable"
		exit 1
	fi
	# Ensure STATEDIR is present and writeable
	mkdir -p "$STATEDIR"
	if [ ! -w "$STATEDIR" ]; then
		eerror "${STATEDIR} does not exist or is not writeable"
		exit 1
	fi
}

netifrc_cleanup() {
	# Delete all the saved values
	rm -f ${OPTIONSDIR}/*
}

rc=0
case $1 in
	start)
		netifrc_init
		start
		rc=$?;;
	stop)
		stop
		netifrc_cleanup
		rc=$?;;
	*)
		die "Unrecognised command $1";;
esac
exit $rc

# vi: ts=4 sw=4 noexpandtab
