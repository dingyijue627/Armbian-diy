@echo off
@title UFI001C Armbian 全能刷机工具
color 0A
mode con cols=105 lines=50

:: =============================================================================================
:: 定义文件路径变量，方便维护
:: =============================================================================================
set "FASTBOOT_PATH=%~dp0fastboot"
set "FIRMWARE_PATH=%~dp0firmware"
set "IMAGES_PATH=%~dp0images"

:main
cls
echo =============================================================================================
echo.
echo                   欢迎使用 UFI001C Armbian 全能刷机工具
echo.
echo      本脚本将引导您完成所有步骤，包括备份、刷写底层固件和安装 Armbian 系统。
echo     - 【警告】请确保 'images' 文件夹中只有一个 Armbian 版本的 boot 和 rootfs 镜像！
echo.
echo =============================================================================================
echo.

:: 1. 检测设备连接
echo [步骤 1/7] 正在检测设备连接...
echo.
echo --- 检测ADB设备 (安卓模式) ---
"%FASTBOOT_PATH%\adb.exe" devices -l | find "device product:" >nul
if errorlevel 1 (
    echo [提示] ADB设备未连接。如果设备已在Fastboot模式，此提示可忽略。
) else (
    echo [成功] ADB设备已连接。
)
echo.
echo --- 检测Fastboot设备 (刷机模式) ---
"%FASTBOOT_PATH%\fastboot.exe" devices
echo.

:: 2. 用户确认
echo ------------------------------------- [ !! 重要警告 !! ] --------------------------------------
echo.
echo   此操作将【完全擦除】设备上的所有数据！刷机有风险，操作需谨慎！
echo   请确保已备份好个人数据，并保持USB连接稳定。
echo.
echo -----------------------------------------------------------------------------------------------
echo.
set /p confirm="准备就绪，请按 回车键(Enter) 直接开始，或输入 N 退出: "
if /i "%confirm%"=="N" (
    echo.
    echo [操作取消] 用户已选择退出刷机。
    pause
    exit
)

:: ===================================================================================================
::  关键步骤：刷写 lk2nd 以进行安全备份
:: ===================================================================================================
echo.
echo [步骤 2/7] 正在刷写临时引导程序 (lk2nd) 以进行安全备份...
echo.
"%FASTBOOT_PATH%\adb.exe" reboot bootloader >nul 2>&1
timeout /t 2 /nobreak >nul

"%FASTBOOT_PATH%\fastboot.exe" flash boot "%FIRMWARE_PATH%\lk2nd.img"
echo 正在重启到 lk2nd 临时引导...
"%FASTBOOT_PATH%\fastboot.exe" reboot
echo.
echo 正在自动检测设备重连，请稍候 (最长等待 30 秒)...
set /a countdown=30

:waitForLk2nd
if %countdown% leq 0 (
    echo.
    echo.
    echo [错误] 等待设备重新连接超时！
    echo 请检查USB连接和驱动程序，然后重新运行脚本。
    pause
    goto :eof
)
"%FASTBOOT_PATH%\fastboot.exe" devices | findstr "fastboot" > nul
if %errorlevel% equ 0 (
echo.
    echo [成功] 设备已在 lk2nd Fastboot 模式下连接！
    goto :continueToBackup
)
set /p ".=." <nul
timeout /t 1 /nobreak >nul
set /a countdown-=1
goto waitForLk2nd

:continueToBackup
echo.
echo [步骤 3/7] 正在备份射频校准分区 (fsc, fsg, modemst1, modemst2)...
echo.
"%FASTBOOT_PATH%\fastboot.exe" oem dump fsc && "%FASTBOOT_PATH%\fastboot.exe" get_staged "%FIRMWARE_PATH%\fsc.bin"
"%FASTBOOT_PATH%\fastboot.exe" oem dump fsg && "%FASTBOOT_PATH%\fastboot.exe" get_staged "%FIRMWARE_PATH%\fsg.bin"
"%FASTBOOT_PATH%\fastboot.exe" oem dump modemst1 && "%FASTBOOT_PATH%\fastboot.exe" get_staged "%FIRMWARE_PATH%\modemst1.bin"
"%FASTBOOT_PATH%\fastboot.exe" oem dump modemst2 && "%FASTBOOT_PATH%\fastboot.exe" get_staged "%FIRMWARE_PATH%\modemst2.bin"
echo.
echo [成功] 关键分区已备份至 'firmware' 文件夹。
timeout /t 2 /nobreak
echo.

