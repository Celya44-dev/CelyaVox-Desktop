/**
 * Emplacements des fichiers de configuration (config.ini, sso.ini)
 *
 * Deux niveaux :
 *  - ADMINISTRATEUR : fichier déployé une fois par poste, commun à tous les utilisateurs.
 *      Linux   : /etc/celyavox/            (dev : /etc/celyavox-dev/)
 *      Windows : %ProgramData%\CelyaVox\   (dev : %ProgramData%\CelyaVox-dev\)
 *      macOS   : /Library/Application Support/CelyaVox/
 *    La variable d'environnement CELYAVOX_ADMIN_CONFIG_DIR, si définie, est prioritaire.
 *    Pour compatibilité, le répertoire d'installation est aussi accepté
 *    (<install>/resources/config.ini, <install>/resources/resources/config.ini, ...).
 *    ⚠️ Sous Windows ce répertoire est vidé à chaque mise à jour : préférer %ProgramData%.
 *
 *  - UTILISATEUR : fichier optionnel créé par l'utilisateur dans son profil.
 *      Linux   : ~/.config/CelyaVox/
 *      Windows : %APPDATA%\CelyaVox\
 *      macOS   : ~/Library/Application Support/CelyaVox/
 *
 * config.ini : valeurs par défaut ← fichier administrateur ← fichier utilisateur (clé par clé)
 * sso.ini    : fichier administrateur s'il existe, sinon fichier utilisateur
 *
 * Ce module ne dépend pas d'Electron : il est utilisable avant app.whenReady().
 */

const path = require('path');
const fs = require('fs');
const os = require('os');

function isDevEnv() {
  return (process.env.APP_ENV || 'prod') === 'dev';
}

function getAppDirName() {
  return isDevEnv() ? 'CelyaVox-dev' : 'CelyaVox';
}

/** Répertoire de l'utilisateur (= userData de l'application). */
function getUserConfigDir() {
  const appName = getAppDirName();
  const home = os.homedir();
  if (process.platform === 'win32') {
    const appData = process.env.APPDATA || path.join(home, 'AppData', 'Roaming');
    return path.join(appData, appName);
  }
  if (process.platform === 'darwin') {
    return path.join(home, 'Library', 'Application Support', appName);
  }
  return path.join(home, '.config', appName);
}

/** Répertoire système recommandé pour les fichiers administrateur. */
function getSystemConfigDir() {
  const appName = getAppDirName();
  if (process.platform === 'win32') {
    const programData = process.env.ProgramData || process.env.ALLUSERSPROFILE || 'C:\\ProgramData';
    return path.join(programData, appName);
  }
  if (process.platform === 'darwin') {
    return path.join('/Library', 'Application Support', appName);
  }
  return path.join('/etc', appName.toLowerCase());
}

/**
 * Répertoires administrateur, par ordre de priorité.
 * Le premier qui contient le fichier recherché est utilisé.
 */
function getAdminConfigDirs() {
  const dirs = [];

  // Emplacement personnalisé (variable d'environnement système), prioritaire
  if (process.env.CELYAVOX_ADMIN_CONFIG_DIR) {
    dirs.push(process.env.CELYAVOX_ADMIN_CONFIG_DIR);
  }

  dirs.push(getSystemConfigDir());

  // Compatibilité : répertoire d'installation de l'application packagée
  if (process.resourcesPath && !process.defaultApp) {
    dirs.push(process.resourcesPath);
    dirs.push(path.join(process.resourcesPath, 'resources'));
    dirs.push(path.join(process.resourcesPath, 'app.asar.unpacked', 'resources'));
  }

  // Développement (electron .) : racine du projet
  if (process.defaultApp || !process.resourcesPath) {
    dirs.push(__dirname);
    dirs.push(path.join(__dirname, 'resources'));
  }

  return dirs;
}

/** Premier fichier administrateur existant, ou null. */
function findAdminFile(fileName) {
  for (const dir of getAdminConfigDirs()) {
    const candidate = path.join(dir, fileName);
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

/** Fichier utilisateur s'il existe, ou null. */
function findUserFile(fileName) {
  const candidate = path.join(getUserConfigDir(), fileName);
  return fs.existsSync(candidate) ? candidate : null;
}

/** sso.ini à utiliser : administrateur en priorité, sinon utilisateur. */
function findSsoFile() {
  return findAdminFile('sso.ini') || findUserFile('sso.ini');
}

/** Liste lisible de tous les chemins examinés (pour les logs). */
function describeSearchPaths(fileName) {
  return {
    admin: getAdminConfigDirs().map(dir => path.join(dir, fileName)),
    user: path.join(getUserConfigDir(), fileName)
  };
}

/** Vrai si filePath est contenu dans dir (sans ambiguïté de préfixe). */
function isPathInside(filePath, dir) {
  if (!filePath || !dir) return false;
  const rel = path.relative(path.resolve(dir), path.resolve(filePath));
  return rel !== '' && !rel.startsWith('..') && !path.isAbsolute(rel);
}

module.exports = {
  getAppDirName,
  getUserConfigDir,
  getSystemConfigDir,
  getAdminConfigDirs,
  findAdminFile,
  findUserFile,
  findSsoFile,
  describeSearchPaths,
  isPathInside
};
