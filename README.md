1. Inputs - Namespace

2. If you want to expose the x509 gate to the external world, please create a spin-x509 service of type LB with application running on port 8085 
and create DNS record spin-x509.NAMESPACE.opsmx.com 


## HALYARD CONFIG

hal config security api ssl edit --key-alias gate --keystore /home/spinnaker/tls.jks --keystore-password --keystore-type jks --truststore /home/spinnaker/tls.jks --truststore-password --truststore-type jks

hal config security api ssl enable

hal config security authn x509 enable

## Add this to default/profiles/gate-local.yml

    default:
      apiPort: 8085
      legacyServerPort: 9001

 hal deploy apply
