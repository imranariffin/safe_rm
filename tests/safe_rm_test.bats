#!/usr/bin/env bats

RECYCLEBIN="$HOME/.deleted"
RESTOREFILE="$HOME/.restore.info"
safe_rm="$HOME/safe_rm/safe_rm"
cleanup="$HOME/safe_rm/test_scripts/cleanup"
create_dirs="$HOME/safe_rm/test_scripts/create_dirs"

function setup() {
	cd $HOME/safe_rm/tests
	run bash $cleanup
}

function teardown() {
	run bash $cleanup
	run rm -rf somedir dir
}

@test "Returns error when no argument given" {
	setup
	run bash $safe_rm
	[ "$status" -eq 1 ]
	[ "${lines[0]}" = "safe_rm: missing operand" ]
	[ "${lines[1]}" = "Try 'safe_rm --help' for more information." ]

	teardown
}

@test "Returns error when argument is not a file" {
	setup
	run mkdir somedir
	run bash $safe_rm somedir
	[ "$status" -eq 1 ]
	[ "$output" = "safe_rm: cannot remove 'somedir/': Is a directory" ]

	teardown
}

@test "Returns error when trying to remove non-existing file" {
	setup
	run touch file1
	run rm file1
	run bash $safe_rm file1
	[ "$status" -eq 1 ]
	[ "$output" = "safe_rm: cannot remove 'file1': No such file or directory" ]

	teardown
}

@test "Returns error when trying to remove itself" {
	setup
	run cd $HOME/safe_rm
	run bash $safe_rm $safe_rm
	[ "$status" -eq 1 ]
	[ "$output" = "safe_rm: cannot remove itself" ]

	teardown
}

@test "should move a file to $RECYCLEBIN and create an entry in $RESTOREFILE" {
	setup
	run bash cleanup
	run touch somefile

	run bash $safe_rm somefile

	[ "$status" -eq 0 ]
	[ "$output" = "" ]
	[ ! -e somefile ]
	[ -e $RECYCLEBIN/somefile_* ]
	run egrep '^somefile_' $RESTOREFILE
	[ "$status" -eq 0 ]

	teardown
}

@test "Should safe delete a file in the same directory" {
	setup
	run touch somefile

	run bash $safe_rm somefile

	[ "$status" -eq 0 ]
	[ "$output" = "" ]
	[ ! -e somefile ]

	teardown
}

@test "Should safe delete a file in a child directory" {
	setup
	run touch ../somefile
	[ -e ../somefile ]

	run bash $safe_rm ../somefile

	[ "$status" -eq 0 ]
	[ "$output" = "" ]
	[ ! -e ../somefile ]

	teardown
}

@test "Should safe delete a file in a parent directory" {
	setup
	run mkdir somedir
	run touch somedir/somefile
	[ -e somedir/somefile ]

	run bash $safe_rm somedir/somefile

	[ "$status" -eq 0 ]
	[ "$output" = "" ]
	[ ! -e somedir/somefile ]

	teardown
}

#@test "Should delete two files"

@test "should safe delete files with wildcard" {
	setup
	run touch file{1..5}
	[ $(ls file* 2> /dev/null | wc -l) -eq 5 ]
	[ $(ls $RECYCLEBIN/file*_ 2> /dev/null | wc -l) -eq 0 ]
	[ $(egrep '^file[0-9]_[0-9]*:' $RESTOREFILE | wc -l) -eq 0 ]
	run bash $safe_rm file*

	[ "$status" -eq 0 ]
	[ $(ls file* 2> /dev/null | wc -l) -eq 0 ]
	[ $(ls $RECYCLEBIN/file* 2> /dev/null | wc -l) -eq 5 ]
	[ $(egrep '^file[0-9]_[0-9]*:' $RESTOREFILE | wc -l) -eq 5 ]

	teardown
}

@test "Should be able to safe delete a folder recursively when given option '-r'" {
	setup
	run bash $create_dirs
	n=$(find dir 2> /dev/null | wc -l)

	run bash $safe_rm -r dir

	[ $(find dir 2> /dev/null | wc -l) -ne $n ]

	teardown
}

@test "Should be able to safe delete more than one folders recursively" {
	setup
	run bash $create_dirs
	n1=$(find dir/dir1 2> /dev/null | wc -l)
	n3=$(find dir/dir3 2> /dev/null | wc -l)

	run bash $safe_rm -r dir/dir1 dir/dir3

	[ $(find dir/dir1 2> /dev/null | wc -l) -ne $n1 ]
	[ $(find dir/dir3 2> /dev/null | wc -l) -ne $n3 ]

	teardown
}

@test "Should return error given option -r but no files/directory" {
	setup

	run bash $safe_rm -r

	[ "$status" -eq 1 ]
	[ "${lines[0]}" = "safe_rm: missing operand" ]
	[ "${lines[1]}" = "Try 'safe_rm --help' for more information." ]

	teardown
}