:: ===================================================================================================
::  清理临时引导，开始刷写底层
:: ===================================================================================================
echo [步骤 4/7] 正在刷写底层固件和分区表...
echo.
echo 清理临时引导并重启到Bootloader...
"%FASTBOOT_PATH%\fastboot.exe" erase boot
"%FASTBOOT_PATH%\fastboot.exe" reboot bootloader
echo 等待设备再次进入Bootloader...
timeout /t 5 /nobreak >nul

"%FASTBOOT_PATH%\fastboot.exe" flash partition "%FIRMWARE_PATH%\gpt_both0.bin"
"%FASTBOOT_PATH%\fastboot.exe" flash hyp "%FIRMWARE_PATH%\hyp.mbn"
"%FASTBOOT_PATH%\fastboot.exe" flash rpm "%FIRMWARE_PATH%\rpm.mbn"
"%FASTBOOT_PATH%\fastboot.exe" flash sbl1 "%FIRMWARE_PATH%\sbl1.mbn"
"%FASTBOOT_PATH%\fastboot.exe" flash tz "%FIRMWARE_PATH%\tz.mbn"
"%FASTBOOT_PATH%\fastboot.exe" flash aboot "%FIRMWARE_PATH%\aboot.bin"
"%FASTBOOT_PATH%\fastboot.exe" flash cdt "%FIRMWARE_PATH%\sbc_1.0_8016.bin"
echo.

echo [步骤 5/7] 正在恢复关键分区并擦除旧系统...
echo.
"%FASTBOOT_PATH%\fastboot.exe" flash fsc "%FIRMWARE_PATH%\fsc.bin"
"%FASTBOOT_PATH%\fastboot.exe" flash fsg "%FIRMWARE_PATH%\fsg.bin"
"%FASTBOOT_PATH%\fastboot.exe" flash modemst1 "%FIRMWARE_PATH%\modemst1.bin"
"%FASTBOOT_PATH%\fastboot.exe" flash modemst2 "%FIRMWARE_PATH%\modemst2.bin"
echo.
echo 正在擦除boot和rootfs分区以备刷写...
"%FASTBOOT_PATH%\fastboot.exe" erase boot
"%FASTBOOT_PATH%\fastboot.exe" erase rootfs
echo.

:: ===================================================================================================
::  自动查找并刷写 Armbian
:: ===================================================================================================
echo [步骤 6/7] 正在自动查找 Armbian 系统镜像...
echo.
set "ROOTFS_IMAGE_FILE="
set "BOOT_IMAGE_FILE="

:: 【新增】查找 boot.img 文件
for %%F in ("%IMAGES_PATH%\Armbian*.boot.img") do (
    set "BOOT_IMAGE_FILE=%%~fF"
)

:: 查找 rootfs.img 文件 (路径格式化为 %%~fF)
for %%F in ("%IMAGES_PATH%\Armbian*.rootfs.img") do (
    set "ROOTFS_IMAGE_FILE=%%~fF"
)

:: 【修改】检查 boot.img 是否找到
if not defined BOOT_IMAGE_FILE (
    echo [错误] 在 'images' 文件夹中没有找到匹配 'Armbian*.boot.img' 的文件！
    echo 请检查文件名是否正确，或者文件是否存在。
    pause
    exit
)
if not defined ROOTFS_IMAGE_FILE (
    echo [错误] 在 'images' 文件夹中没有找到匹配 'Armbian*.rootfs.img' 的文件！
    echo 请检查文件名是否正确，或者文件是否存在。
    pause
    exit
)

echo [成功] 自动检测到系统镜像为:
echo   Boot   : "%BOOT_IMAGE_FILE%"
echo   Rootfs : "%ROOTFS_IMAGE_FILE%"
echo.

echo [步骤 7/7] 正在刷入新的 Armbian 系统...
echo   此过程可能需要几分钟，请耐心等待，不要断开USB连接！
echo.
echo --- 正在刷入 boot 分区 ---
"%FASTBOOT_PATH%\fastboot.exe" flash boot "%BOOT_IMAGE_FILE%"
echo.
echo --- 正在刷入 rootfs 分区 (大文件，请耐心等待) ---
"%FASTBOOT_PATH%\fastboot.exe" -S 200m flash rootfs "%ROOTFS_IMAGE_FILE%"
echo.

:: ===================================================================================================
::  完成
:: ===================================================================================================
echo ===================================================================================================
echo.
echo [成功] 刷机流程已全部完成！
echo.
echo 设备将在 5 秒后自动重启进入新系统。祝您使用愉快！
echo.
echo ===================================================================================================

timeout /t 5 /nobreak
"%FASTBOOT_PATH%\fastboot.exe" reboot

echo.
echo 操作完成，按任意键退出窗口。
pause >nul

exit
