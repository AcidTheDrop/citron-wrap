# 🎮 citron-wrap

> Controller config swapper for Citron on Steam Deck — no more re-binding every time you switch modes.

---

## 🧠 Why this exists

On Steam Deck, controllers are exposed differently between **Desktop Mode** and **Game Mode**, resulting in different device GUIDs.

Citron saves controller bindings tied to those identifiers. When you switch modes, the previous GUID may no longer exist, causing Citron to fall back to a default or “any” device mapping.

This wrapper fixes the issue by swapping in the correct config *before* Citron ever starts.

<details>
<summary><h3>🔧 How it works</h3></summary>

When Citron launches through this wrapper, it will:

1. Detect the current Steam Deck mode
2. Select the matching config file  
   - `qt-config.desktop.ini`  
   - `qt-config.gamemode.ini`
3. Copy it to:

```
qt-config.ini
```

This happens on **every launch**, ensuring the correct device GUIDs are always active.

</details>

---

## 🚀 Setup

### 1️⃣ Desktop Mode config

1. Switch to **Desktop Mode** and launch Citron
2. Open the input configuration screen and set up your controller.
3. Close Citron, open a terminal, and run:

```bash
cd ~/.config/citron
cp qt-config.ini qt-config.desktop.ini
```

---

### 2️⃣ Game Mode config
> 💡 **Tip:** If you don’t have a keyboard connected in Game Mode, bind **F11** to a rear button (for example **L4**) so you can open Citron’s input settings easily.

1. Switch to **Game Mode** and launch Citron.
2. Open the input configuration screen and set up your controller. 
3. Return to **Desktop Mode**.
4. Open a terminal and run:

```bash
cd ~/.config/citron
cp qt-config.ini qt-config.gamemode.ini
```

---

### 3️⃣ Install citron-wrap.sh (ES-DE custom launcher)
> 💡 **Tip:** Your paths here may vary depending on where you chose to install your EmuDeck directory during setup.

Copy the wrapper into EmuDeck’s launchers folder and make it executable:

```bash
cp citron-wrap.sh ~/Emulation/tools/launchers/citron-wrap.sh
chmod +x ~/Emulation/tools/launchers/citron-wrap.sh
```

Open ES-DE’s custom systems file:

```
~/ES-DE/custom_systems/es_systems.xml
```

Update the Citron command to:

```xml
<command label="Citron (Standalone)">~/Emulation/tools/launchers/citron-wrap.sh -f -g %ROM%</command>
```
### That's it! You're good to go! 
When you launch a switch game from ES-DE "citron-wrap.sh" gets called instead of "citron.sh" (leave citron.sh where it is). The steamdeck mode is detected by citron-wrap and the contents of "qt-config.ini" get swapped out for either, "qt-config.desktop.ini" or "qt-config.gamemode.ini" (One of the 2 config files you manually created in steps 1-2). 

<details>
<summary><h3>📝 Log file</h3></summary>



The wrapper writes a debug log on every launch:

```
$HOME/.local/state/citron-wrap.log
```

If something isn’t working, check this file first:

```
bash
cat ~/.local/state/citron-wrap.log
```
</details>
<details>
<summary><h3>🔄 How to Undo</h3></summary>



To revert back to Citron’s original launcher, edit:

```
/home/deck/ES-DE/custom_systems/es_systems.xml
```

and change the command back to one of these:

```xml
<command label="Citron (Standalone)">%INJECT%=%BASENAME%.esprefix %EMULATOR_CITRON% -f -g %ROM%</command>
```
```xml
<command label="Citron (Standalone)">/home/deck/Emulation/tools/launchers/citron.sh -f -g %ROM%</command>
```
</details>
