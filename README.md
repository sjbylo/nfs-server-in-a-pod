# Simple NFS server in a pod, good for demos

Based on:

https://cormachogan.com/2019/06/20/kubernetes-storage-on-vsphere-101-readwritemany-nfs/

If you're in a hurry, run:

```
./go.sh
```

## Steps

Use this for the NFS server pod:
  oc adm policy add-scc-to-user privileged -z default

This "nfs-server-sts.yaml" is set up for gp2 sc

First, ensure that "nfs-server-sts.yaml" can provision PVC/PV or

set up a PV and matching PVC and adjust the "volumeClaimTemplates" in the yaml

IMPORTANT: must replace server: "172.30.119.25" in "nfs-client-pv.yaml" with the actual svc IP address.  Seems like the svc name does not work!
Use sed, as below

```
#oc create -f nfs-server-sc-OPTIONAL.yaml
```

```
oc new-project nfs
```

```
oc adm policy add-scc-to-user privileged -z default
```

```
oc create -f nfs-server-sts.yaml
oc create -f nfs-server-svc.yaml
```

```
IP=`oc get svc nfs-server -n nfs | grep ClusterIP | awk '{print $3}'`
```

```
oc new-project nfs-client-test
```

```
oc create -f nfs-client-pod-1.yaml
sed -i orig "s/server:.*/server: $IP/g" nfs-client-pv.yaml 
oc create -f nfs-client-pv.yaml
oc create -f nfs-client-pvc.yaml
```

## Verify

```
oc rsh nfs-client-pod-1 ls -l /nfs/ 
```

## Clean up

```
oc delete po nfs-client-pod-1 & oc delete pvc nfs-client-pvc & oc delete pv nfs-client-pv
oc delete project nfs-client-test nfs
```

