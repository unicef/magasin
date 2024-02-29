# Helm Charts for Apache Drill

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/magasin-drill)](https://artifacthub.io/packages/search?repo=magasin-drill)


This repository contains a collection of files that can be used to deploy [Apache Drill](http://drill.apache.org/) on [Kubernetes](https://kubernetes.io/) using [Helm Charts](https://helm.sh/). Supports single-node and [cluster](http://drill.apache.org/docs/installing-drill-in-distributed-mode/) modes.

This is an extended version of the originally chart created in [github.com/Agirish/drill-helm-charts](https://github.com/Agirish/drill-helm-charts). This extension has been created to fit the needs of [UNICEF's magasin](https://github.com/unicef/magasin).

## Pre-requisites
- A Kubernetes Cluster.
- [Helm](https://github.com/helm/helm#install) version 3.0 or greater.
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) version 1.16.0 or greater.

## Install

1.- Add the helm repo
    ```sh
    helm repo add magasin-drill https://unicef.github.io/magasin-drill/
    ```

2. Intall the chart
    ```sh
    helm install drill magasin-drill/drill --namespace magasin-drill --create-namespace
    ```

This will install Apache Drill within the namespace `magasin-drill`. If you skip `--namespace magasin-drill --create-namespace` the chart is installed in the `default` namespace. 

You can list the pods by running:

```shell
# kubectl get pods -n <namespace>
kubectl get pods -n magasin-drill
NAME         READY   STATUS    RESTARTS   AGE
drillbit-0   1/1     Running   0          5m3s
drillbit-1   1/1     Running   0          5m3s
zk-0         1/1     Running   0          5m3s 
```

Once all the pods  have the READY value as `1/1` and the `STATUS` is `Running`, you can launch the Drill Web UI using the `launch_ui.sh` script:

```shell
# ./scripts/launch_ui [-n <namespace>]
#  where namespace defaults to "magasin-drill"
./scripts/launch_ui.sh 

Open a browser at http://localhost:8087

Forwarding from 127.0.0.1:8047 -> 8047
Forwarding from [::1]:8047 -> 8047
```

Then open `http://localhost:8047` in a browser.

## Chart version

The chart appVersion displays the drill and zookeeper versions, respectively.
For example:

```shell
helm list -n magasin-drill
NAME 	NAMESPACE    	REVISION	UPDATED                            	STATUS  	CHART      	APP VERSION 
drill	magasin-drill	1       	2023-11-20 09:12:48.88172 +0300 EAT	deployed	drill-0.6.0	1.21.1-3.9.1
```

The helm chart version 0.6.0 comes with Apache Drill 1.21 and Zookeper 3.9.1.


### Customizing the setup

Helm Charts use `values.yaml` for providing default values to 'variables' used in the chart templates.  Refer to the [charts/drill/values.yaml](charts/drillvalues.yaml) file for details on default values for the charts.

You can create a `values.yaml`` file to overrides some of the default values. For example, by default the helm chart launches 2 drillbits, but you can set it to 1.

```yaml
# values.yaml
drill:
  count: 1
```

Then you add the `-f filename.yaml` or `--values filename.yaml` to the install command earlier 

```sh
helm install drill magasin-drill/drill -f values.yaml -n magasin-drill --create-namespace
```

If the setup already exist you can use `upgrade`:

```sh
helm upgrade drill magasin-drill/drill -n magasin-drill -f values.yaml
Release "drill" has been upgraded. Happy Helming!
NAME: drill
LAST DEPLOYED: Wed Nov  8 13:41:10 2023
NAMESPACE: magasin-drill
STATUS: deployed
REVISION: 2
TEST SUITE: None
```

Now, the cluster only has a drillbit:
```shell
kubectl get pods -n magasin-drill
NAME         READY   STATUS    RESTARTS       AGE
drillbit-0   0/1     Running   1 (22s ago)   156m
zk-0         1/1     Running   0              157m
```


### Override the storage plugin configuration

It is possible to deploy drill with a custom set of storage plugins (ie. connected to a set of storages such as Azure Blobs, S3 Buckets, etc.).

To do that:

1. Edit the configuration file: `storage-plugins-override.conf`.

2. Enable the storage plugin config overriding by setting to `true` the `drill.volumes.drillStorage.override` section in your values file `values.yaml` file.

```yaml
# values.yaml
drill:
  volumes: 
    drillStorage:
      override: true 
```

3. Create the `drill-storage-plugin-secret` secret. When a Drill chart is deployed, the files contained within this secret will be downloaded to each container and used by the drill-bit process during start-up. You can create the secret by running the script:

```shell
# ./scripts/create_secret.sh <namespace> 
./scripts/create_secret.sh -n magasin-drill -f <config-file>
```
or manually

```shell
kubectl create secret generic drill-storage-plugin-secret --from-file=storage-plugins-override.conf --namespace magasin-drill
```


#### Override drill config
You can enable config overriding by modifying the values of the `drill.volumes.configOverrides` in your customized `values.yaml` file. Example:


```yaml
# values.yaml
drill:
  volumes:
    # Make true if you want to add any volumes. Else, make false.
    add: true
    # Drill Configuration can be overridden by mounting them on each Drill container.
    configOverrides:
      # Contents of drill-override.conf
      # This file follows the HOCON format
      # https://github.com/lightbend/config/blob/master/HOCON.md
      # The available options are described: 
      # # https://drill.apache.org/docs/configuration-options-introduction/
      #
      # Alternatively on the web UI you can run the query:
      #
      # SELECT * FROM sys.boot;
      #
      drillOverrideConf: |
        drill.exec.options.exec.errors.verbose: true
      # Contents of drill-env.sh 
      drillEnvSh: |
        echo "Running drill-env.sh..."
        export DRILL_PID_DIR="/opt/drill"
        ps -ax
        env 
        #...
 

```

#### Allow access to Drill web UI from outside of the cluster.

By default, you can only access the Drill Web UI by performing a port forward to your localhost `using scripts/launch_ui.sh` or using `kubectl`:

`kubectl port-forward --namespace <namespace> service/drill-service 8047:8047`

For cloud based deployments, you can setup a `LoadBalancer` type [service](https://kubernetes.io/docs/concepts/services-networking/service/). This allows to access the drill web UI from outside the cluster through a public IP. Basically, this type of service acts like a proxy which internally redirects the HTTP requests to any of the available drill pods.

To enable the service, modify the flag `exposeWebService` in your `values.yaml` in the `drill` section.

```yaml
# values.yaml
drill:
  #...
  #...
  exposeWebService: true
  webServiceType: LoadBalancer
  #...
  #...
```
and proceed to upgrade the setup.

Alternatively, you can upgrade your setup just changing the value
```shell
 helm upgrade drill magasin-drill/drill -n magasin-drill --set drill.exposeWebService=true
```
Now the drill-web-svc shall appear. 
```shell
 kubectl get services -n magasin-drill
NAME            TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                                  AGE
drill-service   ClusterIP      10.96.253.218   <none>          8047/TCP,31010/TCP,31011/TCP,31012/TCP   28s
drill-web-svc   LoadBalancer   10.96.20.170    23.16.193.208   8047:31889/TCP,31010:31926/TCP           28s
zk-service      ClusterIP      10.96.54.14     <none>          2181/TCP,2888/TCP,3888/TCP               2
```

You can open http://[external-ip]:8047 to access the cluster.

Exposing the cluster externally is **not recommended without enabling the authentication**. Anyone will be able to access your drill!!! 

You can read more on [drill documentation about how to enable authentication](https://drill.apache.org/docs/securing-drill-introduction/)


### Deploy multiple drill clusters
Kubernetes [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) can be used when more that one Drill Cluster needs to be created. The `default` namespace is used by default. 

```shell
# helm install <release-name> repo/chart --namespace <namespace> --create-namespace
helm install drill2 magasin-drill/drill --namespace magasin-drill2 --create-namespace
```

Note that installing the Drill Helm Chart also installs the dependent Zookeeper chart. So with current design, for each instance of a Drill cluster includes a single-node Zookeeper.

```shell
kubectl get pods -n magasin-drill2
NAME                       READY   STATUS    RESTARTS   AGE
drill2bit-0                1/1     Running   0          51s
drill2bit-1                1/1     Running   0          51s
zk-0                       1/1     Running   0          51s
```

You can use the `launch_ui.sh` script with the `-n <namespace>` as argument

```shell
./scripts/launch_ui.sh -n magasin-drill2
```

### Upgrading Drill Charts

Currently only scaling up/down the number of Drill pods is supported as part of Helm Chart upgrades. To resize a Drill Cluster, edit the `values.yaml` file and apply the changes as below:


```shell
# 
helm upgrade drill1 magasin-drill/drill -f values.yaml

# If cloned this repo
# helm upgrade <release-name> repo/chart/
helm upgrade drill1 magasin-drill/drill
```
Alternatively, provide the count as a part of the `upgrade` command:

```shell
# helm upgrade <release-name> repo/chart --set drill.count=2
helm upgrade drill1 magasin-drill/drill --set drill.count=2
```

### Autoscaling Drill Clusters
The size of the Drill cluster (number of Drill Pod replicas / number of drill-bits) can not only be manually scaled up or down as shown above, but can also be autoscaled to simplify cluster management. When enabled, with a higher CPU utilization, more drill-bits are added automatically and as the cluster load goes down, so do the number of drill-bits in the Drill Cluster. The drill-bits deemed excessive [gracefully shut down](https://drill.apache.org/docs/stopping-drill/#gracefully-shutting-down-the-drill-process), by going into quiescent mode to permit running queries to complete.

Enable autoscaling by editing the drill.autoscale section in `charts/drill/values.yaml` file.

```yaml
# values.yaml
drill:
  #...
  #..
  autoscale:
    # Flag to turn-on / turn-off this option
    enabled: true
    # Maximum number of Drill Pods
    maxCount: 4
    # Target CPU Utilization Percentage
    cpuThreshold: 75
```

If autoscaling is enabled:

```shell
# helm upgrade <release-name> repo/chart --set drill.count=<new-min-count> --set drill.autoscale.maxCount=<new-max-count>
helm upgrade drill1 magasin-drill/drill --set drill.count=3 --set drill.autoscale.maxCount=6
```


### Package
Drill Helm Charts can be packaged for distribution as follows:

```sh
helm package charts/drill/
Successfully packaged chart and saved it to: /xxx/magasin-drill/drill-1.0.0.tgz
```

### Uninstall
Drill Helm Charts can be uninstalled as follows: 

```shell
# helm [uninstall|delete] <HELM_INSTALL_RELEASE_NAME> -n <namespace>
helm delete drill1
helm delete drill2
```
Note that `LoadBalancer` and a few other Kubernetes resources may take a while to terminate. Before re-installing Drill Helm Charts, please make sure to wait until all objects from any previous installation (in the same namespace) have terminated.

## Building custom docker images

The [`docker/`](docker/) directory contains everything required to build and customize the Docker images of Apache Drill and Apache ZooKeeper included in the helm chart.

Already built docker images are available in [Docker Hub](https://hub.docker.com/u/merlos/). 

Once you have updated the images, you need to replace the 'image' option in your `values.yaml` file.

To update the drill image edit the `drill.image` value:

```yaml
drill:
  #...
  # Change the line below with your custom image
  image: merlos/drill:1.21.1-multi-arch 
```

And, in the zookeeper section:
```yaml
zookeper: 
  #...
  #...
  # Change the line below with your custom image
  image: merlos/zookeeper:3.9.1-multi-arch
```


## Troubleshooting

Assuming we have installed the helm chart in the `magasin-drill` namespace we'll explore how to fix an issue

Check the health of the pods:

```shell
kubectl get pods -n magasin-drill
NAME         READY   STATUS             RESTARTS   AGE
drillbit-0   0/1     Running            0          4m25s
drillbit-1   0/1     Running            0          4m25s
zk-0         1/1     Running            0          4m5s
```
If after a few min the status is not Running as well as the readiness is "1/1", then you may be spotting a problem.

In that case, it is good to expand on the status of the pod. To do that you can use the describe pod kubectl command.

Generally you'll need to take a deeper look to the Events section:

```shell
# kubectl describe pod <podname> -n <namespace> 
kubectl describe pod drillbit-0 -n magasin-drill
Name:             drillbit-0
Namespace:        magasin-drill
Priority:         0
Service Account:  drill-sa
...
...
...

Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  2m                 default-scheduler  Successfully assigned magasin-drill/drillbit-0 to aks-systempool-32354579-vmss00000o
  Normal   Pulling    2m                 kubelet            Pulling image "busybox"
  Normal   Pulled     119s               kubelet            Successfully pulled image "busybox" in 756.658172ms (756.671572ms including waiting)
  Normal   Created    119s               kubelet            Created container zk-available
  Normal   Started    119s               kubelet            Started container zk-available
  Normal   Pulling    118s               kubelet            Pulling image "merlos/drill:1.21.1"
  Normal   Pulled     117s               kubelet            Successfully pulled image "merlos/drill:1.21.1" in 730.646907ms (730.656407ms including waiting)
  Normal   Created    117s               kubelet            Created container drill-pod
  Normal   Started    117s               kubelet            Started container drill-pod
  Warning  Unhealthy  30s (x3 over 90s)  kubelet            Liveness probe failed: Running drill-env.sh...
/opt/drill/drillbit.pid file is present but drillbit is not running.
[WARN] Only DRILLBIT_MAX_PROC_MEM is defined. Auto-configuring for Heap & Direct memory
[INFO] Attempting to start up Drill with the following settings
  DRILL_HEAP=1G
  DRILL_MAX_DIRECT_MEMORY=3G
  DRILLBIT_CODE_CACHE_SIZE=768m
  Warning  Unhealthy  25s (x4 over 90s)  kubelet  Readiness probe failed: Running drill-env.sh...
/opt/drill/drillbit.pid file is present but drillbit is not running.
[WARN] Only DRILLBIT_MAX_PROC_MEM is defined. Auto-configuring for Heap & Direct memory
[INFO] Attempting to start up Drill with the following settings
  DRILL_HEAP=1G
  DRILL_MAX_DIRECT_MEMORY=3G
  DRILLBIT_CODE_CACHE_SIZE=768m

```

In this case, among the info, we see the line bellow, that tells us that the drillbit is not running. 

```
/opt/drill/drillbit.pid file is present but drillbit is not running.
```

But this is not enough info. Another thing we can try is to display the logs:

```shell
# kubectl logs <pod> -n <namespace> -f
kubectl logs drillbit-0 -n magasin-drill -f

Defaulted container "drill-pod" out of: drill-pod, zk-available (init)
sed: cannot rename /opt/drill/conf/sedQRvtNI: Device or resource busy
sed: cannot rename /opt/drill/conf/sed6kHmUI: Device or resource busy
Running drill-env.sh...
[WARN] Only DRILLBIT_MAX_PROC_MEM is defined. Auto-configuring for Heap & Direct memory
[INFO] Attempting to start up Drill with the following settings
  DRILL_HEAP=1G
  DRILL_MAX_DIRECT_MEMORY=3G
  DRILLBIT_CODE_CACHE_SIZE=768m
Starting drillbit, logging to /var/log/drill/drillbit.out
Running drill-env.sh...
[WARN] Only DRILLBIT_MAX_PROC_MEM is defined. Auto-configuring for Heap & Direct memory
[INFO] Attempting to start up Drill with the following settings
  DRILL_HEAP=1G
  DRILL_MAX_DIRECT_MEMORY=3G
  DRILLBIT_CODE_CACHE_SIZE=768m
drillbit is running.

```

The `-f` argument will display new logs continuously. In this case, these logs do not give us any additional clue. So, next step is to look inside of the pod itself:

```sh
# kubectl exec <pod> -n <namespace> -ti -- <command> 
kubectl exec drillbit-0 -n magasin-drill -ti -- /bin/bash
```

This command will launch a shell within the pod. `-ti` is to allow interactive mode.

Within the shell we can explore the `/opt/drill/conf` and `/var/log/drill/` folders.

```sh
[root@drillbit-0 /]# pwd
/
[root@drillbit-0 /]# cd /opt/drill/conf/
[root@drillbit-0 conf]# ls
core-site-example.xml  drill-metastore-override-example.conf  logback.xml
distrib-env.sh         drill-on-yarn-example.conf             saffron.properties
distrib-setup.sh       drill-override-example.conf            storage-plugins-override-example.conf
drill-am-log.xml       drill-override.conf                    yarn-client-log.xml
drill-distrib.conf     drill-setup.sh
drill-env.sh           drill-sqlline-override-example.conf
[root@drillbit-0 conf]# 
```

The `drill-env.sh` is the custom script that is run prior to launching the pod. You can check that the contents are the ones you set in `values.yaml`.
The `drill-override.conf` is the custom configuration you set in `values.yaml`.

In the logs folder we have two files:
```
root@drillbit-0 conf]# cd /var/log/drill/
[root@drillbit-0 log]# ls
drillbit.log  drillbit.out  drillbit_queries.json
[root@drillbit-0 log]# 
```

We can explore `drillbit.log` and `drillbit.out`

```shell
[root@drillbit-0 log]# cat drillbit.out 
OpenJDK 64-Bit Server VM warning: If the number of processors is expected to increase from one, then you should configure the number of parallel GC threads appropriately using -XX:ParallelGCThreads=N
Exception in thread "main" com.typesafe.config.ConfigException$Parse: drill-override.conf @ file:/opt/drill/conf/drill-override.conf: 5: unbalanced close brace '}' with no open brace (if you intended '}' to be part of a key or string value, try enclosing the key or value in double quotes)
	at com.typesafe.config.impl.ConfigDocumentParser$ParseContext.parseError(ConfigDocumentParser.java:201)
	at com.typesafe.config.impl.ConfigDocumentParser$ParseContext.parseError(ConfigDocumentParser.java:197)
	at com.typesafe.config.impl.ConfigDocumentParser$ParseContext.parseObject(ConfigDocumentParser.java:434)
	at com.typesafe.config.impl.ConfigDocumentParser$ParseContext.parse(ConfigDocumentParser.java:648)
	at com.typesafe.config.impl.ConfigDocumentParser.parse(ConfigDocumentParser.java:14)
	at com.typesafe.config.impl.Parseable.rawParseValue(Parseable.java:262)
	at com.typesafe.config.impl.Parseable.rawParseValue(Parseable.java:250)
	at com.typesafe.config.impl.Parseable.parseValue(Parseable.java:180)
	at com.typesafe.config.impl.Parseable.parseValue(Parseable.java:174)
	at com.typesafe.config.impl.Parseable.parseValue(Parseable.java:309)
	at com.typesafe.config.impl.Parseable$ParseableResources.rawParseValue(Parseable.java:738)
	at com.typesafe.config.impl.Parseable$ParseableResources.rawParseValue(Parseable.java:701)
	at com.typesafe.config.impl.Parseable.parseValue(Parseable.java:180)
	at com.typesafe.config.impl.Parseable.parseValue(Parseable.java:174)
	at com.typesafe.config.impl.Parseable.parse(Parseable.java:152)
	at com.typesafe.config.impl.SimpleIncluder.fromBasename(SimpleIncluder.java:172)
	at com.typesafe.config.impl.ConfigImpl.parseResourcesAnySyntax(ConfigImpl.java:133)
	at com.typesafe.config.ConfigFactory.parseResourcesAnySyntax(ConfigFactory.java:1083)
	at com.typesafe.config.ConfigFactory.load(ConfigFactory.java:118)
	at com.typesafe.config.ConfigFactory.load(ConfigFactory.java:79)
	at org.apache.drill.common.config.DrillConfig.create(DrillConfig.java:270)
	at org.apache.drill.common.config.DrillConfig.create(DrillConfig.java:165)
	at org.apache.drill.common.config.DrillConfig.create(DrillConfig.java:149)
	at org.apache.drill.exec.server.Drillbit.start(Drillbit.java:556)
	at org.apache.drill.exec.server.Drillbit.main(Drillbit.java:552)
[root@drillbit-0 log]# command terminated with exit code 137
```

There is one line:

```
Exception in thread "main" com.typesafe.config.ConfigException$Parse: drill-override.conf @ file:/opt/drill/conf/drill-override.conf: 5: unbalanced close brace '}' with no open brace (if you intended '}' to be part of a key or string value, try enclosing the key or value in double quotes)
```

In this case the line tells us that there is a `}` in excess. Let's check it in the file:

```sh
[root@drillbit-0 /]# cat /opt/drill/conf/drill-override.conf 

exec.errors: { 
    verbose: true
}
}
[root@drillbit-0 /]# 
```
Effectively that is the case.
Now, we just need to update the `values.yaml` file and install again the chart.

### Error: ImagePullBackOff in minikube

For testing purposes you may be running your cluster in [minikube](https://minikube.sigs.k8s.io/). We have experimented  `Error: ImagePullBackOff` errors. 

For example after running

```shell
kubectl describe pods zk-0 -n magasin-drill
```

You may see something like:
```
Events:
  Type     Reason     Age                  From               Message
  ----     ------     ----                 ----               -------
  Normal   Scheduled  2m40s                default-scheduler  Successfully assigned magasin-drill/zk-0 to minikube
  Warning  Failed     37s                  kubelet            Failed to pull image "merlos/zookeeper:3.9.1": rpc error: code = Unknown desc = context deadline exceeded
  Warning  Failed     37s                  kubelet            Error: ErrImagePull
  Normal   BackOff    37s                  kubelet            Back-off pulling image "merlos/zookeeper:3.9.1"
  Warning  Failed     37s                  kubelet            Error: ImagePullBackOff
  Normal   Pulling    22s (x2 over 2m40s)  kubelet            Pulling image "merlos/zookeeper:3.9.1"

