#!/bin/bash -ex
#See:
#  https://cormachogan.com/2019/06/20/kubernetes-storage-on-vsphere-101-readwritemany-nfs/

# Use this for the NFS server pod:
#  oc adm policy add-scc-to-user privileged -z default


# This "nfs-server-sts.yaml" is set up for gp2 sc
# First, ensure that "nfs-server-sts.yaml" can provision PVC/PV or
# set up a PV and matching PVC and adjust the "volumeClaimTemplates" in the yaml

# IMPORTANT: must replace server: "172.30.119.25" in "nfs-client-pv.yaml" with the actual svc IP address.  Seems like the svc name does not work!
# Use sed, as below

# untilPodCmdSuccess <pod> <command>
untilPodCmdSuccess() {
	POD=$1
	shift
	i=0
	while [ $i -lt 5 ]
	do
		oc rsh $POD $@ && return 0
		let i=$i+1
		sleep $i
	done
	return 1
}

# FIXME: Get the storage class to work
#oc create -f nfs-server-sc-OPTIONAL.yaml

oc new-project nfs || oc project nfs 

echo Ensure you are logged in as cluster-admin user
oc adm policy add-scc-to-user privileged -z default

oc create -f nfs-server-sts.yaml
oc create -f nfs-server-svc.yaml

oc rollout status statefulset nfs-server --watch 

IP=`oc get svc nfs-server -n nfs | grep ClusterIP | awk '{print $3}'`

oc new-project nfs-client-test || oc project nfs-client-test 

oc create -f nfs-client-pod-1.yaml
sed -i orig "s/^    server: .*/    server: $IP/g" nfs-client-pv.yaml 
oc create -f nfs-client-pv.yaml
oc create -f nfs-client-pvc.yaml

echo Waiting for test pod to come up ...
until oc get pod nfs-client-pod-1 --template '{{.status.phase}}' | grep Running; do sleep 1; done

echo Verifying NFS mount ...
untilPodCmdSuccess nfs-client-pod-1 "ls -l /nfs/index.html" && echo Success && exit 1

echo "Could not varify NFS mount in pod nfs-client-pod-1.  Something went wrong!"

# Clean up the test pod first
# oc delete po nfs-client-pod-1 & oc delete pvc nfs-client-pvc & oc delete pv nfs-client-pv && oc delete project nfs-client-test nfs 

# Note, cannot get NFS SC to work.  See nfs-test*

