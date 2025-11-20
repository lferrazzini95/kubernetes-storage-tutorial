## Storage Snapshot

Storage-Snapshots are a useful tool when it comes to desaster recovery. It simplifies the backup and restore process of provided `PVC`s. `Storage-Snapshots` allow to capture the state of a `PVC` at a particular time and restore this snapshot in case of failure.

First we need to enable the volumesnapshot feature on our cluster:
```bash
minikube addons enable volumesnapshots
minikube addons enable csi-hostpath-driver
```

# VolumeSnapshotClass

The resource that generate the snapshots dynamically is the `VolumeSnapshotClass` it acs similarly to the `StorageClass` as it defines a blueprint for `VolumeSnapshot` resources. Checkout the `VolumeSnapshotClass` that is provided in the cluster: 
```bash
kubectl get volumesnapshotclass csi-hostpath-snapclass -o yaml
```

Now we need an actual `PVC` to snapshot. Deploy the `../resources/pvc-snapshot.yaml` and `../resources/pod.yaml`:
**Note:** We use a differen `PVC` than in the last tutorials as we do not use the default `StorageClass` but the `StorageClass` that is enabled for `VolumeSnapshotClass`.

```bash
kubectl apply -f resources/pvc-snapshot.yaml
kubectl apply -f resources/pod.yaml
```

Note that the `Pod` writes an entry with a timestamp into a file `/mnt/data/test.txt`. To check this file run:

```bash
kubectl exec -n playground data-writer -- cat /mnt/data/test.txt
```

# Volume Snapshot
As mentioned above we now need a `VolumeSnapshot` that defines which `PVC` should be backed up. Once we deploy `../resources/volumesnapshot.yaml` a snapshot will be taken of the defined `PVC`.

```bash
kubectl apply -f resources/volumesnapshot.yaml
```

Inspect the `VolumeSnapshot` status and wait until the `ReadyToUse=true`:

```bash
kubectl get volumesnapshot pvc-snapshot -n playground
```

Once the `VolumeSnapshot` is ready to use we can delete the `PVC` and the `Pod`:

```bash
kubectl delete -f resources/pod.yaml
kubectl delete -f resources/pvc-snapshot.yaml
```

Now to restore a `VolumeSnapshot` we need to define the datasource in the `PVC`. To achieve this edit the `../resouces/pvc-snapshot.yaml` and add the `dataSource` field with the correct definitions. Once the changes are done compare it with the solution below and apply the resource to your cluster togheter with the `Pod`.
<details>
    <summary>Solution</details>

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-claim
  namespace: playground
spec:
  storageClassName: csi-hostpath-sc
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  dataSource:
    name: pvc-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io

```
</details>

```bash
kubectl apply -f resources/pvc-snapshot.yaml
kubectl apply -f resources/pod.yaml
```

Now the pod should have two entry in the test file:
```bash
kubectl exec -n playground data-writer -- cat /mnt/data/test.txt
```

## Cleanup

Reset the `resources`:
```bash
git restore resources/pvc.yaml
```

Delete the cluster resources:
```bash
kubectl delete pod data-writer -n playground
kubectl delete pvc pvc-claim -n playground
kubectl delete volumesnapshot pvc-snapshot -n playground
```

If you are done with everything don't forget to delete the minikube clsuter:

```bash
minikube delete
```
