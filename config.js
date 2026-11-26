/**
 * Configuration pour les environnements dev/prod
 *
 * Ordre de fusion (clé par clé) :
 *   1. valeurs par défaut ci-dessous
 *   2. config.ini ADMINISTRATEUR (déployé par poste, commun à tous les utilisateurs)
 *   3. config.ini UTILISATEUR (optionnel, créé par l'utilisateur dans son profil)
 * Voir config-locations.js pour les emplacements.
 */

const packageJson = require('./package.json');
const path = require('path');
const fs = require('fs');
const ini = require('ini');
const locations = require('./config-locations');

// Lire l'environnement depuis package.json config ou variable d'environnement
const environment = process.env.APP_ENV || packageJson.config?.environment || 'dev';

// Queue pour stocker les logs avant que le logger global soit initialisé
let logQueue = [];
const queueLog = (message, level = 'INFO') => {
  logQueue.push({ message, level, timestamp: new Date().toISOString() });
};

// Helper pour loguer avec un logger ou queue
const logMessage = (message, level = 'INFO') => {
  if (global.logger) {
    if (level === 'INFO') global.logger.info(message);
    else if (level === 'ERROR') global.logger.error(message);
    else if (level === 'WARN') global.logger.warn(message);
  } else {
    queueLog(message, level);
  }
};

// Fonction pour vider la queue dans le logger
const flushLogQueue = () => {
  if (global.logger && logQueue.length > 0) {
    logQueue.forEach(({ message, level }) => {
      if (level === 'INFO') global.logger.info(message);
      else if (level === 'ERROR') global.logger.error(message);
      else if (level === 'WARN') global.logger.warn(message);
    });
    logQueue = [];
  }
};


// ============================================================
// Lecture des fichiers config.ini (administrateur puis utilisateur)
// ============================================================
function readIniFile(filePath, label) {
  if (!filePath) return {};
  try {
    const parsed = ini.parse(fs.readFileSync(filePath, 'utf-8'));
    logMessage(`✅ config.ini ${label} chargé: ${filePath}`);
    return parsed;
  } catch (err) {
    logMessage(`❌ Erreur lors de la lecture de config.ini ${label} (${filePath}): ${err.message}`, 'ERROR');
    return {};
  }
}

const searchPaths = locations.describeSearchPaths('config.ini');
const adminConfigPath = locations.findAdminFile('config.ini');
const userConfigPath = locations.findUserFile('config.ini');

logMessage(`
🔍 RECHERCHE CONFIG.INI (Environnement: ${environment})
🔍 Administrateur (premier trouvé):
${searchPaths.admin.map((p, i) => `  ${i + 1}. ${p}${p === adminConfigPath ? '  ✅' : ''}`).join('\n')}
🔍 Utilisateur:
  ${searchPaths.user}${userConfigPath ? '  ✅' : '  (absent)'}`);

const adminIni = readIniFile(adminConfigPath, 'ADMINISTRATEUR');
const userIni = readIniFile(userConfigPath, 'UTILISATEUR');

// Fusion clé par clé : l'utilisateur surcharge l'administrateur, section par section
function mergeIni(base, override) {
  const result = {};
  for (const source of [base, override]) {
    for (const [section, values] of Object.entries(source)) {
      if (values && typeof values === 'object') {
        result[section] = { ...(result[section] || {}), ...values };
      } else {
        result[section] = values;
      }
    }
  }
  return result;
}

const iniConfig = mergeIni(adminIni, userIni);

// Répertoire des fichiers référencés par nom (profilePicture, CustomRingtone) :
// celui du fichier qui définit ces clés, sinon celui de l'utilisateur, sinon celui de l'administrateur.
function definesUiFile(parsed) {
  return parsed.ui && (parsed.ui.profilePicture !== undefined || parsed.ui.CustomRingtone !== undefined);
}
let configDirectory;
if (userConfigPath && definesUiFile(userIni)) {
  configDirectory = path.dirname(userConfigPath);
} else if (adminConfigPath && definesUiFile(adminIni)) {
  configDirectory = path.dirname(adminConfigPath);
} else {
  configDirectory = path.dirname(userConfigPath || adminConfigPath || path.join(locations.getUserConfigDir(), 'config.ini'));
}

