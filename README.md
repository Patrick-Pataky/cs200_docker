# CS200 <!-- omit in toc -->

- [How to use](#how-to-use)
  - [Initial setup](#initial-setup)
  - [Install docker desktop and devcontainer extension for VSCode](#install-docker-desktop-and-devcontainer-extension-for-vscode)
  - [Launch the devcontainer](#launch-the-devcontainer)
  - [Working with the container](#working-with-the-container)
- [(Optional) Building the container from source](#optional-building-the-container-from-source)

## How to use

### Initial setup
Go to the directory where you want to work on the labs and run the following command:
```bash
git clone https://github.com/Patrick-Pataky/cs200_docker.git --no-checkout

cd cs200_docker
```

To hide the source files (skip only if you plan to build the container on your own):
```bash
git sparse-checkout init --cone
git sparse-checkout set .devcontainer.json
git checkout
```

And finally, open the folder in VSCode.
```bash
code .
```

### Install docker desktop and devcontainer extension for VSCode
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [VSCode Devcontainer](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [VSCode Remote Containers](https://aka.ms/vscode-remote/download/extension)

### Launch the devcontainer
- Hit `CTRL+SHIFT+P` and type `Dev Containers: Rebuild and Reopen in Container`

This should start the container and open the project in VSCode.

### Working with the container
By default, the container will start in the `cs200` directory, which contains the labs folder. 

For `lab1`, two versions are available: `lab1` and `lab1_fast`. You can work on both, as `lab1_fast` is simply a *symlink* to `lab1` with an accelerated simulation. Symlink means that any changes made in `lab1` will be reflected in `lab1_fast` and vice versa.

**!!! Important**
Do NOT modify the `lab1_fast` directory while the container is NOT running, as it will break the symlink.
**!!!**

Good luck!

## (Optional) Building the container from source

First, restore the source files, if they were hidden during the initial setup:
```bash
sudo chown -R $USER:$USER ./
git sparse-checkout disable
```

Then, build the container:
```bash
docker build -t cs200 .
```

Note that this will take a while, especially the RISC-V toolchain installation. In case you get errors or it is too slow, you can update the amount of parallel jobs in the `Dockerfile`:
```Dockerfile
ENV NB_THREADS=16
```

Finally, update the `.devcontainer.json` file to use the local image:
```json
"image": "cs200",
```
