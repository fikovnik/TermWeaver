#!/bin/sh

PROJECT_NAME="TermWeaver"
BUILD_DIR="build/Release"
KEY_FILE="$HOME/Dropbox/Personal/Keys/TermWeaver/dsa_priv.pem"
URL="http://nkuyu.net/apps/termweaver"
APPCAST_URL="$URL/appcast.xml"
DOWNLOAD_URL="$URL/downloads"

# -- do not modify
SRC="$BUILD_DIR/$PROJECT_NAME.prefPane"

# build
xcodebuild -target TermWeaver -configuration Release

# version
VERSION=$(defaults read `pwd`/"$SRC/Contents/Info" CFBundleVersion)
#ARCHIVE_NAME="$PROJECT_NAME-$VERSION.dmg"
ARCHIVE_NAME="$PROJECT_NAME-$VERSION.zip"
ARCHIVE_PATH="$BUILD_DIR/$ARCHIVE_NAME"

echo "Version: $VERSION"
echo "Name: $ARCHIVE_NAME"
echo "Path: $ARCHIVE_PATH"

# create an archive
if [ -f $ARCHIVE_PATH ]; then echo "Removing previously built archive"; rm -fr $ARCHIVE_PATH; fi

#hdiutil create -anyowners -scrub -srcfolder $SRC -volname ${ARCHIVE_NAME##.dmg} $ARCHIVE_PATH
#hdiutil internet-enable -yes $ARCHIVE_PATH

ditto -ck --keepParent "$SRC" "$ARCHIVE_PATH"

# size
SIZE=$(stat -c %s "$ARCHIVE_PATH")
#SIZE=$(du -bs $SRC | cut -f 1)
echo "Size: $SIZE"

# date
PUBDATE=$(LC_TIME=en_US date +"%a, %d %b %G %T %z")
echo "Date: $PUBDATE"

# sign
SIGNATURE=$(openssl dgst -sha1 -binary < "$ARCHIVE_PATH" | openssl dgst -dss1 -sign "$KEY_FILE" | openssl enc -base64)
echo "Sig: $SIGNATURE"

echo

# item
cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"  xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>TermWeaver Changelog</title>
    <link>$APPCAST_URL</link>
    <description>Most recent changes with links to updates.</description>
    <language>en</language>
    <item>
      <title>Version $VERSION</title>
      <description>
	<![CDATA[
		 <h2>New Features</h2>
	]]>
      </description>
      <pubDate>$PUBDATE</pubDate>
      <enclosure url="$DOWNLOAD_URL/$ARCHIVE_NAME" sparkle:version="$VERSION" length="$SIZE" type="application/octet-stream" sparkle:dsaSignature="$SIGNATURE" />
    </item>
  </channel>
</rss>
EOF
