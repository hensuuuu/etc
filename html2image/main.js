const { app, BrowserWindow, ipcMain, dialog, shell } = require('electron');
const path = require('path');
const fs = require('fs');
const os = require('os');

let mainWindow;
let offscreenWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 900,
    minHeight: 600,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
    title: 'HTML to Image',
    backgroundColor: '#1a1a2e',
    show: false,
  });

  mainWindow.loadFile('index.html');
  mainWindow.once('ready-to-show', () => mainWindow.show());
  mainWindow.on('closed', () => { mainWindow = null; });
}

// HTML을 오프스크린 BrowserWindow로 렌더링 후 캡처
ipcMain.handle('capture-html', async (event, { html, width, height, format, scale }) => {
  return new Promise((resolve, reject) => {
    if (offscreenWindow && !offscreenWindow.isDestroyed()) {
      offscreenWindow.destroy();
    }

    const win = new BrowserWindow({
      width: width,
      height: height,
      show: false,
      webPreferences: {
        offscreen: false,
        nodeIntegration: false,
        contextIsolation: true,
      },
      backgroundColor: '#ffffff',
    });

    offscreenWindow = win;

    // HTML을 data URL로 로드
    const dataUrl = `data:text/html;charset=utf-8,${encodeURIComponent(html)}`;
    win.loadURL(dataUrl);

    win.webContents.once('did-finish-load', () => {
      setTimeout(() => {
        win.webContents.capturePage().then((image) => {
          let buffer;
          if (format === 'jpg' || format === 'jpeg') {
            buffer = image.toJPEG(95);
          } else {
            buffer = image.toPNG();
          }

          if (!win.isDestroyed()) win.destroy();

          resolve({ success: true, buffer: Array.from(buffer), width: image.getSize().width, height: image.getSize().height });
        }).catch((err) => {
          if (!win.isDestroyed()) win.destroy();
          reject({ success: false, error: err.message });
        });
      }, 500); // 렌더링 완료 대기
    });

    win.webContents.once('did-fail-load', (event, code, desc) => {
      if (!win.isDestroyed()) win.destroy();
      reject({ success: false, error: `로드 실패: ${desc}` });
    });
  });
});

// 파일 저장 다이얼로그
ipcMain.handle('save-image', async (event, { buffer, format, defaultName }) => {
  const ext = format === 'jpg' || format === 'jpeg' ? 'jpg' : 'png';
  const result = await dialog.showSaveDialog(mainWindow, {
    title: '이미지 저장',
    defaultPath: path.join(os.homedir(), 'Desktop', `${defaultName || 'html-image'}.${ext}`),
    filters: [
      { name: ext.toUpperCase() + ' 이미지', extensions: [ext] },
      { name: '모든 파일', extensions: ['*'] },
    ],
  });

  if (result.canceled) return { canceled: true };

  const data = Buffer.from(buffer);
  fs.writeFileSync(result.filePath, data);
  return { canceled: false, filePath: result.filePath };
});

// 파일 탐색기에서 열기
ipcMain.handle('show-in-folder', async (event, filePath) => {
  shell.showItemInFolder(filePath);
});

app.whenReady().then(createWindow);
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow();
});
