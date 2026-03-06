import type { OpenClawPluginApi } from "openclaw/plugin-sdk";
import { emptyPluginConfigSchema } from "openclaw/plugin-sdk";
import { adpOpenclawPlugin } from "./src/channel.js";
import { setAdpOpenclawRuntime } from "./src/runtime.js";

const plugin = {
  id: "adp-openclaw",
  name: "ADP OpenClaw",
  description: "ADP channel plugin backed by a Go WebSocket server",
  configSchema: emptyPluginConfigSchema(),
  register(api: OpenClawPluginApi) {
    // console.log("[adp-openclaw] register() called");
    setAdpOpenclawRuntime(api.runtime);
    api.registerChannel({ plugin: adpOpenclawPlugin });
  },
};

export default plugin;
