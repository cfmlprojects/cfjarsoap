package xrm;

import java.io.IOException;

import javax.security.auth.callback.Callback;
import javax.security.auth.callback.CallbackHandler;
import javax.security.auth.callback.UnsupportedCallbackException;
import org.apache.wss4j.common.ext.WSPasswordCallback;

public class HardcodedPassword implements CallbackHandler {
  @Override
  public void handle(Callback[] callbacks)
      throws IOException, UnsupportedCallbackException {
    for (Callback c : callbacks) {
      if (c instanceof WSPasswordCallback) {
        WSPasswordCallback passwordCallback = (WSPasswordCallback) c;
        passwordCallback.setPassword("passw0rd");
        continue;
      }
      throw new UnsupportedCallbackException(c);
    }
  }
}
