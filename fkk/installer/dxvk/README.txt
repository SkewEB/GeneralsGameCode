DXVK (https://github.com/doitsujin/dxvk), Direct3D 8/9 -> Vulkan.
zlib/libpng licence, see LICENSE.txt.
Unmodified x32 d3d8.dll and d3d9.dll of the official release, version pinned in
.github/workflows/fkk-installer.yml (SHA-256 checked in CI).

The game loads them from this folder; without a Vulkan capable graphics driver it
falls back to the normal Direct3D 8 automatically. To turn DXVK off, start the
"Generals FKK Edition (ohne DXVK)" shortcut (passes -nodxvk to the game).
