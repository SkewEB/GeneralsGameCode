; Private game-data download for friends without a Zero Hour install.
; Values come from FKK-Spieldaten-hochladen.ps1 (run once by Kewe).
; Empty hashes = download option disabled.
#define DataBaseURL     "https://dl.kewekordes.com/spieldaten/"
#define ZHDataFile      "fkk-zh.zip"
#define ZHDataSHA256    "24f224a74094403838f1fc6332de310c10cc265dd8b6fe2aab44cdb5fdd291ab"
#define GenDataFile     "fkk-generals.zip"
#define GenDataSHA256   "b0be0554549a5a8c1b27f11da880c02984a30c6d751e710b4813c3b3b1e67cde"
#define DataLanguage    "german"
#define DataVersion     "65540"

; Optional HD texture pack (AI-upscaled unit/building textures, loose files in Art\Textures).
; Values come from FKK-HD-hochladen.ps1 (run once by Kewe). Empty hash = part not offered.
#define HDSize          "ca. 520 MB Download, 1,1 GB auf der Platte"
#define HDFile1         "fkk-hd-1.zip"
#define HDSHA1          "3bf3fc14a6e57f59f87159f2e3572d5e81d4981c409775312761c0e8492bc7d2"
#define HDFile2         "fkk-hd-2.zip"
#define HDSHA2          "f52df1284e8acbcf6fe0ad6b7d8d18638f4fb36af9bf3e2c71ca03050895105e"
#define HDFile3         "fkk-hd-3.zip"
#define HDSHA3          ""
