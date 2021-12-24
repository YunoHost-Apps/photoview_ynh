# Photoview pour YunoHost

[![Niveau d'intégration](https://dash.yunohost.org/integration/photoview.svg)](https://dash.yunohost.org/appci/app/photoview) ![](https://ci-apps.yunohost.org/ci/badges/photoview.status.svg) ![](https://ci-apps.yunohost.org/ci/badges/photoview.maintain.svg)  
[![Installer photoview avec YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=photoview)

*[Read this readme in english.](./README.md)*

> *Ce package vous permet d'installer Photoview rapidement et simplement sur un serveur YunoHost.  
Si vous n'avez pas YunoHost, consultez [le guide](https://yunohost.org/#/install) pour apprendre comment l'installer.*

## Vue d'ensemble
Photoview est une galerie photos simple et facile à utiliser, conçue pour les photographes et qui vise à fournir un moyen simple et rapide pour naviguer dans les dossiers contenant des milliers de photos haute résolution.

**Version incluse :** 2.3.9

## Captures d'écran

![](https://github.com/photoview/photoview/raw/master/screenshots/timeline.png)

## Démo

* [Démo officielle](https://photos.qpqp.dk/) Nom d'utilisateur: **demo** Mot de pase: **demo**

## Configuration

Vous pouvez accéder à un panneau admin depuis l'interface web.

## Documentation

* Documentation officielle : https://photoview.github.io/docs/

#### Support multi-utilisateur

* L'authentification LDAP et HTTP est-elle prise en charge ? **Non**
* L'application peut-elle être utilisée par plusieurs utilisateurs ? **Oui**

#### Architectures supportées

* x86-64 - [![Build Status](https://ci-apps.yunohost.org/ci/logs/photoview.svg)](https://ci-apps.yunohost.org/ci/apps/photoview/)
* ARMv8-A - [![Build Status](https://ci-apps-arm.yunohost.org/ci/logs/photoview.svg)](https://ci-apps-arm.yunohost.org/ci/apps/photoview/)

## Liens

* Signaler un bug : https://github.com/YunoHost-Apps/photoview_ynh/issues
* Site de l'application : https://photoview.github.io/
* Dépôt de l'application principale : https://github.com/photoview/photoview
* Site web YunoHost : https://yunohost.org/

---

## Informations pour les développeurs

Merci de faire vos pull request sur la [branche testing](https://github.com/YunoHost-Apps/photoview_ynh/tree/testing).

Pour essayer la branche testing, procédez comme suit.
```
sudo yunohost app install https://github.com/YunoHost-Apps/photoview_ynh/tree/testing --debug
ou
sudo yunohost app upgrade photoview -u https://github.com/YunoHost-Apps/photoview_ynh/tree/testing --debug
```
