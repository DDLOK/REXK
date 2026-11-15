# REXK — ollie's bench

FiveM freeroam server pack built by Olivia. Drops into any FXServer install.

## what's inside

| resource | does |
|---|---|
| `[local]/chat_ollie` | `/me` `/ooc` `/pm` `/clear` `/help`, join+leave broadcasts, welcome lines |
| `[local]/menu_ollie` | F5 main menu — self, teleports, vehicles, weapons, world, players |
| `[local]/spawn_ollie` | random sane spawn on join (Legion Sq, LSIA, Sandy, Paleto, Chiliad, Grove) |
| `[local]/admin_ollie` | `/kick` `/ban` `/unban` `/ac` `/players` `/whoami` (ace-gated) |

Plus full `cfx-server-data` core resources ([system], [managers], [gameplay], [gamemodes]).

## deploy on altare / any pterodactyl-style host

1. in your panel's **File Manager** or via **SFTP**, land in `/home/container/`
2. clone this repo:
   ```sh
   git clone https://github.com/andreh901300/REXK.git .
   ```
   (the `.` is important — clones into current dir, not a subfolder)
3. set your license key:
   - panel **Startup** tab → `LICENSE_KEY` variable → paste your key from https://keymaster.fivem.net
   - OR edit `server.cfg` → uncomment `sv_licenseKey` line and paste your key
4. set your port:
   - check panel **Network** tab for your allocated port
   - edit `server.cfg` → update the two `endpoint_add_*` lines to that port
5. hit **Start** in panel console

## deploy locally (windows)

download the Windows setup from https://github.com/andreh901300/REXK/wiki
or use the `run.bat` from the companion repo.

## updating

on the host, in its console or SFTP terminal:
```sh
cd /home/container
git pull
```
then **Restart** from the panel.

## in-game controls

| key / command | action |
|---|---|
| **F5** | toggle main menu |
| `/menu` | same as F5 |
| `/help` | list chat commands |
| `/whoami` | your identifiers (for admin setup) |

## admin yourself

after first connect, in chat: `/whoami` → copy the `license:...` line → edit `server.cfg`:
```cfg
add_principal identifier.license:YOUR_HEX group.admin
```
then in server console: `restart admin_ollie`

---

built by Olivia — https://discord.gg/6h2kEeasJx
