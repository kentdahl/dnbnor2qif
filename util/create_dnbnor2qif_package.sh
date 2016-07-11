#!/bin/bash

BASEPATH=`dirname $0`


##
# Version setup
#
VERSION=`cat $BASEPATH/../VERSION.txt`
FILEVERSION=`echo $VERSION | sed s/\\\\./_/g`
echo $VERSION

TAGPREFIX=dnbnor2qif-alpha-release

PREVTAG=`git-tag | grep $TAGPREFIX | head -n 1`

git-tag -a -m "Tagging release $VERSION"  $TAGPREFIX-$VERSION


##
# Package directory setup
#
TARGETDIR=dnbnor2qif_v${FILEVERSION}
echo $TARGETDIR

rm -rf dist
mkdir -p dist



##
# Changelog 
#
if [ "$PREVTAG" ]
then
    git-log --pretty=format:"%s%n%b" $PREVTAG..$TAGPREFIX-$VERSION \
    | grep -v "^$" \
    > dist/changelog-$VERSION.txt
fi


## 
# Create package
#
echo "Creating archive ..."
TARGETFILE=dist/$TARGETDIR.tar.gz
git-archive --prefix=$TARGETDIR/ master  |gzip>$TARGETFILE
echo "Wrote file: $TARGETFILE".


##
# Run tests.
#
cd dist
tar xzvf `basename $TARGETFILE`
cd $TARGETDIR
echo "Testing..."
ruby test/run.rb 

# Run larger random testsuite.
if [ -d ../../test/various/ ]
then
  for i in ../../test/various/*.xls 
  do  
    ruby dnbnor2qif.rb -c convert -i $i
  done
fi


echo "Done."

