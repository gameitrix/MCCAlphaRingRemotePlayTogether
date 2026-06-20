# Guía de Uso: PlayMCCWithAlphaRing.ps1

Este script de PowerShell está diseñado para facilitar el lanzamiento de **Halo: The Master Chief Collection (MCC)** modificado con el **"Alpha Ring"**, permitiendo el uso de la funcionalidad **Remote Play Together** de Steam.

## 🎯 ¿Para qué sirve?

El objetivo principal es permitir que **varios jugadores jueguen en un mismo PC** (o a través de internet simulando estar en el mismo PC) utilizando *Remote Play Together*, una característica que no está habilitada nativamente para Halo MCC.

El script realiza varias tareas automáticas para lograr esto:
1.  **Engaña a Steam**: Hace creer a Steam que estás ejecutando un juego diferente (Un juego que hallas instalado con anterioridad) que sí admite Remote Play Together.
2.  **Gestión de Ventanas**: Detecta y oculta la consola de depuración/comandos que aparece al iniciar el Alpha Ring. Esto es crítico porque Steam a menudo captura la ventana equivocada (la consola negra) en lugar del juego. El script fuerza a Steam a transmitir la ventana correcta del juego.
3.  **Lanzamiento Limpio**: Cierra instancias previas y lanza el juego con los parámetros necesarios (`-anti-cheat-disabled`, etc.).

## ⚙️ Configuración

Antes de ejecutar el script, debes editar las siguientes variables dentro del archivo `PlayMCCWithAlphaRing.ps1` para que coincidan con tu sistema:

### 1. Ruta del Juego (`$gameBase`)
Esta variable debe apuntar a la carpeta donde tienes instalado Halo: MCC.
*   **Línea 2**:
    ```powershell
    $gameBase = "J:\SteamLibrary\steamapps\common\Halo The Master Chief Collection"
    ```
    *Cambia la ruta entre comillas por la ubicación real en tu PC.*

### 2. ID de Steam Falso (`$fakeAppId`)
Este es el ID del juego por el cual "estás haciendo pasar" a Halo. Se recomienda usar `886460` (Outside the Lines) ya que es gratuito y soporta Remote Play Together.
*   **Línea 6**:
    ```powershell
    $fakeAppId = "886460"
    ```
    *Solo cambia esto si usaste otro juego que no es Outside the Lines.*

## 🚀 Cómo usarlo

https://www.youtube.com/

---
*Este script automatiza el proceso de ocultar la consola y enfocar la ventana principal para asegurar que la transmisión de video funcione correctamente.*

