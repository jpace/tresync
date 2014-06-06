#!/bin/sh -f

# fetched from github.com/jpace/svnx, then the .git directory removed
FROM_DIR=/tmp/svnx

TRESYNC=/proj/org/incava/tresync/bin/tresync.rb

TEST_DIR=/tmp/tresync/testing

FULL_DIR=$TEST_DIR/svnx
INCR_DIR=$TEST_DIR.1/svnx

CHANGED_COPIED_FILE=$FROM_DIR/README.md
CHANGED_IGNORED_FILE=$FROM_DIR/test/integration/tc.rb

rm -rf $TEST_DIR
mkdir --parents $TEST_DIR

rm -rf $FULL_DIR
rm -rf $INCR_DIR

# -------------------------------------------------------
# full backup
# -------------------------------------------------------

# lots of output from the full backup:
$TRESYNC $FROM_DIR $FULL_DIR > /dev/null

EXPECTED_FULL_CMP_FILE=/tmp/tresync/expected_full_cmp.txt
ACTUAL_FULL_CMP_FILE=/tmp/tresync/actual_full_cmp.txt

echo "Only in $FROM_DIR: pkg" > $EXPECTED_FULL_CMP_FILE
echo "Only in $FROM_DIR/test: integration" >> $EXPECTED_FULL_CMP_FILE

diff -r $FROM_DIR $FULL_DIR > $ACTUAL_FULL_CMP_FILE
cmp $EXPECTED_FULL_CMP_FILE $ACTUAL_FULL_CMP_FILE || echo "full backup test failed"

# -------------------------------------------------------
# incremental no change backup
# -------------------------------------------------------

sleep 1

EXPECTED_EMPTY_INCR_CMP_FILE=$TEST_DIR/expected_empty_incr_cmp.txt
ACTUAL_EMPTY_INCR_CMP_FILE=$TEST_DIR/actual_empty_incr_cmp.txt

echo $INCR_DIR > $EXPECTED_EMPTY_INCR_CMP_FILE

$TRESYNC $FROM_DIR $FULL_DIR $INCR_DIR

find $INCR_DIR | sort > $ACTUAL_EMPTY_INCR_CMP_FILE
cmp $EXPECTED_EMPTY_INCR_CMP_FILE $ACTUAL_EMPTY_INCR_CMP_FILE || echo "empty incremental backup failed"

# -------------------------------------------------------
# incremental changed backup
# -------------------------------------------------------

sleep 1

echo "a new line" >> $CHANGED_COPIED_FILE
echo "# a new line" >> $CHANGED_IGNORED_FILE

EXPECTED_CHANGED_INCR_CMP_FILE=$TEST_DIR/expected_changed_incr_cmp.txt
ACTUAL_CHANGED_INCR_CMP_FILE=$TEST_DIR/actual_changed_incr_cmp.txt

$TRESYNC $FROM_DIR $FULL_DIR $INCR_DIR

find $INCR_DIR | sort > $ACTUAL_CHANGED_INCR_CMP_FILE

echo $INCR_DIR > $EXPECTED_CHANGED_INCR_CMP_FILE
echo "$INCR_DIR/README.md" >> $EXPECTED_CHANGED_INCR_CMP_FILE

cmp $EXPECTED_CHANGED_INCR_CMP_FILE $ACTUAL_CHANGED_INCR_CMP_FILE || echo "changed incremental backup failed"

# now do the rsync business ...

RSYNC_TGT_DIR=$TEST_DIR/rsynctgt/svnx

rm -rf $RSYNC_TGT_DIR
mkdir -p $RSYNC_TGT_DIR

rsync -ra $FULL_DIR/ $RSYNC_TGT_DIR

EXPECTED_FULL_CMP_FILE=$TEST_DIR/expected_full_cmp.txt
ACTUAL_FULL_CMP_FILE=$TEST_DIR/actual_full_cmp.txt

echo "Only in /tmp/svnx: pkg" > $EXPECTED_FULL_CMP_FILE
echo "diff -r /tmp/svnx/README.md /tmp/tresync/testing/rsynctgt/svnx/README.md" >> $EXPECTED_FULL_CMP_FILE
echo "42d41" >> $EXPECTED_FULL_CMP_FILE
echo "< a new line" >> $EXPECTED_FULL_CMP_FILE
echo "Only in /tmp/svnx/test: integration" >> $EXPECTED_FULL_CMP_FILE

diff -r $FROM_DIR $RSYNC_TGT_DIR > $ACTUAL_FULL_CMP_FILE

cmp $EXPECTED_FULL_CMP_FILE $ACTUAL_FULL_CMP_FILE || echo "rsync full sync failed"
