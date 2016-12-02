#!/bin/bash

usage()
{
cat << EOF
usage: $0 --hostname aa --username xx --orgname yy
Retrieve configuration for vagrant-vcloud plugin for a given user.
OPTIONS:
--help|-h      Show this message
--username|-u  The username to login to vCloud
--orgname|-o   The org name to login to vCloud
--hostname|-n  The hostname of your vCloud
EOF
exit 1
}

for arg
do
  delim=""
  case "$arg" in
    --help) args="${args}-h ";;
    --username) args="${args}-u ";;
    --hostname) args="${args}-n ";;
    --orgname) args="${args}-o ";;
    # pass through anything else
    *) [[ "${arg:0:1}" == "-" ]] || delim="\""
      args="${args}${delim}${arg}${delim} ";;
  esac
done
# reset the translated args
eval set -- $args
# now we can process with getopt
while getopts "hvu:o:" opt; do
  case $opt in
    h) usage ;;
    u) USER=$OPTARG ;;
    n) HOST=$OPTARG ;;
    o) ORG=$OPTARG ;;
    \?) usage ;;
    :)
      echo "option -$OPTARG requires an argument"
      usage
      ;;
  esac
done
shift $((OPTIND -1))

if [ -z "$USER" ]; then
  echo "Option -u must be specified!"
  exit 1
fi

if [ -z "$ORG" ]; then
  echo "Option -o must be specified!"
  exit 1
fi

which http >/dev/null
if [ $? -eq 1 ]; then
  echo "Tool http (or httpie) not installed. Install it first with"
  echo "sudo pip install --upgrade httpie"
  exit 1
fi

which jq >/dev/null
if [ $? -eq 1 ]; then
  echo "Tool jq not installed. Install it first with"
  echo "sudo apt-get install -y jq"
  exit 1
fi

which xml2json >/dev/null
if [ $? -eq 1 ]; then
  echo "Tool xml2json not installed. Install it first with"
  echo "npm install -g xml2json-command"
  exit 1
fi


session=vcloud-$USER-$ORG
url=https://$HOST

org_url=$(http --session=$session --verify=no -a $USER@$ORG POST $url/api/sessions 'Accept:application/*+xml;version=5.5' | xml2json | jq '.Session.Link[] | select(.type=="application/vnd.vmware.vcloud.org+xml") | .href' | sed -e 's/^"//' -e 's/"$//')
org_name=$(http --session=$session --verify=no $org_url | xml2json | jq '.Org.name')

vdc_url=$(http --session=$session --verify=no $org_url | xml2json | jq '.Org.Link[] | select(.type=="application/vnd.vmware.vcloud.vdc+xml") | .href' | sed -e 's/^"//' -e 's/"$//')
vdc_name=$(http --session=$session --verify=no $org_url | xml2json | jq '.Org.Link[] | select(.type=="application/vnd.vmware.vcloud.vdc+xml") | .name')
vdc_network_name=$(http --session=$session --verify=no $org_url | xml2json | jq '.Org.Link[] | select(.type=="application/vnd.vmware.vcloud.orgNetwork+xml") | select(.name!="LOOPBACK-DIRECT-CONNECTED") | .name')

vdc_edge_gateway_url=$(http --session=$session --verify=no $vdc_url | xml2json | jq '.Vdc.Link[] | select(.rel=="edgeGateways") | .href' | sed -e 's/^"//' -e 's/"$//')
vdc_edge_gateway=$(http --session=$session --verify=no $vdc_edge_gateway_url | xml2json | jq '.QueryResultRecords.EdgeGatewayRecord.name')

edge_gateway_url=$(http --session=$session --verify=no $vdc_edge_gateway_url | xml2json | jq '.QueryResultRecords.EdgeGatewayRecord.href' | sed -e 's/^"//' -e 's/"$//')
vdc_edge_gateway_ip=$(http --session=$session --verify=no $edge_gateway_url | xml2json | sed -e 's/\$t/t/g' | jq '.EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[] | select(.InterfaceType.t=="uplink") | .SubnetParticipation[] | select(.IpRanges.IpRange) | .IpRanges.IpRange.StartAddress.t')
if [ -z $vdc_edge_gateway_ip ]; then
  vdc_edge_gateway_ip=$(http --session=$session --verify=no $edge_gateway_url | xml2json | sed -e 's/\$t/t/g' | jq '.EdgeGateway.Configuration.GatewayInterfaces.GatewayInterface[] | select(.InterfaceType.t=="uplink") | .SubnetParticipation | select(.IpRanges.IpRange) | .IpRanges.IpRange.StartAddress.t')
fi

echo "Put this lines to your global ~/.vagrant.d/Vagrantfile"
echo ""

echo "Vagrant.configure(\"2\") do |config|"
echo "  if Vagrant.has_plugin?(\"vagrant-vcloud\")"
echo "    config.vm.provider :vcloud do |vcloud, override|"
echo "      vcloud.hostname            = \"$url\""
echo "      vcloud.username            = ENV['VCLOUD_USERNAME'] || \"vagrant\""
echo "      vcloud.password            = ENV['VCLOUD_PASSWORD'] || \"vagrant\""
echo "      vcloud.org_name            = $org_name"
echo "      vcloud.vdc_name            = $vdc_name"
echo "      vcloud.catalog_name        = \"COM-BUILD-CATALOG\""
echo "      vcloud.ip_subnet           = \"172.16.32.1/255.255.255.0\""
echo "      vcloud.ip_dns              = [\"10.100.20.2\", \"8.8.8.8\"]"
echo "      vcloud.vdc_network_name    = $vdc_network_name"
echo "      vcloud.vdc_edge_gateway    = $vdc_edge_gateway"
echo "      vcloud.vdc_edge_gateway_ip = $vdc_edge_gateway_ip"
echo "      override.vm.usable_port_range = 2200..2999"
echo "    end"
echo "  end"
echo "end"
