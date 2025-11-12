# Kubernetes Storage Tutorial

## Introduction

This tutorial should give an overview of the most important storage components in kubernetes while providing a balance of theory and practical hands-on excercises.
The workshop is setup up in such a way that we will first setup our dev-environment and install the dependencies that we neeed. After this is ready we can proceed to the exercises found under [./exercises/](./exercises/) and get familiar with the kubernetes storage system.

## Setup

First we need to install [`minikube`](https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fbinary+download). You can either do this with the official documentation or in case you have `devbox` installed just enter the `devbox` shell and you are ready to go.

To start you minikube cluster run the following command:
```bash
minikube start
```
Once the cluster is ready try to list all `namespaces` to make sure it works:
```bash
kubectl get namespaces
```

If you cluster is running create a `playground` namespace that we will use for the exercises.
```bash
kubectl create namespace playground
```
Perfect! Now you can continue with the tutorials under [./exercises/](./exercises/).
