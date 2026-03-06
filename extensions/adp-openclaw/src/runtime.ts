// Runtime singleton for adp-openclaw plugin
import type { PluginRuntime } from "openclaw/plugin-sdk";

let adpOpenclawRuntime: PluginRuntime | null = null;

// Plugin-level config storage (from plugins.entries.adp-openclaw.config)
export type PluginConfig = {
  wsUrl?: string;
  clientToken?: string;
  signKey?: string;
};

let pluginConfig: PluginConfig = {};

export function setAdpOpenclawRuntime(runtime: PluginRuntime): void {
  adpOpenclawRuntime = runtime;
}

export function getAdpOpenclawRuntime(): PluginRuntime {
  if (!adpOpenclawRuntime) {
    throw new Error("ADP OpenClaw runtime not initialized");
  }
  return adpOpenclawRuntime;
}

export function setPluginConfig(config: PluginConfig): void {
  pluginConfig = config;
}

export function getPluginConfig(): PluginConfig {
  return pluginConfig;
}
