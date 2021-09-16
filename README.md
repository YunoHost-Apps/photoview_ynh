# Photoview for YunoHost

[![Integration level](https://dash.yunohost.org/integration/photoview.svg)](https://dash.yunohost.org/appci/app/photoview) ![](https://ci-apps.yunohost.org/ci/badges/photoview.status.svg) ![](https://ci-apps.yunohost.org/ci/badges/photoview.maintain.svg)  
[![Install photoview with YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=photoview)

*[Lire ce readme en français.](./README_fr.md)*

> *This package allows you to install Photoview quickly and simply on a YunoHost server.  
If you don't have YunoHost, please consult [the guide](https://yunohost.org/#/install) to learn how to install it.*

## Overview
Photoview is a simple and user-friendly photo gallery that's made for photographers and aims to provide an easy and fast way to navigate directories, with thousands of high resolution photos.

**Shipped version:** 2.3.6

## Screenshots

![](https://github.com/photoview/photoview/raw/master/screenshots/timeline.png)

## Demo

* [Official demo](https://photos.qpqp.dk/) Username: **demo** Password: **demo**

## Configuration

You can access an admin panel from the web interface.

## Documentation

* Official documentation: https://photoview.github.io/docs/

#### Multi-user support

Are LDAP and HTTP auth supported? **No**
Can the app be used by multiple users? **Yes**

#### Supported architectures

* x86-64 - [![Build Status](https://ci-apps.yunohost.org/ci/logs/photoview.svg)](https://ci-apps.yunohost.org/ci/apps/photoview/)
* ARMv8-A - [![Build Status](https://ci-apps-arm.yunohost.org/ci/logs/photoview.svg)](https://ci-apps-arm.yunohost.org/ci/apps/photoview/)

## Links

* Report a bug: https://github.com/YunoHost-Apps/photoview_ynh/issues
* App website: https://photoview.github.io/
* Upstream app repository: https://github.com/photoview/photoview
* YunoHost website: https://yunohost.org/

---

## Developer info

Please send your pull request to the [testing branch](https://github.com/YunoHost-Apps/photoview_ynh/tree/testing).

To try the testing branch, please proceed like that.
```
sudo yunohost app install https://github.com/YunoHost-Apps/photoview_ynh/tree/testing --debug
or
sudo yunohost app upgrade photoview -u https://github.com/YunoHost-Apps/photoview_ynh/tree/testing --debug
```
