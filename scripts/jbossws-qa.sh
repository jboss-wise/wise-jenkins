#!/bin/sh

ensureJavaExists() {
  if [ ! -d $JAVA_HOME ]; then
    echo "Please point java.home specified in ant.properties to correct JDK installations"
    exit 1
  fi
}

setupEnv() {
  TMP_DIR_PROPERTY=
  if [ -d /data/tmp ]; then
    TMP_DIR_PROPERTY=-Djava.io.tmpdir=/data/tmp
  elif [ -d /tmp ]; then
    TMP_DIR_PROPERTY=-Djava.io.tmpdir=/tmp
  else
    echo "Cannot detect temporary directory";
    exit -1;
  fi
  if [ "$JBOSS_INSTANCE" != "" ]; then
    rm -rf $WORKSPACE/jboss-as
    cp -r $JBOSS_INSTANCE $WORKSPACE/jboss-as
    export JBOSS_HOME=$WORKSPACE/jboss-as
    ENVIRONMENT="$TMP_DIR_PROPERTY -Dmaven.opts=-U -Dserver.home=$JBOSS_HOME"
  else
    ENVIRONMENT="$TMP_DIR_PROPERTY -Dmaven.opts=-U"
  fi
}

logMavenDependencies() {
  cd $STACK_DIR
  mvn -Ptestsuite,dist clean
  mvn -P$JBOSS_TARGET dependency:tree | tee $WORKSPACE/dependency-tree.txt
}

copyTestLogs() {
  cat $WORKSPACE/tests.log | egrep FIXME\|FAILED | sort -u | tee $WORKSPACE/fixme.txt
  cat $WORKSPACE/fixme.txt > $WORKSPACE/errata-$JBOSS_TARGET.txt
  for i in `find $STACK_DIR -name surefire-reports`; do egrep -h "skipped message"\|FIXME\|"Test skipped: " $i/*|grep -v "<system-out>"|sort -u|sed 's/    <skipped message=\"//'|sed 's/\"\/>//'|sed 's/Test skipped: //' >> $WORKSPACE/errata-$JBOSS_TARGET.txt; done;
}

detectFailures() {
  #rm -rf $WORKSPACE/jboss-as
  cat $WORKSPACE/tests.log | egrep "BUILD FAILURE|BUILD ERROR|java.lang.OutOfMemoryError" | tee $WORKSPACE/failure.log
  if [ -s $WORKSPACE/failure.log ]; then
    echo "Failure detected"
    exit 1
  fi
}

runTestsViaMaven() {
  echo "TEST_OPTS: $TEST_OPTS"
  mvn $ENVIRONMENT -Phudson,$JBOSS_TARGET $TEST_OPTS integration-test 2>&1 | tee $WORKSPACE/tests.log
}

runTestsViaMavenWithSecMgr() {
  echo "TEST_OPTS: $TEST_OPTS"
  mvn $ENVIRONMENT -Phudson,$JBOSS_TARGET,wildfly9-secmgr $TEST_OPTS integration-test 2>&1 | tee $WORKSPACE/tests.log
}

coreTest() {
  setupEnv
  ensureJavaExists
  logMavenDependencies
  runTestsViaMaven
  copyTestLogs
  detectFailures
}

coreTestWithSecMgr() {
  setupEnv
  ensureJavaExists
  logMavenDependencies 
  runTestsViaMavenWithSecMgr
  copyTestLogs
  detectFailures
}




