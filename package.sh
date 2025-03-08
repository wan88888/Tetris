#!/bin/bash

# 俄罗斯方块游戏打包脚本
# 用于创建.love文件和各平台的可执行文件

# 设置变量
GAME_NAME="tetris"
VERSION="1.0"
OUTPUT_DIR="./dist"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

echo "=== 开始打包俄罗斯方块游戏 ==="

# 检查是否缺少音频文件
if [ ! -f "audio/move.wav" ] || [ ! -f "audio/rotate.wav" ] || [ ! -f "audio/drop.wav" ] || \
   [ ! -f "audio/clear.wav" ] || [ ! -f "audio/gameover.wav" ]; then
    echo "警告：缺少音频文件！请确保以下文件存在："
    echo "  - audio/move.wav"
    echo "  - audio/rotate.wav"
    echo "  - audio/drop.wav"
    echo "  - audio/clear.wav"
    echo "  - audio/gameover.wav"
    echo "请创建这些文件后再继续。"
    exit 1
fi

# 创建.love文件
echo "正在创建 ${GAME_NAME}.love 文件..."
zip -9 -r "${OUTPUT_DIR}/${GAME_NAME}.love" . -x "*.git*" "*.DS_Store" "dist/*" "*.sh" "*.zip" "*.love"

echo "${GAME_NAME}.love 文件已创建在 ${OUTPUT_DIR} 目录中"

# 创建Windows版本
echo "正在创建Windows版本..."
if [ -f "${OUTPUT_DIR}/${GAME_NAME}-windows.zip" ]; then
    rm "${OUTPUT_DIR}/${GAME_NAME}-windows.zip"
fi

echo "注意：要创建Windows版本，你需要下载LÖVE for Windows并将其放在dist/love-win32目录中"
echo "你可以从 https://love2d.org/ 下载LÖVE for Windows"
echo "然后运行以下命令："
echo "mkdir -p dist/love-win32"
echo "# 将LÖVE for Windows解压到dist/love-win32目录"
echo "cat ${OUTPUT_DIR}/${GAME_NAME}.love >> dist/love-win32/love.exe"
echo "zip -9 -j -r ${OUTPUT_DIR}/${GAME_NAME}-windows.zip dist/love-win32/*"

# 创建macOS版本
echo "正在创建macOS版本..."
if [ -f "${OUTPUT_DIR}/${GAME_NAME}-macos.zip" ]; then
    rm "${OUTPUT_DIR}/${GAME_NAME}-macos.zip"
fi

echo "注意：要创建macOS版本，你需要下载LÖVE for macOS并将其放在dist/love-macos目录中"
echo "你可以从 https://love2d.org/ 下载LÖVE for macOS"
echo "然后运行以下命令："
echo "mkdir -p dist/love-macos"
echo "# 将LÖVE for macOS解压到dist/love-macos目录"
echo "cp ${OUTPUT_DIR}/${GAME_NAME}.love dist/love-macos/love.app/Contents/Resources/"
echo "zip -9 -r ${OUTPUT_DIR}/${GAME_NAME}-macos.zip dist/love-macos/love.app"

# 创建Linux版本
echo "正在创建Linux版本..."
if [ -f "${OUTPUT_DIR}/${GAME_NAME}-linux.zip" ]; then
    rm "${OUTPUT_DIR}/${GAME_NAME}-linux.zip"
fi

echo "注意：要创建Linux版本，你需要下载LÖVE for Linux并将其放在dist/love-linux目录中"
echo "你可以从 https://love2d.org/ 下载LÖVE for Linux"
echo "然后运行以下命令："
echo "mkdir -p dist/love-linux"
echo "# 将LÖVE for Linux解压到dist/love-linux目录"
echo "cp ${OUTPUT_DIR}/${GAME_NAME}.love dist/love-linux/"
echo "echo '#!/bin/bash\nlove ./tetris.love' > dist/love-linux/start.sh"
echo "chmod +x dist/love-linux/start.sh"
echo "zip -9 -r ${OUTPUT_DIR}/${GAME_NAME}-linux.zip dist/love-linux/*"

echo "=== 打包完成 ==="
echo "生成的文件位于 ${OUTPUT_DIR} 目录中："
echo "  - ${GAME_NAME}.love (可直接用LÖVE运行)"
echo "  - ${GAME_NAME}-windows.zip (Windows版本)"
echo "  - ${GAME_NAME}-macos.zip (macOS版本)"
echo "  - ${GAME_NAME}-linux.zip (Linux版本)"

echo "请按照README.md中的说明分发这些文件。"