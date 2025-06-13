# Armbian 个人构建版升级软件源说明

本文档将指导您如何使用此目录下的 GPG 密钥，为您的 Armbian 系统添加并配置个人构建软件源，以获取最新的内核和系统更新。

## 操作步骤

### 第一步：安装 GPG 签名密钥

首先，您的系统必须信任本软件源的 GPG 签名密钥。此密钥用于验证所有软件包的来源和完整性。

请在您的 Armbian 设备终端中执行以下命令，它将把 GPG 密钥复制到系统的标准密钥环目录中。

```bash
sudo curl -fsSL "https://raw.githubusercontent.com/YANXIAOXIH/SOM3588Cat-Armbian/main/Keyrings/armbian-actions.gpg" -o /usr/share/keyrings/armbian-actions.gpg
```

### 第二步：添加软件源

接下来，我们将创建一个新的软件源列表文件。以下命令将自动检测您当前的系统架构和发行版代号，无需手动修改。

请直接复制并执行以下**一整个代码块**：

```bash
cat <<EOF | sudo tee /etc/apt/sources.list.d/armbian-actions.sources > /dev/null
Types: deb
URIs: https://YANXIAOXIH.github.io/SOM3588Cat-Armbian/
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /usr/share/keyrings/armbian-actions.gpg
EOF
```

### 第三步：刷新并更新系统

所有配置均已完成。现在您可以进行系统更新。

1.  **刷新软件包列表：**
    ```bash
    sudo apt update
    ```
    您应该能在输出中看到一条指向 `https://YANXIAOXIH.github.io/SOM3588Cat-Armbian/` 的信息。

2.  **执行系统升级：**
    ```bash
    sudo apt upgrade
    ```
    `apt` 会列出所有可用的更新，按照提示操作即可。

3.  **重启系统（如果内核被更新）：**
    内核更新后，必须重启才能生效。
    ```bash
    sudo reboot
    ```

---
您的系统现在已配置完成，可以持续接收来自本项目的更新。
