# --- CONFIGURACIÓN DE RUTAS ---
$gameBase = "J:\SteamLibrary\steamapps\common\Halo The Master Chief Collection"
$binDir = "$gameBase\MCC\Binaries\Win64"
$gameExe = "MCC-Win64-Shipping.exe"
$appIdFile = Join-Path $binDir "steam_appid.txt"
$fakeAppId = "886460" # ID del juego que Steam pensará que está ejecutando

# --- WIN32 API (EnumWindows) - Cambiar atributos de la consola PS ---
Add-Type -TypeDefinition @"
  using System;
  using System.Runtime.InteropServices;
  using System.Collections.Generic;
  using System.Text;

  public class Win32 {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("user32.dll")] public static extern bool GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")] public static extern int GetClassName(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    
    [DllImport("user32.dll", EntryPoint = "GetWindowLongPtr")]
    public static extern IntPtr GetWindowLongPtr(IntPtr hWnd, int nIndex);
    
    [DllImport("user32.dll", EntryPoint = "SetWindowLongPtr")]
    public static extern IntPtr SetWindowLongPtr(IntPtr hWnd, int nIndex, IntPtr dwNewLong);
    
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    public static List<IntPtr> GetProcessWindows(int processId) {
        List<IntPtr> handles = new List<IntPtr>();
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            uint pid;
            GetWindowThreadProcessId(hWnd, out pid);
            if (pid == processId) {
                handles.Add(hWnd);
            }
            return true;
        }, IntPtr.Zero);
        return handles;
    }

    public static string GetWindowTitle(IntPtr hWnd) {
        StringBuilder sb = new StringBuilder(512);
        GetWindowText(hWnd, sb, 512);
        return sb.ToString();
    }
    
    public static string GetWindowClassName(IntPtr hWnd) {
        StringBuilder sb = new StringBuilder(256);
        GetClassName(hWnd, sb, 256);
        return sb.ToString();
    }
  }
"@

# 1. OCULTAR CONSOLA INICIAL
try {
    $hConsole = [Win32]::GetConsoleWindow() 
    if ($hConsole -ne [IntPtr]::Zero) { [Win32]::ShowWindow($hConsole, 0) }
}
catch {}

# 2. LIMPIEZA - Cerrar procesos que puedan interferir
Get-Process -Name "MCC*", "Easy*", "WinSystem*", "SystemCore*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
$eacDir = "$gameBase\easyanticheat"; $eacOff = "$gameBase\easyanticheat_disabled_bypass"
if (Test-Path $eacOff) { Move-Item $eacOff $eacDir -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 1

# 3. MÁSCARA - Cambiar el ID de la aplicación
Set-Content $appIdFile $fakeAppId -Force
$env:SteamAppId = $fakeAppId
$env:SteamGameId = $fakeAppId

# 4. LANZAMIENTO - Lanzar el juego con argumentos para desactivar anticheat y funcione el alpha ring
$launchArgs = "-anti-cheat-disabled -noeac -noneos -content_offline -nomutex -winfast"
$targetPath = Join-Path $binDir $gameExe

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $targetPath
$psi.Arguments = $launchArgs
$psi.WorkingDirectory = $binDir
$psi.UseShellExecute = $false

$mccProc = [System.Diagnostics.Process]::Start($psi)
$mccPid = $mccProc.Id

# 5. GESTIÓN DE VENTANAS (DETECTAR CONSOLA POR CLASE) - Mantener el foco en la ventana del juego
$maxIterations = 600
$GWL_EXSTYLE = -20
$WS_EX_TOOLWINDOW = 0x00000080

for ($i = 0; $i -lt $maxIterations; $i++) {
    if ($mccProc.HasExited) { break }

    $windows = [Win32]::GetProcessWindows($mccPid)
    
    foreach ($hwnd in $windows) { 
        $title = [Win32]::GetWindowTitle($hwnd)
        $class = [Win32]::GetWindowClassName($hwnd)
        
        # A. Es la consola? (Por Clase o porque el Título es una ruta de archivo)
        if ($class -eq "ConsoleWindowClass" -or $title -like "*MCC-Win64-Shipping.exe*") {
            # ES LA CONSOLA MALDITA
            # 1. Convertir en TOOLWINDOW para borrarla de Alt-Tab y Taskbar (Steam la ignora)
            $style = [Win32]::GetWindowLongPtr($hwnd, $GWL_EXSTYLE)
            if (($style.ToInt64() -band $WS_EX_TOOLWINDOW) -eq 0) {
                $newStyle = [IntPtr]($style.ToInt64() -bor $WS_EX_TOOLWINDOW)
                [Win32]::SetWindowLongPtr($hwnd, $GWL_EXSTYLE, $newStyle) | Out-Null
            }
            # 2. Ocultarla
            [Win32]::ShowWindow($hwnd, 0) | Out-Null
        }
        # B. Es el juego? (Visible, tiene título y NO es consola)
        elseif ($title -ne "" -and $class -ne "ConsoleWindowClass" -and [Win32]::IsWindowVisible($hwnd)) {
            # VENTANA DEL JUEGO
            [Win32]::ShowWindow($hwnd, 9) | Out-Null # Restore
            [Win32]::SetForegroundWindow($hwnd) | Out-Null
            
            # Se encontró la ventana del juego y se supero el tiempo de espera.
            # Se puede para la lucha que mantiene la ventana del MCC en primer plano.
            if ($i -gt 250) { $breakLoop = $true }
        }
    }
    
    if ($breakLoop) { break }
    Start-Sleep -Milliseconds 250
}

# 6. MANTENER VIVO PARA REMOTE PLAY
if (!$mccProc.HasExited) { $mccProc | Wait-Process }

# 7. LIMPIEZA FINAL
exit
