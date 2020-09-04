# ZeroJudge (Docker Image)
This is a Taiwanese online judge made into an Docker Image, which would then be able to use with Docker or Podman etc.

中文說明尚未完成 (Chinese Version of this readme is still in the works)

## Installation
1. Download the lxc container from my Google Drive [here](https://drive.google.com/file/d/1UVMDmFYb12o8kzIQDFSzO6etXNUWSsHZ/view?usp=sharing).
    * If you aren't comfortable downloading it from my drive and prefer to download from the orignal author himself, go to [his repository](https://github.com/jiangsir/ZeroJudge) and click on the link `請先下載 ZeroJudge虛擬機` then extract the `/var/lib/lxc/lxc-ALL/` folder within the virtual machine.

2. Install `lxc` on your system. 
   * Ubuntu/Debian: `apt-get install lxc`
   * CentOS: `yum -y install epel-release && yum -y install lxc`
       * If your LXC version is older than 2.1, you might need to change some new configuration keys to legacy ones. You could verify this by running `lxc-attach --version`. If you discover the need of switching, check out this table [here](https://github.com/lxc/lxd/issues/4396#issuecomment-378322166) to change the keys from the new one to the old ones.

3. Create folders for persistent storage and configuration file. The directory doesn't have to be this, but make sure to use the same directory for the below steps.
```sh
mkdir /container-zerojudge-data
mkdir /container-zerojudge-data/configs
mkdir /container-zerojudge-data/ssh
```

3. Do a `git clone https://github.com/superjeng1/ZeroJudge.git` and copy `ZeroJudge_CONSOLE` folder and `configs/ServerConfig.xml` file to `/container-zerojudge-data/ZeroJudge_CONSOLE` and `/container-zerojudge-data/configs/ServerConfig.xml` respectively. And then remove the git folder if you wish.
    * Note: This folder is for storing test-data for the challenges hosted on your site.
    * Note: The config file is for the judge itself, not the web interface.

4. Generate an SSH keypair for the container for it to control the lxc container on the host. Also mark the key authorised in the host.
```sh
ssh-keygen -f /container-zerojudge-data/ssh/id_rsa -t ecdsa -b 521 -q -N ""
cat /container-zerojudge-data/ssh/id_rsa.pub >> ~/authorized_keys
```
* **IMPORTANT: Take note of the current user that you are using, the second command below will permit the container to ssh into the host as the user. Also, the user must either be root, or able to sudo(Recommended).**

5. Make sure the folders have the correct permissions respectively.
```sh
chmod -R 770 /container-zerojudge-data/ZeroJudge_CONSOLE
chmod -R 770 /container-zerojudge-data/configs
chmod -R 700 /container-zerojudge-data/ssh
```

6. MySQL Database (I am still working on a empty SQL dump, check back later! Sorry for the inconvenience!)

7. Pull the docker image and mount some volumes from the host for persistent storage and the configuration file:
```sh
docker pull superjeng1/zerojudge:latest
docker run --name zerojudge \
  -v /container-zerojudge-data/configs/ServerConfig.xml:/etc/zerojudge/configs/ServerConfig.xml \
  -v /container-zerojudge-data/ssh:/etc/zerojudge/ssh \
  -v /container-zerojudge-data/disk/ZeroJudge_CONSOLE/:/ZeroJudge_CONSOLE/ \
  -v /var/lib/lxc/lxc-ALL/:/var/lib/lxc/lxc-ALL/ \
  -v /tmp/:/tmp/ \
  -e MY_SQL_IP='<MySql Database IP>' \
  -e MY_SQL_PORT='3306' \
  -e MY_SQL_DB_NAME='<MySql Database Name>' \
  -e MY_SQL_USERNAME='<MySql Username>' \
  -e MY_SQL_PASSWORD='<MySql Password>' \
  -d docker.io/superjeng1/zerojudge:latest
```
* Note: Make sure to put yourown MySql Settings in the quotes `''`. And make sure you don't leave the brackets `<>` in-place.
* For REVERSE PROXY USERS: Add the environment varible `REVERSE_PROXY_IP` with `-e REVERSE_PROXY_IP='<REVERSE_PROXY_IP>'` to make sure tomcat grabs the correct client IP.

8. Connect to your ZeroJudge with the container's IP and the port `8080`. To verify the container is working as intended, try to login with the default credentials listed below. Then go to the `Submissions` tab and re-run the submissions to make sure the judge is working properly.
```
Account: zero
Password: !@#$zerojudge
```

## Get in touch
If you have any questions or you encountered any problem when setting this up, feel free to open up an issue and I will make sure I would take a look at it.
