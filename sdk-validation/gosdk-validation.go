package main

import (
        "context"
        "fmt"

        "github.com/oracle/oci-go-sdk/common"
        "github.com/oracle/oci-go-sdk/common/auth"
        "github.com/oracle/oci-go-sdk/example/helpers"
        "github.com/oracle/oci-go-sdk/identity"
)

func main() {
        provider, err := auth.InstancePrincipalConfigurationProvider()
        helpers.FatalIfError(err)

        client, err := identity.NewIdentityClientWithConfigurationProvider(provider)
        helpers.FatalIfError(err)

        tenancyID, _ := provider.TenancyOCID()

        _, err = client.ListAvailabilityDomains(context.Background(), identity.ListAvailabilityDomainsRequest{
                CompartmentId: common.String(tenancyID),
        })
        helpers.FatalIfError(err)
        fmt.Println("GoSDK Install Validation Success")
}
