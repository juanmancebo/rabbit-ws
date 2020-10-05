#!/bin/bash

{ read GROUP; read APP_NAME; read JVM_ARGS; read JAVA_VERSION; read APP_VERSION; } <<<$(./gradlew properties -q | egrep -w "^group:|^name:|^org.gradle.jvmargs:|^targetCompatibility:|^version:" | awk '{print $2 " " $3}')
export GROUP APP_NAME JVM_ARGS JAVA_VERSION APP_VERSION
export XMS=$(printenv JVM_ARGS|grep "Xms" | tr ' ' '\n' | grep "Xms" |cut -c 5-)
export XMX=$(printenv JVM_ARGS|grep "Xmx" | tr ' ' '\n' | grep "Xmx" |cut -c 5-)



