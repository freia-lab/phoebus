#!/bin/sh

SOURCE_DIR=/home/konrad/freia-lab/phoebus
DEST_DIR=phoebus-4.7.4-SNAPSHOT
TOP_DEST_DIR=/tmp
DEST_PATH=${TOP_DEST_DIR}/${DEST_DIR}

# Build the Javadoc, i.e. html files to be included in the manual
( cd ${SOURCE_DIR}/app/display/editor; ant -f javadoc.xml clean all )

# Building the manual will locate and include
# all ../phoebus/**/doc/index.rst and ../phoebus/**/doc/html
( cd ${SOURCE_DIR}/docs; make clean html )
# Windows: Use make.bat html

# Build Product

# Fetch dependencies
( cd ${SOURCE_DIR}; mvn clean verify -f dependencies/pom.xml )

# Create settings.ini for the product with current date
# and URL of your update site.
# Update site contains '$(arch)' which client will replace with
# its host OS (linux, mac, win).
# Note that this example replaces an existing product/settings.ini.
# If your product already contains settings.ini,
# consider using '>>' to append instead of replacing.
URL='https://freia.physics.uu.se/CSS/phoebus/phoebus-$(arch).zip'
( cd ${SOURCE_DIR};
  app/update/mk_update_settings.sh $URL > phoebus-product/settings.ini
)
# Build product 
( cd ${SOURCE_DIR}; mvn -DskipTests clean install )

# Create settings_template.ini
( cd ${SOURCE_DIR}/phoebus-product; python3 create_settings_template.py )

# Create bundle for distribution, including the documentation
rm -r ${DEST_PATH}
mkdir -p ${DEST_PATH}/lib
mkdir ${DEST_PATH}/doc
cp -a ${SOURCE_DIR}/phoebus-product/target/lib ${DEST_PATH}
cp -a ${SOURCE_DIR}/phoebus-product/target/doc ${DEST_PATH}
cp ${SOURCE_DIR}/phoebus-product/phoebus.* ${DEST_PATH}
cp  ${SOURCE_DIR}/phoebus-product/site_splash.png ${DEST_PATH}
cp ${SOURCE_DIR}/phoebus-product/target/product-*.jar ${DEST_PATH}
cp  ${SOURCE_DIR}/phoebus-product/settings* ${DEST_PATH}
( cd ${TOP_DEST_DIR}; zip -r ${SOURCE_DIR}/phoebus-product/phoebus-linux.zip ${DEST_DIR} )
