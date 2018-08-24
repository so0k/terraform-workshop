# Kops Workshop

This workshop will cover usage of [kubernetes/kops](https://github.com/kubernetes/kops) and utilities such as `channels`.

## Workshop Introduction

The `kops` tool aims to manage Kubernetes clusters in the same way Kubernetes itself manages resources: Through desired state manifests.

Kubernetes uses Etcd for state storage and similarly, Kops uses a **state store** which can either be Google Cloud Storage or S3 buckets. 

An S3 bucket for state storage is created as part of this Workshop setup.

Additionally, `kops` bundles a utility to deploy kubernetes add-ons called `channels` which we will cover in this workshop as well.

## Kops cluster maintenance

### Load env vars

On your workstation, an `.env` file has been created with all configuration kops needs for the following exercises.

Verify the contents of the `.env` file, then load these variables into your shell environment:

```bash
export $(cat .env | xargs)
```

### Get/Set cluster definitions

Ideally we keep these cluster definitions as manifests under source control (Infrastructure as code).

Review / Edit the cluster manifest

```bash
vim manifests/${CLUSTER_NAME}.yaml
```

Read more about specs in this manifest:

- [Cluster Spec](https://github.com/kubernetes/kops/blob/master/docs/cluster_spec.md)
- [Instance Groups](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md)

During cluster bootstrap, manifests are read from the state store by the bootstrapping components.
Thus, we need to ensure the manifests are updated into the state store.

Set:

```bash
kops replace --force -f manifests/${CLUSTER_NAME}.yaml
kops create secret --name=${CLUSTER_NAME} sshpublickey admin -i ~/.ssh/kops_key.pub
```

### Generate Terraform config

```bash
kops update cluster --name ${CLUSTER_NAME} \
  --target=terraform \
  --out=modules/clusters/${CLUSTER_NAME} 

kops update cluster \
		--name ${CLUSTER_NAME} \
		--out=modules/kops \
		--target=terraform
```

**Note** Add this stage, `kops` will automatically configure your `kubeconfig` as well. 
We can also manually get the `kubeconfig`: 

```bash
kops export --name ${CLUSTER_NAME} kubecfg
```

#### Build cluster

As we heavily use Terraform modules and manage infrastructure outside of Kubernetes using Terraform, we import the kops generated module into our `main.tf` file:

```hcl

```

Initialise, plan and apply the Terraform configuration:

```bash
terraform init
terraform apply -target module.channels
terraform apply -target module.kops
terraform apply
```

Wait for the cluster to be ready...

```bash
until kubectl cluster-info; do (( i++ ));echo "Cluster not available yet, waiting for 5 seconds ($i)"; sleep 5; done
```

**Troubleshooting**

-   Get the public IP from the master and ssh into it

    ```
    ssh -i ~/.ssh/kops_key admin@54.254.203.127
    ```

-   Check the status of the systemd units (kubelet / docker)

    ```
    sudo systemctl status kubelet
    sudo systemctl status docker
    ```

-   Follow the `kubelet` journal logs and look for errors

    ```
    sudo journalctl -u kubelet
    ```

-   Follow the `api-server` logs and look for errors

    ```
    sudo tail -f /var/log/kube-apiserver.log
    ```

## Kops addon channels

Kubernetes addons are bundles of resources that provide specific functionality (such as dashboards, auto scaling, ...). Multiple addons can be versioned together and managed through the concept of
addon channels. The `channels` tool bundled with `kops` aims to simplify the management of addons. The `channels` tool is similar to Helm, but without the need for a server side component - yet it can not provide the templating and release management provided by Helm.

Addon channels are defined as a list of addons stored in an `addons.yaml` file. This list  keeps track of all addon versions applicable for a particular channel. Each addon may have multiple
kubernetes resource manifests streamed into a single yaml file. The `channels` tool keeps track of which addon version is deployed in a cluster and automates
the creation of all addons in the channel.

### Deploy upstream channels

There are several upstream channels such as dashboard and heapster, we may install these as follows:

```bash
channels apply channel monitoring-standalone --yes
channels apply channel kubernetes-dashboard --yes
```

> Currently `channels` is hardcoded to prefix simple channel names such as `kubernetes-dashboard` by searching `master` in [kubernetes/kops/addons](https://github.com/kubernetes/kops/tree/master/addons/kubernetes-dashboard) for the `addons.yaml` list.
> See [channels/pkg/cmd/apply_channel.go](https://sourcegraph.com/github.com/kubernetes/kops@1.7.1/-/blob/channels/pkg/cmd/apply_channel.go#L90) source

At this stage, we can review all addons that were deployed by `channels` (notice several addons were deployed as part of kops cluster bootstrap)

```bash
channels get addons
```

> Good to know: behind the scene, `channels` uses annotations on the `kube-systems` namespace to keep track of deployed addon versions:

We can get similar output using `jq`:

```bash
kubectl get ns kube-system -o json | jq '.metadata.annotations | with_entries(select(.value | contains("addons"))) | map_values(fromjson | .version)'
```

Now that the dashboard is deployed - notice that as we did not make our cluster private, we can access the dashboard form anywhere (requires basic-auth):

https://api.bee02-cluster.training.honestbee.com/ui

Once we accepted the untrusted root cluster certificate, we can get a list of basic-auth credentials from our `kubeconfig`:

```bash
kubectl config view -o json | jq '[.users[] | select(.name | contains("basic-auth")) | {(.name): {(.user.username): .user.password}}]'
```

### Deploy custom Honestbee - beekeeper channel

As Honestbee depends on Helm for all of its deployments, we created our own addons channel called `beekeeper` to bootstrap Helm and 
other core Kubernetes addons (namespaces, service accounts, registry secrets, rbac, ...). On your workstation are sample addons for
practice purposes.

```
beekeeper/
├── addons.yaml
├── kube-state-metrics.addons.k8s.io
│   ├── README.md
│   ├── v1.0.1.yaml
│   └── v1.1.0-rc.0.yaml
├── namespaces.honestbee.io
│   └── k8s-1.7.yaml
└── tiller.addons.k8s.io
    └── k8s-1.7.yaml
```

To apply this channel to the cluster, run the following command:

```
channels apply channel -f beekeeper/addons.yaml --yes
```


## Cleaning up

### Delete cluster

As the cloud resources are managed through Terraform, the only thing we want to do is delete the manifest:

```bash
kops delete cluster --name ${CLUSTER_NAME} --unregister --yes
```

## Todo

- Add section about rolling updates
- Add section about `kops toolbox template`
- Add section on how to clean up clusters
