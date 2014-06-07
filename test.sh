#!/bin/sh -f

# fetched from github.com/jpace/svnx, then the .git directory removed
SRC_DIR=/proj/org/incava/tresync/test/fixtures

TRESYNC=/proj/org/incava/tresync/bin/tresync.rb

TEST_DIR=/tmp/tresync/testing

FROM_DIR=$TEST_DIR/from

FULL_DIR=$TEST_DIR/to/tresync
INCR_DIR=$TEST_DIR.1/to/tresync

CHANGED_COPIED_FILE=$FROM_DIR/backedup/b1.txt
CHANGED_IGNORED_FILE=$FROM_DIR/ignored/i1.txt

rm -rf $TEST_DIR
mkdir --parents $TEST_DIR

rm -rf $FULL_DIR
rm -rf $INCR_DIR

EXPECTED_DIFF_FILE=$TEST_DIR/expected_diff.txt
ACTUAL_DIFF_FILE=$TEST_DIR/actual_diff.txt

EXPECTED_FIND_FILE=$TEST_DIR/expected_find.txt
ACTUAL_FIND_FILE=$TEST_DIR/actual_find.txt

compare_diff() {
    what=$1
    from=$2
    to=$3
    shift; shift; shift
    output=$@

    echo "running: $what"

    echo $output > $EXPECTED_DIFF_FILE
    
    diff -r $from $to > $ACTUAL_DIFF_FILE

    cmp $EXPECTED_DIFF_FILE $ACTUAL_DIFF_FILE
    if [ "$?" -ne "0" ]; then
	echo "FAILED: $what"
	exit 1
    fi

    echo

    sleep 1
}

compare_find() {
    what=$1
    where=$2
    shift; shift
    files=$@

    echo "running: $what"

    echo -n "" > $EXPECTED_FIND_FILE

    for file in $files; do
	echo $file >> $EXPECTED_FIND_FILE
    done

    find $where | sort > $ACTUAL_FIND_FILE

    cmp $EXPECTED_FIND_FILE $ACTUAL_FIND_FILE
    if [ "$?" -ne "0" ]; then
	echo "FAILED: $what"
	exit 1
    fi

    echo

    sleep 1
}

# -------------------------------------------------------
# copy test fixture
# -------------------------------------------------------

mkdir --parents $FROM_DIR
rsync -rav $SRC_DIR/ $FROM_DIR

echo

sleep 1

# -------------------------------------------------------
# full backup
# -------------------------------------------------------

# lots of output from the full backup:
$TRESYNC $FROM_DIR $FULL_DIR > /dev/null

compare_diff "full backup test" $FROM_DIR $FULL_DIR "Only in $FROM_DIR: archived\nOnly in $FROM_DIR: ignored"

# -------------------------------------------------------
# incremental no change backup
# -------------------------------------------------------

$TRESYNC $FROM_DIR $FULL_DIR $INCR_DIR

compare_find "empty incremental backup" $INCR_DIR $INCR_DIR

# -------------------------------------------------------
# incremental changed backup
# -------------------------------------------------------

echo "running incremental backup (with changes) ..."

echo "a new line" >> $CHANGED_COPIED_FILE
echo "# a new line" >> $CHANGED_IGNORED_FILE

EXPECTED_CHANGED_INCR_CMP_FILE=$TEST_DIR/expected_changed_incr_cmp.txt
ACTUAL_CHANGED_INCR_CMP_FILE=$TEST_DIR/actual_changed_incr_cmp.txt

$TRESYNC $FROM_DIR $FULL_DIR $INCR_DIR

compare_find "changed incremental backup" $INCR_DIR $INCR_DIR "$INCR_DIR/backedup" "$INCR_DIR/backedup/b1.txt"

# -------------------------------------------------------
# restoring from backup
# -------------------------------------------------------

echo "restoring from full backup ..."

RSYNC_TGT_DIR=$TEST_DIR/rsyncto

rm -rf $RSYNC_TGT_DIR
mkdir -p $RSYNC_TGT_DIR

rsync -ra $FULL_DIR/ $RSYNC_TGT_DIR

expected="Only in /tmp/tresync/testing/from: archived"
expected="$expected\ndiff -r /tmp/tresync/testing/from/backedup/b1.txt /tmp/tresync/testing/rsyncto/backedup/b1.txt"
expected="$expected\n2d1"
expected="$expected\n< a new line"
expected="$expected\nOnly in /tmp/tresync/testing/from: ignored"

compare_diff "rsync full sync" $FROM_DIR $RSYNC_TGT_DIR $expected

# -------------------------------------------------------
# applying incremental backup
# -------------------------------------------------------

echo "applying incremental backup ..."

rsync -ra $INCR_DIR/ $RSYNC_TGT_DIR

expected="Only in /tmp/tresync/testing/from: archived"
expected="$expected\nOnly in /tmp/tresync/testing/from: ignored"

compare_diff "rsync incremental sync" $FROM_DIR $RSYNC_TGT_DIR $expected

echo "done; restored to: $RSYNC_TGT_DIR"
