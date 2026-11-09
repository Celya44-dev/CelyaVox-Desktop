/**
 * Configuration pour les environnements dev/prod
 * Charge la configuration depuis config.ini si disponible
 * En production, le fichier est dans le dossier utilisateur et n'est jamais écrasé
 */

const packageJson = require('./package.json');
const path = require('path');
const fs = require('fs');
const ini = require('ini');

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

// Charger la configuration .ini si elle existe
let iniConfig = {};

// Déterminer le chemin du fichier config.ini
// Ordre de priorité:
// 1. Répertoire utilisateur (userData) - pour personnalisation utilisateur
// 2. Répertoire d'installation (bundle app) - pour déploiements centralisés
// 3. Chemins de développement (seulement si app non packagée)
const getConfigPath = () => {
  const configPaths = [];
  
  // Priorité 1: Répertoire utilisateur (userData) - VÉRIFIÉ EN PREMIER
  if (process.env.CELYAVOX_USER_CONFIG_PATH) {
    configPaths.push(process.env.CELYAVOX_USER_CONFIG_PATH);
  }
  
  const homeDir = process.env.HOME || process.env.USERPROFILE;
  if (homeDir) {
    if (environment === 'dev') {
      if (process.platform === 'linux') {
        configPaths.push(path.join(homeDir, '.config', 'CelyaVox-dev', 'config.ini'));
      } else if (process.platform === 'darwin') {
        configPaths.push(path.join(homeDir, 'Library', 'Application Support', 'CelyaVox-dev', 'config.ini'));
      } else if (process.platform === 'win32') {
        const appData = process.env.APPDATA || homeDir;
        configPaths.push(path.join(appData, 'CelyaVox-dev', 'config.ini'));
      }
    } else {
      if (process.platform === 'linux') {
        configPaths.push(path.join(homeDir, '.config', 'CelyaVox', 'config.ini'));
      } else if (process.platform === 'darwin') {
        configPaths.push(path.join(homeDir, 'Library', 'Application Support', 'CelyaVox', 'config.ini'));
      } else if (process.platform === 'win32') {
        const appData = process.env.APPDATA || homeDir;
        configPaths.push(path.join(appData, 'CelyaVox', 'config.ini'));
      }
    }
  }
  
  // Priorité 2: Répertoire d'installation (bundle app) - seulement avec process.resourcesPath
  if (process.resourcesPath) {
    configPaths.push(path.join(process.resourcesPath, 'resources', 'config.ini'));
    configPaths.push(path.join(process.resourcesPath, 'config.ini'));
  }
  
  // Priorité 3: Chemins de développement (seulement en DEV et si pas packagée)
  // Note: Ne pas utiliser __dirname car il pointe à l'intérieur d'app.asar en packagé
  if (environment === 'dev' && !process.resourcesPath) {
    configPaths.push(path.join(__dirname, 'resources', 'config.ini'));
    configPaths.push(path.join(__dirname, 'config.ini'));
    configPaths.push(path.join(__dirname, 'config', 'config.ini'));
  }
  
  return configPaths;
};

// Charger le fichier config.ini
const configPaths = getConfigPath();
logMessage(`
🔍 RECHERCHE CONFIG.INI (Environnement: ${environment})
🔍 __dirname: ${__dirname}
🔍 process.resourcesPath: ${process.resourcesPath || 'N/A'}
🔍 Chemins à tester:
${configPaths.map((p, i) => `  ${i + 1}. ${p}`).join('\n')}`);

