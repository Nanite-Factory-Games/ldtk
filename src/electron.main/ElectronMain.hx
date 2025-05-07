import Settings.AppSettings;
import electron.main.App;
import electron.main.IpcMain;
import js.Node.__dirname;
import js.Node.process;
import js.Syntax;


@:expose("ElectronMain")
class ElectronMain {

	public static var APP_RESOURCE_DIR = Syntax.code("require('path').dirname(require('find-up').findUpSync('package.json', {cwd:__dirname})) + require('path').sep + 'assets' + require('path').sep");

	static var mainWindow : electron.main.BrowserWindow;

	static var settings : Settings;

	// contructor
	public function new() { }

	public function main(?in_settings: AppSettings) {
		settings = new Settings(in_settings);
		// Force best available GPU usage
		if( settings.v.useBestGPU && !App.commandLine.hasSwitch("force_low_power_gpu") )
			App.commandLine.appendSwitch("force_high_performance_gpu");

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

		initIpcBindings();
	}

	public function quit() {
		mainWindow.close();
		App.quit();
	}


	static function initIpcBindings() {
		// *** invoke/handle *****************************************************

		IpcMain.handle("appReady", function(ev) {
			// Window close button
			mainWindow.on('close', function(ev) {
				if( !dn.js.ElectronUpdater.isIntalling ) {
					ev.preventDefault();
					mainWindow.webContents.send("onWinClose");
				}
			});
			// Window move
			mainWindow.on('move', function(ev) {
				mainWindow.webContents.send("onWinMove");
			});
		});

		IpcMain.handle("getSettings", function(ev) {
			ev.returnValue = settings;
		});


		// *** sendSync/on *****************************************************
	}

	static function fileNotFound(file:String) {
		electron.main.Dialog.showErrorBox("File not found", '"$file" was not found in app assets!');
		App.quit();
	}


	static var splash : electron.main.BrowserWindow = null;
	static function showSplashWindow() {
		#if debug

			createMainWindow();

		#else

			splash = new electron.main.BrowserWindow({
				width: 300,
				height: 300,
				alwaysOnTop: true,
				transparent: true,
				frame: false,
			});

			var ver = new dn.Version( MacroTools.getAppVersion() );

			splash
				.loadFile(APP_RESOURCE_DIR + 'splash.html', { query:{
					mainVersion : ver.major+"."+ver.minor,
					patchVersion : ver.patch>0 ? "."+ver.patch : "",
				}})
				.then(
					_->createMainWindow(),
					_->fileNotFound("splash.html")
				);

		#end

	}

	static function createMainWindow() {
		// Init window
		mainWindow = new electron.main.BrowserWindow({
			webPreferences: { nodeIntegration:true, contextIsolation:false },
			fullscreenable: true,
			show: false,
			title: "LDtk",
			// icon: __dirname+"/appIcon.png",
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
		var p = mainWindow.loadFile(APP_RESOURCE_DIR + 'app.html', {});
		#if debug
			// Show immediately
			mainWindow.maximize();
			p.then( (_)->{}, (_)->fileNotFound(APP_RESOURCE_DIR + "app.html") );
		#else
			// Wait for loading before showing up
			p.then( (_)->{
				mainWindow.show();
				mainWindow.maximize();
				splash.destroy();
			}, (e)->{
				electron.main.Dialog.showErrorBox("error:", '"$e"');
				splash.destroy();
				fileNotFound(APP_RESOURCE_DIR + "app.html");
			});
		#end

		// Destroy
		mainWindow.on('closed', function() {
			mainWindow = null;
		});

		// Misc bindings
		dn.js.ElectronDialogs.initMain(mainWindow);
		dn.js.ElectronUpdater.initMain(mainWindow);
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
