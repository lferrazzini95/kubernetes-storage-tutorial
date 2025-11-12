# Storage in Kubernetes

Basic storage ("non-persistent" or "ephemeral") is provided by default as a temporary directory on the host machine, ifthe container crashes, the volume is gone. Persistent storage is provided over multiple storage types like file, block or object storage services from cloud providers or local data ceneters. This is usually handled via the `Container Storage Interface`.

<details>

  <summary>General Storage Types</summary> 
    We generally distinct the following three storage types:

    - Block: The storage service only knows about numbered blocks and is completely unaware of files, directories, etc. The client OS needs to manage the file system. Used for services that require raw attachable disk, like databases.
    - File: The storage service manages the file system itself, the client requests data using these file names. Used for shared file access like web servers.
    - Object: The storage service manages data as immutable objects within flat containers (buckets). It uses HTTP/REST APIs and is optimized for scale. Used for unstructured data like images, videos, backups etc. This is often also directly integrated with REST APIs to get better speed.
</details>

Before we look at the `Container Storage Interface` we will get an overview of the main storage resources in kubernetes.


## Volumes
  Volumes allow pods to access and share data via the file system. In essence a volume is just a directory with potential data in it. Volumes have a lifetime that generally matches the lifetime of the pod. In essence there are two types of volumes:
  - `ephemeral Volumes` which is bound to the lifetime of a specific pod. Meaning if the pod crashes, restarts or is rescheduled to a different Node the data in these volumes are lost. 
  - `Persitent Volumes`  which provide storage that exists beyond a pod lifetime.

<details>
    <summary>Volume Spec</summary>
    Volumes are defined in the pod spec under `spec.volumes` and to make them available they need to be mounted at a specific path under `spec.containers[*].volumeMounts`. 
</details>

## Persistent Volumes and Persistent Volume Claims

  When talking about persistent storage in kubernetes there are essentially three resource types we need to take a look at. That is `Persistent Volumes` which define how storage should be *provisioned*, `Persistent Volume Claim` that define how storage should be *consumed* and a `Storage Class` which provide a blueprint for `Persitent Volumes` allowing them to be provisioned dynamically. In general `Persistent Volumes` and `Storage Class` are provided by the administrator (define how to provide the storage) and `Persistent Volume Claims` are defined by the developer (how the storage should be used).

 If a user requires storage for his application a `Persistent Volume Claim` needs to be created that binds a `Persistent Volume` to the application. *PVC* and *PVs* follow an "Object in Use protection" which means that a storage is not deleted as long it is still in use by a pod. (if you delete the PV or the PVC nothing happens until the pod which binds these resources are deleted.)

  Once a *PVC* is deleted the *PV* tells the cluster what what happens as the *PV* is reclaimed (This is defined in the `spec`). This can either be `Retain` (the *PV* remains claimed by the pvc and is therefore not free to use. It requires an administrator to remove the claim from the PV) or `Delete` (PV is deleted).

`PVCs` also define how the storage should be accessed. This is defined in the `spec` and there exist the following settings:
  -  *ReadWriteOnce:* The volume can be mounted as read-write by a single node. ReadWriteOnce access mode still can allow multiple pods to access (read from or write to) that volume when the pods are running on the same node. For single pod access, please see ReadWriteOncePod.
  - *ReadOnlyMany:* The volume can be mounted as read-only by many nodes.
  - *ReadWriteMany:* The volume can be mounted as read-write by many nodes.
  - *ReadWriteOncePod:* The volume can be mounted as read-write by a single Pod. Use ReadWriteOncePod access mode if you want to ensure that only one pod across the whole cluster can read that PVC or write to it.

## Container Storage Interface

  In the old days storage device drivers needed to be integrated with kubernetes. `Container Storage Interface` (CSI) allows a plugin architecture to easily add support for other storage devices or services.

The CSI consists of two major parts the `CSI Controller` and the `CSI Node Module`:

### CSI Controller (Resource Creation)
The `CSI Controller` runs on the control plane and contains the logic to watch the Kubernetes API for storage requests (specifically new `Persistent Volume Claims` which require Dynamic Provisioning). The controller communicates with the external storage backend via `gRPC` to perform lifecycle operations such as `CreateVolume`, `DeleteVolume`, and volume attachment/detachment (`ControllerPublishVolume`/`ControllerUnpublishVolums`) to make sure the worker nodes have the required permissions to access the data.

### CSI Node Component
   The `CSI Node Component` on the otherhand is called by the `kublet` in case there is a volume that needs to be mounted onto a pod. Once the `CSI Controller` configured the storage the `CSI Node Component` then mounts the storage to a staging path to the worker node. If the volume needs formatting the `CSI Node Component` calls the required tools to format the storage. Once these action are done the `CSI Node Component` then mounts the storage to a pod specific path where it is ready to be mounted by the `kublet`.
