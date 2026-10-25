# MacBook8,1 (12" 2015): no sound from the speakers on Linux

[Türkçe açıklama aşağıda](#türkçe)

On the 12" MacBook (MacBook8,1) the built-in speakers stay silent on Linux. `cat /proc/asound/cards` lists the Cirrus Logic CS4208 codec, and volume controls move, but nothing comes out. The speakers sit behind a TDM class-D amplifier that the stock `snd_hda_codec_cs420x` driver cannot drive.

The driver that fixes this is [thomas-shirley/macbook8.1-speaker-driver](https://github.com/thomas-shirley/macbook8.1-speaker-driver). All credit for it goes to its author; read its README and `HOW_IT_WORKS.md` for the details. This repository only adds:

- a fix for a DKMS build failure on Ubuntu 24.04 / Linux Mint 22 ([upstream PR #9](https://github.com/thomas-shirley/macbook8.1-speaker-driver/pull/9))
- a one-command installer that applies that fix
- notes from running it day to day on Linux Mint

## The DKMS problem

The driver is packaged for DKMS, which rebuilds it on every kernel update. With dkms 3.0.11 (Ubuntu 24.04, Linux Mint 22) the build fails and the patched modules are never installed.

DKMS runs the steps in this order:

1. `PRE_BUILD` (`dkms_build.sh`) builds the modules into `build/`.
2. `CLEAN` runs at the start of the build step. Upstream sets it to `rm -rf build`, which deletes those modules.
3. `MAKE` is a no-op, so DKMS finds nothing to install.

The fix is a single line in `dkms.conf`: `CLEAN="true"`. DKMS still deletes the build tree on its own after it has copied the modules.

## Install

```sh
git clone https://github.com/hakanseyhan92/macbook8-1-linux-audio-fix
cd macbook8-1-linux-audio-fix
sudo ./install.sh
sudo reboot
```

`install.sh`:

1. Installs the build dependencies (`gcc make dkms wget git` and your kernel headers).
2. Clones the upstream driver into `/opt/macbook8.1-speaker-driver` at a tested commit. DKMS rebuilds from this folder on every kernel update, so leave it there.
3. Applies the `CLEAN="true"` fix.
4. Runs the upstream `install.sh`.

The build downloads the matching kernel source from kernel.org, so it needs an internet connection and takes a few minutes. To use the latest upstream code instead of the tested commit, run `sudo UPSTREAM_REF=main ./install.sh`.

### Manual install

```sh
git clone https://github.com/thomas-shirley/macbook8.1-speaker-driver
cd macbook8.1-speaker-driver
sed -i 's/^CLEAN="rm -rf build"$/CLEAN="true"/' dkms.conf
sudo bash install.sh
sudo reboot
```

If you install manually, keep the cloned folder where it is. DKMS links its source to it.

## Verify

```sh
wpctl status | grep -i speaker      # "MacBook Speaker (EQ)" should be the default sink
modinfo -n snd-hda-codec-cs420x     # should be under .../updates/dkms/
dkms status                         # macbook12-audio/0.1 installed for your kernel
```

## Suspend

The upstream package installs `mb81-resume-recover.service`, which brings the speakers back after every resume. It also runs after an s2idle resume. If you use the [keyboard/trackpad suspend fix](https://github.com/hakanseyhan92/macbook8-1-linux-suspend-fix), the two fit together.

## Uninstall

```sh
cd /opt/macbook8.1-speaker-driver
sudo bash install.sh -r
sudo reboot
```

## Tested on

- MacBook8,1 (Retina, 12-inch, Early 2015)
- Linux Mint 22.3 Xfce, dkms 3.0.11
- Kernels 6.17.0-29, 7.0.0-29, 7.0.0-30 and 7.0.0-38. DKMS rebuilt the driver automatically on each update.

## License

The installer and docs here are MIT. The driver itself is GPL-2.0-or-later and belongs to its upstream authors.

---

## Türkçe

12" MacBook'ta (MacBook8,1) Linux'ta hoparlörden ses gelmez. Ses kartı (Cirrus Logic CS4208) görünür, ses seviyesi değişir ama ses çıkmaz.

Sorunu çözen sürücü [thomas-shirley/macbook8.1-speaker-driver](https://github.com/thomas-shirley/macbook8.1-speaker-driver) projesidir. Emek onun yazarına aittir. Bu depo Linux Mint 22 / Ubuntu 24.04'te kurulumu bozan bir sorunu düzeltir ve tek komutla kurulum sağlar.

**Sorun:** DKMS, derlemenin ortasında `CLEAN` adımını çalıştırıyor. Orijinal ayardaki `rm -rf build` yeni derlenen sürücüyü silip kurulumu başarısız yapıyor. Düzeltme, `dkms.conf` içinde `CLEAN="true"` satırı.

**Kurulum:**

```sh
git clone https://github.com/hakanseyhan92/macbook8-1-linux-audio-fix
cd macbook8-1-linux-audio-fix
sudo ./install.sh
sudo reboot
```

Betik sürücüyü `/opt/macbook8.1-speaker-driver` klasörüne indirir, düzeltmeyi uygular ve orijinal kurulumu çalıştırır. Kernel her güncellendiğinde sürücü bu klasörden otomatik yeniden derlenir, bu yüzden klasörü silmeyin. Kurulum sırasında internet bağlantısı gerekir ve birkaç dakika sürer.

**Kontrol:** yeniden başlattıktan sonra `wpctl status | grep -i speaker` komutunda "MacBook Speaker (EQ)" görünmeli.

**Kaldırma:** `cd /opt/macbook8.1-speaker-driver && sudo bash install.sh -r`, ardından yeniden başlatın.

Uykudan uyanınca sesi geri getiren servis de kuruluma dahildir ve [klavye/trackpad uyku düzeltmesiyle](https://github.com/hakanseyhan92/macbook8-1-linux-suspend-fix) birlikte çalışır.
