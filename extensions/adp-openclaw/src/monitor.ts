// Monitor: WebSocket connection to Go server for real-time message handling
// Supports: API Token auth, conversation tracking for multi-turn dialogues

import type { PluginLogger, ClawdbotConfig } from "openclaw/plugin-sdk";
import { getAdpOpenclawRuntime } from "./runtime.js";
import crypto from "crypto";

// Plugin version from package.json
const PLUGIN_VERSION = "0.0.25";

// WebSocket reconnect delay (fixed at 1 second)
const RECONNECT_DELAY_MS = 1000;

export type MonitorParams = {
  wsUrl: string; // WebSocket URL (direct, no conversion needed)
  clientToken: string;
  signKey?: string; // HMAC key for signature generation
  abortSignal?: AbortSignal;
  log?: PluginLogger;
  cfg?: ClawdbotConfig; // OpenClaw config for model settings
};

// WebSocket message types
const MsgType = {
  Auth: "auth",
  AuthResult: "auth_result",
  Ping: "ping",
  Pong: "pong",
  Inbound: "inbound",
  Outbound: "outbound",
  OutboundChunk: "outbound_chunk",
  OutboundEnd: "outbound_end",
  Ack: "ack",
  Error: "error",
  ConvHistory: "conv_history",
  ConvResponse: "conv_response",
} as const;

type WSMessage = {
  type: string;
  requestId?: string;
  payload?: unknown;
  timestamp: number;
};

// UserInfo represents full user identity (matching Go server's UserInfo)
type UserInfo = {
  userId: string;
  username?: string;
  avatar?: string;
  email?: string;
  tenantId?: string;
  source?: string;
  extra?: Record<string, string>;
};

type InboundMessage = {
  id: string;
  conversationId: string;
  recordId?: string; // Record ID from server for tracking message pairs
  clientId: string;
  from: string;
  to: string;
  text: string;
  timestamp: number;
  user?: UserInfo; // Full user identity information
};

type AuthResultPayload = {
  success: boolean;
  clientId?: string;
  message?: string;
};

// Generate HMAC-SHA256 signature for authentication (includes timestamp for anti-replay)
// Uses signKey as the HMAC key, and "token:nonce:timestamp" as the message
function generateSignature(signKey: string, token: string, nonce: string, timestamp: number): string {
  // Use HMAC-SHA256 with signKey as the key, and "token:nonce:timestamp" as the message
  return crypto.createHmac("sha256", signKey).update(`${token}:${nonce}:${timestamp}`).digest("hex");
}

// Generate random nonce
function generateNonce(): string {
  return crypto.randomBytes(16).toString("hex");
}

