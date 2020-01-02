echo EXECUTING POST_BUILD SCRIPT
echo BUILD_DIR $TARGET_DIR
cd $TARGET_DIR/etc/systemd/system/getty.target.wants
ls -l
rm console-getty.service
cd $TARGET_DIR/etc/systemd/system/getty.target.wants
ln -s /usr/lib/systemd/system/timedatectl.service .
echo FINISHED POST_BUILD SCRIPT
