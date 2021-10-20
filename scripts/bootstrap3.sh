#!/bin/bash

# Variables
USER_NAME=opc
USER_HOME=/home/${USER_NAME}
APP_NAME=splunk-oci-dev-kit
DEV_TOOLS_HOME=${USER_HOME}/${APP_NAME}
INSTALL_LOG_FILE_NAME=install-${APP_NAME}.log
INSTALL_LOG_FILE=${USER_HOME}/${INSTALL_LOG_FILE_NAME}
SSHD_BANNER_FILE=/etc/ssh/sshd-banner
SSHD_CONFIG_FILE=/etc/ssh/sshd_config
UPDATE_SCRIPT_FILE=update-kit.sh
UPDATE_SCRIPT_WITH_PATH=/usr/local/bin/${UPDATE_SCRIPT_FILE}
UPDATE_SCRIPT_LOG_FILE=${USER_HOME}/${UPDATE_SCRIPT_FILE}.log

INSTALLATION_IN_PROGRESS="
    #################################################################################################
    #                                           WARNING!                                            #
    #   SPLUNK _OCI Development Kit Installation is still in progress.                                      #
    #   To check the progress of the installation run -> tail -f ${INSTALL_LOG_FILE_NAME}           #
    #################################################################################################
"

USAGE_INFO="
    =================================================================================================
                                        SPLUNK_OCI DEV KIT Usage
                                        ===================
    This instance has OCI Dev Kit such as CLI, Terraform, Ansible, SDKs (Java, Python3.6, Go, Dotnet, Ruby, Typescript)

    To update OCI Dev Kit to the latest version, run the following command: ${UPDATE_SCRIPT_FILE}

    You could use Instance Principal authentication to use the dev tools.

    For running CLI, type the following to get more help: oci --help
    =================================================================================================
"

start=`date +%s`

# yum install packages are listed here. This same list is used for update too
PACKAGES_TO_INSTALL=(
    python36-oci-cli
    terraform
    terraform-provider-oci
    oci-ansible-collection
    python36-oci-sdk.x86_64
    oracle-golang-release-el7.x86_64
    golang
    unzip
    go-oci-sdk.x86_64
    java-oci-sdk.x86_64
    git-1.8.3.1-23.el7_8.x86_64
    rh-ruby27
    oci-ruby-sdk
    oracle-nodejs-release-el7
    oci-dotnet-sdk.noarch
)

# Log file
sudo -u ${USER_NAME} touch ${INSTALL_LOG_FILE}
sudo -u ${USER_NAME} chmod +w ${INSTALL_LOG_FILE}

# Sending all stdout and stderr to log file
exec >> ${INSTALL_LOG_FILE}
exec 2>&1

echo "Installing SPLUNK_OCI Dev Kit"
echo "------------------------"

echo "Creating sshd banner"
sudo touch ${SSHD_BANNER_FILE}
sudo echo "${INSTALLATION_IN_PROGRESS}" > ${SSHD_BANNER_FILE}
sudo echo "${USAGE_INFO}" >> ${SSHD_BANNER_FILE}
sudo echo "Banner ${SSHD_BANNER_FILE}" >> ${SSHD_CONFIG_FILE}
sudo systemctl restart sshd.service

####### Installing yum packages #########

echo "Packages to install ${PACKAGES_TO_INSTALL[@]}"
sudo yum -y install ${PACKAGES_TO_INSTALL[@]} && echo "#################### Successfully installed all yum packages #####################"

sudo yum -y install --enablerepo=ol7_developer_nodejs10 --enablerepo=ol7_developer oci-typescript-sdk && echo "#################### Successfully installed typescript #####################"

####### Installing yum packages -End #########

####### Adding environment variables #########
echo "Adding environment variable so terraform can be AuthN using instance principal"
sudo -u ${USER_NAME} echo 'export TF_VAR_auth=InstancePrincipal' >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo "export TF_VAR_region=$(oci-metadata -g regionIdentifier --value-only)" >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo "export TF_VAR_tenancy_ocid=$(oci-metadata -g tenancy_id --value-only)" >> ${USER_HOME}/.bashrc

echo "Adding environment variable so oci-cli can be AuthN using instance principal"
sudo -u ${USER_NAME} echo 'export OCI_CLI_AUTH=instance_principal' >> ${USER_HOME}/.bashrc

echo "Adding environment variable so ansible can be AuthN using instance principal"
sudo -u ${USER_NAME} echo 'export OCI_ANSIBLE_AUTH_TYPE=instance_principal' >> ${USER_HOME}/.bashrc

sudo -u ${USER_NAME} echo 'export GOPATH=/usr/share/gocode' >> ${USER_HOME}/.bashrc

echo "Adding environment variable so oci jars are in the classpath"
JAVASDK_VERSION=$(yum list java-oci-sdk.x86_64 | grep -o "[0-9].[0-9]\+.[0-9]\+")
sudo -u ${USER_NAME} echo "export CLASSPATH=/usr/lib64/java-oci-sdk/lib/oci-java-sdk-full-${JAVASDK_VERSION}.jar:/usr/lib64/java-oci-sdk/third-party/lib/*" >> ${USER_HOME}/.bashrc

