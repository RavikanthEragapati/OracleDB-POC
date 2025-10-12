set JAVA_HOME and Add JAVA_HOME/bin to PATH variable

add JAVA_HOME/include/** in C/C++ plugin config to remove red scrible underneeth include <jni.h>

javac JNIExample.java
javac -h . JNIExample.java

gcc -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/darwin/" -o libjniexample.jnilib -shared JNIExample.c