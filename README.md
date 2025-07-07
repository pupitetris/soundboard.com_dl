# soundboard.com_dl
Quick and dirty soundboard downloader for the soundboard.com website (2025). Other scrapers around don't work anymore because they depend on resources that are no longer available on the website.

## Installation

On a Debian/Ubuntu based distro, install packages:

```sh
apt install libfile-mimeinfo-perl libhtml-parser-perl libjson-perl liblwp-protocol-https-perl liburi-perl
```

Download the software:

```sh
git clone https://github.com/pupitetris/soundboard.com_dl.git
```

## Invokation

After that, just run the program providing the URL to the specific soundboard you want to scrape inside the desired directory:

```sh
mkdir duke_nukem
cd duke_nukem
../soundboard.com_dl/soundboard.com_dl.pl https://www.soundboard.com/sb/solrosin
```

## Output

The script will download the web page and save it as `index.html`, generate a metadata JSON file as `metadata.json` with all of the recovered information from the web page, and then proceed to download all of the tracks.

Every track is saved inside a new `tracks` subdirectory using its position in the soundboard, track_id and track title as a filename. The extension is guessed from the arriving data, which should probably always be `.mp3`. If the file type guess fails, the extension will be `.dat`. The original JSON track files will be stored in `tracks/json`.

```sh
find . -print | sort
```

```
.
./boardicon.jpg
./index.html
./metadata.json
./soundboard_dl.pl
./tracks
./tracks/01-54064-I've got balls of steel.mp3
./tracks/02-54065-Balls of steel.mp3
./tracks/03-54066-Balls.mp3
...
./tracks/json
./tracks/json/01-54064-I've got balls of steel.json
./tracks/json/02-54065-Balls of steel.json
./tracks/json/03-54066-Balls.json
...
```

If run again, the script won't download existing files, so if you want to force a download, remove the respective file (or all of the directory's content) and run the script again. If you want to re-download a track audio file, remove the corresponding file inside the `tracks/json` directory. The `mp3` (or whatever) files are not downloaded: they are generated from their JSON counterparts which are the data downloaded from the site.