// Configuration par défaut pour chaque environnement
const config = {
  dev: {
    serverUrl: 'https://freepbx17-dev.celya.fr/celyavox',
    appName: 'CelyaVox Dev',
    productName: 'CelyaVox-dev',
    appId: 'fr.celya.celyavox.dev',
    window: {
      width: 1280,
      height: 820
    },
    ui: {
      disableBuddies: false,
      disableDoNotDisturb: false,
      disableCallForward: false,
      disableGUISipAccount: false,
      Notifications: true,
      profilePicture: null,
      CustomRingtone: null
    },
    audio: {
      ringerOutputLabel: null,  // Label du device de sortie pour la sonnerie
      ringerGain: 1.0           // Volume de la sonnerie (0.0 à 1.0)
    }
  },
  prod: {
    serverUrl: 'https://celyavox.celya.fr/phone',
    appName: 'CelyaVox',
    productName: 'CelyaVox',
    appId: 'fr.celya.celyavox',
    window: {
      width: 1280,
      height: 820
    },
    ui: {
      disableBuddies: false,
      disableDoNotDisturb: false,
      disableCallForward: false,
      disableGUISipAccount: false,
      Notifications: true,
      profilePicture: null,
      CustomRingtone: null
    },
    audio: {
      ringerOutputLabel: null,  // Label du device de sortie pour la sonnerie
      ringerGain: 1.0           // Volume de la sonnerie (0.0 à 1.0)
    }
  }
};

// Exporter la config selon l'environnement
const currentConfig = config[environment] || config.dev;

logMessage(`
📋 FUSION CONFIG:
INI fusionné (administrateur ← utilisateur):
${JSON.stringify(iniConfig, null, 2)}

Config par défaut (${environment}):
${JSON.stringify(currentConfig, null, 2)}`);

// Deep merge avec la config INI (surcharge les valeurs par défaut)
const mergedConfig = JSON.parse(JSON.stringify(currentConfig)); // Clone profond

if (iniConfig.window) {
  mergedConfig.window = mergedConfig.window || {};
  logMessage(`  📐 Paramètres window trouvés dans INI: ${JSON.stringify(iniConfig.window)}`);
  // Convertir en nombres si c'est des strings
  if (iniConfig.window.width) {
    mergedConfig.window.width = parseInt(iniConfig.window.width, 10) || currentConfig.window.width;
    logMessage(`    ✅ width: ${mergedConfig.window.width}`);
  }
  if (iniConfig.window.height) {
    mergedConfig.window.height = parseInt(iniConfig.window.height, 10) || currentConfig.window.height;
    logMessage(`    ✅ height: ${mergedConfig.window.height}`);
  }
}

if (iniConfig.ui) {
  mergedConfig.ui = mergedConfig.ui || {};
  logMessage(`  🎛️  Paramètres UI trouvés dans INI: ${JSON.stringify(iniConfig.ui)}`);
  // Convertir les booléens (0/1 ou true/false)
  if (iniConfig.ui.disableBuddies !== undefined) {
    mergedConfig.ui.disableBuddies = iniConfig.ui.disableBuddies === '1' || iniConfig.ui.disableBuddies === true;
    logMessage(`    ✅ disableBuddies: ${mergedConfig.ui.disableBuddies}`);
  }
  if (iniConfig.ui.disableDoNotDisturb !== undefined) {
    mergedConfig.ui.disableDoNotDisturb = iniConfig.ui.disableDoNotDisturb === '1' || iniConfig.ui.disableDoNotDisturb === true;
    logMessage(`    ✅ disableDoNotDisturb: ${mergedConfig.ui.disableDoNotDisturb}`);
  }
  if (iniConfig.ui.disableCallForward !== undefined) {
    mergedConfig.ui.disableCallForward = iniConfig.ui.disableCallForward === '1' || iniConfig.ui.disableCallForward === true;
    logMessage(`    ✅ disableCallForward: ${mergedConfig.ui.disableCallForward}`);
  }
  if (iniConfig.ui.disableGUISipAccount !== undefined) {
    mergedConfig.ui.disableGUISipAccount = iniConfig.ui.disableGUISipAccount === '1' || iniConfig.ui.disableGUISipAccount === true;
    logMessage(`    ✅ disableGUISipAccount: ${mergedConfig.ui.disableGUISipAccount}`);
  }
  if (iniConfig.ui.Notifications !== undefined) {
    logMessage(`    🔍 DEBUG Notifications brut: "${iniConfig.ui.Notifications}" (type: ${typeof iniConfig.ui.Notifications})`);
    mergedConfig.ui.Notifications = iniConfig.ui.Notifications === '1' || iniConfig.ui.Notifications === true;
    logMessage(`    ✅ Notifications: ${mergedConfig.ui.Notifications}`);
  }
  if (iniConfig.ui.profilePicture !== undefined) {
    mergedConfig.ui.profilePicture = iniConfig.ui.profilePicture;
    logMessage(`    ✅ profilePicture: ${mergedConfig.ui.profilePicture}`);
  }
  if (iniConfig.ui.CustomRingtone !== undefined) {
    mergedConfig.ui.CustomRingtone = iniConfig.ui.CustomRingtone;
    logMessage(`    ✅ CustomRingtone: ${mergedConfig.ui.CustomRingtone}`);
  }
} else {
  logMessage(`  ⚠️  Aucun paramètre UI trouvé dans INI (iniConfig.ui est undefined)`);
}

