// User Matching System Configuration
// Modify these values to customize the system behavior

export const USER_MATCHING_CONFIG = {
  // Match threshold - number of messages that need to match before notification
  MATCH_THRESHOLD: 10,

  // Similarity threshold for finding similar users (0.0 to 1.0, lower = more similar)
  SIMILARITY_THRESHOLD: 0.7,

  // Maximum number of similar users to find per message
  MAX_SIMILAR_USERS: 3,

  // Maximum number of matches to record per user per day
  MAX_DAILY_MATCHES: 50,

  // Notification settings
  NOTIFICATIONS: {
    // Enable/disable notifications
    ENABLED: true,

    // Notification types
    TYPES: {
      USER_MATCH: "user_match",
      CONNECTION_ESTABLISHED: "connection_established",
    },

    // Notification titles
    TITLES: {
      USER_MATCH: "New Connection Opportunity!",
      CONNECTION_ESTABLISHED: "Connection Established!",
    },

    // Notification messages
    MESSAGES: {
      USER_MATCH:
        "You have {matchCount} matching messages with {userName}. Would you like to connect?",
      CONNECTION_ESTABLISHED:
        "You're now connected with {userName}! Their email: {userEmail}",
    },
  },

  // Database settings
  DATABASE: {
    // Table names
    TABLES: {
      USER_MATCHES: "user_matches",
      USER_CONNECTIONS: "user_connections",
      USER_MEMORY: "user_memory",
      USERS: "users",
    },

    // Column names
    COLUMNS: {
      USER_ID: "user_id",
      DISPLAY_NAME: "display_name",
      EMAIL: "email",
    },
  },

  // Performance settings
  PERFORMANCE: {
    // Enable caching
    CACHE_ENABLED: false,

    // Cache TTL in seconds
    CACHE_TTL: 300,

    // Batch size for bulk operations
    BATCH_SIZE: 100,

    // Enable debug logging
    DEBUG_LOGGING: process.env.DEBUG_USER_MATCHING === "true",
  },

  // Security settings
  SECURITY: {
    // Enable rate limiting
    RATE_LIMITING: true,

    // Maximum requests per minute per user
    MAX_REQUESTS_PER_MINUTE: 60,

    // Enable input validation
    INPUT_VALIDATION: true,

    // Maximum message length for similarity search
    MAX_MESSAGE_LENGTH: 1000,
  },

  // Feature flags
  FEATURES: {
    // Enable automatic matching
    AUTO_MATCHING: true,

    // Enable connection management
    CONNECTION_MANAGEMENT: true,

    // Enable email exchange
    EMAIL_EXCHANGE: true,

    // Enable match statistics
    MATCH_STATISTICS: true,
  },
};

// Helper functions for configuration
export const getConfig = (key) => {
  const keys = key.split(".");
  let value = USER_MATCHING_CONFIG;

  for (const k of keys) {
    if (value && typeof value === "object" && k in value) {
      value = value[k];
    } else {
      return undefined;
    }
  }

  return value;
};

export const isFeatureEnabled = (feature) => {
  return USER_MATCHING_CONFIG.FEATURES[feature] === true;
};

export const getNotificationMessage = (type, replacements = {}) => {
  const message = USER_MATCHING_CONFIG.NOTIFICATIONS.MESSAGES[type];
  if (!message) return "";

  return message.replace(/\{(\w+)\}/g, (match, key) => {
    return replacements[key] || match;
  });
};

export const getNotificationTitle = (type) => {
  return USER_MATCHING_CONFIG.NOTIFICATIONS.TITLES[type] || "";
};

// Environment-specific overrides
export const getEnvironmentConfig = () => {
  const env = process.env.NODE_ENV || "development";

  const envConfigs = {
    development: {
      PERFORMANCE: {
        DEBUG_LOGGING: true,
      },
    },
    production: {
      PERFORMANCE: {
        DEBUG_LOGGING: false,
        CACHE_ENABLED: true,
      },
      SECURITY: {
        RATE_LIMITING: true,
      },
    },
    test: {
      PERFORMANCE: {
        DEBUG_LOGGING: true,
      },
      FEATURES: {
        AUTO_MATCHING: false,
      },
    },
  };

  return envConfigs[env] || {};
};

// Merge environment config with base config
export const getMergedConfig = () => {
  const baseConfig = { ...USER_MATCHING_CONFIG };
  const envConfig = getEnvironmentConfig();

  // Deep merge
  const merge = (target, source) => {
    for (const key in source) {
      if (
        source[key] &&
        typeof source[key] === "object" &&
        !Array.isArray(source[key])
      ) {
        target[key] = target[key] || {};
        merge(target[key], source[key]);
      } else {
        target[key] = source[key];
      }
    }
  };

  merge(baseConfig, envConfig);
  return baseConfig;
};

export default USER_MATCHING_CONFIG;
