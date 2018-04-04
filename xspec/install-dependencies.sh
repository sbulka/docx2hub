#!/usr/bin/env bash
## GET SAXON
wget -O saxon.zip https://sourceforge.net/projects/saxon/files/latest/download
unzip -d saxon saxon.zip
rm saxon.zip

## GET XMLRESOLVER
wget -O saxon/xmlresolver-1.2.jar http://central.maven.org/maven2/xml-resolver/xml-resolver/1.2/xml-resolver-1.2.jar

## GET XSPEC
git clone https://github.com/xspec/xspec/ xspec-master
cd xspec-master
git fetch origin pull/172/head:172
git checkout 172
cd ..

## GET XSLT-dependencies
mkdir lib
cd lib
git clone https://github.com/transpect/xslt-util xslt-util
