# Topology Constraints

Applying topology constraints to a `Pod` requires also the storage to follow the same constraints as otherwise the `Pod` cannot be started or gives a false sense of robustness.

One issue when we immediately provision storage once a `PVC` is created is that we might not know where the consuming `Pod` acutally will be scheduled. Here we can use the parameter `volumeBindingMode` and set it to `WaitForFirstCustomer`. This allows to postpone the provisioning of the storage until the `PVC` is actually requested by a `Pod` and it is clear where it will be scheduled.

In order to identify zones on our minikube cluster we need to set a label on our nodes.
 Once we added some topology constraints to our `Pod` the scheduler will use this label to decide on which `node` to schedule the Pod, and when configured correctly the storage provisioner will then create the volume in that same "zone".

Set the following label on the minikube nodes:
```bash
kubectl label node minikube topology.kubernetes.io/zone=restricted-zone
kubectl label node minikube-m02 topology.kubernetes.io/zone=schedule-zone
kubectl label node minikube-m03 topology.kubernetes.io/zone=restricted-zone
```

Now we need to adapt our `storageclass` to provision the storage on the same zone as the `Pod`. To achieve this change the `volumeBindingMode` and add our `schedule-zone` as a topology constraint in our `StorageClass` using the `allowedTopologies` this makes sure that the storage provider is only allowed to provide storage on these nodes. Try to come up with the solution by editing the earlier saved file `../resources/storageclass.yaml` and compare it with the one below.

<details>
    <summary>Hint</summary>
    Checkout the `matchLabelExpressions` and set key = `topology.kubernetes.io/zone` and value = `schedule-zone`.
</details>

<details>
    <summary>Solution</summary>

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
  name: standard
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowedTopologies:
- matchLabelExpressions:
  - key: topology.kubernetes.io/zone
    values:
    - schedule-zone
```
</details>
</br>

To apply the changes to our storage class we need to delete and redeploy the `storageclass` as some parameters is immutable:
```bash
kubectl delete storageclass standard
kubectl apply -f resources/storageclass.yaml
```

Now let's reapply the `PVC`:
```bash
kubectl apply -f resources/pvc.yaml
```

As we set the `volumeBindingMode` to `WaitForFirstCustomer` the `PV` should only be provisioned once the `Pod` is scheduled. Therefore the following command should not return any `PV`:
```bash
kubectl get pv -n playground
```

Try to change the `../resources/pod.yaml` such that a `nodeSelector` is used to apply some topology constraints.
<details>
    <summary>Solution</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: data-writer
  namespace: playground
spec:
  nodeSelector:
    topology.kubernetes.io/zone: schedule-zone
  containers:
  - name: writer
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
    - 'echo "Data written on $(date)" > /mnt/data/test.txt; sleep 3600'
    volumeMounts:
    - mountPath: /mnt/data
      name: storage
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: pvc-claim
```
</details>

We can go ahead and deploy the "Pod":
```bash
kubectl apply -f resources/pod.yaml
```

And check if the `PV` is correctly provisioned:
```bash
kubectl get pv -n playground
```

And double check that the `PVC` and the `Pod` are provisioned on the same node:
```bash
kubectl describe pod data-writer -n playground | grep -i node:
kubectl describe pvc pvc-claim -n playground | grep -i selected-node
```

Now we can apply `nodeAffinity` rules to the `Pod` and the storage will follow the `Pod` topology constraints.

## Cleanup

```bash
kubectl delete pod data-writer -n playground
kubectl delete pvc pvc-claim -n playground
```
