#!/bin/bash

echo "-----

Run Script as below


         bash x509-script.sh <NAMESPACE> <DNS>



Inputs - Make sure that the Namespace Exists
	
	DNS like opsmx.com 

	Once executed the script follow the steps to complete the process.

-------"

read -n 1 -s -r -p "Press ENTER to continue"

namespace=$1
dns=$2
sed -i 's/NAMESPACE/'$namespace'/g' *.yml
sed -i 's/DNS/'$dns'/g' *.yml
echo "---Creating Cluster Issuer----"
echo ""
kubectl apply -f clusterissuer.yml
echo ""

echo "---Creating CACert----"
echo ""
kubectl apply -f cacert.yml -n $namespace

echo ""
echo "---Creating Issuer----"
kubectl apply -f issuer.yml -n $namespace

echo ""
kubectl -n $namespace create secret generic passphrasesecret --from-literal=passphrase=mysecrepassphrase
echo ""
echo "---Creating Certificates for x509..----"
kubectl apply -f cert.yml -n $namespace
echo ""
echo "---Extracting the ca.crt, tls.crt and tls.key----"
kubectl -n $namespace get secret mtlscerts-pkcs12 -o jsonpath='{.data.ca\.crt}' | base64 -d >ca.crt
kubectl -n $namespace get secret mtlscerts-pkcs12 -o jsonpath='{.data.tls\.crt}' | base64 -d >tls.crt
kubectl -n $namespace get secret mtlscerts-pkcs12 -o jsonpath='{.data.tls\.key}' | base64 -d >tls.key

echo ""
echo "---Creating p12 and jks files required for Halyard Configuration----"
openssl pkcs12 -export -clcerts -in tls.crt -inkey tls.key -out tls.p12 -name gate -passin pass:changeit -password pass:changeit
keytool -importkeystore -srckeystore tls.p12 -srcstoretype pkcs12 -srcalias gate -destkeystore tls.jks -destalias gate -deststoretype pkcs12 -deststorepass changeit -destkeypass changeit -srcstorepass changeit
keytool -importcert -keystore tls.jks -alias ca -file ca.crt -storepass changeit -noprompt

echo "---Checking the Keystore for our gate jks entry"
keytool -list -keystore tls.jks -storepass changeit

echo "---Creating spin-x509 service exposing x509 on port 8085"
kubectl apply -f spin-x509.yml -n $namespace
echo ""
echo "-----

Please do the following in the Halyard Pod

## Copy the certificate files to the halyard pod

        kubectl cp ca.crt <NAMESPACE>-spinnaker-halyard-0:/home/spinnaker/ca.crt  -n <NAMESPACE>

        kubectl cp tls.crt <NAMESPACE>-spinnaker-halyard-0:/home/spinnaker/tls.crt  -n <NAMESPACE>
                 
        kubectl cp tls.key <NAMESPACE>-spinnaker-halyard-0:/home/spinnaker/tls.key  -n <NAMESPACE>
                 
        kubectl cp tls.p12 <NAMESPACE>-spinnaker-halyard-0:/home/spinnaker/tls.p12  -n <NAMESPACE>
        
        kubectl cp tls.jks  <NAMESPACE>-spinnaker-halyard-0:/home/spinnaker/tls.jks  -n <NAMESPACE>


   ## Enter into the Halyard pod 

        kubectl exec -it <NAMESPACE>-spinnaker-halyard-0 bash -n <NAMESPACE>

Run the below commands in the Halyard Pod

        hal config security api ssl edit --key-alias gate --keystore /home/spinnaker/tls.jks --keystore-password --keystore-type jks --truststore /home/spinnaker/tls.jks --truststore-password --truststore-type jks
        
  It will promt to password please use this **changeit**

        hal config security api ssl enable

        hal config security authn x509 enable

  ## Add this to default/profiles/gate-local.yml

        default:
          apiPort: 8085
          legacyServerPort: 9001

  ## Run a hal command to apply changes
    
         hal deploy apply


## Verify the x509 in the halyard pod

         curl -vvv https://spin-x509:8085/applications --cacert /home/spinnaker/ca.crt --cert /home/spinnaker/tls.crt --key /home/spinnaker/tls.key
         
         list of applications will be printed in the Json format
----------------------------------"

