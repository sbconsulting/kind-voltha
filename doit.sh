SADIS_NAME=sadis-config-bp-default.json
#SADIS_NAME=sadis-config-notp.json

helm del --purge cord-kafka
helm del --purge onos-subscriber-agent
helm del --purge cord-kafka
helm del --purge fluent-bit
DEPLOY_K8S=yes ./voltha down

sleep 30
VOLTHA_CHART=voltha-helm-charts/voltha TYPE=minimal DEPLOY_K8S=yes VOLTHA_LOG_LEVEL=debug WITH_RADIUS=y WITH_BBSIM=y WITH_TP=y ./voltha up
cat $SADIS_NAME | sed -e 's/:OLT_HWADDR:/00:00:0a:62:ce:e2/g' -e 's/:OLT_IPADDR:/10.98.206.226/g'  | curl -XPOST -sSL http://karaf:karaf@localhost:8181/onos/v1/network/configuration -H Content-type:application/json -d@-
# helm install -f minimal-values.yaml --namespace voltha --name bbsim onf/bbsim
# sleep 5
voltctl device create -t openolt -H $(kubectl get -n voltha service/bbsim -o go-template='{{.spec.clusterIP}}'):50060
sleep 1
voltctl device enable $(voltctl device list --filter Type~openolt -q)

SERIAL=BBSM00000001
voltctl device list -f SerialNumber=$SERIAL | grep -i ACTIVE
while [ $? -ne 0 ]; do
    echo "waiting for onu to activate"
    sleep 1
    voltctl device list -f SerialNumber=$SERIAL | grep -i ACTIVE
done
