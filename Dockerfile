# Start from the proven, working base image
FROM rancher/k3s:v1.30.3-k3s1

# Try installing prerequisites using dnf (or yum, if dnf fails)
# Note: The K3s image might not have dnf or yum, but we must try.
RUN dnf update -y || yum update -y && \
    dnf install -y bash open-iscsi || yum install -y bash open-iscsi && \
    dnf clean all || yum clean all
