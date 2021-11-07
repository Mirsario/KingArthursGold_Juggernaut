![Img](https://i.imgur.com/Hc8ElCj.png)

# What's this?!
Juggernaut is an asymmetrical team deathmatch gamemode for [King Arthur's Gold](https://store.steampowered.com/app/219830/King_Arthurs_Gold/), where evil giants with hammers throw grandpas at knights.

# How do I play this?
There might be a juggernaut server online in KAG's server browser. If not, then..

# How do I host this?
My recommendation is to clone this repository (or your fork of it) with git, and then create symlinks inside KAG's Mods folder to the folders inside the repo.
On Windows, this can be done with something like this:
```
mklink /J "D:\Steam\steamapps\common\King Arthur's Gold\Mods\Mirsario_Juggernaut" "Mirsario_Juggernaut"`
mklink /J "D:\Steam\steamapps\common\King Arthur's Gold\Mods\Mirsario_JuggernautMusic" "Mirsario_JuggernautMusic"
```

Then, add `Mirsario_Juggernaut` and `Mirsario_JuggernautMusic` to `mods.cfg`.

# License stuff
All *original* code & art in this repository is licensed under the MIT license, which you can read in [LICENSE.md](https://github.com/Mirsario/KingArthursGold_Juggernaut/blob/master/LICENSE.md).

The music tracks, found in `Mirsario_JuggernautMusic/Music`, are special re-renders of music tracks that fully belong to Id Software & TeamTNT. No commercial use & copyright infringement are intended.

# Thanks to
- Koi_ (Bananaman) - Various help in early development.
- kezzawozza - A neat map!
