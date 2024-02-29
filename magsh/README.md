# magsh - magasin shell Docker Image (experimental)

`magsh` is a docker image based on debian that includes all the commands required to install and admin magasin (kubectl, helm, mc (MinIO client) and mag-cli). 

To install _magasin_, certain prerequisites are required. While the magasin installer can automatically set them up for you, you may opt not to install them directly on your computer. Alternatively, you can utilize `magsh`, a prebuilt Docker image that contains all the necessary dependencies and commands to install and manage _magasin_. 

Simply running this Docker image will launch a bash shell equipped with all the common commands needed to manage a _magasin_ instance. This approach offers a convenient way to set up your environment and manage your _magasin_ instance without the need of installing the dependencies in you own computer.

## Running the pre-built Docker image

We have built an image that you can directly run. You can use the following command:

```sh
docker run -ti -P \
  -v ~/.kube/config:/kube/config \
  -v ~/.mc:/root/.mc \ 
  -v ~/magsh:/shared \
  merlos/magsh:latest
```

The image exposes the default ports of the different UIs of the components of magasin (Dagster, Apache Superset, Apache Drill,...) these are enabled if the `-P` option is passed to `docker run`. The complete list of ports can be found in the `Dockerfile`.

In addition to the common component port, it exposes the port `11000`, `11001` and `11002`. These can be used, to expose other services of the kubernetes cluster such as the port of a database service. 

The image configuration sets the `kubectl` configuration file is in `/kube/config` within its file system. You can map your computer kubernetes config file by adding `-v ~/.kube/config:/kube/config` when running `docker run`.

The command syncs the via the option `-v ~/.mc:/root/.mc`, the local computer [MinIO client config](https://min.io/docs/minio/linux/reference/minio-mc.html?ref=docs-redirect#id5), with the image one. So, if update any o them, it will be synced.

In the command above, also the folder `/shared` is used as a shared folder between your computer and the image. In your computer it will point to the `~/magsh` folder.

Note that the shell is run as the `root` user.

 
To ease create the following alias.

* **bash alias**
  ```sh
    echo "alias magsh='docker run -P -ti -v ~/.kube/config:/kube/config -v ~/.mc:/root/.mc -v ~/magsh:/shared merlos/magsh:latest'" >> ~/.bashrc
  ```

* **zsh alias**
    
    ```sh
    echo "alias magsh='docker run -P -ti -v ~/.kube/config:/kube/config -v ~/.mc:/root/.mc -v ~/mag-shared:/shared merlos/magsh:latest'" >> ~/.zshrc
    ```

After creating the alias, you will be able to run the shell just with:

```sh
magsh
```


### Testing sync command

To validate kubectl config is working run in the image shell:

```sh
kubectl config get-contexts
```

To validate the minio client is working run in the image shell

```sh 
mc alias list
```

## Development

If you need to customize the image, clone the repo, go to `magasin/magsh`, edit the `Dockerfile` and and run the `build.sh` script.

The `build.sh` script requires two arguments `-r` for indicating the registry (username, in the case of docker hub) and `-t` for the tag.  In addition to creating this tag, it always creates the `latest` tag when a build is successful.

Example:

```sh
./build.sh -r merlos -t 0.1.0
```

This will create an image called `merlos/magsh` and two tags `0.1.0` and `latest`. 

If the optional argument `-p` is added, then it pushes the image to the registry. In this case the image is created supporting [multi-platform](https://docs.docker.com/build/building/multi-platform/) (`linux/arm64`, `linux/amd64`). It also adds the `latest` tag.

```sh
build.sh -r merlos -t 0.1.0 -p
``` 

## License

Apache 2.0 License
