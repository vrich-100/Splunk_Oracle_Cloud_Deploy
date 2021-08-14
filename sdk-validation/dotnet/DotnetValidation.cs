using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Oci.Common;
using Oci.Common.Auth;
using Oci.IdentityService;
using Oci.IdentityService.Models;
using Oci.IdentityService.Requests;
using Oci.IdentityService.Responses;

namespace Oci.Examples
{
    public class DotnetValidation
    {
        public static async Task Main()
        {
            // Accepts profile name and creates a auth provider based on config file
            var provider = new InstancePrincipalsAuthenticationDetailsProvider();
            // Create a client for the service to enable using its APIs
            var client = new IdentityClient(provider, new ClientConfiguration());

            try
            {
                await ListOciRegions(client);
            }
            catch (Exception e)
            {
                Console.WriteLine($"Received exception due to {e.Message}");
            }
            finally
            {
                client.Dispose();
            }
        }

        private static async Task ListOciRegions(IdentityClient client)
        {
            // List regions
            var listRegionsRequest = new ListRegionsRequest();
            ListRegionsResponse listRegionsResponse = await client.ListRegions(listRegionsRequest);
            Console.WriteLine("List Regions");
            Console.WriteLine("=============");
            foreach (Oci.IdentityService.Models.Region reg in listRegionsResponse.Items)
            {
                Console.WriteLine($"{reg.Key} : {reg.Name}");
            }
        }
    }
}
