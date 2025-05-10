import Settings.AppSettings;
import electron.main.App;
import electron.main.IpcMain;
import js.Node.__dirname;
import js.Node.process;
import js.Syntax;


@:expose("ElectronMain")
class ElectronMain {

	static var mainWindow : electron.main.BrowserWindow;

	static var settings : Settings;

	var getSettingsHandler : Null<haxe.Constraints.Function> = null;
	var eventsSender : Null<haxe.Constraints.Function> = null;

	// contructor
	public function new() { }

	public function main(in_settings: AppSettings, events: Null<haxe.Constraints.Function>) {
		settings = new Settings(in_settings);
		eventsSender = events;
		// Force best available GPU usage
		if( settings.v.useBestGPU && !App.commandLine.hasSwitch("force_low_power_gpu") )
			App.commandLine.appendSwitch("force_high_performance_gpu");

		initIpcBindings(in_settings);

		App.whenReady().then( (_)->showSplashWindow() );

		// Mac
		App.on('window-all-closed', function() {
			mainWindow = null;
			App.quit();
		});
		App.on('activate', ()->{
			if( electron.main.BrowserWindow.getAllWindows().length == 0 )
				showSplashWindow();
		});
	}

	public function quit() {
		removeIpcBindings();
		mainWindow.close();
	}

	function removeIpcBindings() {
		IpcMain.removeHandler("appReady");
		IpcMain.removeListener("getSettings", getSettingsHandler);
	}

	function initIpcBindings(in_settings: AppSettings) {
		// *** invoke/handle *****************************************************

		IpcMain.handle("appReady", function(ev) {
			// Window close button
			mainWindow.on('close', function(ev) {
				ev.preventDefault();
				mainWindow.webContents.send("onWinClose");
			});
			// Window move
			mainWindow.on('move', function(ev) {
				mainWindow.webContents.send("onWinMove");
			});
		});
		getSettingsHandler = function(ev) {
			ev.returnValue = in_settings;
		};
		IpcMain.on("getSettings", getSettingsHandler);


		// *** sendSync/on *****************************************************
	}

	static function fileNotFound(file:String) {
		electron.main.Dialog.showErrorBox("File not found", '"$file" was not found in app assets!');
		App.quit();
	}

	static var splash : electron.main.BrowserWindow = null;
	function showSplashWindow() {
		createMainWindow();
	}

	function createMainWindow() {
		// Init window
		mainWindow = new electron.main.BrowserWindow({
			webPreferences: { nodeIntegration:true, contextIsolation:false },
			fullscreenable: true,
			show: false,
			title: "LDtk",
			icon: Const.APP_RESOURCE_DIR+"appIcon.png",
		});
		mainWindow.once("ready-to-show", ev->{
			mainWindow.webContents.setZoomFactor( settings.getAppZoomFactor() );
			if( settings.v.startFullScreen )
				dn.js.ElectronTools.setFullScreen(true);
			mainWindow.webContents.send("settingsApplied");
		});
		dn.js.ElectronTools.initMain(mainWindow);

		// Window menu
		#if debug
			enableDebugMenu();
		#else
			// electron.main.Menu.setApplicationMenu( electron.main.Menu.buildFromTemplate( [] ) ); // macos
			mainWindow.removeMenu(); // windows
		#end

		// Load app page
		var p = mainWindow.loadFile(Const.APP_RESOURCE_DIR + 'app.html', {});
		#if debug
			// Show immediately
			mainWindow.maximize();
			p.then( (_)->{}, (_)->fileNotFound(Const.APP_RESOURCE_DIR + "app.html") );
		#else
			// Wait for loading before showing up
			p.then( (_)->{
				mainWindow.show();
				mainWindow.maximize();
				splash.destroy();
			}, (e)->{
				electron.main.Dialog.showErrorBox("error:", '"$e"');
				splash.destroy();
				fileNotFound(Const.APP_RESOURCE_DIR + "app.html");
			});
		#end

		// Destroy
		mainWindow.on('closed', function() {
			mainWindow = null;
			if (eventsSender != null)
				eventsSender('closed');
		});

		// Misc bindings
		dn.js.ElectronDialogs.initMain(mainWindow);
	}



	// Create a custom debug menu
	#if debug
	static function enableDebugMenu() {
		var menu = electron.main.Menu.buildFromTemplate([{
			label: "Debug tools",
			submenu: cast [
				{
					label: "Reload",
					click: function() mainWindow.reload(),
					accelerator: "CmdOrCtrl+R",
				},
				{
					label: "Dev tools",
					click: function() mainWindow.webContents.toggleDevTools(),
					accelerator: "CmdOrCtrl+Shift+I",
				},
			]
		}]);

		mainWindow.setMenu(menu);
	}
	#end
}
