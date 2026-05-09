import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { Component, TUI } from "@earendil-works/pi-tui";

type ClearableComponent = { clear?: () => void };

type TuiRoot = TUI & {
	children?: ClearableComponent[];
};

const emptyComponent: Component = {
	render: () => [],
	invalidate: () => {},
};

async function clear(ctx: ExtensionContext) {
	if (!ctx.hasUI) return;

	await ctx.ui.custom<void>((tui, _theme, _keybindings, done) => {
		// pi's root TUI children are ordered as:
		// header, chat, pending messages, status, widgets, editor, widgets, footer.
		// Clearing child 1 drops the visible chat/message buffer while preserving
		// the current session history on disk and in context.
		const root = tui as TuiRoot;
		const chatContainer = root.children?.[1];

		if (chatContainer && typeof chatContainer.clear === "function") {
			chatContainer.clear();
		}

		// Force a full redraw so pi-tui clears viewport + scrollback and redraws
		// the remaining UI from its new component tree.
		tui.requestRender(true);
		done();
		return emptyComponent;
	});
}

export default function (pi: ExtensionAPI) {
	pi.registerShortcut("ctrl+l", {
		description: "Clear TUI buffer",
		handler: clear,
	});

	pi.registerCommand("clear", {
		description: "Clear the visible TUI message buffer",
		handler: async (_args, ctx) => {
			await clear(ctx);
		},
	});
}