if (iniConfig.audio) {
  mergedConfig.audio = mergedConfig.audio || {};
  logMessage(`  🔊 Paramètres Audio trouvés dans INI: ${JSON.stringify(iniConfig.audio)}`);
  if (iniConfig.audio.ringerOutputLabel !== undefined) {
    mergedConfig.audio.ringerOutputLabel = iniConfig.audio.ringerOutputLabel || null;
    logMessage(`    ✅ ringerOutputLabel: ${mergedConfig.audio.ringerOutputLabel}`);
  }
  if (iniConfig.audio.ringerGain !== undefined) {
    const gain = parseFloat(iniConfig.audio.ringerGain);
    if (isFinite(gain)) {
      mergedConfig.audio.ringerGain = Math.min(Math.max(gain, 0), 1);
      logMessage(`    ✅ ringerGain: ${mergedConfig.audio.ringerGain}`);
    }
  }
}

if (iniConfig.server) {
  logMessage(`  🌐 Paramètres Serveur trouvés dans INI: ${JSON.stringify(iniConfig.server)}`);
  if (iniConfig.server.serverUrl) {
    mergedConfig.serverUrl = iniConfig.server.serverUrl;
    logMessage(`    ✅ serverUrl: ${mergedConfig.serverUrl}`);
  }
}

if (iniConfig.app) {
  logMessage(`  📦 Paramètres App trouvés dans INI: ${JSON.stringify(iniConfig.app)}`);
  if (iniConfig.app.appName) {
    mergedConfig.appName = iniConfig.app.appName;
    logMessage(`    ✅ appName: ${mergedConfig.appName}`);
  }
  if (iniConfig.app.appId) {
    mergedConfig.appId = iniConfig.app.appId;
    logMessage(`    ✅ appId: ${mergedConfig.appId}`);
  }
}

module.exports = {
  environment,
  ...mergedConfig,
  isDev: environment === 'dev',
  isProd: environment === 'prod',
  // Exposer la config INI pour débogage
  _iniConfig: iniConfig,
  _configPath: { admin: adminConfigPath, user: userConfigPath },
  // Répertoire où sont cherchés les fichiers référencés par nom (images, sonneries)
  configDirectory,
  // Répertoires dont le renderer peut lire des fichiers (read-file-as-base64)
  allowedFileDirectories: [
    adminConfigPath ? path.dirname(adminConfigPath) : null,
    locations.getUserConfigDir()
  ].filter(Boolean),
  // Exposer les paramètres de fenêtre
  window: mergedConfig.window || currentConfig.window,
  // Exposer les paramètres UI
  ui: mergedConfig.ui || currentConfig.ui,
  // Exposer les paramètres Audio
  audio: mergedConfig.audio || currentConfig.audio,
  // Fonction pour vider la queue de logs
  flushLogQueue
};

logMessage(`
✨ CONFIG FINALE EXPORTÉE:
  Environnement: ${environment}
  config.ini admin: ${adminConfigPath || 'aucun'}
  config.ini utilisateur: ${userConfigPath || 'aucun'}
  Répertoire fichiers: ${configDirectory}
  App Name: ${mergedConfig.appName}
  App ID: ${mergedConfig.appId}
  Server URL: ${mergedConfig.serverUrl}
  Window: ${JSON.stringify(mergedConfig.window || currentConfig.window)}
  UI: ${JSON.stringify(mergedConfig.ui || currentConfig.ui)}
  Audio: ${JSON.stringify(mergedConfig.audio || currentConfig.audio)}`);
