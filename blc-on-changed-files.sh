#!/usr/bin/env bash

BASE_BRANCH='master'

git fetch origin refs/heads/$BASE_BRANCH:refs/remotes/origin/$BASE_BRANCH
BASE_BRANCH_SHA=`git rev-parse origin/$BASE_BRANCH`
# If the git diff result below is something like:
# readme.md
# readme.txt
# dir/readme.txt
# dir/readme.md
# dir/anotherdir/readme.md
# dir/anotherdir/readme.txt
# dir.md/anotherdir/readme.md
# dir.md/anotherdir/readme.txt
#
# the grepping should filter it down to
# dir/readme.md
# dir/anotherdir/readme.md
# dir.md/anotherdir/readme.md
git diff --name-only $BASE_BRANCH_SHA | grep --regexp="\.md$" | grep --regexp="^.*/" > changed-files.txt

if [ `cat changed-files.txt | wc -l` -eq 0 ]; then
    echo "There are no MarkDown files to check."
else
    echo "These files need to be checked:"
    cat changed-files.txt
fi

EXIT_CODE=0
# read an individual line from the changed-files.txt file
while read line;
do 
    # Ignore deleted files
    echo "travis_fold:start:blc"
    if [ ! -f $line ]; then
        continue
    fi

    # Use liche to check links in Markdown file
    echo /docs/$line
    docker run -v $PWD:/docs peterevans/liche:1.1.1 -t 60 -c 16 -d /docs /docs/$line 2> stdout.txt;
    # Take note of the success or failure of the blc command.
    if [ $? -ne 0 ]; then
        EXIT_CODE=1
    fi

    N_BROKEN=$(cat stdout.txt | grep --regexp="^.\{2\}[ERROR]" | wc -l)
    if [ $N_BROKEN -eq 0 ]; then
        echo "No broken links found."
        echo "travis_fold:end:blc"
    else
        echo "travis_fold:end:blc"
        cat stdout.txt
    fi

done < changed-files.txt

# If any failures have occurred during the above while loop, exit with a failure
# code (1), otherwise, exit with a success code (0).
exit $EXIT_CODE
