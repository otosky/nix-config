import path from "node:path";
import { isToolCallEventType, type ExtensionAPI, type ExtensionContext } from "@mariozechner/pi-coding-agent";

type PathDecision = {
	level: "allow" | "confirm" | "block";
	reason?: string;
};

type CommandFinding = {
	reason: string;
	pattern: RegExp;
};

let safetyEnabled = true;

const statusKey = "safety-mode";

const dangerousCommands: CommandFinding[] = [
	{ reason: "uses sudo", pattern: /(^|[\s;&|()])sudo(\s|$)/ },
	{ reason: "recursively removes files", pattern: /(^|[\s;&|()])rm\s+[^\n;&|]*(-[A-Za-z]*r[A-Za-z]*|--recursive)\b/ },
	{ reason: "forcefully resets git state", pattern: /(^|[\s;&|()])git\s+reset\b[^\n;&|]*--hard\b/ },
	{ reason: "force-cleans untracked git files", pattern: /(^|[\s;&|()])git\s+clean\b[^\n;&|]*-[A-Za-z]*f[A-Za-z]*/ },
	{ reason: "force-pushes git history", pattern: /(^|[\s;&|()])git\s+push\b[^\n;&|]*(--force(?:-with-lease)?|-f\b|\s\+[^\s]+)/ },
	{ reason: "executes a remote download via a shell", pattern: /\b(curl|wget)\b[^\n|]*\|\s*(sudo\s+)?(sh|bash|zsh|fish)\b/ },
	{ reason: "uses find -delete", pattern: /(^|[\s;&|()])find\b[^\n;&|]*\s-delete\b/ },
	{ reason: "recursively changes ownership or permissions", pattern: /(^|[\s;&|()])(chmod|chown|chgrp)\b[^\n;&|]*-[A-Za-z]*R[A-Za-z]*\b/ },
	{ reason: "writes directly to a block device", pattern: /(^|[\s;&|()])dd\b[^\n;&|]*\bof=\/dev\// },
	{ reason: "formats a filesystem", pattern: /(^|[\s;&|()])mkfs(\.|\s|$)/ },
];

const lockFiles = new Set([
	"package-lock.json",
	"pnpm-lock.yaml",
	"yarn.lock",
	"Cargo.lock",
	"Gemfile.lock",
	"poetry.lock",
	"uv.lock",
	"go.sum",
	"flake.lock",
]);

const generatedDirs = new Set(["dist", "build", "coverage", "target", ".next", ".nuxt", "out"]);

function updateStatus(ctx: ExtensionContext) {
	ctx.ui.setStatus(statusKey, safetyEnabled ? "🛡 safety:on" : "⚠ safety:off");
}

function setSafetyEnabled(enabled: boolean, ctx: ExtensionContext, source: string) {
	safetyEnabled = enabled;
	updateStatus(ctx);
	ctx.ui.notify(`Safety mode ${enabled ? "enabled" : "disabled"} (${source})`, enabled ? "success" : "warning");
}

function stripQuotes(value: string) {
	return value.replace(/^['"]|['"]$/g, "");
}

function toAbsolutePath(candidate: string, cwd: string) {
	const cleaned = stripQuotes(candidate.trim());
	if (!cleaned || cleaned.startsWith("-") || cleaned.includes("$")) return undefined;
	return path.isAbsolute(cleaned) ? path.normalize(cleaned) : path.resolve(cwd, cleaned);
}

function splitParts(filePath: string) {
	return filePath.split(path.sep).filter(Boolean);
}

function classifyPath(candidate: string | undefined, cwd: string): PathDecision {
	if (!candidate) return { level: "allow" };

	const absolute = toAbsolutePath(candidate, cwd);
	if (!absolute) return { level: "allow" };

	const base = path.basename(absolute);
	const parts = splitParts(absolute);

	if (parts.includes(".git")) return { level: "block", reason: "writes inside .git" };
	if (parts.includes("node_modules")) return { level: "block", reason: "writes inside node_modules" };
	if (parts.includes(".ssh")) return { level: "block", reason: "writes inside .ssh" };

	if (base === ".env" || base.startsWith(".env.")) return { level: "block", reason: "writes to an environment/secrets file" };
	if (base === ".npmrc" || base === ".pypirc") return { level: "block", reason: "writes to a token-bearing config file" };
	if (/^id_(rsa|dsa|ecdsa|ed25519)(\.pub)?$/.test(base)) return { level: "block", reason: "writes to an SSH key file" };
	if (/\.(pem|key|p12|pfx|agekey|asc|gpg)$/i.test(base)) return { level: "block", reason: "writes to a private key or credential file" };
	if (/(^|[._-])(secret|secrets|credential|credentials|token|tokens)([._-]|$)/i.test(base)) {
		return { level: "block", reason: "writes to a file that looks like it contains secrets" };
	}

	if (lockFiles.has(base)) return { level: "confirm", reason: "edits a lockfile" };
	if (parts.some((part) => generatedDirs.has(part))) return { level: "confirm", reason: "writes inside a generated/build output directory" };
	if (/\.(min\.js|generated\.[^.]+|pb\.go)$/i.test(base) || /(^|[._-])gen(erated)?([._-]|\.)/i.test(base)) {
		return { level: "confirm", reason: "edits a generated file" };
	}

	return { level: "allow" };
}

function analyzeCommand(command: string) {
	return dangerousCommands.filter((finding) => finding.pattern.test(command));
}

function extractRedirectTargets(command: string) {
	const targets: string[] = [];
	const redirectPattern = /(?:&>>|&>|2>>|2>|1>>|1>|>>|>)\s*([^\s;&|]+)/g;
	let match: RegExpExecArray | null;
	while ((match = redirectPattern.exec(command))) {
		targets.push(match[1]);
	}
	return targets;
}

function extractCommandTokens(command: string) {
	return command.match(/"[^"]+"|'[^']+'|[^\s;&|()]+/g) ?? [];
}

function commandWritesProtectedPath(command: string, cwd: string): string | undefined {
	const writeCommandPattern = /(^|[\s;&|()])(tee|cp|mv|install|touch|truncate)\b/;
	const shouldInspectTokens = writeCommandPattern.test(command);
	const candidates = shouldInspectTokens ? [...extractCommandTokens(command), ...extractRedirectTargets(command)] : extractRedirectTargets(command);

	for (const candidate of candidates) {
		const decision = classifyPath(candidate, cwd);
		if (decision.level === "block") return `${stripQuotes(candidate)} (${decision.reason})`;
	}

	return undefined;
}

async function confirmOrBlock(ctx: ExtensionContext, title: string, message: string) {
	if (!ctx.hasUI) return false;
	return ctx.ui.confirm(title, message);
}

async function checkPathTool(toolName: "write" | "edit", targetPath: string | undefined, ctx: ExtensionContext) {
	const decision = classifyPath(targetPath, ctx.cwd);

	if (decision.level === "block") {
		return {
			block: true,
			reason: `Safety mode blocked ${toolName} to ${targetPath}: ${decision.reason}. Toggle safety off with Shift+Tab or /safety off if this is intentional.`,
		};
	}

	if (decision.level === "confirm") {
		const ok = await confirmOrBlock(ctx, "Safety Mode", `${toolName} targets ${targetPath}\nReason: ${decision.reason}\n\nAllow this operation?`);
		if (!ok) return { block: true, reason: `Safety mode denied ${toolName} to ${targetPath}: ${decision.reason}.` };
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		updateStatus(ctx);
	});

	pi.on("before_agent_start", async (event) => {
		if (!safetyEnabled) return;
		return {
			systemPrompt:
				event.systemPrompt +
				"\n\nSafety Mode extension is active. Prefer non-destructive commands. Avoid editing secrets, private keys, generated files, build outputs, node_modules, and .git internals unless the user explicitly asks.",
		};
	});

	pi.registerShortcut("shift+tab", {
		description: "Toggle safety mode",
		handler: async (ctx) => {
			setSafetyEnabled(!safetyEnabled, ctx, "Shift+Tab");
		},
	});

	pi.registerCommand("safety", {
		description: "Show or toggle Safety Mode: /safety [on|off|toggle|status]",
		handler: async (args, ctx) => {
			const action = (args ?? "status").trim().toLowerCase();

			if (["on", "enable", "enabled"].includes(action)) {
				setSafetyEnabled(true, ctx, "/safety on");
				return;
			}
			if (["off", "disable", "disabled"].includes(action)) {
				setSafetyEnabled(false, ctx, "/safety off");
				return;
			}
			if (action === "toggle") {
				setSafetyEnabled(!safetyEnabled, ctx, "/safety toggle");
				return;
			}
			if (action === "" || action === "status") {
				updateStatus(ctx);
				ctx.ui.notify(`Safety mode is ${safetyEnabled ? "ON" : "OFF"}. Shift+Tab toggles it.`, safetyEnabled ? "info" : "warning");
				return;
			}

			ctx.ui.notify("Usage: /safety [on|off|toggle|status]", "warning");
		},
	});

	pi.on("tool_call", async (event, ctx) => {
		updateStatus(ctx);
		if (!safetyEnabled) return;

		if (isToolCallEventType("write", event)) {
			return checkPathTool("write", event.input.path, ctx);
		}

		if (isToolCallEventType("edit", event)) {
			return checkPathTool("edit", event.input.path, ctx);
		}

		if (isToolCallEventType("bash", event)) {
			const command = event.input.command;
			const protectedTarget = commandWritesProtectedPath(command, ctx.cwd);
			if (protectedTarget) {
				return {
					block: true,
					reason: `Safety mode blocked shell command writing to protected path: ${protectedTarget}. Toggle safety off with Shift+Tab or /safety off if this is intentional.`,
				};
			}

			const findings = analyzeCommand(command);
			if (findings.length > 0) {
				const reasons = [...new Set(findings.map((finding) => finding.reason))].join(", ");
				const ok = await confirmOrBlock(
					ctx,
					"Safety Mode",
					`Shell command looks potentially destructive: ${reasons}\n\n${command}\n\nAllow this command?`,
				);
				if (!ok) return { block: true, reason: `Safety mode denied shell command: ${reasons}.` };
			}
		}
	});
}
