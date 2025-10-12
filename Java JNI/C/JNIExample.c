#include <stdio.h>
#include <jni.h>
#include "JNIExample.h"

JNIEXPORT void JNICALL Java_JNIExample_sayHello
  (JNIEnv *env, jobject object, jint len) {
  printf("\nThe length of your string is %d.\n\n", len);
}