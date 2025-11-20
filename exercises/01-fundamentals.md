# Storage in Kubernetes

Basic storage ("non-persistent" or "ephemeral") is provided by default as a temporary directory on the host machine, if the container crashes, the volume is gone. Persistent storage on the other hand is provided over multiple storage types like file, block or object storage services from cloud providers or local data centers. This is usually handled via the `Container Storage Interface` (we will cover a short section on it further below).

<details>
  <summary>General Storage Types</summary>

- **Block**: The storage service only knows about numbered blocks and is completely unaware of files, directories, etc. The client OS needs to manage the file system. Used for services that require raw attachable disk, like databases.
- **File**: The storage service manages the file system itself, the client requests data using these file names. Used for shared file access like web servers.
- **Object**: The storage service manages data as immutable objects within flat containers (buckets). It uses HTTP/REST APIs and is optimized for scale. Used for unstructured data like images, videos, backups etc. This is often also directly integrated with REST APIs to get better speed.
</details>
</br>

Before we look at the `Container Storage Interface` we will get an overview of the main storage resources in Kubernetes.

## Volumes
  Volumes allow pods to access and share data via a filesystem. In essence a volume is just a directory with potential data in it stored on any data service. Volumes have a lifetime that generally matches the lifetime of the pod. There are two types of volumes:
  - `ephemeral Volumes` which are bound to the lifetime of a specific `Pod`. Meaning if the `pod` crashes, restarts or is rescheduled to a different Node the data in these volumes are lost.
  - `Persitent Volumes` which provide storage that exists beyond a `Pod` lifetime.

<details>
    <summary>Volume Spec</summary>

Volumes are defined in the `Pod` spec under `spec.volumes` and to make them available they need to be mounted at a specific path under `spec.containers[*].volumeMounts`.

</details>

## Persistent Volumes and Persistent Volume Claims

When talking about persistent storage in kubernetes there are essentially three resource types we need to take a look at. 

* `Persistent Volumes` define how storage should be **provisioned**
* `Persistent Volume Claim` define how storage should be **consumed**
* `Storage Class` provides a blueprint for `Persitent Volumes` allowing them to be provisioned dynamically.

In general `Persistent Volumes` and `Storage Class` are provided by the administrator (define how to provide the storage) and `Persistent Volume Claims` are defined/created by the developer (how the storage should be used).

If a user requires storage for his application a `Persistent Volume Claim` needs to be created that binds a `Persistent Volume` to the application. `PVC` and `PV`s follow an "Object in Use protection" which means that a storage is not deleted as long it is still in use by a pod. (if you delete the `PV` or the `PVC` nothing happens until the pod which binds these resources are deleted.)

  Once a `PVC` is deleted the `PV` tells the cluster what happens (This is defined in the `spec`). The options are either `Retain` (the `PV` remains claimed by the `PVC` and is therefore not free to use. It requires an administrator to remove the claim from the PV) or `Delete` (`PV` is deleted).

`PVCs` also define how the storage should be accessed. This is defined in the `spec` and there exist the following settings:
  -  **ReadWriteOnce:** The volume can be mounted as `read-write` by a single node. This mode still allows multiple `Pods` to access that volume when they are running on the same node. For single `Pod` access, please see `ReadWriteOncePod`.
  - **ReadOnlyMany:** The volume can be mounted as `read-only` by multiple nodes.
  - **ReadWriteMany:** The volume can be mounted as `read-write` by multiple nodes.
  - **ReadWriteOncePod:** The volume can be mounted as `read-write` by a single Pod. This ensures that only one `Pod` across the whole cluster can read that `PVC` or write to it.

## Storage Class
Let's take a look at the default `Storage Class` that is provided with the cluster. Later on we will need the definition, therefore we can directly store it in a file and inspect the content. For this run the following commands:

```bash
kubectl get storageclasses.storage.k8s.io standard -o yaml > resources/storageclass.yaml
cat resources/storageclass.yaml
```

When inspecting the parameters `volumeBindingMode` you should see the value `Immediate` this means that whenever a `PVC` is created the storage provider will immediately deploy a match `PV` if possible.

## Create Storage
Now that we have an idea how the storage will be provided in our cluster check out the `PVC` under `../resources/pvc.yaml` and apply it to the cluster:

```bash
kubectl apply -f resources/pvc.yaml
```

As the storage class implement the `volumeBindingMode=immediate` we should see a `PV` that is directly created without a `Pod` that binds the PV:

```bash
kubectl get pv -n playground
```

Now the `PV` is ready to be consumed by a `Pod`. Checkout the `../resources/pod.yaml` and deploy it. Make sure to understand where the `Pod` defined the binding to the `PVC`. Once the `Pod` pod is deployed we can check if it is running with:

```bash
kubectl apply -f resources/pod.yaml
kubectl get pods -n playground -w
```

## Clean Up

Clean up the created resources from above:

```bash
kubectl delete -f resources/pod.yaml
kubectl delete -f resources/pvc.yaml
```


<details>
    <summary> <b>Bonus Question:</b> Which field is responsible for the immediate deletion of the `PV` after the `PVC` is deleted?</summary>

`StorageClass` defines as blueprint: `reclaimPolicy`: `Delete`

</details>
</br>

 To get a deeper understanding of how storage is provisioned we take a slightly deeper look into the `Container Storage Interface` which is usually only changed by cluster administrators.

## Container Storage Interface

In the old days storage device drivers needed to be integrated with Kubernetes. `Container Storage Interface` (CSI) allows a plugin architecture to easily add support for other storage devices or services.

The CSI consists of two major parts the `CSI Controller` and the `CSI Node Module`:

### CSI Controller (Resource Creation)
The `CSI Controller` runs on the control plane and contains the logic to watch the Kubernetes API for storage requests (specifically new `Persistent Volume Claims` which require Dynamic Provisioning). The controller communicates with the external storage backend via `gRPC` to perform lifecycle operations such as `CreateVolume`, `DeleteVolume`, and volume attachment/detachment (`ControllerPublishVolume`/`ControllerUnpublishVolums`) to make sure the worker nodes have the required permissions to access the data.

### CSI Node Component
   The `CSI Node Component` on the otherhand is called by the `kublet` in case there is a volume that needs to be mounted onto a pod. Once the `CSI Controller` configured the storage the `CSI Node Component` then mounts the storage to a staging path to the worker node. If the volume needs formatting the `CSI Node Component` calls the required tools to format the storage. Once these action are done the `CSI Node Component` then mounts the storage to a pod specific path where it is ready to be mounted by the `kublet`.
