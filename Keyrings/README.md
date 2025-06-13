# Armbian 个人构建版升级软件源说明

本文档将指导您如何为您的 Armbian 系统添加并配置个人构建软件源，以获取为特定板卡和分支编译的最新内核。

## 操作步骤

### 第一步：安装 GPG 签名密钥

首先，您的系统必须信任本软件源的 GPG 签名密钥。此密钥用于验证所有软件包的来源和完整性。

请在您的 Armbian 设备终端中执行以下命令，它将下载并安装 GPG 密钥。

```bash
sudo curl -fsSL "https://raw.githubusercontent.com/YANXIAOXIH/Armbian-Actions/main/Keyrings/armbian-actions.gpg" -o /usr/share/keyrings/armbian-actions.gpg
```

### 第二步：选择您的设备并添加软件源

本软件源为不同的开发板和内核分支提供了独立的软件包。**请根据您的设备型号和需求，从以下选项中选择一个执行。**

---

#### 选项 A：为 LemonPi 添加 Edge 内核源

如果您使用的是 `LemonPi` 并希望使用最新的 `edge` 内核：
```bash
cat <<EOF | sudo tee /etc/apt/sources.list.d/armbian-actions.sources > /dev/null
Types: deb
URIs: https://YANXIAOXIH.github.io/Armbian-Actions/
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: main lemonpi-edge
Architectures: $(dpkg --print-architecture)
Signed-By: /usr/share/keyrings/armbian-actions.gpg
EOF
```

---

#### 选项 B：为 LemonPi 添加 Vendor 内核源

如果您使用的是 `LemonPi` 并希望使用更稳定的 `vendor` (厂商) 内核：
```bash
cat <<EOF | sudo tee /etc/apt/sources.list.d/armbian-actions.sources > /dev/null
Types: deb
URIs: https://YANXIAOXIH.github.io/Armbian-Actions/
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: main lemonpi-vendor
Architectures: $(dpkg --print-architecture)
Signed-By: /usr/share/keyrings/armbian-actions.gpg
EOF
```

---

#### 选项 C：为 SOM3588-CAT 添加 Edge 内核源

如果您使用的是 `SOM3588-CAT` 并希望使用最新的 `edge` 内核：
```bash
cat <<EOF | sudo tee /etc/apt/sources.list.d/armbian-actions.sources > /dev/null
Types: deb
URIs: https://YANXIAOXIH.github.io/Armbian-Actions/
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: main som3588-cat-edge
Architectures: $(dpkg --print-architecture)
Signed-By: /usr/share/keyrings/armbian-actions.gpg
EOF
```

---

#### 选项 D：为 SOM3588-CAT 添加 Vendor 内核源

如果您使用的是 `SOM3588-CAT` 并希望使用更稳定的 `vendor` (厂商) 内核：
```bash
cat <<EOF | sudo tee /etc/apt/sources.list.d/armbian-actions.sources > /dev/null
Types: deb
URIs: https://YANXIAOXIH.github.io/Armbian-Actions/
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: main som3588-cat-vendor
Architectures: $(dpkg --print-architecture)
Signed-By: /usr/share/keyrings/armbian-actions.gpg
EOF
```

---

### 第三步：刷新并更新系统

当您完成了第二步的选择后，现在可以进行系统更新。

1.  **刷新软件包列表：**
    ```bash
    sudo apt update
    ```
    您应该能在输出中看到一条指向 `https://YANXIAOXIH.github.io/Armbian-Actions/` 的信息。

2.  **执行系统升级：**
    ```bash
    sudo apt upgrade
    ```
    `apt` 会找到并列出所有可用的内核更新，按照提示操作即可。

3.  **重启系统（如果内核被更新）：**
    内核更新后，必须重启才能生效。
    ```bash
    sudo reboot
    ```

---
您的系统现在已配置完成，可以持续接收来自您所选组件的更新。