// Generate unique request ID
function generateRequestId(): string {
  return `req-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

export async function monitorAdpOpenclaw(params: MonitorParams): Promise<void> {
  const { wsUrl, clientToken, signKey, abortSignal, log, cfg } = params;
  const runtime = getAdpOpenclawRuntime();

  log?.info(`[adp-openclaw] WebSocket monitor started, connecting to ${wsUrl}`);

  while (!abortSignal?.aborted) {
    try {
      await connectAndHandle({
        wsUrl,
        clientToken,
        signKey,
        abortSignal,
        log,
        runtime,
        cfg,
      });
    } catch (err) {
      if (abortSignal?.aborted) break;
      log?.error(`[adp-openclaw] WebSocket error: ${err}`);
    }

    // Wait before reconnecting
    if (!abortSignal?.aborted) {
      log?.info(`[adp-openclaw] Reconnecting in ${RECONNECT_DELAY_MS}ms...`);
      await sleep(RECONNECT_DELAY_MS, abortSignal);
    }
  }

  log?.info(`[adp-openclaw] WebSocket monitor stopped`);
}

type ConnectParams = {
  wsUrl: string;
  clientToken: string;
  signKey?: string;
  abortSignal?: AbortSignal;
  log?: PluginLogger;
  runtime: ReturnType<typeof getAdpOpenclawRuntime>;
  cfg?: ClawdbotConfig;
};

async function connectAndHandle(params: ConnectParams): Promise<void> {
  const { wsUrl, clientToken, signKey, abortSignal, log, runtime, cfg } = params;

  // Dynamic import for WebSocket (works in both Node.js and browser)
  const WebSocket = (await import("ws")).default;

  return new Promise((resolve, reject) => {
    const ws = new WebSocket(wsUrl);
    let authenticated = false;
    let pingInterval: NodeJS.Timeout | null = null;

    // Handle abort signal
    const abortHandler = () => {
      ws.close();
      resolve();
    };
    abortSignal?.addEventListener("abort", abortHandler);

    ws.on("open", () => {
      log?.info(`[adp-openclaw] WebSocket connected, authenticating...`);

      // Send authentication message with signature (includes timestamp for anti-replay)
      const nonce = generateNonce();
      const timestamp = Date.now();
      // Generate signature only if signKey is provided
      const signature = signKey ? generateSignature(signKey, clientToken, nonce, timestamp) : "";

      const authMsg: WSMessage = {
        type: MsgType.Auth,
        requestId: generateRequestId(),
        payload: {
          token: clientToken,
          nonce: signKey ? nonce : undefined,
          signature: signKey ? signature : undefined,
          timestamp: signKey ? timestamp : undefined, // Include timestamp in payload for server verification
        },
        timestamp: Date.now(),
      };

      ws.send(JSON.stringify(authMsg));
    });

    ws.on("message", async (data: Buffer) => {
      try {
        const msg: WSMessage = JSON.parse(data.toString());

        switch (msg.type) {
          case MsgType.AuthResult: {
            const result = msg.payload as AuthResultPayload;
            if (result.success) {
              authenticated = true;
              log?.info(`[adp-openclaw] Plugin v${PLUGIN_VERSION} authenticated as client ${result.clientId}`);

              // Start ping interval
              pingInterval = setInterval(() => {
                if (ws.readyState === WebSocket.OPEN) {
                  ws.send(JSON.stringify({
                    type: MsgType.Ping,
                    requestId: generateRequestId(),
                    timestamp: Date.now(),
                  }));
                }
              }, 25000);
            } else {
              log?.error(`[adp-openclaw] Authentication failed: ${result.message}`);
              ws.close();
            }
            break;
          }

          case MsgType.Pong:
            // Heartbeat response, connection is alive
            break;

          case MsgType.Inbound: {
            if (!authenticated) break;

            // Debug: log raw payload to verify recordId is received
            log?.info(`[adp-openclaw] Raw payload: ${JSON.stringify(msg.payload)}`);
            
            const inMsg = msg.payload as InboundMessage;
            log?.info(`[adp-openclaw] Received: ${inMsg.from}: ${inMsg.text} (conv=${inMsg.conversationId}, rec=${inMsg.recordId || 'none'}, user=${JSON.stringify(inMsg.user || {})})`);

            // Process the message with full user identity
            try {
              // Build user identity string for From field (like Feishu: "feishu:user_id")
              const userIdentifier = inMsg.user?.userId || inMsg.from;
              const tenantPrefix = inMsg.user?.tenantId ? `${inMsg.user.tenantId}:` : "";
              
              // Build metadata for user context (passed through to openclaw)
              const userMetadata: Record<string, string> = {};
              if (inMsg.user) {
                if (inMsg.user.username) userMetadata.username = inMsg.user.username;
                if (inMsg.user.email) userMetadata.email = inMsg.user.email;
                if (inMsg.user.avatar) userMetadata.avatar = inMsg.user.avatar;
                if (inMsg.user.tenantId) userMetadata.tenantId = inMsg.user.tenantId;
                if (inMsg.user.source) userMetadata.source = inMsg.user.source;
                if (inMsg.user.extra) {
                  Object.entries(inMsg.user.extra).forEach(([k, v]) => {
                    userMetadata[`extra_${k}`] = v;
                  });
                }
              }

              // Use resolveAgentRoute to get proper sessionKey (like QQBot does)
              // This ensures session history is correctly associated
              const peerId = inMsg.conversationId;
              const route = runtime.channel.routing.resolveAgentRoute({
                cfg: {
                  ...(cfg ?? {}),
                  session: {
                    ...(cfg?.session ?? {}),
                    // Override dmScope to "per-peer" so each user gets their own session
                    // This prevents all DM users from sharing the same "main" session
                    dmScope: "per-peer",
                  },
                },
                channel: "adp-openclaw",
                accountId: "default",
                peer: {
                  kind: "dm",  // direct message
                  id: peerId,
                },
              });

              // Get envelope format options and messages config (like QQBot does)
              const envelopeOptions = runtime.channel.reply.resolveEnvelopeFormatOptions(cfg ?? {});
              const messagesConfig = runtime.channel.reply.resolveEffectiveMessagesConfig(cfg ?? {}, route.agentId);

              // Use formatInboundEnvelope to format the message body (like QQBot does)
              const formattedBody = runtime.channel.reply.formatInboundEnvelope({
                channel: "ADP-OpenClaw",
                from: inMsg.user?.username ?? inMsg.from,
                timestamp: inMsg.timestamp || Date.now(),
                body: inMsg.text,
                chatType: "direct",
                sender: {
                  id: userIdentifier,
                  name: inMsg.user?.username,
                },
                envelope: envelopeOptions,
              });

              const ctx = runtime.channel.reply.finalizeInboundContext({
                Body: formattedBody,
                RawBody: inMsg.text,
                CommandBody: inMsg.text,
                // User identity: format as "adp-openclaw:{tenantId}:{userId}" for multi-tenant support
                From: `adp-openclaw:${tenantPrefix}${userIdentifier}`,
                To: `adp-openclaw:bot`,
                // SessionKey from resolveAgentRoute for proper session history tracking
                SessionKey: route.sessionKey,
                AccountId: route.accountId,
                ChatType: "direct",
                // SenderId carries the raw user ID for identification
                SenderId: userIdentifier,
                SenderName: inMsg.user?.username,
                Provider: "adp-openclaw",
                Surface: inMsg.user?.source || "adp-openclaw",
                MessageSid: inMsg.id,
                MessageSidFull: inMsg.id,
                Timestamp: inMsg.timestamp || Date.now(),
                OriginatingChannel: "adp-openclaw",
                OriginatingTo: "adp-openclaw:bot",
                // Pass user metadata through context (like Feishu does)
                ...userMetadata,
              });

              // Generate unique stream ID for this response
              const streamId = `stream-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
              let chunkIndex = 0;
              let lastPartialText = ""; // Track last sent text for delta calculation
              let finalSent = false; // Track if outbound_end has been sent
              const displayName = inMsg.user?.username || inMsg.from;

              // Helper function to send outbound_end message
              const sendOutboundEnd = (text: string) => {
                if (finalSent) return; // Prevent duplicate sends
                finalSent = true;
                
                if (chunkIndex > 0) {
                  log?.info(`[adp-openclaw] Sending outbound_end to ${displayName}: ${text.slice(0, 50)}... (chunks=${chunkIndex})`);
                  const endMsg: WSMessage = {
                    type: MsgType.OutboundEnd,
                    requestId: generateRequestId(),
                    payload: {
                      to: inMsg.from,
                      text: text,
                      conversationId: inMsg.conversationId,
                      recordId: inMsg.recordId, // Pass recordId back to server
                      streamId: streamId,
                      totalChunks: chunkIndex,
                      user: inMsg.user,
                    },
                    timestamp: Date.now(),
                  };
                  ws.send(JSON.stringify(endMsg));
                } else {
                  // No streaming chunks were sent, send as regular outbound message
                  log?.info(`[adp-openclaw] Sending outbound to ${displayName}: ${text.slice(0, 50)}...`);
                  const outMsg: WSMessage = {
                    type: MsgType.Outbound,
                    requestId: generateRequestId(),
                    payload: {
                      to: inMsg.from,
                      text: text,
                      conversationId: inMsg.conversationId,
                      recordId: inMsg.recordId, // Pass recordId back to server
                      user: inMsg.user,
                    },
                    timestamp: Date.now(),
                  };
                  ws.send(JSON.stringify(outMsg));
                }
              };

              log?.info(`[adp-openclaw] Starting dispatchReplyWithBufferedBlockDispatcher for ${displayName}`);
              await runtime.channel.reply.dispatchReplyWithBufferedBlockDispatcher({
                ctx,
                cfg: cfg ?? {},
                // Enable block streaming for SSE support
                replyOptions: {
                  disableBlockStreaming: false, // Force enable block streaming
                  // Use onPartialReply for real-time streaming (character-level)
                  // onPartialReply receives cumulative text, so we need to calculate delta
                  onPartialReply: async (payload: { text?: string }) => {
                    const fullText = payload.text || "";
                    if (!fullText) return;
                    
                    // Calculate delta (new text since last send)
                    let delta = fullText;
                    if (fullText.startsWith(lastPartialText)) {
                      delta = fullText.slice(lastPartialText.length);
                    } else {
                      // Text was reset or non-monotonic, send full text
                      log?.debug?.(`[adp-openclaw] Partial text reset, sending full text`);
                    }
                    
                    // Skip if no new content
                    if (!delta) return;
                    
                    lastPartialText = fullText;
                    
                    // Send delta as streaming chunk
                    log?.debug?.(`[adp-openclaw] Partial delta[${chunkIndex}] to ${displayName}: ${delta.slice(0, 30)}...`);
                    
                    const chunkMsg: WSMessage = {
                      type: MsgType.OutboundChunk,
                      requestId: generateRequestId(),
                      payload: {
                        to: inMsg.from,
                        chunk: delta, // Send only the new delta, not cumulative
                        conversationId: inMsg.conversationId,
                        recordId: inMsg.recordId, // Pass recordId back to server
                        streamId: streamId,
                        index: chunkIndex,
                        isPartial: true, // Mark as incremental delta
                        user: inMsg.user,
                      },
                      timestamp: Date.now(),
                    };
                    
                    ws.send(JSON.stringify(chunkMsg));
                    chunkIndex++;
                  },
                },
                dispatcherOptions: {
                  // ⭐ Add responsePrefix from messagesConfig (like QQBot does)
                  // This tells the AI what tools are available
                  responsePrefix: messagesConfig.responsePrefix,
                  // Unified deliver callback - handles both streaming blocks and final reply
                  // SDK calls this with info.kind = "block" for streaming chunks, "final" for complete response
                  deliver: async (payload: { text?: string }, info?: { kind?: string }) => {
                    const text = payload.text || "";
                    const kind = info?.kind;
                    
                    // Debug log for all deliver calls - log the actual info object
                    log?.info(`[adp-openclaw] deliver called: kind=${kind}, text.length=${text.length}, info=${JSON.stringify(info)}`);
                    
                    // Handle streaming block - IGNORE because handlePartial already sent deltas
                    // The "block" callback contains cumulative text (same as final), not incremental delta
                    // Sending it would cause duplicate data on the server side
                    if (kind === "block") {
                      log?.debug?.(`[adp-openclaw] Ignoring block callback (handlePartial already sent deltas), text.length=${text.length}`);
                      return;
                    }

                    // Handle tool result - log but don't send separately
                    if (kind === "tool") {
                      log?.debug?.(`[adp-openclaw] Tool result received for ${displayName}`);
                      return;
                    }

                    // Handle final reply or undefined kind - send outbound_end
                    // SDK may call deliver without kind when streaming ends
                    if (kind === "final" || kind === undefined) {
                      log?.info(`[adp-openclaw] deliver triggering sendOutboundEnd (kind=${kind})`);
                      sendOutboundEnd(text || lastPartialText);
                    }
                  },
                  onError: (err: Error) => {
                    log?.error(`[adp-openclaw] Reply error: ${err.message}`);
                  },
                },
              });
              
              log?.info(`[adp-openclaw] dispatchReplyWithBufferedBlockDispatcher returned (finalSent=${finalSent}, chunkIndex=${chunkIndex})`);
              
              // IMPORTANT: After dispatchReplyWithBufferedBlockDispatcher completes,
              // ensure outbound_end is sent even if "final" deliver was not called.
              // This handles cases where the SDK only sends blocks without a final callback.
              if (!finalSent && chunkIndex > 0) {
                // Use the last accumulated partial text as the final text
                const finalText = lastPartialText || "";
                log?.info(`[adp-openclaw] dispatchReply completed without final, sending outbound_end (chunks=${chunkIndex})`);
                sendOutboundEnd(finalText);
              }
            } catch (err) {
              log?.error(`[adp-openclaw] Failed to process message: ${err}`);
            }
            break;
          }

          case MsgType.Ack:
            // Message acknowledgment
            log?.debug?.(`[adp-openclaw] Message acknowledged: ${msg.requestId}`);
            break;

          case MsgType.Error: {
            const error = msg.payload as { error: string; message: string };
            log?.error(`[adp-openclaw] Server error: ${error.error} - ${error.message}`);
            break;
          }

          default:
            log?.warn(`[adp-openclaw] Unknown message type: ${msg.type}`);
        }
      } catch (err) {
        log?.error(`[adp-openclaw] Failed to parse message: ${err}`);
      }
    });

    ws.on("close", (code, reason) => {
      if (pingInterval) clearInterval(pingInterval);
      abortSignal?.removeEventListener("abort", abortHandler);
      log?.info(`[adp-openclaw] WebSocket closed: ${code} ${reason.toString()}`);
      resolve();
    });

    ws.on("error", (err) => {
      if (pingInterval) clearInterval(pingInterval);
      abortSignal?.removeEventListener("abort", abortHandler);
      reject(err);
    });
  });
}

function sleep(ms: number, signal?: AbortSignal): Promise<void> {
  return new Promise((resolve) => {
    if (signal?.aborted) {
      resolve();
      return;
    }
    const timeout = setTimeout(resolve, ms);
    signal?.addEventListener("abort", () => {
      clearTimeout(timeout);
      resolve();
    });
  });
}
