"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deactivate = exports.activate = void 0;
const vscode = require("vscode");
const fs = require("fs");
const path = require("path");
const os = require("os");
const chokidar = require("chokidar");
const Color = require("color");
const template_1 = require("./template");
const walCachePath = path.join(os.homedir(), '.cache', 'wal');
const walColorsPath = path.join(walCachePath, 'colors');
const walColorsJsonPath = path.join(walCachePath, 'colors.json');
let autoUpdateWatcher = null;
function activate(context) {
    // Register the update command
    let disposable = vscode.commands.registerCommand('walTheme.update', generateColorThemes);
    context.subscriptions.push(disposable);
    // Start the auto update if enabled
    if (vscode.workspace.getConfiguration().get('walTheme.autoUpdate')) {
        /*
         * Update theme at startup
         * Needed for when wal palette updates while vscode isn't running.
         * The timeout is required to overcome a limitation of vscode which
         * breaks the theme auto-update if updated too early at startup.
         */
        setTimeout(generateColorThemes, 10000);
        autoUpdateWatcher = autoUpdate();
    }
    // Toggle the auto update in real time when changing the extension configuration
    vscode.workspace.onDidChangeConfiguration(event => {
        if (event.affectsConfiguration('walTheme.autoUpdate')) {
            if (vscode.workspace.getConfiguration().get('walTheme.autoUpdate')) {
                if (autoUpdateWatcher === null) {
                    autoUpdateWatcher = autoUpdate();
                }
            }
            else if (autoUpdateWatcher !== null) {
                autoUpdateWatcher.close();
                autoUpdateWatcher = null;
            }
        }
    });
}
exports.activate = activate;
function deactivate() {
    // Close the watcher if active
    if (autoUpdateWatcher !== null) {
        autoUpdateWatcher.close();
    }
}
exports.deactivate = deactivate;
/**
 * Generates the theme from the current color palette and overwrites the last one
 */
function generateColorThemes() {
    var _a, _b;
    // Import colors from pywal cache
    let colors;
    try {
        colors = fs.readFileSync(walColorsPath)
            .toString()
            .split(/\s+/, 16)
            .map(hex => Color(hex));
        if (fs.existsSync(walColorsJsonPath)) {
            let colorsJson;
            const colorsRaw = fs.readFileSync(walColorsJsonPath).toString();
            try {
                colorsJson = JSON.parse(colorsRaw);
            }
            catch (_c) {
                // The wallpaper path on Windows can cause JSON.parse errors since the
                // path isn't properly escaped.
                colorsJson = JSON.parse(colorsRaw
                    .split('\n')
                    .filter((line) => !line.includes('wallpaper'))
                    .join('\n'));
            }
            colors[0] = Color((_a = colorsJson === null || colorsJson === void 0 ? void 0 : colorsJson.special) === null || _a === void 0 ? void 0 : _a.background);
            colors[7] = Color((_b = colorsJson === null || colorsJson === void 0 ? void 0 : colorsJson.special) === null || _b === void 0 ? void 0 : _b.foreground);
        }
    }
    catch (error) {
        // Not a complete failure if we have colors from the wal colors file, but failed to load from the colors.json
        if (colors === undefined || colors.length === 0) {
            vscode.window.showErrorMessage('Couldn\'t load colors from pywal cache, be sure to run pywal before updating.');
            return;
        }
        vscode.window.showWarningMessage('Couldn\'t load all colors from pywal cache');
    }
    // Generate the normal theme
    const colorTheme = template_1.default(colors, false);
    fs.writeFileSync(path.join(__dirname, '..', 'themes', 'wal.json'), JSON.stringify(colorTheme, null, 4));
    // Generate the bordered theme
    const colorThemeBordered = template_1.default(colors, true);
    fs.writeFileSync(path.join(__dirname, '..', 'themes', 'wal-bordered.json'), JSON.stringify(colorThemeBordered, null, 4));
}
/**
 * Automatically updates the theme when the color palette changes
 * @returns The watcher for the color palette
 */
function autoUpdate() {
    // Watch for changes in the color palette of wal
    return chokidar
        .watch(walCachePath)
        .on('change', generateColorThemes);
}
//# sourceMappingURL=extension.js.map