```
In this case, you can fix the issue by pulling the image manually using the following command:

```shell
# minikube image pull <image-name>
minikube image pull merlos/zookeeper:3.9.1
minikube image pull merlos/drill:1.21.1
```
These will download the images locally so they'll be available. Use `minikube image ls` to view the images available and `minikube image remove <image-name>` to remove them.

## The chart structure
Apache Drill Helm charts are organized as a collection of files inside of the `charts/drill/` directory. As Drill depends on [Apache Zookeeper](https://zookeeper.apache.org/) for cluster co-ordination, a zookeeper chart is inside the dependencies folder ['charts/drill/charts'](charts/drill/charts/). The Zookeeper chart follows a similar structure as the Drill chart.

```
charts/drill/   
  Chart.yaml    # A YAML file with information about the chart
  values.yaml   # The default configuration values for this chart
  charts/       # A directory containing the Zookeeper (zk) charts
  templates/    # A directory of templates, when combined with values, will generate valid Kubernetes manifest files
```

#### Templates
Helm Charts contain `templates` which are used to generate Kubernetes manifest files. These are YAML-formatted resource descriptions that Kubernetes can understand. These templates contain 'variables', values for which  are picked up from the `values.yaml` file.

Drill Helm Charts contain the following templates:
```
charts/drill/
  ...
  templates/
    drill-rbac-*.yaml       # To enable RBAC for the Drill app
    drill-service.yaml      # To create a Drill Service
    drill-web-service.yaml  # To expose Drill's Web UI externally using a LoadBalancer. Works on cloud deployments only. 
    drill-statefulset.yaml  # To create a Drill cluster
  charts/
    zookeeper/
      ...
      templates/
        zk-rbac.yaml        # To enable RBAC for the ZK app
        zk-service.yaml     # To create a ZK Service
        zk-statefulset.yaml # To create a ZK cluster. Currently only a single-node ZK (1 replica) is supported
```

## License 

Apache License 2.0 UNICEF.org

Note tha this is an updated version of the original: https://github.com/Agirish/drill-helm-charts
