#!/usr/bin/env bats

RECYCLEBIN="$HOME/.deleted"
RESTOREFILE="$HOME/.restore.info"
safe_rm="$HOME/safe_rm/safe_rm"
safe_rm_restore="$HOME/safe_rm/safe_rm_restore"
cleanup="$HOME/safe_rm/test_scripts/cleanup"

function setup() {
	cd $HOME/safe_rm/tests
	run bash $cleanup
	run mkdir mockdata
	run touch mockdata/initfile
	run bash $safe_rm mockdata/initfile
}

@test "Returns error if recycle bin is empty" {
	cd $HOME/safe_rm/tests
	run bash $cleanup
	run bash $safe_rm_restore nonexistingentry_1234
	[ "$status" -eq 1 ]
	[ "$output" = "safe_rm_restore: recyle bin is empty" ]
}

@test "Returns error if no entry given" {
	setup
	run bash $safe_rm_restore
	[ "$status" -eq 1 ]
	[ "${lines[0]}" = "safe_rm_restore: missing operand" ]
	[ "${lines[1]}" = "Try 'safe_rm_restore --help' for more information." ]
}

@test "Returns error if entry does not exist" {
	setup
	run bash $safe_rm_restore nonexisting_12345
	[ -e $RESTOREFILE ]
	[ "$status" -eq 1 ]
	[ "$output" = "safe_rm_restore: no such entry 'nonexisting_12345' to restore" ]
}

@test "Restore a single file given exact entry" {
	setup
	entry=$(head -n 1 $RESTOREFILE)
	file=$(echo $entry | cut -d ":" -f1)

	[ ! -e mockdata/initfile ]
	[ -e $RECYCLEBIN/initfile_* ]

	run bash $safe_rm_restore $file

	[ ! -e $RECYCLEBIN/initfile_* ]
	[ -e mockdata/initfile ]
	[ ! $(egrep -q '^'$entry'$' $RESTOREFILE) ]
}
