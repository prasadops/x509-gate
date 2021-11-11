## Requirements

1. Inputs - Namespace and DNS of wildcard (like:  opsmx.com)

2.  Once executed the script follow the steps to complete the process.

## Steps to be Followed

1. Clone the repo 

        git clone git clone https://github.com/lakkireddys-opsmx/x509-gate.git
        
        cd x509-gate
        
2.  Run the script 

        bash x509-script.sh <NAMESPACE> <DNS>
        
    example: bash  x509-script.sh oes-spin opsmx.com
 
3. After Running the script please follow below steps

## HALYARD CONFIG

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