echo "Adding environment variable so ruby collections are properly set"
sudo -u ${USER_NAME} echo "source scl_source enable rh-ruby27" >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo "export GEM_PATH=/usr/share/gems:'gem env gempath'" >> ${USER_HOME}/.bashrc
echo "Adding environment variable so dotnet collections are properly set"
sudo -u  ${USER_NAME} echo "source scl_source enable rh-dotnet31" >> ${USER_HOME}/.bashrc

echo "Adding environment variable so oci-cli can be AuthN using instance principal"
sudo echo 'export OCI_CLI_AUTH=instance_principal' >> /etc/bashrc

echo "Adding environment variable for SDK analytics"
sudo -u ${USER_NAME} echo 'export OCI_SDK_APPEND_USER_AGENT=Oracle-ORMDevTools' >> ${USER_HOME}/.bashrc

####### Adding environment variables - End #########

####### Generating upgrade script #########
DOLLAR_SIGN="$"

echo "Creating update script"
echo "----------------------"
cat > ${UPDATE_SCRIPT_WITH_PATH} <<EOL
#!/bin/bash

PACKAGES_TO_UPDATE=(
    python36-oci-cli
    terraform
    terraform-provider-oci
    terraform-provider-splunk
    terraform-provider-signalfx
    oci-ansible-collection
    python36-oci-sdk.x86_64
    oracle-golang-release-el7.x86_64
    golang
    go-oci-sdk.x86_64
    java-oci-sdk.x86_64
    git
    oci-ruby-sdk
    oracle-nodejs-release-el7
    --enablerepo=ol7_developer_nodejs10 --enablerepo=ol7_developer oci-typescript-sdk
    oci-dotnet-sdk.noarch
)

# Log file
sudo -u ${USER_NAME} touch ${UPDATE_SCRIPT_LOG_FILE}
sudo -u ${USER_NAME} chmod +w ${UPDATE_SCRIPT_LOG_FILE}

exec > >(tee ${UPDATE_SCRIPT_LOG_FILE})
exec 2>&1

echo "Updating OCI Dev Kit"
echo "----------------------"

echo "Packages to update ${DOLLAR_SIGN}{PACKAGES_TO_UPDATE[@]}"
sudo yum -y install ${DOLLAR_SIGN}{PACKAGES_TO_UPDATE[@]} && echo "#################### Successfully updated all yum packages #####################"

echo "-----------------------------------"
echo "Updating OCI Dev Kit is complete"

EOL
####### Generating upgrade script -End #########
echo "Update script creation complete"

sudo chmod +x ${UPDATE_SCRIPT_WITH_PATH}

end=`date +%s`

executionTime=$((end-start))

echo "--------------------------------------------------------------"
echo "Installation of OCI Dev Kit is complete. (Took ${executionTime} seconds)"

sudo echo "${USAGE_INFO}" > ${SSHD_BANNER_FILE}

echo "Running disk setup..."
echo "Testing, no-op"


echo "Gathering metadata..."


# Config is assumed to be in this location in instance metadata
export CONFIG_LOCATION='.metadata.config'


json=$(curl -sSL http://169.254.169.254/opc/v1/instance/)
shape=$(echo $json | jq -r .shape)

echo "$shape"

echo $json | jq $CONFIG_LOCATION

#######################################################
##################### Disable firewalld ###############
#######################################################
systemctl stop firewalld
systemctl disable firewalld

# admin password
password=$(echo $json | jq -r $CONFIG_LOCATION.password)
sites_string=$(echo $json | jq -r $CONFIG_LOCATION.sites_string)

product="splunk"       # values can be : splunk , splunkforwarder
version="8.2.2"        # Splunk product Version
hash="87344edfcdb4"    # specific per Version
arch="x86_64"           # values can be : x86_64 (redhat, tgz), amd64 (ubuntu), x64 (Windows)
os="linux"             # values can be : linux, windows
pkg="rpm"              # Values can be : tgz, rpm, deb, msi


filename="splunk-8.2.2-87344edfcdb4-linux-2.6-x86_64.rpm"

url="https://download.splunk.com/products/splunk/releases/8.2.2/linux/splunk-8.2.2-87344edfcdb4-linux-2.6-x86_64.rpm"
wget -O $filename $url
chmod 744 $filename
mkdir -p /opt/splunk
rpm -i $filename

#copy over basic conf files
cat << EOF > /opt/splunk/etc/system/local/ui-tour.conf
[search-tour]
viewed = 1
EOF


#template user-seed conf files
cat << EOF > /opt/splunk/etc/system/local/user-seed.conf
[user_info]
USERNAME = admin
PASSWORD = $password
EOF

#template inputs conf files
cat << EOF > /opt/splunk/etc/system/local/inputs.conf
[splunktcp:9997]
EOF

#template web conf files
cat << EOF > /opt/splunk/etc/system/local/web.conf
[settings]
httpport = 8000
enableSplunkWebSSL = true
EOF

#template outputs conf files
#cat << EOF > /opt/splunk/etc/system/local/outputs.conf


# edit server.conf files
#cat << EOF > /opt/splunk/etc/system/local/server.conf



# make splunk_app_oci directory
#mkdir -p /opt/splunk/etc/apps/splunk_app_oci

echo "Start splunk"
/opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt


exec -l $SHELL