for (const configPath of configPaths) {
  logMessage(`   Vérification: ${configPath}...`);
  if (fs.existsSync(configPath)) {
    logMessage(`   ✅ FICHIER TROUVÉ!`);
    try {
      const iniContent = fs.readFileSync(configPath, 'utf-8');
      iniConfig = ini.parse(iniContent);
      logMessage(`✅ Config INI chargée depuis: ${configPath}`);
      // Exposer le répertoire contenant config.ini
      global.configDirectory = path.dirname(configPath);
    } catch (err) {
      logMessage(`❌ Erreur lors de la lecture de config.ini: ${err.message}`, 'ERROR');
    }
    break;
  } else {
    logMessage(`   ❌ Fichier non trouvé`);
  }
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
INI trouvé:
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
  _configPath: configPaths,
  // Répertoire contenant config.ini
  configDirectory: global.configDirectory,
  // Exposer les paramètres de fenêtre
  window: mergedConfig.window || currentConfig.window,
  // Exposer les paramètres UI
  ui: mergedConfig.ui || currentConfig.ui,
  // Exposer les paramètres Audio
  audio: mergedConfig.audio || currentConfig.audio,
  // Fonction pour vider la queue de logs
  flushLogQueue,
  // Exporter une fonction pour recharger la config (sera appelée depuis main.js après app.whenReady())
  reloadConfig: function(appPath, resourcesPath) {
    // Mettre à jour les chemins de recherche avec les données d'Electron disponibles
    const updatedPaths = [];
    
    // Priorité 1: Répertoire d'installation (bundle app)
    if (resourcesPath) {
      updatedPaths.push(path.join(resourcesPath, 'resources', 'config.ini'));
      updatedPaths.push(path.join(resourcesPath, 'config.ini'));
    }
    if (appPath) {
      updatedPaths.push(path.join(appPath, 'resources', 'config.ini'));
      updatedPaths.push(path.join(appPath, 'config.ini'));
    }
    
    // Priorité 2: Répertoire utilisateur (userData)
    if (process.env.CELYAVOX_USER_CONFIG_PATH) {
      updatedPaths.push(process.env.CELYAVOX_USER_CONFIG_PATH);
    }
    
    const homeDir = process.env.HOME || process.env.USERPROFILE;
    if (homeDir) {
      if (environment === 'dev') {
        if (process.platform === 'linux') {
          updatedPaths.push(path.join(homeDir, '.config', 'CelyaVox-dev', 'config.ini'));
        } else if (process.platform === 'darwin') {
          updatedPaths.push(path.join(homeDir, 'Library', 'Application Support', 'CelyaVox-dev', 'config.ini'));
        } else if (process.platform === 'win32') {
          const appData = process.env.APPDATA || homeDir;
          updatedPaths.push(path.join(appData, 'CelyaVox-dev', 'config.ini'));
        }
      } else {
        if (process.platform === 'linux') {
          updatedPaths.push(path.join(homeDir, '.config', 'CelyaVox', 'config.ini'));
        } else if (process.platform === 'darwin') {
          updatedPaths.push(path.join(homeDir, 'Library', 'Application Support', 'CelyaVox', 'config.ini'));
        } else if (process.platform === 'win32') {
          const appData = process.env.APPDATA || homeDir;
          updatedPaths.push(path.join(appData, 'CelyaVox', 'config.ini'));
        }
      }
    }
    
    // Charger le fichier config.ini depuis les chemins mis à jour
    logMessage(`\n🔄 RECHARGEMENT CONFIG.INI APRÈS ELECTRON READY`);
    logMessage(`🔍 Chemins à tester:`);
    updatedPaths.forEach((p, i) => logMessage(`  ${i + 1}. ${p}`));
    
    let foundConfig = null;
    for (const configPath of updatedPaths) {
      if (fs.existsSync(configPath)) {
        try {
          const iniContent = fs.readFileSync(configPath, 'utf-8');
          foundConfig = ini.parse(iniContent);
          logMessage(`✅ Config INI RECHARGÉE depuis: ${configPath}`);
          
          // Fusionner la nouvelle config
          this._remergeConfig(foundConfig);
          return;
        } catch (err) {
          logMessage(`❌ Erreur lors de la lecture de config.ini: ${err.message}`, 'ERROR');
        }
      }
    }
    
    if (!foundConfig) {
      logMessage(`⚠️  Aucun config.ini trouvé aux chemins attendus`);
    }
  },
  // Fonction interne pour refusionner la config
  _remergeConfig: function(newIniConfig) {
    iniConfig = newIniConfig;
    
    // Re-fusionner avec la config par défaut
    if (iniConfig.window) {
      if (iniConfig.window.width) {
        mergedConfig.window.width = parseInt(iniConfig.window.width, 10) || currentConfig.window.width;
      }
      if (iniConfig.window.height) {
        mergedConfig.window.height = parseInt(iniConfig.window.height, 10) || currentConfig.window.height;
      }
    }
    
    if (iniConfig.ui) {
      logMessage(`  🎛️  Paramètres UI trouvés dans INI (reloadConfig): ${JSON.stringify(iniConfig.ui)}`);
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
      logMessage(`  ⚠️  Aucun paramètre UI trouvé dans INI (reloadConfig) - iniConfig.ui est undefined`);
    }
    
    if (iniConfig.audio) {
      if (iniConfig.audio.ringerOutputLabel !== undefined) {
        mergedConfig.audio.ringerOutputLabel = iniConfig.audio.ringerOutputLabel || null;
      }
      if (iniConfig.audio.ringerGain !== undefined) {
        const gain = parseFloat(iniConfig.audio.ringerGain);
        if (isFinite(gain)) {
          mergedConfig.audio.ringerGain = Math.min(Math.max(gain, 0), 1);
        }
      }
    }
    
    if (iniConfig.server) {
      if (iniConfig.server.serverUrl) {
        mergedConfig.serverUrl = iniConfig.server.serverUrl;
      }
    }
    
    if (iniConfig.app) {
      if (iniConfig.app.appName) {
        mergedConfig.appName = iniConfig.app.appName;
      }
      if (iniConfig.app.appId) {
        mergedConfig.appId = iniConfig.app.appId;
      }
    }
    
    logMessage(`📋 Configuration refusionnée avec succès`);
  }
};

logMessage(`
✨ CONFIG FINALE EXPORTÉE:
  Environnement: ${environment}
  App Name: ${mergedConfig.appName}
  App ID: ${mergedConfig.appId}
  Server URL: ${mergedConfig.serverUrl}
  Window: ${JSON.stringify(mergedConfig.window || currentConfig.window)}
  UI: ${JSON.stringify(mergedConfig.ui || currentConfig.ui)}
  Audio: ${JSON.stringify(mergedConfig.audio || currentConfig.audio)}`);
