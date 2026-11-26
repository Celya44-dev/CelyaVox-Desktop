# Fichiers de configuration `config.ini` et `sso.ini`

CelyaVox lit sa configuration à deux niveaux, pour qu'un administrateur puisse configurer
un poste partagé par plusieurs utilisateurs, tout en laissant chaque utilisateur
personnaliser ses propres réglages.

## 📁 Emplacements

### Fichiers ADMINISTRATEUR (un par poste, communs à tous les utilisateurs)

Le premier dossier qui contient le fichier est utilisé :

| Priorité | Emplacement |
|---|---|
| 1 | dossier défini dans la variable d'environnement `CELYAVOX_ADMIN_CONFIG_DIR` |
| 2 | **Linux** : `/etc/celyavox/` — **Windows** : `%ProgramData%\CelyaVox\` (en général `C:\ProgramData\CelyaVox\`) — **macOS** : `/Library/Application Support/CelyaVox/` |
| 3 | dossier d'installation, pour compatibilité : `<install>/resources/`, `<install>/resources/resources/`, `<install>/resources/app.asar.unpacked/resources/` |

En version **dev**, les dossiers système sont `/etc/celyavox-dev/`, `%ProgramData%\CelyaVox-dev\` et `/Library/Application Support/CelyaVox-dev/`.

> ⚠️ Sous Windows, le dossier d'installation est vidé à chaque mise à jour. Déposez les
> fichiers administrateur dans `%ProgramData%\CelyaVox\`.

### Fichiers UTILISATEUR (optionnels, dans le profil)

| Système | Emplacement |
|---|---|
| Linux | `~/.config/CelyaVox/` |
| Windows | `%APPDATA%\CelyaVox\` |
| macOS | `~/Library/Application Support/CelyaVox/` |

L'application ne crée **pas** de `config.ini` dans le profil : c'est l'utilisateur qui le crée s'il veut changer un réglage.

## 🔀 Règles de priorité

### `config.ini` : fusion clé par clé

```
valeurs par défaut (config.js)
   ← config.ini ADMINISTRATEUR
      ← config.ini UTILISATEUR
```

L'utilisateur ne met dans son fichier **que les clés qu'il veut changer**. Toutes les autres
viennent du fichier administrateur.

Exemple :

```ini
; /etc/celyavox/config.ini (administrateur)
[server]
serverUrl=https://celyavox.example.com/phone
[ui]
disableBuddies=1
Notifications=1
```

```ini
; ~/.config/CelyaVox/config.ini (utilisateur)
[ui]
Notifications=0
```

Résultat : `serverUrl` et `disableBuddies` viennent de l'administrateur, et `Notifications=0` de l'utilisateur.

### `sso.ini` : le fichier administrateur l'emporte

- Si un `sso.ini` administrateur existe, il est utilisé et le fichier utilisateur est ignoré.
- Sinon, le `sso.ini` du profil utilisateur est utilisé.
- Si aucun n'existe, un modèle entièrement commenté est copié dans le profil au premier lancement.

Le SSO n'est activé que si le fichier contient une section `[SAML]`, en majuscules, avec au moins une valeur non commentée.

### Fichiers référencés par nom (`profilePicture`, `CustomRingtone`)

Un nom de fichier comme `profilePicture=logo.png` est cherché dans le dossier du `config.ini`
qui définit la clé : celui de l'utilisateur s'il la définit, sinon celui de l'administrateur.
L'application ne peut lire que des fichiers situés dans les dossiers administrateur ou utilisateur.

## 🚀 Déploiement par l'administrateur

**Linux (.deb)**
```bash
sudo mkdir -p /etc/celyavox
sudo cp config.ini sso.ini /etc/celyavox/
sudo chmod 644 /etc/celyavox/*.ini
```

**Windows (GPO, Intune, script)**
```powershell
New-Item -ItemType Directory -Force "$env:ProgramData\CelyaVox"
Copy-Item config.ini, sso.ini "$env:ProgramData\CelyaVox\"
```

Les mises à jour de l'application ne touchent jamais à ces fichiers.

## 🔍 Logs

Au démarrage, le log indique les dossiers parcourus et les fichiers retenus :
```
🔍 Administrateur (premier trouvé):
  1. /etc/celyavox/config.ini  ✅
🔍 Utilisateur:
  /home/jean/.config/CelyaVox/config.ini  (absent)
```

Les logs sont écrits dans `<profil utilisateur>/logs/`.

## 🧩 Code

- [config-locations.js](config-locations.js) : emplacements et recherche, seul endroit à modifier pour changer un chemin.
- [config.js](config.js) : lecture et fusion de `config.ini`.
- [main.js](main.js) : `verifySSOStatus()`, `check-sso-file`, `initializeSAML()` (qui transmet le `sso.ini` retenu à `loadSAMLConfig`).
