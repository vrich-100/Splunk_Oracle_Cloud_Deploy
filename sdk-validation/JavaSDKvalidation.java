import com.oracle.bmc.auth.InstancePrincipalsAuthenticationDetailsProvider;
import com.oracle.bmc.identity.IdentityAsyncClient;
import com.oracle.bmc.identity.IdentityClient;
import java.net.ConnectException;
import java.net.SocketTimeoutException;

public class JavaSDKValidation {

    public static void main(String[] args) {

        final InstancePrincipalsAuthenticationDetailsProvider provider;
        try {
            provider = InstancePrincipalsAuthenticationDetailsProvider.builder().build();
        } catch (Exception e) {
            if (e.getCause() instanceof SocketTimeoutException
                    || e.getCause() instanceof ConnectException) {
                System.out.println(
                        "This sample only works when running on an OCI instance. Are you sure you’re running on an OCI instance? For more info see: https://docs.cloud.oracle.com/Content/Identity/Tasks/callingservicesfrominstances.htm");
                return;
            }
            throw e;
        }

        final IdentityClient identityClient = new IdentityClient(provider);
        final IdentityAsyncClient identityAsyncClient = new IdentityAsyncClient(provider);

        identityClient.close();
        identityAsyncClient.close();
        System.out.println("JavaSDK Install Validation Success");
    }
}
