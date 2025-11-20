<div align="center">

<img src="./assets/kubernetes.png" alt="Kubernetes Storage" width="25%" />

# Kubernetes Storage Tutorial

</div>


## Introduction

This tutorial should give an overview of the main storage components in kubernetes while providing a balance of theory and practical hands-on excercises.
The workshop is setup up to first get our dev-environment up and running and after that lead through 3 topics namely:
* [Fundamentals](./exercises/01-fundamentals.md)
* [Topology Constraints](./exercises/02-topology-constraints.md)
* [Storage Snapshots](./exercises/03-storage-snapshots.md)

All these exercises can be found under [./exercises](./exercises/) and are intended to be solved one after the other. During the exercises various resources will be applied. It is highly encouraged to try to get to the solutions yourself, however some basic resources are provided to focus on the important aspects under [./resources](./resources/).

## Setup

First we need to install [Minikube](https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fbinary+download). You can either do this with the official documentation or in case you have `devbox` installed just enter the `devbox` shell and you are ready to go.

To start you minikube cluster run the following command:

```bash
minikube --driver=docker --nodes 3 start
```

Once the cluster is ready try to list all `namespaces` to make sure it works:
```bash
kubectl get namespaces
```

Once the cluster is created, create a `playground` namespace that we will use for the exercises.
```bash
kubectl create namespace playground
```

Perfect! Now you can continue with the tutorials under [./exercises/](./exercises/).

## Cleanup
Once you are finished with the exercises, you can pause or delete your cluster.

To pause you cluster run:
```bash
minikube stop
```
And to delete your cluster run:
```bash
minikube delete
```
