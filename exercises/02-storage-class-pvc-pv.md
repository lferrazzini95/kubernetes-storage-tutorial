# Kubernets Storage Tutorial - API Resources

In this tutorial we will investigate the storage components of kubernetes from a user perspective. These 3 types include:

- **Storage Class:** Describes the blueprint of how a `persistent volume` should be provisioned dynamically
- **Persistent Volume:** Define how storage should be *provisioned*
- **Persistent Volume Claim:** Define how storage should be *used* by a pod

## Storage Class

In the previous tutorial we talked about the `Storage Class` resource. Let's take a look at the default `Storage Class` that is provided with the cluster. As we will need the definition later we can directly store the definition in a file and look at the content. For this run the following commands:
```bash
kubectl get storageclasses.storage.k8s.io standard -o yaml > resources/storageclass.yaml
cat resources/storageclass.yaml
```

When inspecting the parameters `volumeBindingMode` you should see the value `Immediate` this means that whenever a `PVC` is created the storage provider will immediately deploy a match `PV` if possible.

## Persistent Volume & Persistent Volume Claim

Now we want to showcase the `volumeBindingMode` of the `StorageClass` by deploying a `PVC` and inspect if the `PV` is actually immediately deployed as well:

```bash
kubectl apply -f resources/pvc.yaml
```

Check if the corresponding pv is created:

```bash
kubectl get pv -n playground
```

## Topology Constraints
Now as learned before if the storage should be provisioned in the same topology constraint as the `Pod` we can set the parameter `volumeBindingMode` to `WaitForFirstCustomer` which will wait to provision the storage until the `PVC` is actually requested by a `Pod`. 

Let's try this by changing the parameter `volumeBindingMode` accordingly in the resource `resources/storageclass.yaml` and applying it afterwards (**Note:** we first need to delete the old `storageclass` as this parameter is immutable):

```bash
kubectl delete storageclass standard
kuvectl apply -f resources/storageclass.yaml
```

Now we can delete the earlier provisioned `PVC`:
```bash
kubectl delete -f resources/pvc.yaml
```

And make sure that the `PV` is actually deleted:
<details>
    <summary>Bonus Question: Which field is responsible for the immediate deletion of the `PV` after the `PVC` is deleted?</summary>
`StorageClass` defines as blueprint: `reclaimPolicy`: `Delete`
</details>

```bash
kubectl get pv -n playground
```
Now lets reapply the `PVC`:
```bash
kubectl apply -f resources/pvc.yaml
```

and check that no `PV` is created:
```bash
kubectl get pv -n playground
```

Instead the `PV` should only be provisioned once the `Pod` actually requests the `PVC` therefore we can go ahead and deploy the "Pod-1":

```bash
kubectl apply -f resources/pod-1.yaml
```

And check if pv exist:
```bash
kubectl get pv -n playground
```

## Deletion Prevention
## Storage Snapshots
