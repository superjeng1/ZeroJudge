# ZeroJudge (Docker Image)
This is a Taiwanese online judge made into an Docker Image, which would then be able to use with Docker or Podman etc.

Built image is available on [GitHub Container Repository](https://github.com/users/superjeng1/packages/container/zerojudge/versions) and [Docker Hub](https://hub.docker.com/r/superjeng1/zerojudge)

**IMPORTANT: However, setup is REQUIRED before first run, please do follow the instructions below.**

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
mkdir /container-zerojudge-data/disk
mkdir /container-zerojudge-data/ssh
```

3. Do a `git clone https://github.com/superjeng1/ZeroJudge.git` and copy `ZeroJudge_CONSOLE` folder and `configs/ServerConfig.xml` file to `/container-zerojudge-data/disk/ZeroJudge_CONSOLE` and `/container-zerojudge-data/configs/ServerConfig.xml` respectively. And then remove the git folder if you wish.
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

6. Get the MySQL dumps from the author's repo [this](https://raw.githubusercontent.com/jiangsir/ZeroJudge/3.3/Schema_V3.0.sql) and [this](https://raw.githubusercontent.com/jiangsir/ZeroJudge/3.3/SchemaUpdate_V3.0.sql).

7. Modify the second file:
    * Line 3: Remove `DEFAULT ''` at near the end of the line
    * Line 4: Remove this line entirely.

8. Create MySQL database and user then import the dumps.
```sh
mysql -u root -p
<Enter Password>
CREATE DATABASE zerojudge;
CREATE USER 'zerojudge'@'%' IDENTIFIED WITH mysql_native_password BY '<Your Password of choice>';
FLUSH PRIVILEGES;
exit;
mysql -u root -p zerojudge < Schema_V3.0.sql
<Enter Password>
mysql -u root -p zerojudge < SchemaUpdate_V3.0.sql
<Enter Password>
mysql -u root -p
<Enter Password>
GRANT ALL ON zerojudge.* TO 'zerojudge'@'%';
FLUSH PRIVILEGES;
# If you need to login from external IP, do the two commented lines below
# USE DATABASE zerojudge;
# UPDATE appconfigs set manager_ip = '[0.0.0.0/0]';
# UPDATE appconfigs set allowedIP = '[0.0.0.0/0]';
exit;
```
* Note: You will likely change the above command. For example, you might want to specify the host of the user, or change the username and database name. Or you might want to use a container for MySQL. It doesn't mean you have to, but it's recommended.

7. Pull the docker image and mount some volumes from the host for persistent storage and the configuration file:
```sh
docker network create --subnet=<Subnet Example: 172.18.0.0/16> <Network Name>
docker pull ghcr.io/superjeng1/zerojudge:latest
docker run --name zerojudge \
  -v /container-zerojudge-data:/etc/zerojudge \
  -v /var/lib/lxc/lxc-ALL/:/var/lib/lxc/lxc-ALL/ \
  -e MY_SQL_PASSWORD='<MySql Password>' \
  --net <Network Name> --ip <IP for this container within the subnet above Example: 172.18.0.2> \
  -d ghcr.io/superjeng1/zerojudge:latest
```
* Note: Image is also available on Docker Hub, just replace GitHub Container Repository (ghcr.io) with docker.io to use that.
* Note: Look down below to find image tags and environment variables.
* Note: Make sure to put yourown MySql Settings in the quotes `''`. And make sure you don't leave the brackets `<>` in-place.
* Note: Make sure to put yourown settings replacing all the place holders surrounded by `<>`. And make sure you don't leave the brackets `<>` in-place.
* For REVERSE PROXY USERS: Add the environment varible `REVERSE_PROXY_IP` with `-e REVERSE_PROXY_IP='<REVERSE_PROXY_IP>'` to make sure tomcat grabs the correct client IP.

8. Connect to your ZeroJudge with the container's IP and the port `8080`. To verify the container is working as intended, try to login with the default credentials listed below. Then go to the `Submissions` tab and re-run the submissions to make sure the judge is working properly.
```
Account: zero
Password: !@#$zerojudge
```

## Docker Image Variants (Tags)
### `zerojudge:latest`
This is an image based on debian slim, and this should be kept stable every version. Just make sure you do `docker pull` before `docker run` to ensure docker pulls the newest avalible image.

### `zerojudge:latest-alpine`
This is an image based on alpine linux. This should be a way smaller image than latest since the base image size is way smaller (Alpine linux image comes in only 5 MB!). And like `zerojudge:latest` this should be kept stable every version. Just make sure you do `docker pull` before `docker run` to ensure docker pulls the newest avalible image.

## Environment Variables
### `MY_SQL_PASSWORD`
This variable is **mandatory** and specifies the password that will be used to connect to the MySQL instance.

### `MY_SQL_IP`
This variable tells tomcat where the MySQL instance is hosted. If not set, this defaults to the host's IP relative to the container.

### `MY_SQL_PORT`
This variable tells tomcat which port the MySQL instance is hosted. If not set, this defaults to 3306.

### `MY_SQL_DB_NAME`
This variable tells tomcat what the MySQL database name is. If not set, this defaults to `zerojudge`.

### `MY_SQL_USERNAME`
This variable specifies the username that will be used to connect to the MySQL instance. If not set, this defaults to `zerojudge`.

### `SSH_USER`
This variable specifies the username that will be used to `ssh` to the host. If not set, this defaults to `root`. And you should consider adding a system account and add the user to sudoers. Also only allow it to use the command `lxc-attach`. (This will be included in the tutorial later.)

### `SSH_HOST`
This variable specifies the host's IP relative to the container. If not set, the container will detect this for itself.

### `REVERSE_PROXY_IP`
This variable specifies the IP of reverse proxy relative to the container, and has no defaults.

### `TOMCAT_SSL_ENABLED`
This variable tells tomcat whether to use SSL. If you use reverse proxy, you might not need this. This defaults to `FALSE`.

## Get in touch
If you have any questions or you encountered any problem when setting this up, feel free to open up an issue and I will make sure I would take a look at it.
