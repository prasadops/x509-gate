#!/bin/bash

echo "-----

Inputs - Make sure that the Namespace Exists
If you want to expose the x509 gate to the external world, please create a spin-x509 service of type LB with application running on port 8085 
and create DNS record spin-x509.NAMESPACE.opsmx.com 

-------"

read -n 1 -s -r -p "Press ENTER to continue"

namespace=$1

sed -i 's/NAMESPACE/'$namespace'/g' *.yml

echo "---Creating Cluster Issuer----"
kubectl apply -f clusterissuer.yml


echo "---Creating CACert----"
kubectl apply -f cacert.yml -n $namespace


echo "---Creating Issuer----"
kubectl apply -f issuer.yml -n $namespace


kubectl -n $namespace create secret generic passphrasesecret --from-literal=passphrase=mysecrepassphrase

echo "---Creating Certificates for x509..----"
kubectl apply -f cert.yml -n $namespace

echo "---Extracting the ca.crt, tls.crt and tls.key----"
kubectl -n $namespace get secret mtlscerts-pkcs12 -o jsonpath='{.data.ca\.crt}' | base64 -d >ca.crt
kubectl -n $namespace get secret mtlscerts-pkcs12 -o jsonpath='{.data.tls\.crt}' | base64 -d >tls.crt
kubectl -n $namespace get secret mtlscerts-pkcs12 -o jsonpath='{.data.tls\.key}' | base64 -d >tls.key


echo "---Creating p12 and jks files required for Halyard Configuration----"
openssl pkcs12 -export -clcerts -in tls.crt -inkey tls.key -out tls.p12 -name gate -passin pass:changeit -password pass:changeit
keytool -importkeystore -srckeystore tls.p12 -srcstoretype pkcs12 -srcalias gate -destkeystore tls.jks -destalias gate -deststoretype pkcs12 -deststorepass changeit -destkeypass changeit -srcstorepass changeit
keytool -importcert -keystore tls.jks -alias ca -file ca.crt -storepass changeit -noprompt

echo "---Checking the Keystore for our gate jks entry"
keytool -list -keystore tls.jks -storepass changeit

echo "---Creating spin-x509 service exposing x509 on port 8085"
kubectl apply -f spin-x509.yml -n $namespace

echo "-----

Please do the following in the Halyard Pod


## HALYARD CONFIG
hal config security api ssl edit --key-alias gate --keystore /home/spinnaker/tls.jks --keystore-password --keystore-type jks --truststore /home/spinnaker/tls.jks --truststore-password --truststore-type jks
hal config security api ssl enable
hal config security authn x509 enable

## Add this to default/profiles/gate-local.yml
default:
  apiPort: 8085
  legacyServerPort: 9001

hal deploy apply

----------------------------------"

