#!/usr/bin/env bats

RECYCLEBIN="$HOME/.deleted"
RESTOREFILE="$HOME/.restore.info"

@test "Returns error when no argument given" {
	run bash safe_rm
	[ "$status" -eq 1 ]
	[ "${lines[0]}" = "safe_rm: missing operand" ]
	[ "${lines[1]}" = "Try 'safe_rm --help' for more information." ]
}

@test "Returns error when argument is not a file" {
	run mkdir somedir
	run bash safe_rm somedir
	[ "$status" -eq 1 ]
	[ "$output" = "safe_rm: cannot remove 'somedir/': Is a directory" ]
}

@test "Returns error when trying to remove non-existing file" {
	run touch file1
	run rm file1
	run bash safe_rm file1
	[ "$status" -eq 1 ]
	[ "$output" = "safe_rm: cannot remove 'file1': No such file or directory" ]
}

@test "Returns error when trying to remove itself" {
	run cd $HOME/safe_rm
	run bash safe_rm safe_rm
	[ "$status" -eq 1 ]
	[ "$output" = "safe_rm: cannot remove itself" ]
}

@test "should move a file to $RECYCLEBIN and create an entry in $RESTOREFILE" {
	run bash cleanup
	run touch somefile

	run bash safe_rm somefile

	[ "$status" -eq 0 ]
	[ "$output" = "" ]
	[ ! -e somefile ]
	[ -e $RECYCLEBIN/somefile_* ]
	run egrep '^somefile_' $RESTOREFILE
	[ "$status" -eq 0 ]
}

@test "Should safe delete a file in the same directory" {
	run touch somefile
	run bash safe_rm somefile
	[ "$status" -eq 0 ]
	[ "$output" = "" ]
	run find . somefile
	[ "$status" -ne 0 ]
}

@test "Should safe delete a file in a child directory" {}

@test "Should safe delete a file in a parent directory" {}

#@test "Should delete two files"

@test "Not a test, just cleaninup" {
	run bash cleanup
}
