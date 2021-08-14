JAVASDK_VERSION=$(yum list java-oci-sdk.x86_64 | grep -o "[0-9].[0-9]\+.[0-9]\+")

# Validate Java SDK
cp -r /usr/lib64/java-oci-sdk/examples/shared .
javac -cp .:/usr/lib64/java-oci-sdk/lib/oci-java-sdk-full-$JAVASDK_VERSION.jar:/usr/lib64/java-oci-sdk/third-party/lib/* JavaSDKValidation.java
java -cp .:/usr/lib64/java-oci-sdk/lib/oci-java-sdk-full-$JAVASDK_VERSION.jar:/usr/lib64/java-oci-sdk/third-party/lib/* JavaSDKValidation

# Validate Python SDK
python3 pythonsdk-validation.py

# Validate Go SDK
go run gosdk-validation.go

# Validate Ruby SDK
ruby rubysdk-validation.rb

# Validate Typescript SDK
cd typescript
npm init -y
npm link oci-sdk
tsc typescript-validation.ts
node typescript-validation.js
cd ..

# Validate Dotnet SDK
cd dotnet
dotnet new Console
rm Program.cs
dotnet add package OCI.DotNetSDK.Common --source /usr/lib/dotnet/NuPkgs/
dotnet add package OCI.DotNetSDK.Identity --source /usr/lib/dotnet/NuPkgs/
dotnet build
dotnet run
cd ..

# Validate terraform
terraform init
terraform apply -auto-approve
