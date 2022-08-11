#*************************************
#           TF  Environment
#*************************************


locals {
  current_time                    = formatdate("YYYYMMDDhhmmss", timestamp())
  app_name                        = "splunk-oci-dev-kit"
  display_name                    = join("-", [local.app_name, local.current_time])
  compartment_name                = data.oci_identity_compartment.this.name
  #dynamic_group_tenancy_level     = "Allow dynamic-group ${oci_identity_dynamic_group.for_instance.name} to manage all-resources in tenancy"
  #dynamic_group_compartment_level = "Allow dynamic-group ${oci_identity_dynamic_group.for_instance.name} to manage all-resources in compartment ${local.compartment_name}"


  instance_image_ocid = {
    # See https://docs.us-phoenix-1.oraclecloud.com/images/
    # Oracle-provided image "Oracle-Linux-8.6-aarch64-2022.06.30-0"
    af-johannesburg-1 	= "ocid1.image.oc1.af-johannesburg-1.aaaaaaaarhpn6phdm2gtt3klkyz5dx2jfigdxbh574zgkdhhrwbmelgpbfmq"
    ap-chuncheon-1 	= "ocid1.image.oc1.ap-chuncheon-1.aaaaaaaa4hyucgrabpwhgwphruavior6qekrqupmdd4lfp7ng2qzpoefes5q"
    ap-hyderabad-1 	= "ocid1.image.oc1.ap-hyderabad-1.aaaaaaaav7ghge44nbzvunsewfbioz7hy6t7wh3ltrkfsck2cx36wfr5ft5a"
    ap-melbourne-1 	= "ocid1.image.oc1.ap-melbourne-1.aaaaaaaakxjymlan3wr53pa57ckbygf6h2n2c3y2oof4juaaxjbxni5slpvq"
    ap-mumbai-1 	= "ocid1.image.oc1.ap-mumbai-1.aaaaaaaardc7ywh4omtf4cskyyjofz555uxwyimm2e4h6e7s4yhk3j4mtrra"
    ap-osaka-1 	= "ocid1.image.oc1.ap-osaka-1.aaaaaaaazn6g4662t7dbmb2y5ycptnkj5ot6m6zemd4bent5qr5d4hd76ora"
    ap-seoul-1 	= "ocid1.image.oc1.ap-seoul-1.aaaaaaaawfdaqp77uv5baevyjp5dtzm5m3bnalywv4winpvdt3h24lcbfy2a"
    ap-singapore-1 	= "ocid1.image.oc1.ap-singapore-1.aaaaaaaao4y3idcgqek3d6gqwmscazur33qwrebdtwwpv7hmasewgdbbkanq"
    ap-sydney-1 	= "ocid1.image.oc1.ap-sydney-1.aaaaaaaaerfgnkrvzb2zzvgl74tgwduusospnh2wdse5l22j67zsk2tilkqa"
    ap-tokyo-1 	= "ocid1.image.oc1.ap-tokyo-1.aaaaaaaag47jgtka6ze4uzgbfumv2uiby4iz3fi6oj2n3vgngvuqmtr6h2ya"
    ca-montreal-1 	= "ocid1.image.oc1.ca-montreal-1.aaaaaaaasnao22qm24ynjsnhrccqukv5olgnnfvmo2c3fywdpchuk27ez7fq"
    ca-toronto-1 	= "ocid1.image.oc1.ca-toronto-1.aaaaaaaamvilee6y5pr3wk5fbqalcrmmjknxpa4ocaa3dpact6h64t3y56ya"
    eu-amsterdam-1 	= "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaag2tvqc3bzz24effe6zt6whn7ylej4esbgtklczmjqodvcprux6eq"
    eu-frankfurt-1 	= "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaeab34ms37ohy5y4ylwwmagvlmxq7l5bdsdscpghzlzopryo3kk4a"
    eu-marseille-1 	= "ocid1.image.oc1.eu-marseille-1.aaaaaaaa3m6zxyezuosx77mqzkizzgz5hgaigby7xfcqqkbayc3ozsahcw3q"
    eu-milan-1 	= "ocid1.image.oc1.eu-milan-1.aaaaaaaahuqq5jbok3otbmxaum4musc6bezkdh2t6rbucwvj675oyzihm54q"
    eu-stockholm-1 	= "ocid1.image.oc1.eu-stockholm-1.aaaaaaaahbcblnesjh5hj62kgpnlzvriqeciiwjrxmonvdsffqebtedf7qeq"
    eu-zurich-1 	= "ocid1.image.oc1.eu-zurich-1.aaaaaaaarbdvozjh2l6szfvk23ggwm6hzwm5dtjpxj5pithq2varyl2w3sma"
    il-jerusalem-1 	= "ocid1.image.oc1.il-jerusalem-1.aaaaaaaacylah6x45v33rt2tborxzlrd5xoddc2nklbr7bxluhlmbilxqewa"
    me-abudhabi-1 	= "ocid1.image.oc1.me-abudhabi-1.aaaaaaaar2qq2n32rtv5vsfkrtzudol3dgsvc5jrl4pbfzo7cr4zojwobpda"
    me-dubai-1 	= "ocid1.image.oc1.me-dubai-1.aaaaaaaauwvm727lowmoth5bvf2di2iuxc3tvfdtxrqsrj75sviwu33yl64a"
    me-jeddah-1 	= "ocid1.image.oc1.me-jeddah-1.aaaaaaaaxtct7hfaurphvrntp6txc6gaju67ctvadytf4rhdul4un6zx4esa"
    sa-santiago-1 	= "ocid1.image.oc1.sa-santiago-1.aaaaaaaanlhvg5szpo6r45rh7vtf45ggc5qsfkxhiuzx3m4qkatw7h3px62a"
    sa-saopaulo-1 	= "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaaldxp2kr76xccfwrvccait7yxikyq76dxjzrhtqbgw6lddboethuq"
    sa-vinhedo-1 	= "ocid1.image.oc1.sa-vinhedo-1.aaaaaaaayp4chbjjf4tfbsmbftac5a3zquh7l5gydym4nsuag64eb6lifwra"
    uk-cardiff-1 	= "ocid1.image.oc1.uk-cardiff-1.aaaaaaaaufcqrbgsc7bmx7wqafgdgki7g7qykqxgdzaxbo2htqcsckj7afua"
    uk-london-1 	= "ocid1.image.oc1.uk-london-1.aaaaaaaatyleob4emm2a3us7x6ofxtzs3w6y7vlkmrgt64fxl632yylvnnea"
    us-ashburn-1 	= "ocid1.image.oc1.iad.aaaaaaaabibzfmbo7aulkqsh4vnb3h5noehrvd366yr3bpmrqg6dxjunlrda"
    us-phoenix-1 	= "ocid1.image.oc1.phx.aaaaaaaalz3plgjt37dt3gj7ckwxklmfn7bxe5gittmbxsdxbviefmbbtpaq"
    us-sanjose-1	= "ocid1.image.oc1.us-sanjose-1.aaaaaaaakltkdnlroylc466enh6hqgtoxoplih7xojaepprelee4apxwectq"
  }

}


