[![PullReview stats](https://www.pullreview.com/github/atmosx/pritory/badges/refactor.svg?)](https://www.pullreview.com/github/atmosx/pritory/reviews/refactor)

# Summary
**Pritory** is an [open source](http://en.wikipedia.org/wiki/Open_source), **price tracking application for small businesses**. **Pritory** aims to help small business owners to keep an organized and up-to-date overview of their local, regional and possibly international market for their products. 

# Installation
## Introduction
This is a step-by-step installation guide to help get **Pritory** up and running in no time! The guide assumes that you have access to a UNIX-based server. You can install all this software manually, but it's better to use your system's package manager. Under MacOSX you can use either [homebrew](http://brew.sh) or the [MacPorts](https://www.macports.org) to install the software packages.

## Packages
In order to install **Pritory** you need to install the following software packages to your server:
* The ruby programming language, any version >= 2.x
* A running MySQL database
* A running Redis key-value storege engine
* ImageMagick
* Nginx, not strictly necessary but higly recommended!

## Configure the MySQL database
First install the MySQL database and configure the root user. Here are some guides for [Ubuntu](https://help.ubuntu.com/12.04/serverguide/mysql.html), [MacPorts](http://jackal.livejournal.com/2160464.html) and [FreeBSD](http://www.freebsddiary.org/mysql.php). You can find guides for your system online.

Now create a MySQL database called `pritory` with the following command:
```
CREATE DATABASE tomato DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
```

Now let's create a MySQL user and grant privileges to manipulate our new database:
```
CREATE USER 'user'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON pritory.* TO 'user'@'localhost' WITH GRANT OPTION;
```
You can substitute `user` and `password` with whatever you like.

## Ruby, ImageMagick and Redis
Now install [ImageMagick](http://www.imagemagick.org) and [ruby](https://www.ruby-lang.org). The better approach to this is to follow the guidelines of your distribution's package manager. Compilation of `ImageMagick` take a while, especially if you enable `+x11` support! Do the same with [Redis](http://redis.io). Precompiled binaries are available for all major Linux distributions though. Remember to install MySQL dev-headers too!

## NGINX Configuration

Aworking example of NGINX, with OpenSSL support:
```
server {
  listen         80;
  server_name my.domain.net;
  return 301 https://$host$request_uri;
}

server {
  listen 443 ssl;
  server_name my.domain.net;
  client_max_body_size 2G;
  ssl_certificate /etc/ssl/path/to.crt;
  ssl_certificate_key /etc/ssl/path/to.key;
  ssl_session_timeout 5m;
  ssl_protocols SSLv3 TLSv1;
  ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv3:+EXP;
  ssl_prefer_server_ciphers on;

  root /home/user/code/pritory/public;
  try_files $uri @thin;

  location ^~ /assets/ {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    proxy_pass http://thin;
  }

  location ~* \.(jpeg|jpg|gif|png|ico|css|bmp|js)$ {
    root /home/user/code/pritory/public;
  }

# serve file as static if exists
  if (-f $request_filename)
  {
    break;
  }

  location @thin {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    proxy_pass http://thin;
  }
  error_page 500 502 503 504 /50x.html;
  location = /50x.html {
    root html;
  }
}

upstream thin {
  server 127.0.0.1:3000;
}
```
As you probably understood we will use [Thin](http://code.macournoyer.com/thin/usage/) as our default rack web server. Thin by default runs on port `3000`.

## Clone and install gems
Now we are ready to clone `pritory` and fetch the required gems:
```
mkdir $HOME/code && cd $HOME/code
git clone https://github.com/atmosx/pritory
cd pritory && bundle install
```
Compilation of the gems might also take a while. Also note installation of additional software might be needed!

## Create the configuration file
Create a configuration file called 'mysecrets.rb` in the project's root directory and pass the options the database options, like this:
```
#!/usr/bin/env ruby
module MySecrets
    DBUSER = 'dbuser'
    DBPASS = 'dbpass'
    ENVIR = 'production'
end
```
Please note that this file **doesn't exist** and you'll have to create it yourself in the root directory of the project!

Then create your user and any other user you like, manually via `irb` using the following commands:
```
cd $HOME/code/pritory
irb -r './pritory'
User.create(user: 'username', password: 'password')
```

Now you can run `thin start` on a `tmux` session and launch `nginx`. Then connect to the web age and perform your first login! Go straight to the 'Settings' menu and change the settings to whatever suits your needs.

#License
**Pritory** is released under [LGPLv3](https://www.gnu.org/licenses/lgpl-3.0.txt).

# Contact
Contact information at <atma@convalesco.org>
