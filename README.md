# NixOS configs

NixOS configurations for all my systems.

- [NixOS configs](#nixos-configs)
  - [1. Repository Architecture Overview](#1-repository-architecture-overview)
    - [1.1. Key Components](#11-key-components)
      - [1.1.1. Flake Entrypoint (`flake.nix`)](#111-flake-entrypoint-flakenix)
      - [1.1.2. Machines (`machines/`)](#112-machines-machines)
      - [1.1.3. Modules (`modules/`)](#113-modules-modules)
      - [1.1.4. Users (`users/`)](#114-users-users)
      - [1.1.5. Utils (`utils/`)](#115-utils-utils)
      - [1.1.6. Secrets Management (`secrets/`)](#116-secrets-management-secrets)
    - [1.2. How It Works](#12-how-it-works)
  - [2. Secrets Management with SOPS-nix](#2-secrets-management-with-sops-nix)
    - [2.1. Generating an age key](#21-generating-an-age-key)
    - [2.2. Creating/Modifying a new secrets file with sops](#22-creatingmodifying-a-new-secrets-file-with-sops)
  - [3. Install](#3-install)
    - [3.1. Baremetal machine](#31-baremetal-machine)
      - [3.1.1. Set a password for ssh access (optional)](#311-set-a-password-for-ssh-access-optional)
      - [3.1.2. Partitioning](#312-partitioning)
        - [3.1.2.1. Partition the drive](#3121-partition-the-drive)
        - [3.1.2.2. Preparing the root partition](#3122-preparing-the-root-partition)
        - [3.1.2.3. Encrypt root partition](#3123-encrypt-root-partition)
          - [3.1.2.3.1. Create and mount Btrfs partition](#31231-create-and-mount-btrfs-partition)
        - [3.1.2.4. Preparing the EFI System Partition](#3124-preparing-the-efi-system-partition)
          - [3.1.2.4.1. Format EFI System Partition](#31241-format-efi-system-partition)
          - [3.1.2.4.2. Mount EFI System Partition](#31242-mount-efi-system-partition)
        - [3.1.2.5. Clone repo](#3125-clone-repo)
      - [3.1.3. Generate hardware-config](#313-generate-hardware-config)
      - [3.1.4. Create initrd ssh key](#314-create-initrd-ssh-key)
      - [3.1.5. Activate SOPS-Nix](#315-activate-sops-nix)
      - [3.1.6. Install the system](#316-install-the-system)
      - [3.1.7. Post install](#317-post-install)
    - [3.2. WSL install](#32-wsl-install)
      - [3.2.1. Distribution installation](#321-distribution-installation)
      - [3.2.2. Clone repo](#322-clone-repo)
      - [3.2.3. Activate SOPS-Nix](#323-activate-sops-nix)
      - [3.2.4. Install the system](#324-install-the-system)
      - [3.2.5. Post Install](#325-post-install)

## 1. Repository Architecture Overview

This NixOS configuration repository is organized to support modular, maintainable, and scalable system and user configurations using Nix flakes and home-manager.

### 1.1. Key Components

#### 1.1.1. Flake Entrypoint (`flake.nix`)

- Defines inputs for NixOS, home-manager, and related channels.
- Specifies all system configurations (e.g. `aspire` and `wsl` at the time of writing).
- Each system pulls in its respective machine configuration and home-manager integration.

#### 1.1.2. Machines (`machines/`)

- Contains per-host configuration folders (e.g., `aspire`, `wsl`).
- Each folder includes:
  - `default.nix`: Main system configuration for the host.
  - `hardware-configuration.nix`: Hardware-specific settings (for physical machines).

#### 1.1.3. Modules (`modules/`)

- Houses reusable NixOS modules, organized by category:
  - `base/`: Core system settings (e.g., editor, environment variables, home-manager integration).
  - `boot/`, `containers/`, `networking/`, `services/`, `storage/`: Service and system modules, often with further submodules.
- Each module is typically imported into machine configs for composability.

#### 1.1.4. Users (`users/`)

- Per-user configuration folders (e.g., `gsegt`).
- Each user folder contains:
  - `default.nix`: Main home-manager configuration for the user.
  - Subfolders (e.g., `git/`, `shell/`, `ssh/`): Home-manager modules for user-specific settings and packages.
- User modules are automatically imported using utility functions.

#### 1.1.5. Utils (`utils/`)

- Utility functions for module management.
- Example: `importSubmodules.nix` automates importing all submodules in a directory.

#### 1.1.6. Secrets Management (`secrets/`)

- Secrets are managed using [SOPS](https://github.com/getsops/sops), [age](https://github.com/FiloSottile/age), and the [sops-nix](https://github.com/Mic92/sops-nix) framework.
- [sops-nix](https://github.com/Mic92/sops-nix) integrates SOPS secrets directly into NixOS and Home Manager modules, making secret values available as Nix options.
- Age keys are stored in `/etc/secrets/sosp/age/keys.txt` (see instructions below for generation).
- Encrypted secrets are stored in YAML files, with the default at `secrets/default.yaml`. ANy file matching the `secrets/.*\.yaml` pattern can be used for extra secrets.
- SOPS is used to encrypt, decrypt, and edit secrets files. The public key from the age key is used for encryption.
- NixOS and Home Manager modules can consume secrets by referencing the decrypted files at build or runtime, or by using sops-nix options.

### 1.2. How It Works

- **System Configuration:** Each machine (`aspire`, `wsl`) is defined in `flake.nix` and references its folder in `machines/`. These configs import relevant modules from `modules/`.
- **User Configuration:** Home-manager is integrated via modules and per-user configs in `users/`. User modules are auto-imported for convenience.
- **Modularity:** New features or services can be added by creating new modules in `modules/` or user modules in `users/<user>/`.
- **Reproducibility:** The flake structure ensures reproducible builds and easy upgrades.

## 2. Secrets Management with SOPS-nix

### 2.1. Generating an age key

A key can be created to `/etc/secrets/sosp/age/keys.txt` with `nix shell nixpkgs#age --command sudo age-keygen -o /etc/secrets/sops/age/keys.txt`

Then, if necessary, `sed -i "s/\&aspire .*/\&aspire $(nix shell nixpkgs#age --command sudo age-keygen -y /etc/secrets/sops/age/keys.txt)/g" .sops.yaml` can be used to update the `.sops.yaml` configuration

### 2.2. Creating/Modifying a new secrets file with sops

To create a new encrypted secrets file (default: `secrets/default.yml`):

```sh
mkdir -vp secrets
nix shell nixpkgs#sops --command sh -c "SOPS_AGE_KEY_CMD='sudo tail -n 1 /etc/secrets/sops/age/keys.txt' sops secrets/default.yaml"
```

This will open your editor. Add your secrets, save, and close the editor. The file will be encrypted.

## 3. Install

### 3.1. Baremetal machine

1. Boot up the NixOS minimal ISO on the target machine

#### 3.1.1. Set a password for ssh access (optional)

1. Run `passwd` to give the default `nixos` user a password to ssh into it.

#### 3.1.2. Partitioning

##### 3.1.2.1. Partition the drive

1. Run `sudo lsblk` to find your drive
2. Run `sudo sgdisk --zap-all /dev/${drive}` to completely erase your drive and create new GPT partition table with no partitions
3. Run the following command to partition the drive and give the partitions labels:

    ```shell
    sudo sgdisk --clear \
      --new=1:0:+1GiB --typecode=1:ef00 --change-name=1:ESP \
      --new=2:0:0 --typecode=2:8300 --change-name=2:cryptsystem \
      /dev/${drive}
    ```

4. Run `lsblk -o +partlabel` to verify partitioning and labelling

> [!NOTE]
> `partlabel` (and `label` further down the guide) are optional are are simply based on convenience.

##### 3.1.2.2. Preparing the root partition

##### 3.1.2.3. Encrypt root partition

1. Run `sudo cryptsetup luksFormat /dev/disk/by-partlabel/cryptsystem` and then type `YES` and then type your encryption password twice to encrypt the root partition
2. Run `sudo cryptsetup open /dev/disk/by-partlabel/cryptsystem system` to open the encrypted partition with name `system` ; It can now be found under `/dev/mapper/system`

###### 3.1.2.3.1. Create and mount Btrfs partition

1. Run `sudo mkfs.btrfs --label system /dev/mapper/system` to create the Btrfs root filesystem with the label `system`
2. Run `sudo mount -o defaults,noatime,compress-force=zstd:1,x-mount.mkdir LABEL=system /mnt` to mount the root Btrfs partition to `/mnt`
   - `noatime` prevents update time of a file on reads
   - `compress-force=zstd:1` will enable native compression with zstd algorithm at level 1 and use zstd algorithm to figure if compressing a file is worth it instead of Btrfs' algorithm
   - `x-mount.mkdir` creates a folder if necessary

##### 3.1.2.4. Preparing the EFI System Partition

###### 3.1.2.4.1. Format EFI System Partition

1. Run `sudo mkfs.vfat -F32 -n ESP /dev/disk/by-partlabel/ESP` to create the FAT32 boot filesystem with label `ESP`

###### 3.1.2.4.2. Mount EFI System Partition

1. Run `sudo mount -o defaults,umask=0077,x-mount.mkdir LABEL=ESP /mnt/boot` to mount the ESP in `/mnt`
    - `umask=0077` will mount the drive with 0700 default permissions

2. Run `lsblk -o +label` to verify mounting and labelling

##### 3.1.2.5. Clone repo

1. Run `mkdir -vp ~/.ssh` to create the `~/.ssh` folder
2. Run `echo "<your_key>" > ~/.ssh/github` to create you private github key, it should already be associated with your account
3. Run `chmod 600 ~/.ssh/github` to set correct read/write permission for the private key
4. Run the following to create an ssh config that can clone from github

    ```shell
    echo "#: github.com - commit/pull/push to github.com
    Host github.com gist.github.com
        HostName github.com
        IdentityFile ~/.ssh/github
    " > .ssh/config
    ```

5. Run `sudo mkdir -vp /mnt/etc/nixos` to create the folder for our config
6. Run `sudo chown nixos:users /mnt/etc/nixos` to let the current user have full permissions over the folder
7. Run `git clone git@github.com:gsegt/nixos-configs.git /mnt/etc/nixos` to clone the configuration is the appropriate repo

#### 3.1.3. Generate hardware-config

1. Run `sudo nixos-generate-config --show-hardware-config --root /mnt > /mnt/etc/nixos/system/hardware-configuration.nix` to re-generate an up to date hardware config
2. Run `nix-shell -p nixfmt-rfc-style --run 'nixfmt /mnt/etc/nixos/system/hardware-configuration.nix'` to format the hardware configuration file
3. Run `nano /mnt/etc/nixos/system/hardware-configuration.nix` to add the following to the hardware-config:

    ```conf
    fileSystems."/" = {
        ...
        options = [
            "compress-force=zstd:1"
            "noatime"
        ];
    };
    ```

#### 3.1.4. Create initrd ssh key

1. Run `sudo mkdir -vp /mnt/etc/secrets/initrd/` to create a directory for the initrd ssh key
2. Run `ssh-keygen -a 128 -t ed25519 (or -t rsa -b 4096) -N "" -f /mnt/etc/secrets/initrd/ssh_host_ed25519_key` to create the ssh key
3. Run `sudo chmod 700 /mnt/etc/secrets/` to secure access to the directory, allowing only `root`

#### 3.1.5. Activate SOPS-Nix

1. Run `nix shell nixpkgs#age --command age-keygen -o /etc/secrets/sosp/age/keys.txt` to generate a new age key and save it to `/etc/secrets/sosp/age/keys.txt`
2. Run `sed -i "s/\&aspire .*/\&aspire $(nix shell nixpkgs#age --command sudo age-keygen -y /etc/secrets/sops/age/keys.txt)/g" .sops.yaml` to update `.sops.yaml` configuration

#### 3.1.6. Install the system

1. Run `sudo nixos-install --flake /mnt/etc/nixos#aspire` to install the system
2. Run `reboot` to enjoy your your new system; Congratulations by the way \o/

> [!IMPORTANT]
> Additionally, if you have any keyfiles to transfer, now is a good time.

#### 3.1.7. Post install

1. Run `sudo zfs import <vault>` to import your zfs pool, if any

### 3.2. WSL install

#### 3.2.1. Distribution installation

1. Follow instruction from [https://nix-community.github.io/NixOS-WSL/](https://nix-community.github.io/NixOS-WSL/) to install the base wsl NixOS distribution
2. Run `sudo nix-channel --update` to update the current channels
3. Run `sudo nixos-rebuild switch` to rebuilt with the latest channels

#### 3.2.2. Clone repo

1. Follow the steps 1 to 4 from [2.1.2.5. Clone repo](#2125-clone-repo)
2. Run `sudo chown nixos:users /etc/nixos` to let the current user have full permissions over the folder
3. Run `rm -rf /etc/nixos/*` to clean the `nixos` folder
4. Run `nix-shell -p git` to temporarily install `git`
5. Run `git clone git@github.com:gsegt/nixos-configs.git /etc/nixos` to clone the configuration is the appropriate repo

#### 3.2.3. Activate SOPS-Nix

Follow the steps at [3.1.5. Activate SOPS-Nix](#315-activate-sops-nix)

#### 3.2.4. Install the system

1. Run `sed -i 's|./common/upgrade-diff.nix|# ./common/upgrade-diff.nix|g' /etc/nixos/system/common.nix /etc/nixos/home/common.nix` to avoid errors messages
2. Run `rm ~/.ssh/config` as this file will be generated by `home-manager`
3. Run `sudo nixos-rebuild boot --flake /etc/nixos#wsl` to install the system

> [!IMPORTANT]
> Since the flake changes the default username, it is necessary to foolow the following instructions after rebuilding for the first time: [https://nix-community.github.io/NixOS-WSL/how-to/change-username.html](https://nix-community.github.io/NixOS-WSL/how-to/change-username.html)

#### 3.2.5. Post Install

1. Run `cp -v /home/nixos/.ssh/github ~/.ssh/github` to copy the private key
2. Run `sudo rm -rv /home/nixos` to remove the old user folder
