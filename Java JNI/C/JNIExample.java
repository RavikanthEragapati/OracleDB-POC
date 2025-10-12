public class JNIExample {

  // This loads the library at runtime. NOTICE: on *nix/Mac the extension of the
  // lib should exactly be `.jnilib`, not `.so`, and have `lib` prefix, i.e.
  // the library file should be `libjniexample.jnilib`.
  static {
    System.loadLibrary("jniexample");
  }

  // Native method, no body.
  public native void sayHello(int length);

  public static void main(String args[]) {
    String str = "Hello, world!";

    (new JNIExample()).sayHello(str.length());
  }

}
